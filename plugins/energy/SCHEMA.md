# Energy Memory Schema — Contract for Coordinator MCPs

This document is the **source of truth** for how home-energy data is written into `brian-mcp` by coordinator MCPs (solar, pool heater, EV charging, home battery, whole-home meter, etc.) so that the `energy` plugin in this marketplace can read a consistent shape regardless of source.

**Rule of thumb**: every energy-adjacent memory must be reachable by tag filter `energy.*`, must declare its `source`, must carry a real timestamp with timezone offset, and must be idempotent against re-polling.

---

## Four Top-Level Categories

| Category | Tag | Purpose |
|---|---|---|
| `energy.reading` | Point-in-time telemetry | Power (kW), state of charge (%), meter totals (kWh cumulative) |
| `energy.event` | Bounded event | A pool-heating session, an EV charge session, a grid outage |
| `energy.rollup` | Precomputed summary | Daily / weekly / monthly aggregates (written by the energy plugin itself) |
| `energy.note` | Human annotation | "panels washed", "breaker tripped", "new EVSE installed" |

Additional categories may be added later. Do not overload the four above.

---

## Required Tags (every memory)

Every energy memory MUST include **all** of these tags:

1. Category: one of `energy.reading`, `energy.event`, `energy.rollup`, `energy.note`
2. Subtype: `energy.reading.[subtype]`, `energy.event.[subtype]`, or `energy.rollup.[period]`
3. Source: `source:[slug]` — see **Source Slugs**

Optional tags:

- `device:[slug]` — specific device within a source (e.g. `device:enphase-envoy`, `device:pentair-intelliflo`, `device:tesla-wall-connector`)

**Example tag set** for a solar production reading:
```
energy.reading, energy.reading.solar_production, source:enphase
```

No `user:` tag — energy data is household-scoped, not per-person.

---

## Required Content Fields (every memory)

Write one memory per data point (or one memory per event for `energy.event`). Content is free-form text but MUST include these fields in key: value form:

| Field | Type | Notes |
|---|---|---|
| `source` | string | Same as `source:[slug]` tag |
| `source_id` | string | Coordinator's native ID for this record. Used for idempotency. Synthesize a stable hash of `source + subtype + measured_at` if no native ID exists. |
| `subtype` | string | Matches the subtype tag (e.g. `solar_production`, `pool_consumption`, `ev_charge`) |
| `measured_at` | ISO 8601 with offset | When the measurement or event happened, user-local time with explicit offset |
| `ingested_at` | ISO 8601 UTC | When the coordinator wrote this memory |

---

## `energy.reading` Subtypes

Units are fixed — convert before writing. Polling cadence is up to each coordinator; a reasonable default is every 5 minutes for power readings and every 1 minute for SoC.

### `solar_production`
```
value: [decimal, kW — instantaneous]
unit: kW
cumulative_today_kwh: [decimal or null — coordinator's day-total if available]
```

### `grid_import`
```
value: [decimal, kW]
unit: kW
cumulative_today_kwh: [decimal or null]
```

### `grid_export`
```
value: [decimal, kW]
unit: kW
cumulative_today_kwh: [decimal or null]
```

### `battery_soc`
```
value: [integer, percent 0–100]
unit: percent
power_kw: [decimal — positive = discharging, negative = charging, or null]
```

### `battery_energy`
```
value: [decimal, kWh currently stored]
unit: kWh
capacity_kwh: [decimal — total battery capacity]
```

### `pool_consumption`
```
value: [decimal, kW — instantaneous pump + heater draw]
unit: kW
cumulative_today_kwh: [decimal or null]
mode: [heating | circulating | off | null]
```

### `ev_consumption`
```
value: [decimal, kW — instantaneous EVSE draw]
unit: kW
cumulative_today_kwh: [decimal or null]
vehicle: [slug or null — e.g. "tesla-model-y", "leaf"]
```

### `home_consumption`
Whole-home meter reading, if available (not derived).
```
value: [decimal, kW]
unit: kW
cumulative_today_kwh: [decimal or null]
```

---

## `energy.event` Subtypes

One memory per bounded event. `measured_at` = event start. Include start and end so the skill can compute duration.

### `pool_heating`
```
started_at: [ISO 8601 with offset]
ended_at: [ISO 8601 with offset or null if in progress]
duration_sec: [integer or null]
energy_kwh: [decimal — total kWh consumed during session]
target_temp_f: [decimal or null]
reached_target: [true | false | null]
```

### `ev_charge`
```
started_at: [ISO 8601 with offset]
ended_at: [ISO 8601 with offset or null if in progress]
duration_sec: [integer or null]
energy_kwh: [decimal — total kWh delivered]
start_soc_pct: [integer or null]
end_soc_pct: [integer or null]
avg_kw: [decimal or null]
vehicle: [slug]
connector: [slug or null — e.g. "wall-connector", "level2-public"]
```

### `grid_outage`
```
started_at: [ISO 8601 with offset]
ended_at: [ISO 8601 with offset or null if in progress]
duration_sec: [integer or null]
battery_kwh_discharged: [decimal or null]
```

---

## `energy.rollup` Subtypes (written by the energy plugin, not coordinators)

### `daily`
One memory per calendar date (user-local).
```
date: [YYYY-MM-DD]
solar_produced_kwh: [decimal]
grid_imported_kwh: [decimal]
grid_exported_kwh: [decimal]
battery_charged_kwh: [decimal]
battery_discharged_kwh: [decimal]
pool_kwh: [decimal]
ev_kwh: [decimal]
home_other_kwh: [decimal — derived]
self_consumption_ratio: [decimal 0–1]
peak_solar_kw: [decimal]
hours_above_4kw: [decimal]
```
Regenerate for today on request; treat as immutable once the date flips.

### `weekly`
One per ISO week (Monday start).
```
week_start: [YYYY-MM-DD]
[same fields as daily, summed / averaged appropriately]
vs_prev_week_pct: { solar_produced: [decimal], pool_kwh: [decimal], ev_kwh: [decimal] }
```

### `monthly`
One per calendar month.
```
month: [YYYY-MM]
[same fields as weekly, summed / averaged]
vs_prev_month_pct: { ... }
vs_same_month_last_year_pct: { ... }
```

---

## `energy.note`

Free-text annotations. The skill surfaces notes alongside rollups when the note falls inside the rollup period.

```
note: [free text]
at: [ISO 8601 with offset]
logged_by: [person]
```

Tags: `energy.note`.

---

## Idempotency — Do Not Write Duplicates

Coordinators that poll will surface the same record repeatedly. Before writing, each MCP MUST search for an existing memory with the same `source:[slug]` tag and `source_id`:

1. **Search-then-write** (preferred): `memory_search(tags: ["source:[slug]", "energy.[category]"], query: "source_id: [id]")`. Skip write if any hit.
2. **Update-in-place**: if a record has been revised (e.g. an EV-charge session ended and the coordinator now knows final kWh), delete the old memory by `content_hash` and write the updated one. Preserve `source_id`.

For in-progress events (`ended_at: null`), allow one open memory per `source_id`. Close it on completion by updating in place.

---

## Source Slugs

Use these exact lowercase slugs. Add new slugs here when new coordinators ship.

| Slug | Coordinator / Device |
|---|---|
| `enphase` | Enphase Envoy / IQ Gateway (solar + battery) |
| `tesla-powerwall` | Tesla Powerwall / Gateway |
| `tesla-evse` | Tesla Wall Connector (EV charging) |
| `chargepoint` | ChargePoint Home Flex |
| `pentair` | Pentair IntelliCenter (pool) |
| `hayward` | Hayward OmniLogic (pool) |
| `emporia` | Emporia Vue whole-home meter |
| `sense` | Sense whole-home meter |
| `manual` | Entered by a human via the energy skill (e.g. `energy.note`) |

---

## Read Access from the `energy` Plugin

For reference, the skill reads via:

```
memory_search(tags: ["energy.reading.[subtype]"], limit: 2000)   # telemetry window
memory_search(tags: ["energy.event.[subtype]"], limit: 500)       # events in a period
memory_search(tags: ["energy.rollup.[period]"], limit: 24)        # cached rollups
memory_search(tags: ["energy.note"], limit: 100)                  # recent notes
```

then narrows by `measured_at` range parsed from content.

---

## Versioning

This schema is **v1**. Breaking changes require:
1. A new version tag here (`v2`) with a migration note.
2. A transitional period where both shapes are accepted by the skill.

Add `schema_version: 1` field only when you need to pin a specific record. Absence implies v1.
