---
description: Add, remove, or view items on the shared family grocery list
---

You have access to a shared memory layer (Brian's mcp-memory-service). All grocery data uses the namespace prefix `grocery.`.

## Viewing the list
Search memories with query `"grocery list items"` and tags `["grocery.item"]`. Display as a clean numbered list showing item name and who added it.

If no items are found, say "The grocery list is empty."

## Adding an item
Store a memory with this content:

```
grocery.item: [item name] — added by [person] on [date]
```

Tag it with `grocery.item,grocery`.

Ask who is adding if not stated. Confirm the add and show the updated full list.

## Removing an item
1. Search for the item by name with tags `["grocery.item"]`
2. Show the match and confirm before deleting
3. Delete by content_hash
4. Show the updated list

## Checking off / marking as bought
Delete the memory for that item (it was purchased — remove it from the list). Confirm and show the updated list.

## Clearing the entire list
1. Search all memories tagged `grocery.item`
2. Confirm with the user before bulk deletion
3. Delete each by content_hash
4. Confirm the list is now empty

## Rules
- Never write to any namespace other than `grocery.*`
- Always show the current list after any add or remove operation
- Always ask for confirmation before deleting more than one item at once

## Email (brian-email MCP)

An `email` MCP server is available for outgoing email only. Use it when the user explicitly asks — e.g. "email me the grocery list", "send the shopping list to Moriah".

- Never send email without an explicit request.
- brian-email is send-only. Never treat it as storage — all grocery data still lives in memory under `grocery.*`.
- Resolve recipient names against the `contacts` plugin (`contacts.contact`). If a name can't be resolved to an address, ask.
- Confirm recipient, subject, and a brief preview of the body before sending.
- Keep subjects short (e.g. "Grocery List — April 24"). Send a plain-text body with items as a simple bulleted list.
