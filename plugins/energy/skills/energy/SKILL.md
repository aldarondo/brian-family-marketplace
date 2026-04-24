---
description: Use this skill for anything about home energy reporting — solar production, battery state, pool heater consumption, EV charging, grid import/export, self-consumption ratio, weekly / monthly summaries, trend flags, and emailable energy reports. Reads coordinator telemetry from brian-mcp memory; does not control devices. Triggers include "energy status", "solar today", "energy report this week", "self-consumption ratio", "how much did the pool use", "EV charging this month", "is solar down", "email me the weekly energy summary".
---

# Skill: Home Energy Reporting & Pattern Aggregator

**Storage**: brian-mcp memory at `https://brian.aldarondo.family/mcp`, namespace `energy.*`.
**Reads from**: `energy.*` only (written by coordinator MCPs per SCHEMA.md).
**Talks to**: the `memory` MCP server for reads and rollup writes, and the `email` MCP server for outgoing summaries. **This skill does not control devices** — it never starts the pool heater, opens EV charging sessions, or dispatches solar. Action requests go to the coordinator MCPs directly (Claude routes based on their tool descriptions).

---

## Scope boundary — read carefully

If the user asks for an **action** ("start the pool heater", "charge the Tesla", "disable grid export"), do NOT use this skill. Let the model route to the appropriate coordinator MCP tool directly. This skill only handles **reporting**:

- "how much / how many" — yes
- "what is the status" — yes
- "what happened" — yes
- "do X" — no, hand off

When in doubt, ask: "Do you want the status, or do you want me to actually start/stop something?"

---

## Data model recap (see SCHEMA.md for full detail)

| Tag family | What it holds |
|---|---|
| `energy.reading.*` | Point-in-time telemetry from coordinators — instantaneous kW, SoC %, cumulative kWh |
| `energy.event.*` | Bounded events — pool heating sessions, EV charge sessions, grid outages |
| `energy.rollup.*` | Precomputed aggregates written by this skill — daily, weekly, monthly |
| `energy.note` | Free-text annotations from a human ("panels washed", "breaker tripped") |

No `user:` tag — energy is household-scoped.

---

## Current status

**Trigger**: "energy status now", "what's happening now", "solar right now".

1. Load the most recent `energy.reading.solar_production` → current kW.
2. Load the most recent `energy.reading.battery_soc` → current %.
3. Load the most recent `energy.reading.grid_import` and `energy.reading.grid_export` → net grid flow sign.
4. Load the most recent `energy.reading.pool_consumption` and `energy.reading.ev_consumption`.
5. Check for in-progress events (`energy.event.*` with `ended_at: null`).

Display:
```
Energy — [timestamp, local]

Solar       [kW]        (today so far: [kWh])
Battery     [% SoC]     ([charging | discharging | idle] at [kW])
Grid        [importing | exporting] at [kW]

Active:
  Pool heater — running for [duration], [kWh] so far
  EV charge   — [vehicle], [kWh] delivered, [kW] now

Last reading ages: solar [Ns ago], battery [Ns ago], ...
```

If any source's last reading is older than 30 minutes, flag it: "Solar coordinator silent for [N] min — check enphase MCP."

---

## Daily rollup

**Trigger**: "energy today", "how much solar today", "today's energy report".

1. Compute the current calendar date (user-local).
2. Check for a cached `energy.rollup.daily` memory for today. If present AND today is closed (past midnight), return it. If today or not found, regenerate.
3. To regenerate:
   - Integrate `energy.reading.solar_production` power samples over the day → `solar_produced_kwh`. Prefer `cumulative_today_kwh` when the source provides it (more accurate than Riemann sum); otherwise trapezoidal integration between samples.
   - Same for `grid_import`, `grid_export`, `pool_consumption`, `ev_consumption`, `home_consumption` if available.
   - Sum `energy.event.pool_heating` and `energy.event.ev_charge` `energy_kwh` that fell within today.
   - Derive `home_other_kwh = (solar_produced + grid_imported − grid_exported + battery_discharged − battery_charged) − pool_kwh − ev_kwh`.
   - Compute `self_consumption_ratio = (solar_produced − grid_exported) / solar_produced` (clamp 0–1).
   - Compute `peak_solar_kw` and `hours_above_4kw`.
4. Store as `energy.rollup.daily` (delete old daily rollup for the same date if regenerating).
5. Display:
```
Energy — [YYYY-MM-DD]

Produced         [solar kWh]
  peak            [kW] at [HH:MM]
  hours > 4kW     [N]

Consumed on-site  [kWh]   (self-consumption [NN]%)
  pool heater    [kWh]
  EV charging    [kWh]    ([M] sessions)
  rest of house  [kWh]

Grid             +[import kWh] in / −[export kWh] out  (net [kWh])
Battery          +[charged] / −[discharged]   min [NN]% max [NN]%
```

---

## Weekly rollup

**Trigger**: "energy report this week", "weekly energy summary", "solar vs pool vs EV this week".

1. Resolve the target week (default: current ISO week, Monday start).
2. Load the 7 daily rollups for that week (regenerate today's if needed).
3. Sum and average across days.
4. Compare to the prior 7 days for `vs_prev_week_pct`.
5. Write `energy.rollup.weekly` if the week is closed.
6. Display (same structure as daily, plus day-by-day mini-table and vs-prev-week delta).

Apply trend flags at the bottom:
- Solar production down > 15% vs trailing 28-day avg → "Solar production down — check panel output, weather, or coordinator."
- Self-consumption ratio down > 10 percentage points vs 28-day avg.
- EV consumption up > 30% vs baseline.
- Pool kWh up > 50% vs 28-day avg → "Pool consumption spiked — check for stuck heater or colder pool target."
- Any day with > 2 hours of coordinator silence → "Coordinator gaps detected: [source slugs]."

Include any `energy.note` memories that fell inside the week, under a "Notes" footer.

---

## Monthly rollup

**Trigger**: "energy this month", "monthly energy summary", "solar by month".

1. Resolve the target month.
2. Load weekly rollups for that month (regenerate as needed).
3. Sum, and compute `vs_prev_month_pct` and `vs_same_month_last_year_pct` if data exists.
4. Write `energy.rollup.monthly` if the month is closed.
5. Display similar to weekly with year-over-year line if available.

---

## Channel queries

**Trigger**: "how much did the pool use this month", "EV charging last 30 days", "when did we last run the pool heater".

Single-channel view — load the relevant reading subtype or event subtype for the period, sum, and display with session-level detail for events:

```
Pool heater — last 30 days

Total: [kWh] across [N] sessions
Avg session: [duration], [kWh]
Longest: [date], [duration], [kWh]

Recent:
  Apr 22  2h 14m  9.1 kWh   reached 86°F
  Apr 19  1h 40m  6.8 kWh   ...
```

---

## Self-consumption ratio

**Trigger**: "self-consumption ratio", "how much solar did we actually use".

Definition: `(solar_produced − grid_exported) / solar_produced`, clamped to [0, 1].

Compute for: today, this week, this month, last 28 days. Show the four numbers side by side with a short interpretation (higher = more solar stayed home).

---

## Energy notes

**Trigger**: "note: panels washed", "log: breaker tripped at 2pm", "remember: new Tesla wall connector installed".

Store:
```
energy.note: [free text]
at: [ISO 8601 with offset — default: now]
logged_by: [person]
```
Tag: `energy.note`.

Confirm with a one-line readback. Notes are surfaced alongside matching rollup periods.

---

## Email

**Trigger**: "email me the weekly energy summary", "send Charles the monthly energy report".

Rules (apply the marketplace email contract):
- Send only on explicit request.
- brian-email is send-only. All rollups and notes continue to live in memory under `energy.*`.
- Resolve recipient names via the `contacts` plugin. If unresolved, ask.
- For the weekly default: run the weekly rollup, render it as plain text with the trend-flag block at the bottom, subject `Energy summary — [week-of] — solar [kWh], self-consumption [NN]%`.
- Confirm recipient, subject, and preview before sending.

---

## Source availability

Always include in reports a "Sources used" footer listing which `source:[slug]` tags contributed to the rollup. If a coordinator you expected is missing for the whole period, call it out: "No enphase data this week — solar coordinator may be offline."

This is the cue Charles needs to find a silent coordinator without having to open three dashboards.

---

## Error / Edge Cases

| Situation | Handling |
|---|---|
| No readings at all for the period | "No energy data in memory for [period]. Check that the coordinator MCPs are writing." |
| One coordinator silent, others live | Report what's available; flag the gap loudly. Do NOT substitute guessed values. |
| Partial day (early in the day, or missing hours) | Report partials with explicit coverage note: "Covers 06:00–14:00 today; expect this to shift as the day progresses." |
| User asks for an action | Don't execute. Say: "I'm the reporting skill — for that, I'll hand off to the [solar/pool/EV] coordinator. Want me to do that?" |
| Memory read failure | "I couldn't reach the memory service. Try again shortly or check the Brian tunnel." |

---

## Tone

Concrete and numeric. No editorializing about "green" or "sustainability" unless the user leads. When something is off, say so plainly and point at the likely cause.

---

## Storage rule

All persistent data written by this skill lives in brian-mcp memory under `energy.*`. No local files. No external stores. brian-email is send-only and never used for storage. Rollups are the only writes this skill performs — it never modifies coordinator telemetry.
