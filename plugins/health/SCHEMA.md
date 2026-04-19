# Health Memory Schema — Contract for Vendor MCPs

This document is the **source of truth** for how health data is written into `brian-mcp` by upstream vendor MCPs (Withings, Whoop, Google Health Connect bridge, manual entry, etc.) so that the `health` plugin in this marketplace can read a consistent shape regardless of source.

**Rule of thumb**: every health-adjacent memory must be reachable by tag filter `health.*` + `user:[name]`, must declare its `source`, must carry a real timestamp, and must be idempotent against re-polling.

---

## Two Top-Level Categories

| Category | Tag | Purpose |
|---|---|---|
| `health.vital` | Point-in-time measurement | Weight, BP, HR, SpO2, glucose, temp, HRV, body comp |
| `health.activity` | Bounded event or daily rollup | Workouts, sleep sessions, daily step totals, Whoop recovery/strain |

(Additional categories may be added later: `health.lab`, `health.symptom`, `health.medication_event`. Do not overload the two above.)

---

## Required Tags (every memory)

Every health memory MUST include **all** of these tags:

1. Category: `health.vital` or `health.activity`
2. User scope: `user:[name]` — lowercase, one of `charles | moriah | jack | quincy | emil`
3. Subtype: `health.vital.[type]` or `health.activity.[type]` (see tables below)
4. Source: `source:[vendor]` — lowercase vendor slug (see **Source Slugs**)

Optional tags:

- `device:[slug]` — specific device when vendor has multiple (e.g. `device:body-cardio` for a Withings scale)
- `manual` — when `source:manual` (redundant but helps discovery)

**Example tag set** for a Withings weight reading for Charles:
```
health.vital, user:charles, health.vital.weight, source:withings, device:body-cardio
```

---

## Required Content Fields (every memory)

Write one memory per data point. Content is free-form text but MUST include these fields in key: value form (the health skill parses by key, not position):

| Field | Type | Notes |
|---|---|---|
| `user` | string | Same value as `user:[name]` tag |
| `source` | string | Same as `source:[vendor]` tag |
| `source_id` | string | Vendor's native ID for this record. Used for idempotency. If the vendor has none, synthesize a stable hash from `source + type + measured_at`. |
| `type` | string | Subtype slug matching the tag (e.g. `weight`, `blood_pressure`, `workout`) |
| `measured_at` | ISO 8601 with offset | When the measurement happened, user-local time + explicit offset, e.g. `2026-04-19T08:15:00-04:00`. Never UTC-only without offset. |
| `ingested_at` | ISO 8601 UTC | When the MCP wrote this memory, e.g. `2026-04-19T12:30:00Z`. |

Optional but encouraged:

- `raw_ref` — a short pointer (URL or vendor record ID) back to the source record, in case re-fetching is needed. Do NOT dump full vendor payloads into memory — keep entries small.

---

## `health.vital` Subtypes

Each subtype adds its own required fields on top of the required set above. Units are fixed — convert before writing so the skill doesn't have to.

### `weight`
```
value: [kg, decimal]
unit: kg
body_fat_pct: [decimal or null]
muscle_mass_kg: [decimal or null]
bone_mass_kg: [decimal or null]
water_pct: [decimal or null]
visceral_fat: [integer or null]
```

### `blood_pressure`
```
systolic: [integer, mmHg]
diastolic: [integer, mmHg]
pulse: [integer bpm or null]
position: [sitting | standing | lying | null]
arm: [left | right | null]
```

### `heart_rate`
```
value: [integer, bpm]
unit: bpm
context: [resting | active | max | recovery]
```

### `spo2`
```
value: [integer, percent]
unit: percent
```

### `body_temperature`
```
value: [decimal, celsius]
unit: celsius
site: [oral | tympanic | forehead | core | null]
```

### `blood_glucose`
```
value: [integer, mg/dL]
unit: mg/dL
context: [fasting | post_meal | random | bedtime | null]
```

### `respiratory_rate`
```
value: [integer, breaths per minute]
unit: bpm
```

### `hrv`
```
value: [decimal, milliseconds]
unit: ms
method: [rmssd | sdnn | ln_rmssd]
context: [sleep | resting | null]
```

---

## `health.activity` Subtypes

### `workout`
```
activity: [running | cycling | strength | yoga | swim | hiit | walk | other]
started_at: [ISO 8601 with offset]
ended_at: [ISO 8601 with offset]
duration_sec: [integer]
distance_m: [integer or null]
calories: [integer or null]
avg_hr: [integer bpm or null]
max_hr: [integer bpm or null]
strain: [decimal or null]   # Whoop-style 0–21
```
Note: for `workout`, `measured_at` = `started_at`.

### `sleep`
One memory per sleep session. Primary tag `health.activity.sleep`.
```
started_at: [ISO 8601 with offset]
ended_at: [ISO 8601 with offset]
duration_sec: [integer]
efficiency_pct: [integer 0–100 or null]
stages:
  awake_sec: [integer or null]
  light_sec: [integer or null]
  deep_sec: [integer or null]
  rem_sec: [integer or null]
disturbances: [integer or null]
respiratory_rate_avg: [decimal or null]
```
Note: `measured_at` = `ended_at` (sleep session is keyed to wake time for trend queries).

### `steps_daily`
Daily rollup — one memory per calendar date per user.
```
date: [YYYY-MM-DD, user-local]
count: [integer]
goal: [integer or null]
distance_m: [integer or null]
active_minutes: [integer or null]
```
Note: `measured_at` = `[date]T23:59:59[offset]`.

### `recovery_daily` (Whoop-style)
```
date: [YYYY-MM-DD, user-local]
score: [integer 0–100]
hrv_ms: [decimal or null]
rhr_bpm: [integer or null]
spo2_pct: [decimal or null]
```

### `strain_daily` (Whoop-style)
```
date: [YYYY-MM-DD, user-local]
score: [decimal 0–21]
kilojoules: [integer or null]
avg_hr: [integer or null]
max_hr: [integer or null]
```

---

## Idempotency — Do Not Write Duplicates

Polling vendor APIs will surface the same record repeatedly. Before writing, each vendor MCP MUST search for an existing memory with the same `source:[vendor]` tag and the same `source_id` value. Two options:

1. **Search-then-write** (preferred): `memory_search(tags: ["source:[vendor]", "health.[category]"], query: "source_id: [id]")`. Skip write if any hit.
2. **Update-in-place**: if the vendor record has changed (corrected weight, reclassified workout), delete the old memory by `content_hash` and write the new one. Preserve `source_id`.

Daily rollups (`steps_daily`, `recovery_daily`, `strain_daily`) should be upserted for today until the date flips — vendors often revise same-day numbers.

---

## Source Slugs

Use these exact lowercase slugs for the `source:` tag and `source` field. Add new slugs here when new MCPs ship.

| Slug | Vendor / Origin |
|---|---|
| `withings` | Withings Health Mate API |
| `whoop` | Whoop Developer API |
| `health-connect` | Google Health Connect (via Android bridge) |
| `apple-health` | Apple Health (via iOS bridge) |
| `manual` | Entered by a human via the health skill |
| `prescriptions` | Derived from the `prescriptions` plugin (reserved — do not write here directly) |

---

## Privacy Invariants

- Every write includes `user:[name]`. Zero exceptions. A write without a user tag is a bug.
- Vendor MCPs must keep OAuth tokens and vendor user mappings outside memory — never store tokens in `brian-mcp`.
- One vendor account = one `user:[name]`. Do not merge two family members' data under one source.

---

## Read Access from the `health` Plugin

For reference, the skill in this plugin reads via:

```
memory_search(tags: ["health.vital", "user:[name]"], limit: 200)
memory_search(tags: ["health.activity", "user:[name]"], limit: 200)
```

then narrows by subtype tag (`health.vital.weight`, `health.activity.sleep`, etc.) and by `measured_at` range parsed from content. Any field listed as required above will be assumed present. Optional fields are gracefully handled as missing.

---

## Versioning

This schema is **v1**. Breaking changes require:
1. A new version tag here (`v2`) with a migration note.
2. A transitional period where both shapes are accepted by the skill.
3. A one-time backfill script in the affected vendor MCP.

Add an optional `schema_version: 1` field to memories only if you need to pin a version for a specific record. In the absence of that field, v1 is assumed.
