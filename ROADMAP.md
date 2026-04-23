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
<!-- none -->

### Phase 4 — Access Control
- [x] `[Code]` Confirm all active plugin READMEs have access labels (grocery-list, recipes, prescriptions — all done)

### Phase 6 — Family Onboarding
- [ ] `[Human]` Confirm GitHub accounts for Moriah, Jack, Quincy (public repo — no collab needed, but good to note)
- [ ] `[Human]` Install plugins for Moriah, Jack, Quincy (Charles does this on each machine) — reassigned from [Code]: requires physical access to each person's computer

### Phase 7 — Ongoing Ops
- [x] `[Code]` Document update workflow in README (plugin versioning + family update flow)

## ✅ Completed
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
