# recipes

**Access:** All family members
**Namespace:** `recipes.*`

Family recipe collection. Add recipes manually, import from any URL, search by ingredient or tag, and retrieve full recipes with ingredients and instructions.

## Install

```bash
/plugin install recipes@brian-family
```

## Usage

- "Show me all our recipes"
- "Add a recipe for lasagna"
- "Import the recipe from [URL]"
- "Find recipes with chicken"
- "Get the chocolate chip cookie recipe"
- "Delete the old banana bread recipe"

## Data Structure

Each recipe is stored as a memory tagged `recipes.recipe` with optional category tags:
- `recipes.dinner`, `recipes.lunch`, `recipes.breakfast`
- `recipes.vegetarian`, `recipes.vegan`, `recipes.gluten-free`
- `recipes.dessert`, `recipes.snack`
- `recipes.quick` (under 30 min), `recipes.batch-cook`

## Requirements

Brian memory endpoint must be live at `http://192-168-0-64.aldarondo.direct.quickconnect.to:8765/mcp` (see [brian-mcp](https://github.com/aldarondo/brian-mcp)).

## Migrated From

`claude-recipes` (archived) — the standalone NAS MCP server with JSON file storage and Docker. Superseded by this memory-backed plugin.
