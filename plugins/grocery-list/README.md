# grocery-list

**Access:** All family members
**Namespace:** `grocery.*`

Shared family grocery list. Add, remove, and view items using natural language.

## Install

```bash
/plugin install grocery-list@brian-family
```

## Usage

- "Add milk to the grocery list"
- "What's on the grocery list?"
- "Remove eggs from the list"

## Requirements

Brian memory endpoint must be live at `https://brian.aldarondo.family/mcp` (see [brian-mcp](https://github.com/aldarondo/brian-mcp)). Requires `BRIAN_MCP_CLIENT_ID` and `BRIAN_MCP_CLIENT_SECRET` env vars set (Cloudflare Access service token).
