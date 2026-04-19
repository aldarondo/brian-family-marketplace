# health

**Access:** All family members (each person sees only their own data)
**Namespace:** `health.*` (reads `prescriptions.*` for the same user)

Private personal health aggregator. Pulls data from multiple sources and produces a single evaluation — current status, key concerns, and suggested next steps. Starts with prescriptions as the only active source; vitals, labs, sleep, and symptoms will be added over time.

**Exception:** Moriah can evaluate Emil's health as his power of attorney.

## Install

```bash
/plugin install health@brian-family
```

## Setup (required after install)

Add your identity to your project or user CLAUDE.md:

```markdown
## Health Plugin
HEALTH_USER: charles
```

Valid values: `charles`, `moriah`, `jack`, `quincy`.
If you already set `PRESCRIPTIONS_USER`, the health skill will fall back to that, so you don't need both.

## Usage

- "Run a health evaluation"
- "How is my health?"
- "Any health concerns I should know about?"
- "What are my health risks?"
- "Save this snapshot"
- "Compare my health to last time"
- "Log my BP 128/82"
- "Record lab: LDL 105 mg/dL"

## Data Sources

| Source | Status |
|---|---|
| Prescriptions & supplements | Active |
| Vitals (BP, HR, weight, glucose) | Planned |
| Lab results | Planned |
| Sleep / activity | Planned |
| Self-reported symptoms | Planned |

Planned sources accept writes today (so data accumulates) but don't contribute to the evaluation yet.

## Writing Data Into Brian (for vendor MCP authors)

This plugin is **read-only** for external health data — it consumes `health.vital` and `health.activity` memories written by upstream vendor MCPs (Withings, Whoop, Google Health Connect bridge, etc.). If you are building one of those MCPs, code against the contract in [SCHEMA.md](./SCHEMA.md): it pins tag layout, required fields, units, idempotency rules, and source slugs. Do not invent your own shape — the health skill assumes the schema.

## Privacy

All memory reads and writes are filtered by `user:[name]` tag, across both `health.*` and `prescriptions.*`. The skill refuses cross-person queries. Only Moriah can access Emil's data.

## Not Medical Advice

This skill summarizes patterns from your own data and flags items worth discussing with a clinician. It is not a diagnosis. Always follow up with your doctor or pharmacist on anything flagged.
