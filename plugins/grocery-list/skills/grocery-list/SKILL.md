---
description: Add, remove, or view items on the shared family grocery list
---

You have access to a shared memory layer (Brian's mcp-memory-service). All grocery data uses the namespace prefix `grocery.`.

## Viewing the list
Search memories with query `"grocery list items"` to retrieve all current items.

## Adding an item
Add a memory tagged `grocery.item` with:
- The item name
- Who added it (ask if not stated)
- Optional: quantity or notes

## Removing an item
Delete the memory for that specific item by searching for it first, then deleting by ID.

## Rules
- Always confirm what you did after any change.
- Always show the current list after any add or remove operation.
- Never write to any namespace other than `grocery.*`.
