# brian-family-marketplace Roadmap
> Tag key: `[Code]` = Claude Code · `[Cowork]` = Claude Cowork · `[Human]` = Charles must act
> Phase 1 (memory layer) is tracked in the brian-mcp project.

## 🔄 In Progress
- [ ] `[Code]` Phase 2: Marketplace scaffold — structure, marketplace.json, grocery-list plugin stub (complete pending smoke test)

## 🔲 Backlog

### Phase 3 — Grocery List Plugin
- [ ] `[Human]` Confirm brian-mcp memory endpoint is live at `https://brian.aldarondo.us/memory` (Phase 1 complete)
- [ ] `[Code]` Smoke test: install grocery-list on Charles's Claude Code, add/view/remove item
- [ ] `[Code]` Verify memory persists across Claude Code restarts

### Phase 4 — Access Control Conventions
- [ ] `[Code]` Add access labels + namespace table to each plugin README

### Phase 5 — Additional Plugins
- [ ] `[Code]` Build family-calendar plugin (namespace: `calendar.*`, access: all)
- [ ] `[Code]` Build proof-bread-orders plugin (namespace: `proof.*`, access: Charles + Moriah)
- [ ] `[Code]` Build home-tasks plugin (namespace: `tasks.*`, access: all)
- [ ] `[Code]` Build recipes plugin (namespace: `recipes.*`, access: all) — migrated from claude-recipes

### Recipes Plugin (migrated from claude-recipes)
> Replaces the standalone NAS MCP server. Storage moves to mcp-memory-service (namespace `recipes.*`). No Docker/JSON file infra needed.
- [ ] `[Code]` Create plugin scaffold: `plugins/recipes/` with plugin.json, mcp/config.json, SKILL.md
- [ ] `[Code]` Add `recipes` entry to `marketplace.json`
- [ ] `[Code]` SKILL.md: list all recipes (search `recipes.*`)
- [ ] `[Code]` SKILL.md: get recipe by name/ID
- [ ] `[Code]` SKILL.md: add recipe (with ingredients, instructions, tags, source URL)
- [ ] `[Code]` SKILL.md: search recipes by tag, ingredient, or keyword
- [ ] `[Code]` SKILL.md: import recipe from URL (Claude fetches page, extracts JSON-LD or parses with built-in tools, stores to memory)
- [ ] `[Code]` SKILL.md: update recipe
- [ ] `[Code]` SKILL.md: delete recipe
- [ ] `[Code]` Smoke test: add, retrieve, search, delete a recipe end-to-end

### Phase 6 — Family Onboarding
- [ ] `[Human]` Add family GitHub accounts as collaborators (or confirm public repo)
- [ ] `[Code]` Install plugins for Moriah, Jack, Quincy (Charles does this)

### Phase 7 — Ongoing Ops
- [ ] `[Code]` Document update workflow in README (plugin versioning + family update flow)

## ✅ Completed
- [x] `[Code]` 2026-04-13 — Initial scaffold: README, CLAUDE.md, ROADMAP.md, marketplace.json, grocery-list stub
- [x] `[Human]` 2026-04-14 — Confirmed domain `brian.aldarondo.us` and public repo — all config files updated

## 🚫 Blocked
<!-- log blockers here -->
