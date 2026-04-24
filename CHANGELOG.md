# Changelog

All notable plugin version changes are documented here.

## [Unreleased]

### Changed — health v0.2.0 (generic memory-side aggregator)
- Dropped the Active/Planned source distinction; evaluators are now keyed on subtype tags (`health.vital.weight`, `health.activity.sleep`, etc.) rather than vendor. Any MCP that writes to SCHEMA.md is picked up automatically.
- Added concrete threshold rules for all eight vital subtypes and five activity subtypes (weight trend, BP thresholds incl. crisis reading, resting HR, SpO2, temperature, glucose split by context, respiratory rate, HRV drop detection, sleep duration/efficiency/onset, workout cadence, steps vs goal, recovery streaks, strain-vs-recovery burnout pattern).
- Added new evaluators reading beyond `health.*`: nutrition from `food.entry` (per-user protein/calorie heuristics with logging-coverage note) and household dietary pattern from `mealplan.week` (variety, medication/allergy conflict scan against `recipes.*`).
- Added medication ↔ vitals cross-reference (BP meds present + hypertensive trend → adherence/dosing flag).
- Wired the `email` MCP server for "email me my weekly summary". Recipient resolution through the `contacts` plugin.
- Reports now carry a `Sources used` footer so the user can see which coordinators contributed.

### Added — energy plugin v0.1.0 (household reporting aggregator)
- New `energy` plugin (access: charles). Namespace `energy.*`, household-scoped (no `user:` tag).
- Read-only reporting layer that consumes telemetry written by coordinator MCPs (solar, pool, EV charging, battery, grid) per [`plugins/energy/SCHEMA.md`](plugins/energy/SCHEMA.md).
- Does not control devices. Action requests ("start the pool heater", "charge the Tesla") go to the coordinator MCPs directly via Claude's tool routing.
- Produces daily / weekly / monthly rollups: solar produced, grid import/export, pool kWh, EV kWh, derived home-other kWh, self-consumption ratio, peak solar kW, hours above 4 kW, battery charge/discharge.
- Trend flags: solar production dip (>15% vs 28d avg), self-consumption drop (>10pp), EV consumption spike, pool spike, coordinator silence.
- `energy.note` for human annotations ("panels washed") surfaced alongside rollups.
- `email` MCP wired for weekly summary emails.
- CLAUDE.md and README.md updated with the reporting-skill-vs-coordinator-MCP pattern.

### Added — 6 new plugins (v1.0.0 each)
- **meal-plan** — weekly 7-day dinner plan built from `recipes.*`; pushes missing ingredients to `grocery.*` on request. Namespace `mealplan.*`.
- **vehicles** — shared family vehicle registry with service history and renewal tracking. Namespace `vehicles.*`.
- **contacts** — shared family contact directory covering emergency, medical, schools, household, and a first-class **care-team** category for hospice / end-of-life coordination (after-hours line, case manager, primary nurse, physician, social worker, chaplain, DME, pharmacy, funeral home). Namespace `contacts.*`.
- **maintenance** — recurring home maintenance with last-done log, next-due computation, and overdue surfacing. Namespace `maintenance.*`.
- **gifts** — per-person gift idea lists, given-history, and upcoming birthday/anniversary reminders. Namespace `gifts.*`.
- **travel** — trip planner with itineraries, booking confirmations, and packing lists. Namespace `travel.*`.

### Added — brian-email MCP awareness
- All 6 new plugins wire an `email` MCP server alongside `memory` (same Cloudflare Access service token) at `https://brian.aldarondo.family/email` for outgoing email only.
- Standardized SKILL.md contract: send-only, explicit-request-only, resolve recipients via the `contacts` plugin, confirm before sending.
- Documented in CLAUDE.md and README.md; existing plugins can be upgraded when features require it.

### Added — storage rule
- Codified in CLAUDE.md and README.md: all persistent data for every plugin must live in brian-mcp memory under the plugin's namespace. No local files, no external databases, no other memory services.

## [1.0.2] — 2026-04-14
### prescriptions
- Built prescriptions plugin: plugin.json, mcp/config.json, SKILL.md (intake/add/view/update/refill/export/interaction-check), README.md
- Seeded Charles's supplement stack (19 active + 1 pending) from local data
- Migrated from C:\Brian\skills\prescriptions; now memory-backed with user:[name] tag scoping

### recipes
- Built recipes plugin: plugin.json, mcp/config.json, SKILL.md (list/get/add/import/search/update/delete), README.md
- Migrated from claude-recipes (claude-recipes parked)
- Smoke test passed: store → search by tag → delete

### grocery-list
- SKILL.md rewritten with full add/view/remove/clear instructions and tag conventions
- Smoke test passed: store → search → delete

## [1.0.1] — 2026-04-20
### jellyfin
- new-releases and old-releases skills redesigned for Telegram (conversational MCP-tool flow, natural pick language, genre/decade filters, movies+TV in one pass)
- Added to marketplace.json (access: charles)

## [1.0.0] — 2026-04-14
### All plugins
- Fixed plugin.json mcpServers schema (string path → inline mcp/config.json object); all plugins installable via `claude plugin install`
- Initial scaffold: README, CLAUDE.md, ROADMAP.md, marketplace.json
- Memory endpoint confirmed live: https://brian.aldarondo.family/mcp (Cloudflare Access)
- All plugin mcp/config.json files updated with production endpoint URL
