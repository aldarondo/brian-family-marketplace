---
description: Use this skill to track recurring home maintenance tasks — HVAC filters, smoke detector batteries, gutter cleaning, water softener salt, seasonal landscaping, etc. Triggers include "add maintenance task", "mark filter changed", "what's due this month", "when did we last clean the gutters", "upcoming maintenance".
---

You have access to a shared memory layer (Brian's mcp-memory-service). All maintenance data uses the namespace prefix `maintenance.`.

## Data model

Two kinds of memories.

### `maintenance.task` — a recurring task definition

```
maintenance.task: [Task name]
id: maintenance-[slug]
category: [hvac | plumbing | electrical | exterior | landscaping | appliance | safety | seasonal | other]
cadence: [every N days|weeks|months|years, or "seasonal:spring", "seasonal:fall"]
last_done: YYYY-MM-DD              # most recent completion
next_due: YYYY-MM-DD               # computed from last_done + cadence
who: [person responsible, or "anyone"]
location: [optional — "upstairs hallway", "basement", "front yard"]
notes: [e.g. filter size, vendor, steps]
created_by: [person]
created_at: ISO 8601
```

Tags: `maintenance.task,maintenance,category:[category]`.

### `maintenance.log` — one entry per completion

```
maintenance.log: [Task name] — [YYYY-MM-DD]
task_id: [slug]
date: YYYY-MM-DD
done_by: [person]
notes: [optional — cost, vendor, observations]
```

Tags: `maintenance.log,maintenance,task:[slug]`.

## Adding a task

1. Ask for: name, category, cadence, last-done date (or "never"), who is responsible, location, notes.
2. Compute `next_due` = `last_done` + cadence. If `last_done` is "never," set `next_due` to today.
3. Generate a slug. Store the `maintenance.task` memory.
4. Confirm with the full record.

## Marking a task done

Trigger: "filter changed", "gutters cleaned today", "mark smoke detectors checked".

1. Find the task by name or slug. If multiple match, list and ask.
2. Ask for the date (default today), who did it, optional notes.
3. Update the task:
   - Set `last_done` = the completion date.
   - Recompute `next_due` = `last_done` + cadence.
   - Store updated task (delete old by `content_hash`, store new).
4. Also store a `maintenance.log` entry for the history.
5. Confirm and show the new `next_due`.

## What's due

Trigger: "what's due", "upcoming maintenance", "anything overdue".

1. Load all `maintenance.task` memories.
2. For each, compare `next_due` to today.
3. Bucket into **Overdue**, **This month**, **Next 90 days**. Sort by date inside each bucket.
4. Display:

```
Maintenance — overdue (2)
  Apr 10  HVAC filter (upstairs) — Charles  [30 days late]
  Apr 15  Gutters — anyone

This month (3)
  Apr 28  Smoke detector battery check — Charles
  ...

Next 90 days (5)
  ...
```

If a task is overdue by more than its cadence (e.g. filter every 90 days, overdue by 120+), flag it visually.

## Task history

Trigger: "when did we last clean the gutters", "history for HVAC filter".

1. Resolve task → slug.
2. Show the task definition, then list `maintenance.log` entries tagged `task:[slug]`, newest first.

## Updating a task

Find → delete by `content_hash` → store updated. Show the diff.

## Deleting a task

1. Confirm by name.
2. Delete the `maintenance.task` memory.
3. Ask whether to also delete the log history. Default: keep logs.

## Rules

- Never write outside `maintenance.*`.
- Always recompute `next_due` when marking done — never leave it stale.
- Tag every log with `task:[slug]` so history is queryable.
- Surface overdue tasks first when the user asks what's due.

## Data storage

All persistent data for this plugin lives in the `memory` MCP server (brian-mcp) at `https://brian.aldarondo.family/mcp`. Do not write to local files, other memory services, or any namespace outside `maintenance.*`.

## Email (brian-email MCP)

An `email` MCP server is available for outgoing email only. Use it when the user explicitly asks — e.g. "email me this month's maintenance list", "send the HVAC history to the service company".

- Never send email without an explicit request.
- brian-email is send-only. Never treat it as storage — all task and log data still lives in memory under `maintenance.*`.
- Resolve recipient names against the `contacts` plugin (`contacts.contact`). If a name can't be resolved to an address, ask.
- Confirm recipient, subject, and a brief preview of the body before sending.
- Keep subjects short. Send a plain-text body.
