# brian-family-marketplace

## Project Purpose
GitHub-hosted Claude Code plugin marketplace that distributes shared family skills (grocery list, calendar, Proof Bread orders) to Leatherwood household members via the Brian home server memory layer.

## Relationship to brian-mcp
Phase 1 (mcp-memory-service setup, Cloudflare tunnel, Windows service) lives in the `brian-mcp` project. This repo starts at Phase 2 — the marketplace catalog and plugin definitions. The memory endpoint URL (`https://brian.aldarondo.family/mcp`) must be live before any plugin will function.

## Key Commands
```bash
# Validate marketplace structure
claude plugin validate .

# Test install locally
claude plugin marketplace add ./
claude plugin install grocery-list@brian-family
```

## Plugin Structure Convention
Every plugin follows this layout:
```
plugins/[name]/
  .claude-plugin/plugin.json
  skills/[name]/SKILL.md
  mcp/config.json
  README.md
```

## Adding a New Plugin
1. Create `plugins/[name]/` following the structure above
2. Add entry to `.claude-plugin/marketplace.json`
3. Commit and push
4. Family members run: `/plugin marketplace update brian-family && /plugin install [name]@brian-family`

## Memory Namespace Rules
Each plugin owns a unique prefix — never write memories outside your plugin's prefix:
- `grocery.` — grocery-list
- `recipes.` — recipes (migrated from claude-recipes)
- `prescriptions.` — prescriptions (scoped per-user via `user:[name]` tag)
- `food.` — food-log (scoped per-user via `user:[name]` tag)
- `roadmap.` — roadmap (scoped per-user via `user:[name]` tag)
- `mealplan.` — meal-plan
- `vehicles.` — vehicles
- `contacts.` — contacts
- `maintenance.` — maintenance
- `gifts.` — gifts
- `travel.` — travel

## Storage Rule (mandatory)
All persistent data for every plugin MUST use brian-mcp memory at `https://brian.aldarondo.family/mcp`. No local files, no external databases, no other memory services. If a skill needs to save something, it goes in memory under that plugin's namespace. Writing data anywhere else is a bug.

## Outgoing Email (brian-email MCP)
Plugins that need to send email use a second MCP server named `email`, exposed at `https://brian.aldarondo.family/email` behind the same Cloudflare Access service token (`BRIAN_MCP_CLIENT_ID` / `BRIAN_MCP_CLIENT_SECRET`).

Contract for every plugin that uses email:
- brian-email is **send-only**. It is not a data store. All persistent state stays in brian-mcp memory under the plugin's namespace.
- Only send when the user explicitly asks.
- Resolve recipient names through the `contacts` plugin (`contacts.contact`). If unresolved, ask.
- Confirm recipient, subject, and preview before sending.
- Send plain-text bodies, short subjects.

Currently wired for email: meal-plan, vehicles, contacts, maintenance, gifts, travel. Existing plugins (grocery-list, recipes, prescriptions, health, jellyfin, food-log, roadmap) can be upgraded by adding the `email` server block to their `mcp/config.json` and an Email section to their SKILL.md.

## Confirmed
- Memory endpoint: `https://brian.aldarondo.family/mcp` (production, Cloudflare Access)
- Email endpoint: `https://brian.aldarondo.family/email` (brian-email MCP, same Cloudflare Access service token) — verify exact URL/path against brian-email deployment
- Auth: service token via `BRIAN_MCP_CLIENT_ID` + `BRIAN_MCP_CLIENT_SECRET` env vars
- Repo: public at `aldarondo/brian-family-marketplace`

## Testing Requirements (mandatory)
- Validate all JSON files are well-formed before committing
- Smoke test each plugin after any SKILL.md or config.json change
- Tests live in `tests/`

@~/Documents/GitHub/CLAUDE.md

## Git Rules
- Never create pull requests. Push directly to main.
- solo/auto-push OK
