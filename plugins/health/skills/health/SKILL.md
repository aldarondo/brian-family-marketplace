---
description: Use this skill whenever a family member wants an aggregated view or evaluation of their health. Reads whatever health data is present in brian-mcp memory (prescriptions, food-log, meal-plan, vitals and activity from vendor MCPs, manual entries) and produces a single status-level report with concerns and recommendations. Triggers include "how is my health", "health check", "evaluate my health", "run a health evaluation", "any concerns", "compare my health", "what does my data say", "email me my weekly summary", "log my BP", "record my weight".
---

# Skill: Personal Health Aggregator & Evaluator

**Storage**: brian-mcp memory at `https://brian.aldarondo.family/mcp`, namespace `health.*`, scoped per user via `user:[name]` tag.
**Reads from**: `health.*`, `prescriptions.*`, `food.*`, `mealplan.*` (the last is shared).
**Talks to**: only the `memory` MCP server for reads/writes, and the `email` MCP server for optional outgoing email. Never calls Withings, Whoop, Apple Health, or any other vendor API directly — those are upstream MCPs that write into memory.

---

## Identity & Privacy — Read This First

**Who is the current user?**

1. Check the session context or CLAUDE.md for `HEALTH_USER: [name]`. Fall back to `PRESCRIPTIONS_USER` or `FOOD_LOG_USER` if set.
2. If none are set, ask once: "Just to confirm — what's your name? (Charles, Moriah, Jack, or Quincy)"
3. Store the confirmed name as the active user for all operations this session.

**Privacy rules:**

| Rule | Behavior |
|---|---|
| Default: private | Reads memories tagged `user:[name]` where name = active user, across `health.*`, `prescriptions.*`, and `food.*` |
| `mealplan.*` exception | `mealplan.*` is shared family data (no per-user filter) — use it only as a dietary-pattern signal, never attribute it to a person's private record |
| Moriah ↔ Emil | Moriah can read and evaluate Emil's data; if Moriah says "for Emil" or "Emil's health" → target is `user:emil` |
| Cross-person queries refused | "I keep health data private. I can only evaluate [Name]'s health with them directly." |
| No medical advice | Summarize and flag patterns; never diagnose. Close every report with a reminder to follow up with a clinician for anything flagged. |

**Memory tag conventions (writes):**
- Saved evaluations: `health.evaluation,user:[name]`
- Saved vitals: `health.vital,user:[name],health.vital.[type],source:manual`
- Saved notes: `health.note,user:[name]`

---

## Step 0: Identify Requester and Target

1. Confirm the active user.
2. Determine target: default = active user; Moriah saying "for Emil" → target is `user:emil`.
3. All memory reads filter by `user:[target]` except `mealplan.*` which is shared.

---

## How the evaluator is structured

The skill is **subtype-keyed**, not source-keyed. Any memory that matches a subtype below is evaluated — regardless of which MCP wrote it. A new vendor (e.g. `claude-withings`) starting to write tomorrow will be picked up automatically because its writes land under the same subtype tags.

Run every evaluator in the list. Each returns either a **findings block** (one or more bullets) or nothing. Empty evaluators are skipped silently in the report.

Track which `source:` tags contributed across all evaluators — surface them in the report footer so the user knows what's in scope.

---

## Subtype Evaluators — Vitals (`health.vital.*`)

Query pattern for each subtype:
```
memory_search(tags: ["health.vital.[subtype]", "user:[target]"], limit: 200)
```

Parse `measured_at` and subtype-specific fields from each memory per SCHEMA.md. Skip a subtype silently if no data.

### weight
- Compute 7-day, 28-day, 90-day rolling averages.
- Flag `> 5%` change over 30 days (gain or loss). Flag `> 10%` over 90 days.
- If `body_fat_pct` present, trend it too (flag `> 3pp` change over 30 days).
- Latest value always shown.

### blood_pressure
- Compute 7-day and 28-day averages (systolic and diastolic separately).
- Flag if 7-day systolic avg ≥ 140 OR diastolic avg ≥ 90 — "BP trending hypertensive — worth a check with your PCP."
- Flag if 7-day systolic ≥ 180 OR diastolic ≥ 120 at any single reading — "Reading in the hypertensive-crisis range. Call your doctor today."
- Flag if 7-day avg drops 20%+ below 28-day avg — possible symptom, worth a check.

### heart_rate
- Split by `context` field (resting / active / recovery / max).
- For resting: flag 7-day avg > 90 bpm or sudden 10+ bpm rise vs 28-day avg.
- For resting: flag 7-day avg < 45 bpm unless `notes` indicate trained athlete.

### spo2
- Flag any reading < 92%. Flag 7-day average < 94%.

### body_temperature
- Flag any reading ≥ 38.0 °C (100.4 °F) → "Fever recorded on [date]."
- Flag sustained > 37.5 °C across multiple days.

### blood_glucose
- Split by `context` (fasting / post_meal / random / bedtime).
- Fasting: flag > 125 mg/dL sustained (ADA diabetes threshold) or < 70 mg/dL any.
- Post-meal (2h): flag > 180 mg/dL sustained.

### respiratory_rate
- Flag 7-day avg outside 12–20 breaths/min.

### hrv
- Compute 7-day and 28-day averages.
- Flag 7-day avg down ≥ 15% vs 28-day baseline — "HRV trending down. Often a recovery signal; check sleep and stress."

---

## Subtype Evaluators — Activity (`health.activity.*`)

### sleep
- 7-day avg duration, efficiency, deep+REM proportion.
- Flag 7-day avg duration < 6h → "Sleep below 6h/night this week."
- Flag efficiency 7-day avg < 80%.
- Flag 3+ nights in the last 7 with sleep onset past 1am (from `started_at`).

### workout
- Count workouts per week, types, total duration, avg HR.
- Informational: summarize last week. Flag only if 0 workouts for 14+ days AND any other metric (sleep, HRV, weight) is trending poorly.

### steps_daily
- 7-day average steps.
- Flag 7-day avg below `goal × 0.7` if `goal` present. Else flag < 4,000 steps/day.

### recovery_daily
- 7-day average Whoop-style recovery score.
- Flag 5+ consecutive days in red (< 34) → "Recovery in red for a week straight — suggests accumulating fatigue."
- Flag 7-day avg < 40.

### strain_daily
- 7-day average strain score.
- Flag pattern: sustained strain ≥ 15 alongside recovery 7-day avg < 50 → "High strain with low recovery — risk of burnout."

---

## Subtype Evaluators — Medications (`prescriptions.*`)

Input: `memory_search(query: "prescriptions item", tags: ["prescriptions.item", "user:[target]"], limit: 50)`.

Compute:
- `rx_count` / `otc_count` / `total_count`
- Polypharmacy flags: `rx_count ≥ 5`, or `total_count ≥ 10`
- Interaction flags: run the interaction table mirrored from the prescriptions plugin. Report every pair that triggers.
- Refill risk: any item `refills_remaining === 0` with no `renewal_needed`; any `prescription_expires` within 30 days.
- Adherence risk: items where `next_refill` is more than 14 days past.
- Load by schedule slot: count per `morning | lunch | evening | bedtime | as_needed`. Flag any slot > 8 items.
- Cross-reference with vitals: if BP meds are on the list and BP subtype is trending hypertensive → explicitly note "BP medications present but BP trending high — possible adherence or dosing issue."

---

## Subtype Evaluator — Nutrition (`food.entry` from food-log plugin)

Input: `memory_search(query: "food entry [target]", tags: ["food.entry", "user:[target]"], limit: 14)` (last 14 days).

For each day, parse `totals: { calories, protein_g, carbs_g, fat_g }`. Skip days with no data.

Compute over the last 7 days of logged entries:
- Avg daily calories, avg protein (g and g/kg if `weight` vital recent is known), avg carbs, avg fat.
- Protein goal heuristic: `1.2 × weight_kg` grams/day for adults. Flag if 7-day avg is below 75% of that.
- Flag 3+ days with logged calories < 1200 (rapid/restrictive intake) OR > 4000 (possible logging error or high-stress eating).
- Note logging frequency: "6 of last 7 days logged" — if < 4/7, report "Food-log coverage thin this week — treat these numbers as directional."

Cross-reference with medications:
- If the prescriptions list includes anything flagged as "take with food" and food-log shows days with < 3 logged eating windows → note "Some meds work best taken with food; your log shows [N] days with sparse eating windows."

---

## Subtype Evaluator — Dietary Pattern (`mealplan.week` — shared)

Input: load the current week's and last week's plans.

```
memory_search(query: "mealplan week [monday-date]", tags: ["mealplan.week"], limit: 4)
```

This is shared family data — use it only as a household pattern signal, never as a personal attribution.

Compute:
- Variety: distinct proteins and cuisines across 7 days (look at recipe titles and tags). Flag if ≥ 4 of 7 dinners share the same primary protein or cuisine.
- Vegetable proxy: count recipes whose tags include `vegetarian`, `vegetable-heavy`, or `salad`. Flag if 0 of 7 across two consecutive weeks.
- Medication/allergy conflicts: for the active user, check `prescriptions.*` notes for any "avoid X" mentions. Scan the meal-plan's recipe titles + ingredient lists (fetch via `recipes.*` when needed) for matches and flag.

Output a short "Household dietary pattern" block — do NOT treat it as a personal verdict.

---

## Overall Assessment

Synthesize signals across all evaluators into one of three statuses:

- **Stable** — zero flags
- **Watch** — informational flags only (e.g. modest trends, dietary variety notes, upcoming refills)
- **Action suggested** — at least one flag with clinical or refill urgency (BP crisis reading, out-of-refills with no renewal, extended low recovery, fever, hypoglycemia reading, etc.)

**Key concerns**: up to 3 bullets drawn from the strongest flags across all evaluators.

**Suggested next steps**: short, concrete.
- "Schedule a medication review with Dr. [name]."
- "Call [pharmacy] to renew [medication] — expires [date]."
- "Shift bedtime earlier this week — sleep 7-day avg at 5h 40m."
- "Hit 1.5 L water and one vegetable side with the next three dinners."

---

## Report Format

```
HEALTH EVALUATION — [Full Name]
As of [today's date]
────────────────────────────────

STATUS: [Stable | Watch | Action suggested]

Key concerns:
• [bullet]
• [bullet]
• [bullet]

Suggested next steps:
• [bullet]
• [bullet]

────────────────────────────────
[Subtype blocks in order: Vitals → Activity → Medications → Nutrition → Dietary pattern — skip any that produced no findings]

[Vitals block]
[Activity block]
[Medications block]
[Nutrition block]
[Dietary pattern block]

────────────────────────────────
Sources used: [comma-separated list of source tags that contributed — e.g. "prescriptions, food-log, mealplan, withings, whoop, manual"]
Coverage: [brief note on what was missing — e.g. "No vitals this period; Withings not yet writing."]

Not a diagnosis — share with your clinician for anything flagged.
```

---

## Save / Compare Snapshots

### Save a snapshot
Triggered on user confirmation or explicit "save this".
```
health.evaluation: [Full Name] — [YYYY-MM-DD]
user: [name]
date: [YYYY-MM-DD]
status: [Stable | Watch | Action suggested]
rx_count: [N]
otc_count: [N]
flags: [summary counts per category]
sources_used: [comma-separated list]
report: |
  [full report text]
```
Tags: `health.evaluation,user:[name]`.

### Compare to previous
Trigger: "compare my health", "did anything change since last time".

1. Load `health.evaluation` memories for the user, sorted newest first.
2. If < 2: "I only have [0 or 1] snapshot. Run a health check and save it, then come back after your next one."
3. Produce today's evaluation (do not save).
4. Diff key numbers vs most recent saved snapshot: rx_count, flag counts per category, status change, and any newly appearing or resolved flags.
5. Display today's report, then a CHANGES section, then offer to save.

---

## Manual Write Paths

Accept writes even when an evaluator stub exists elsewhere — the data accrues for trend queries.

**Triggers**: "log my BP 128/82", "record my weight 82.3 kg", "log my blood sugar 118 fasting", "note: fatigue today".

For vitals/activity, write in the SCHEMA.md shape with `source:manual`:

```
health.vital: [type] [value] [unit]
user: [name]
source: manual
source_id: manual-[name]-[type]-[ISO timestamp]
type: [subtype]
measured_at: [ISO 8601 with offset, user-local]
ingested_at: [ISO 8601 UTC now]
[subtype-specific fields per SCHEMA.md]
```
Tags: `health.vital,user:[name],health.vital.[subtype],source:manual`.

For notes: `health.note` tagged `user:[name]`, free text content.

Confirm the write with a one-line readback. Do not retroactively re-run the evaluator unless the user asks.

---

## Email

Triggers: "email me my weekly summary", "send this report to Dr. [name]".

Rules (apply the marketplace email contract):
- Send only on explicit request.
- brian-email is send-only. Never treat it as storage — the report text continues to live in `health.evaluation` when saved.
- Resolve recipient names via the `contacts` plugin (`contacts.contact`, `category:medical` or `care-team`). If unresolved, ask.
- For a clinician recipient, trim to the structured summary and omit free-text notes unless the user approves.
- Confirm recipient, subject, and a preview of the body before sending.
- Plain text. Short subject — "Health summary — [Name] — [date range]".

---

## Error / Edge Cases

| Situation | Handling |
|---|---|
| No user identifier set | Ask once: "Charles, Moriah, Jack, or Quincy?" |
| No data in any evaluator | "I don't have enough data yet to evaluate [name]'s health. Add medications via the prescriptions plugin, log some food, or wait for the Withings/Whoop MCPs to come online." |
| Cross-person request (except Moriah→Emil) | "I keep health data private." |
| Memory read failure | "I couldn't reach the memory service. Try again shortly or check the Brian tunnel." |
| Interaction table disagreement with prescriptions skill | Source of truth is `prescriptions/SKILL.md`. When that table changes, update this skill. |
| User asks for a diagnosis | "I summarize patterns and flag things worth asking a clinician, but I won't diagnose. Want me to pull together a list for your next appointment?" |

---

## Tone

Calm, concrete, never alarmist. Frame flags as "worth discussing" rather than "wrong." Always close with a reminder that this is a summary for self-awareness, not medical advice. No emoji, no dramatic language.

---

## Storage rule

All persistent data written by this skill lives in brian-mcp memory under `health.*` with `user:[name]`. No local files. No external stores. brian-email is send-only and never used for storage.
