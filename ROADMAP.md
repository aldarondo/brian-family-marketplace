# brian-family-marketplace Roadmap
> Tag key: `[Code]` = Claude Code · `[Cowork]` = Claude Cowork · `[Human]` = Charles must act
> Phase 1 (memory layer) is tracked in the brian-mcp project.

## 🔄 In Progress
<!-- nothing active right now -->

## 🔲 Backlog

### Phase 4 — Access Control Conventions
- [ ] `[Code]` Add access labels + namespace table to each plugin README (grocery-list and recipes already have them; add to remaining stubs when built)

### Phase 5 — Additional Plugins
- [ ] `[Code]` Build family-calendar plugin (namespace: `calendar.*`, access: all)
- [ ] `[Code]` Build proof-bread-orders plugin (namespace: `proof.*`, access: Charles + Moriah)
- [ ] `[Code]` Build home-tasks plugin (namespace: `tasks.*`, access: all)

### Phase 6 — Family Onboarding
- [ ] `[Human]` Confirm GitHub accounts for Moriah, Jack, Quincy (public repo — no collab needed, but good to note)
- [ ] `[Code]` Install plugins for Moriah, Jack, Quincy (Charles does this on each machine)

### Phase 7 — Ongoing Ops
- [ ] `[Code]` Document update workflow in README (plugin versioning + family update flow)

## ✅ Completed
- [x] `[Code]` 2026-04-14 — prescriptions plugin built: plugin.json, mcp/config.json, SKILL.md (full intake/add/view/update/refill/export/interaction-check), README.md
- [x] `[Code]` 2026-04-14 — Charles's full supplement stack seeded into memory (19 active items + 1 pending) from C:\Brian\data\charles\prescriptions.md
- [x] `[Code]` 2026-04-14 — Migrated from C:\Brian\skills\prescriptions — memory-backed, user-scoped via user:[name] tags
- [x] `[Code]` 2026-04-14 — Initial scaffold: README, CLAUDE.md, ROADMAP.md, marketplace.json, grocery-list stub
- [x] `[Human]` 2026-04-14 — Confirmed domain and public repo; all config files updated
- [x] `[Human]` 2026-04-14 — Memory endpoint confirmed live: `http://192-168-0-64.aldarondo.direct.quickconnect.to:8765/mcp`
- [x] `[Code]` 2026-04-14 — All plugin mcp/config.json files updated with real endpoint URL
- [x] `[Code]` 2026-04-14 — grocery-list plugin: SKILL.md rewritten with full add/view/remove/clear instructions and tag conventions
- [x] `[Code]` 2026-04-14 — grocery-list smoke test passed: store → search → delete via brian-memory MCP
- [x] `[Code]` 2026-04-14 — recipes plugin built: plugin.json, mcp/config.json, SKILL.md (list/get/add/import/search/update/delete), README.md
- [x] `[Code]` 2026-04-14 — recipes smoke test passed: store → search by tag → delete via brian-memory MCP
- [x] `[Code]` 2026-04-14 — recipes migrated from claude-recipes (claude-recipes parked/archived)

## 🚫 Blocked
<!-- log blockers here -->
