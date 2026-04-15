# brian-family-marketplace

## Project Purpose
GitHub-hosted Claude Code plugin marketplace that distributes shared family skills (grocery list, calendar, Proof Bread orders) to Leatherwood household members via the Brian home server memory layer.

## Relationship to brian-mcp
Phase 1 (mcp-memory-service setup, Cloudflare tunnel, Windows service) lives in the `brian-mcp` project. This repo starts at Phase 2 — the marketplace catalog and plugin definitions. The memory endpoint URL (`https://brian.[domain].com/memory`) must be live before any plugin will function.

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

## Confirmed
- Domain: `brian.aldarondo.us` — memory endpoint is `https://brian.aldarondo.us/memory`
- Repo: public at `aldarondo/brian-family-marketplace`

## Testing Requirements (mandatory)
- Validate all JSON files are well-formed before committing
- Smoke test each plugin after any SKILL.md or config.json change
- Tests live in `tests/`

@~/Documents/GitHub/CLAUDE.md
