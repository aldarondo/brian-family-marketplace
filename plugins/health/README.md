# health

**Access:** Per-user (private — each person sees only their own data)
**Namespace:** `health.*` (reads `prescriptions.*`, `food.*`, and `mealplan.*` for the same user)

Private personal health aggregator. Reads whatever health data has been written to brian-mcp memory for the active user and produces a single status-level evaluation with concerns and recommendations.

The skill is **generic and source-agnostic**. It does not talk to Withings, Whoop, Apple Health, or any vendor API — those are separate MCPs that write into brian-mcp. This skill reads only from memory. If a vendor MCP follows the contract in [SCHEMA.md](./SCHEMA.md), its data is picked up automatically on the next evaluation. No code change in this plugin is required when a new source comes online.

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

Valid values: `charles`, `moriah`, `jack`, `quincy`. If you already set `PRESCRIPTIONS_USER` or `FOOD_LOG_USER`, the health skill will fall back to either.

## Usage

- "Run a health evaluation"
- "How is my health?"
- "Any health concerns I should know about?"
- "What does my data say about my recovery this week?"
- "Save this snapshot" / "Compare my health to last time"
- "Log my BP 128/82" (manual entry — stored under `source:manual`)
- "Email me my weekly summary"

## How data gets in

Anything tagged with a recognized health-family tag and `user:[name]` is picked up automatically.

| Source | Writes | Status |
|---|---|---|
| `prescriptions` plugin | `prescriptions.item` + `user:[name]` | Active |
| `food-log` plugin | `food.entry` + `user:[name]` | Active |
| `meal-plan` plugin | `mealplan.week` (shared — no user filter) | Active |
| `claude-withings` (planned) | `health.vital.weight`, `blood_pressure`, `heart_rate`, body composition | Picked up when it ships |
| `claude-whoop` (planned) | `health.activity.sleep`, `recovery_daily`, `strain_daily`, `health.vital.hrv` | Picked up when it ships |
| `claude-apple-health` / `claude-health-connect` (planned) | `health.activity.steps_daily`, `workout`, phone/watch vitals | Picked up when it ships |
| This plugin's manual entry | `health.vital.*` etc. tagged `source:manual` | Active |

When Withings and Whoop ship, they start writing — and this skill picks up their subtypes the next time someone asks for an evaluation. No change here needed.

## Subtypes this skill understands today

Subtypes with no data are skipped silently.

**Vitals** — weight, blood_pressure, heart_rate, spo2, body_temperature, blood_glucose, respiratory_rate, hrv
**Activity** — sleep, workout, steps_daily, recovery_daily, strain_daily
**Medications** — prescriptions and supplements (from the `prescriptions` plugin)
**Nutrition** — daily food entries with calories, protein, carbs, fat (from `food-log`)
**Dietary pattern** — weekly dinner plan and variety (from `meal-plan`)

See SKILL.md for the rules each evaluator applies.

## Writing data into Brian (for vendor MCP authors)

This plugin is read-only for external health data. Upstream MCPs must follow [SCHEMA.md](./SCHEMA.md) exactly — tag layout, required fields, units, idempotency rules, source slugs. Don't invent a shape; the health skill assumes the schema.

## Privacy

All reads and writes are filtered by `user:[name]` across every tag family. The skill refuses cross-person queries. Only Moriah can access Emil's data.

`mealplan.*` is shared family data (no per-user filter) — it contributes to dietary-pattern findings but is never attributed to a specific person's private record.

## Email

An `email` MCP server is wired in for "email me my health summary" requests. Send-only — all persistent data stays in brian-mcp under `health.*`.

## Not medical advice

This skill summarizes patterns from your own data and flags items worth discussing with a clinician. It is not a diagnosis. Always follow up with your doctor or pharmacist on anything flagged.
