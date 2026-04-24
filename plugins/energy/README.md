# energy

**Access:** Charles only (home infrastructure reporting — can be opened up later)
**Namespace:** `energy.*`

Home energy reporting aggregator. Reads whatever the solar, pool-heater, EV-charging, and grid coordinator MCPs have written into brian-mcp memory and produces daily / weekly / monthly rollups, self-consumption ratios, trend flags, and emailable summaries.

**Scope is deliberately read-only.** This skill does not turn on the pool heater, start EV charging, or control solar routing. Those actions stay on the coordinator MCPs themselves — Claude already routes action requests ("start the pool heater", "charge the Tesla") to the correct coordinator tool based on its description. This skill exists only so you have one place for "what did the house do with its energy this week?"

## Install

```bash
/plugin install energy@brian-family
```

## Usage

```
# Current snapshot
"Energy status right now"
"How much solar did we make today?"

# Rollups
"Energy report for this week"
"Solar vs pool vs EV last month"
"Self-consumption ratio this month"

# Trends
"Is solar production down?"
"Show me the last 30 days"

# Email
"Email me the weekly energy summary"

# Manual note
"Note: panels washed today"
```

## How data gets in

The skill reads three things from memory, all tagged appropriately:

| Source (coordinator MCP) | Writes | Status |
|---|---|---|
| Solar coordinator | `energy.reading.solar_production`, `energy.reading.grid_import`, `energy.reading.grid_export`, `energy.reading.battery_soc` | Planned — coordinator must follow SCHEMA.md |
| Pool-heater coordinator | `energy.reading.pool_consumption`, `energy.event.pool_heating` (start/stop) | Planned |
| EV-charging coordinator | `energy.reading.ev_consumption`, `energy.event.ev_charge` (session start/stop, kWh delivered) | Planned |
| This skill's rollup writer | `energy.rollup.daily`, `energy.rollup.weekly`, `energy.rollup.monthly`, `energy.note` | Active |

**The coordinator MCPs do not need to be called directly.** They write their telemetry to brian-mcp memory on their own cadence. When a new coordinator comes online (e.g. a whole-home meter), it just follows the schema and gets picked up.

## Schema for coordinators

See [SCHEMA.md](./SCHEMA.md) for exact tag layout, required fields, units (always kW, kWh, percent — convert before writing), timestamps with offset, and idempotency rules. Same contract pattern as the health plugin.

## Rollup cadence

The skill computes rollups lazily on request. Once computed, they are cached as memories:

- `energy.rollup.daily` — one per calendar date; regenerated for same-day until midnight rolls over
- `energy.rollup.weekly` — one per ISO week
- `energy.rollup.monthly` — one per calendar month

Requesting a rollup for a closed period returns the cached memory. Requesting today regenerates.

## What the report surfaces

- **Production** — total solar kWh, peak kW, hours above 4 kW
- **Consumption by channel** — pool heater, EV charging, rest of house (derived = total grid + solar − export − battery)
- **Self-consumption ratio** — (solar used on-site) / (solar produced)
- **Grid flow** — kWh imported, kWh exported, net
- **Battery** — min/max SoC, full-cycle count proxy (Σ discharge kWh / capacity)
- **Pool heating** — total session time, total kWh, average session length
- **EV charging** — sessions, total kWh, average rate, share of solar-funded kWh
- **Trend flags** — production down >15% vs trailing 28-day avg, self-consumption ratio down >10 percentage points, EV consumption up >30% vs baseline

## Email

An `email` MCP server is wired in for "email me the weekly summary" requests. Send-only — all rollups live in brian-mcp under `energy.*`.

## Storage rule

All persistent data for this plugin lives in brian-mcp memory under `energy.*`. No local files, no external stores.
