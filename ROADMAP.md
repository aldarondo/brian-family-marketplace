# brian-family-marketplace Roadmap
> Tag key: `[Code]` = Claude Code · `[Cowork]` = Claude Cowork · `[Human]` = Charles must act
> Phase 1 (memory layer) is tracked in the brian-mcp project.

## 🔄 In Progress
- [ ] `[Code]` Phase 2: Marketplace scaffold — structure, marketplace.json, grocery-list plugin stub

## 🔲 Backlog

### Open Questions (block Phase 3)
- [ ] `[Human]` Decide domain: what is `brian.[domain].com`? (existing domain or new?)
- [ ] `[Human]` Confirm repo visibility: public (current) or private? If private, set GITHUB_TOKEN for each family member.

### Phase 3 — Grocery List Plugin
- [ ] `[Human]` Confirm brian-mcp memory endpoint is live (Phase 1 complete)
- [ ] `[Code]` Update `plugins/grocery-list/mcp/config.json` with real domain URL
- [ ] `[Code]` Smoke test: install grocery-list on Charles's Claude Code, add/view/remove item
- [ ] `[Code]` Verify memory persists across Claude Code restarts

### Phase 4 — Access Control Conventions
- [ ] `[Code]` Add access labels + namespace table to each plugin README

### Phase 5 — Additional Plugins
- [ ] `[Code]` Build family-calendar plugin (namespace: `calendar.*`, access: all)
- [ ] `[Code]` Build proof-bread-orders plugin (namespace: `proof.*`, access: Charles + Moriah)
- [ ] `[Code]` Build home-tasks plugin (namespace: `tasks.*`, access: all)

### Phase 6 — Family Onboarding
- [ ] `[Human]` Add family GitHub accounts as collaborators (or confirm public repo)
- [ ] `[Code]` Install plugins for Moriah, Jack, Quincy (Charles does this)

### Phase 7 — Ongoing Ops
- [ ] `[Code]` Document update workflow in README (plugin versioning + family update flow)

## ✅ Completed
- [x] `[Code]` 2026-04-13 — Initial scaffold: README, CLAUDE.md, ROADMAP.md, marketplace.json, grocery-list stub

## 🚫 Blocked
<!-- log blockers here -->
