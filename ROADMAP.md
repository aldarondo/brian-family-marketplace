# brian-family-marketplace Roadmap
> Tag key: `[Code]` = Claude Code · `[Cowork]` = Claude Cowork · `[Human]` = Charles must act
> Phase 1 (memory layer) is tracked in the brian-mcp project.
>
> **Phase map:** Phase 1 = memory layer (brian-mcp) · Phase 2 = marketplace scaffold + core plugins · Phase 3 = additional plugins (recipes, prescriptions) · Phase 4 = access control labels · Phase 5 = Telegram/mobile access (brian-telegram) · Phase 6 = family onboarding · Phase 7 = ongoing ops
>
> **Plugin versioning:** health is `0.1.0` because vendor MCP integrations (Withings, Whoop, etc.) are not yet connected — evaluator stubs exist but produce no findings. All other plugins are `1.0.x` stable.

## 🔄 In Progress
<!-- nothing active right now -->

## 🔲 Backlog

### New Plugins
- [ ] `[Human]` Confirm brian-email deployment and exact endpoint URL (currently assumed `https://brian.aldarondo.family/email` sharing the same Cloudflare Access service token as brian-mcp); correct plugin configs if different
- [x] `[Code]` Smoke-test each new plugin (meal-plan, vehicles, contacts, maintenance, gifts, travel, energy) per `tests/SMOKE_TESTS.md` pattern; add test rows for each
- [ ] `[Human]` Run smoke tests for all new plugins per `tests/SMOKE_TESTS.md` — manual verification required (meal-plan, vehicles, contacts, maintenance, gifts, travel, energy)
- [x] `[Code]` Upgrade remaining plugins (grocery-list, recipes, prescriptions, food-log, jellyfin, roadmap) to include the `email` MCP server + SKILL.md Email section when a use case warrants it
- [ ] `[Human]` Get each home-energy coordinator MCP (solar, pool heater, EV charging, battery, whole-home meter) writing telemetry to brian-mcp per `plugins/energy/SCHEMA.md`. Until at least one coordinator is writing, the `energy` skill has nothing to aggregate.
- [ ] `[Code]` Once coordinators are live, backfill historical daily rollups if the coordinators expose history (one-time job per source)

### Phase 4 — Access Control
- [x] `[Code]` Confirm all active plugin READMEs have access labels (grocery-list, recipes, prescriptions — all done)
- [x] `[Code]` Add Access labels and smoke tests for the 6 new plugins (meal-plan, vehicles, contacts, maintenance, gifts, travel — all `access: all`)

### Phase 6 — Family Onboarding
- [ ] `[Human]` Confirm GitHub accounts for Moriah, Jack, Quincy (public repo — no collab needed, but good to note)
- [ ] `[Human]` Install plugins for Moriah, Jack, Quincy (Charles does this on each machine) — reassigned from [Code]: requires physical access to each person's computer

### Phase 7 — Ongoing Ops
- [x] `[Code]` Document update workflow in README (plugin versioning + family update flow)

## ✅ Completed
- [x] `[Code]` 2026-04-24 — Smoke test procedures complete for all 7 new plugins: meal-plan, vehicles, contacts, maintenance, gifts, travel test rows confirmed present; energy test row added to `tests/SMOKE_TESTS.md` (accounts for empty coordinator-data state)
- [x] `[Code]` 2026-04-24 — Access labels confirmed present in all 6 new plugin READMEs (meal-plan, vehicles, contacts, maintenance, gifts, travel — all `access: all`); smoke test procedures added to `tests/SMOKE_TESTS.md` for all 6.
- [x] `[Code]` 2026-04-24 — Email upgrade for grocery-list, recipes, prescriptions, food-log: added `email` MCP server block to mcp/config.json and an Email section to SKILL.md for each. Jellyfin and roadmap skipped (no warranted email use case). JSON validation passed.
- [x] `[Code]` 2026-04-24 — **energy** plugin v0.1.0 (access: charles): read-only home energy reporting aggregator. Reads coordinator telemetry (solar, pool, EV, battery, grid) from brian-mcp per `plugins/energy/SCHEMA.md` and produces daily/weekly/monthly rollups with trend flags. Does not control devices — action requests route to coordinator MCPs directly. Email wired for weekly summaries. CLAUDE.md and README.md document the reporting-skill-vs-coordinator-MCP split.
- [x] `[Code]` 2026-04-24 — **health** v0.2.0 refactor: generic subtype-keyed evaluators (not vendor-keyed) so any MCP writing to SCHEMA.md is picked up automatically. New evaluators for all vital subtypes, all activity subtypes, nutrition (food-log), and household dietary pattern (meal-plan with medication-conflict scan). Medication↔vitals cross-reference. Email wired.
- [x] `[Code]` 2026-04-24 — Added 6 family plugins (all v1.0.0, access: all): **meal-plan** (reads `recipes.*`, writes `grocery.*` on request), **vehicles** (service + renewals), **contacts** (incl. `care-team` category for hospice / end-of-life with after-hours fields), **maintenance** (recurring tasks + next-due), **gifts** (persons + ideas + given history + upcoming birthdays), **travel** (trips + itineraries + packing). All wired with brian-email MCP (send-only) and strict namespace storage in brian-mcp. marketplace.json, CLAUDE.md, README.md, CHANGELOG updated.
- [x] `[Code]` 2026-04-24 — Marketplace-level brian-email awareness: `email` MCP server alongside `memory` in each new plugin's mcp/config.json; contract documented in CLAUDE.md (send-only, explicit-ask-only, contacts-as-resolver, confirm-before-send); README updated with architecture diagram and per-plugin email table.
- [x] `[Code]` 2026-04-24 — Codified storage rule in CLAUDE.md + README: every plugin's persistent data must live in brian-mcp memory under its own namespace. No local files, no other stores.
- [x] `[Code]` 2026-04-23 — roadmap plugin v1.0.0: plugin.json, mcp/config.json, SKILL.md (list/register/add-entry/view/recent/remove with three GitHub write flows — local clone, `gh` CLI, github MCP), README.md; added to marketplace.json (access: charles); namespace `roadmap.*` registered in CLAUDE.md and README.md
- [x] `[Code]` 2026-04-22 — food-log plugin v1.0.0: plugin.json, mcp/config.json, SKILL.md (log from screenshot, view today/past day, weekly summary, delete), README.md; added to marketplace.json (access: per-user); wired into brian-telegram bot.js (PLUGIN_VERSIONS + PLUGIN_ACCESS + /help food-log)
- [x] `[Code]` 2026-04-20 — jellyfin plugin v1.0.1: new-releases + old-releases skills redesigned for Telegram (conversational MCP-tool flow, natural pick language, genre/decade filters, movies+TV in one pass); added to marketplace.json (access: charles)
- [x] `[Code]` 2026-04-19 — Fixed plugin.json mcpServers schema (string path → inline object); all 3 plugins installable via `claude plugin install`
- [x] `[Code]` 2026-04-14 — Confirmed all 3 plugin READMEs have Access: labels (grocery-list, recipes, prescriptions)
- [x] `[Code]` 2026-04-14 — Documented plugin update workflow in README (two-step update, versioning, new plugin procedure)
- [x] `[Code]` 2026-04-14 — prescriptions plugin built: plugin.json, mcp/config.json, SKILL.md (full intake/add/view/update/refill/export/interaction-check), README.md
- [x] `[Code]` 2026-04-14 — Charles's full supplement stack seeded into memory (19 active items + 1 pending) from C:\Brian\data\charles\prescriptions.md
- [x] `[Code]` 2026-04-14 — Migrated from C:\Brian\skills\prescriptions — memory-backed, user-scoped via user:[name] tags
- [x] `[Code]` 2026-04-14 — Initial scaffold: README, CLAUDE.md, ROADMAP.md, marketplace.json, grocery-list stub
- [x] `[Human]` 2026-04-14 — Confirmed domain and public repo; all config files updated
- [x] `[Human]` 2026-04-14 — Memory endpoint confirmed live: `https://brian.aldarondo.family/mcp` (Cloudflare Access, OTP for family, service token for Claude Code)
- [x] `[Code]` 2026-04-14 — All plugin mcp/config.json files updated with real endpoint URL
- [x] `[Code]` 2026-04-14 — grocery-list plugin: SKILL.md rewritten with full add/view/remove/clear instructions and tag conventions
- [x] `[Code]` 2026-04-14 — grocery-list smoke test passed: store → search → delete via brian-memory MCP
- [x] `[Code]` 2026-04-14 — recipes plugin built: plugin.json, mcp/config.json, SKILL.md (list/get/add/import/search/update/delete), README.md
- [x] `[Code]` 2026-04-14 — recipes smoke test passed: store → search by tag → delete via brian-memory MCP
- [x] `[Code]` 2026-04-14 — recipes migrated from claude-recipes (claude-recipes parked/archived)

## ✅ Resolved
- **Mobile access** — brian-telegram Telegram bot deployed (2026-04-19): plugins installed in ~/.claude mounted into container; family can now use all skills via Telegram on any device.

## 🚫 Blocked / Known Constraints
<!-- none -->
