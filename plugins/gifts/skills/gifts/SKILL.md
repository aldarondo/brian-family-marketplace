---
description: Use this skill to track birthdays and anniversaries, jot down gift ideas for each person, and record gifts given. Triggers include "add a gift idea", "gift ideas for Jack", "what have we given mom", "whose birthday is coming up", "mark that gift as given".
---

You have access to a shared memory layer (Brian's mcp-memory-service). All data uses the namespace prefix `gifts.`.

## Data model — three memory types

### `gifts.person` — one per person

```
gifts.person: [Name]
id: gifts-person-[slug]
relation: [e.g. "son", "mother-in-law", "friend"]
birthday: MM-DD       # year optional; store as YYYY-MM-DD if known
anniversary: MM-DD or YYYY-MM-DD   # optional
sizes: { shirt: "M", shoe: "10", ring: "7" }  # optional map
interests: [comma-separated tags]
avoid: [things they don't want — e.g. "no candles", "allergic to wool"]
notes: [free text]
```

Tags: `gifts.person,gifts`.

### `gifts.idea` — a gift idea for someone (not yet given)

```
gifts.idea: [Short description] — for [Name]
person_id: gifts-person-[slug]
idea: [description]
price_range: [optional — "$30-50"]
link: [optional URL]
occasion: [birthday | christmas | anniversary | "just because" | other]
priority: [low | medium | high]
added_by: [person]
added_at: ISO 8601
status: active
```

Tags: `gifts.idea,gifts,person:[slug],status:active`.

### `gifts.given` — a gift that was given (history)

```
gifts.given: [Gift] — to [Name] on [YYYY-MM-DD]
person_id: gifts-person-[slug]
gift: [description]
occasion: [birthday | christmas | anniversary | other]
date: YYYY-MM-DD
from: [giver or "family"]
cost: [USD or null]
reaction: [optional — "loved it", "returned it"]
```

Tags: `gifts.given,gifts,person:[slug]`.

## Adding a person

1. Ask for name, relation, birthday, optional anniversary, sizes, interests, avoid list.
2. Slug the name. Store `gifts.person`.
3. Confirm.

## Adding a gift idea

1. Ask who it's for. Match against existing `gifts.person`. If none, offer to add them.
2. Ask idea, price range, link, occasion, priority.
3. Store `gifts.idea` tagged with `person:[slug]` and `status:active`.
4. Confirm and show the person's current active idea list.

## Marking an idea as given

Trigger: "gave Jack the headphones", "mark the Lego set as given to Quincy for his birthday".

1. Find the matching `gifts.idea` memory.
2. Create a `gifts.given` memory with date, occasion, from, optional cost/reaction.
3. Update the idea by deleting the old memory (or flipping its tag to `status:given`). Default behavior: delete the idea and keep the `gifts.given` as the historical record.
4. Confirm.

## Viewing ideas for a person

Trigger: "gift ideas for Jack", "what should I get mom".

Search `gifts.idea` with tag `person:[slug]` and `status:active`. Display sorted by priority then date added. Include price range and link.

Alongside, show the person's `interests`, `sizes`, and `avoid` fields so the user has full context.

## Gift history for a person

Trigger: "what have we given mom", "last birthday gift for Jack".

Search `gifts.given` with tag `person:[slug]`, newest first. Display as a short table: date, occasion, gift, from, cost.

Useful for avoiding duplicates.

## Upcoming birthdays and anniversaries

Trigger: "whose birthday is coming up", "any birthdays this month".

1. Load all `gifts.person` memories.
2. Compute the next occurrence of each person's `birthday` and `anniversary` relative to today.
3. Filter to the next 60 days (or user-specified window).
4. Display:

```
Upcoming — next 60 days

Apr 29  Moriah — birthday (turns 17)
May 14  Mom & Dad — anniversary (32 years)
Jun 03  Jack — birthday
```

If age is computable (birth year stored), include it.

## Updating

Find by name/slug, delete by `content_hash`, store updated version.

## Deleting

Confirm name and intent. Delete by `content_hash`. For a `gifts.person` delete, ask whether to also purge their ideas and given history (default: keep history, delete only the person record — but warn).

## Rules

- Never write outside `gifts.*`.
- Always tag person-scoped memories with `person:[slug]`.
- When suggesting ideas for someone, reference their `interests` and respect their `avoid` list.
- Before saving a new idea, quickly check `gifts.given` for the same person — flag if a similar gift was given in the last 2 years.

## Data storage

All persistent data for this plugin lives in the `memory` MCP server (brian-mcp) at `https://brian.aldarondo.family/mcp`. Do not write to local files, other memory services, or any namespace outside `gifts.*`.

## Email (brian-email MCP)

An `email` MCP server is available for outgoing email only. Use it when the user explicitly asks — e.g. "email the upcoming birthdays to the family", "send the idea list for mom to my sister".

- Never send email without an explicit request.
- brian-email is send-only. Never treat it as storage — all person, idea, and given data still lives in memory under `gifts.*`.
- Resolve recipient names against the `contacts` plugin (`contacts.contact`). If a name can't be resolved to an address, ask.
- Never email someone's own idea list to that person without an explicit, unambiguous request from the user — respect the surprise.
- Confirm recipient, subject, and a brief preview of the body before sending.
- Keep subjects short. Send a plain-text body.
