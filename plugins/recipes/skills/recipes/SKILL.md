---
description: Add, search, import, update, or delete recipes in the family recipe collection
---

You have access to a shared memory layer (Brian's mcp-memory-service). All recipe data uses the namespace prefix `recipes.`.

## Listing all recipes
Search memories with query `"recipes list"` and tags `["recipes.recipe"]`. Display results as a numbered list with title, tags, and source URL if present.

## Getting a recipe by name
Search memories with query `"[recipe name]"` and tags `["recipes.recipe"]`. Return the full recipe including ingredients and instructions.

## Adding a recipe
Store a memory with this structure:

```
recipes.recipe: [Title]
Source: [URL or "family recipe"]
Tags: [comma-separated tags, e.g. dinner, italian, vegetarian]
Added by: [person]
Serves: [number]

Ingredients:
- [ingredient + quantity]
- ...

Instructions:
1. [step]
2. ...

Notes: [optional]
```

Tag the memory with `recipes.recipe` plus any relevant category tags (e.g. `recipes.dinner`, `recipes.vegetarian`).

Always confirm what was saved and show the recipe title.

## Importing a recipe from a URL
1. Fetch the URL and extract the recipe content (look for JSON-LD `application/ld+json` schema.org/Recipe first; fall back to reading the visible recipe text)
2. Parse out: title, ingredients, instructions, servings, source URL
3. Ask Charles to confirm the parsed recipe looks correct before saving
4. Save using the same structure as "Adding a recipe" above, with Source set to the original URL

## Searching recipes
Search memories with the query terms (ingredient, dish name, tag) and filter by tag `recipes.recipe`. Present results with title, tags, and a one-line summary. Tell the user how many results were found.

Examples:
- "recipes with chicken" → query: "chicken", tags: ["recipes.recipe"]
- "vegetarian dinners" → query: "vegetarian dinner", tags: ["recipes.recipe"]
- "what recipes do we have?" → query: "recipes list", tags: ["recipes.recipe"]

## Updating a recipe
1. Find the existing recipe memory by name
2. Delete the old memory by content_hash
3. Store the updated version with the same structure
4. Confirm what changed

## Deleting a recipe
1. Find the recipe by name
2. Show it to the user and ask for confirmation before deleting
3. Delete by content_hash
4. Confirm deletion

## Rules
- Never write to any namespace other than `recipes.*`
- Always show the full recipe after adding or updating
- Always confirm before deleting
- When importing from URL, always show the parsed recipe and get approval before saving

## Email (brian-email MCP)

An `email` MCP server is available for outgoing email only. Use it when the user explicitly asks — e.g. "email this recipe to Moriah", "send me the chocolate cake recipe".

- Never send email without an explicit request.
- brian-email is send-only. All recipe data stays in memory under `recipes.*`.
- Resolve recipient names against the `contacts` plugin (`contacts.contact`). If a name can't be resolved to an address, ask.
- Confirm recipient, subject, and a brief preview of the body before sending.
- Keep subjects short (e.g. "Recipe: Chicken Tikka Masala"). Send the full recipe as a plain-text body including ingredients and instructions.
