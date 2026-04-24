---
description: Use this skill to build, view, update, or clear the weekly family meal plan, and to push missing ingredients to the grocery list. Triggers include "plan meals", "what's for dinner", "meal plan", "this week's menu", "swap Tuesday's dinner", "send missing ingredients to grocery".
---

You have access to a shared memory layer (Brian's mcp-memory-service). Meal plan data uses the namespace prefix `mealplan.`. This skill reads from `recipes.*` and writes to `grocery.*` when asked — but only through the rules below.

## Data model

One memory per week, keyed by the Monday of that ISO week:

```
mealplan.week: [YYYY-MM-DD]   # Monday of the week
id: mealplan-[YYYY-MM-DD]
plan:
  mon: { recipe: "[title]", recipe_id: "[content_hash or title slug]", notes: "[optional]" }
  tue: { ... }
  wed: { ... }
  thu: { ... }
  fri: { ... }
  sat: { ... }
  sun: { ... }
created_by: [person]
updated_at: ISO 8601
```

Tag every memory: `mealplan.week,mealplan`.

## Building a week's plan

1. Determine the Monday of the target week (default: this week; accept "next week", "the week of April 27", etc.).
2. Check for an existing plan memory for that Monday. If present, ask whether to overwrite or edit.
3. Ask how many dinners to plan (default 7) and any constraints ("no beef this week", "Jack has practice Tuesday so something quick").
4. Search recipes: `memory_search(query: "recipes list", tags: ["recipes.recipe"])`. Propose a 7-day plan using variety (different proteins, cuisines, effort levels). Show the proposed plan.
5. Once confirmed, store the plan memory.
6. Offer: "Want me to check the grocery list for missing ingredients?"

## Viewing the plan

Trigger: "what's the meal plan", "what's for dinner", "this week's menu".

Search `mealplan.week` for the current Monday. If none, say "No meal plan saved for this week yet. Want me to build one?" Otherwise display:

```
Meal plan — week of Apr 27

Mon  Sheet-pan chicken
Tue  Tacos (quick — Jack has practice)
Wed  Pasta bolognese
...
```

Accept "what's for dinner today" — resolve today's weekday and show just that entry.

## Swapping a single day

Trigger: "swap Tuesday's dinner", "change Wednesday to stir fry".

1. Load the current week's plan.
2. If the user names a specific new recipe, search `recipes.*` to confirm it exists. If not found, ask.
3. Update the day's entry, store, confirm.

## Pushing missing ingredients to grocery

Trigger: "send missing ingredients to grocery", "what do I need to buy", "grocery-ify this plan".

1. Load the week's plan.
2. For each recipe on the plan, fetch the full recipe from `recipes.*` (by title or recipe_id).
3. Collect the ingredient list across all 7 recipes, deduped.
4. Show the combined list to the user with counts: "Here's what the week needs — 24 items across 7 recipes."
5. Ask: "Add everything, or do you want to skip staples you already have?"
6. For each item the user confirms, write a `grocery.item` memory following the grocery-list convention exactly:
   - Content: `grocery.item: [item] — added by meal-plan on [date] (for [recipe])`
   - Tags: `grocery.item,grocery`
7. Confirm count added.

## Clearing a plan

1. Identify the week.
2. Show the current plan and confirm deletion.
3. Delete by `content_hash`.

## Rules

- Only write to `mealplan.*` — except when explicitly asked to push ingredients, in which case follow the grocery-list format exactly for `grocery.item` writes.
- Never invent recipes. Only plan from recipes that exist in `recipes.*`. If the library is thin, say so and suggest adding more.
- Always show the proposed plan before saving.
- Always confirm before pushing multiple items to grocery.
- Respect constraints the user mentions (allergies, time pressure, "no X").

## Data storage

All persistent data for this plugin lives in the `memory` MCP server (brian-mcp) at `https://brian.aldarondo.family/mcp`. Do not write to local files, other memory services, or any namespace outside `mealplan.*` (with the grocery exception noted above). If asked to store something, it goes to memory.

## Email (brian-email MCP)

An `email` MCP server is available for outgoing email only. Use it when the user explicitly asks — e.g. "email this week's plan to Charles", "send the shopping list to me".

- Never send email without an explicit request.
- brian-email is send-only. Never treat it as storage — all drafts, logs, and content still live in memory under `mealplan.*`.
- Resolve recipient names against the `contacts` plugin (`contacts.contact`). If a name can't be resolved to an address, ask.
- Confirm recipient, subject, and a brief preview of the body before sending.
- Keep subjects short. Send a plain-text body.
