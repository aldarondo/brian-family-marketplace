# Changelog

All notable plugin version changes are documented here.

## [Unreleased]

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
