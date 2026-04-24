---
description: Use this skill to register a vehicle, log service or fuel, view service history, check upcoming registration/insurance renewals, or answer "when was the last oil change on the Forester?". Triggers include "add a car", "log oil change", "service history", "when is insurance due", "what cars do we have".
---

You have access to a shared memory layer (Brian's mcp-memory-service). All vehicle data uses the namespace prefix `vehicles.`.

## Data model

Two kinds of memories.

### `vehicles.vehicle` — one per car

```
vehicles.vehicle: [Year Make Model]
id: vehicles-[slug]             # e.g. vehicles-2019-subaru-forester
nickname: [optional — "the Forester"]
vin: [VIN]
plate: [license plate]
year: [YYYY]
make: [make]
model: [model]
trim: [optional]
color: [optional]
fuel: [gas | diesel | hybrid | ev]
primary_driver: [name or "family"]
registration_renewal: YYYY-MM-DD
insurance_carrier: [carrier]
insurance_policy: [policy #]
insurance_renewal: YYYY-MM-DD
inspection_due: YYYY-MM-DD      # if applicable
notes: [optional]
added_by: [person]
added_at: ISO 8601
```

Tags: `vehicles.vehicle,vehicles`.

### `vehicles.service` — one per service event

```
vehicles.service: [Year Make Model] — [service type] — [YYYY-MM-DD]
vehicle_id: [slug from the vehicle memory]
date: YYYY-MM-DD
odometer: [miles]
type: [oil change | tire rotation | brakes | battery | inspection | recall | repair | other]
shop: [where it was done]
cost: [USD or null]
next_due_date: [YYYY-MM-DD or null]
next_due_miles: [miles or null]
notes: [optional]
logged_by: [person]
```

Tags: `vehicles.service,vehicles,vehicle:[slug]`.

## Adding a vehicle

1. Ask for year, make, model, VIN, plate, primary driver.
2. Ask for registration renewal, insurance carrier + renewal, and inspection due (if the state requires one).
3. Generate the slug: `[year]-[make-lowercased]-[model-lowercased-hyphenated]`.
4. Store the `vehicles.vehicle` memory. Confirm with the full record.

## Logging service

1. Ask which car (or infer from nickname). If more than one match, list and ask.
2. Ask date, odometer, service type, shop, cost, and next-due if known.
3. Store the `vehicles.service` memory tagged with `vehicle:[slug]`.
4. Confirm and show the last 3 service entries for that vehicle.

## Viewing a vehicle

Trigger: "show the Forester", "what cars do we have".

- Listing all vehicles: `memory_search(query: "vehicles", tags: ["vehicles.vehicle"])`. Show a table: nickname, year/make/model, primary driver, registration renewal.
- Single vehicle: find by nickname or slug. Show all vehicle fields, then the last 5 service entries (search `tags: ["vehicles.service", "vehicle:[slug]"]`, newest first).

## Service history

Trigger: "when was the last oil change on the Forester", "full service history for the Odyssey".

1. Resolve the vehicle to a slug.
2. Search `vehicles.service` with tag filter `vehicle:[slug]`, optionally narrowed by service type.
3. Sort by date descending. Display.

## Upcoming renewals / due services

Trigger: "what's due soon", "any renewals coming up".

1. Load all `vehicles.vehicle` memories and all `vehicles.service` memories.
2. Collect: registration renewal, insurance renewal, inspection due, any service `next_due_date` or odometer threshold.
3. Filter to the next 60 days (or user-specified window).
4. Display sorted by date:

```
Upcoming — next 60 days

Apr 29  Forester — registration renewal
May 10  Odyssey  — oil change due (5,000 mi)
Jun 02  Forester — insurance renewal ($1,240, Geico)
```

## Updating a vehicle

1. Find the `vehicles.vehicle` memory.
2. Delete by `content_hash`, store updated version with the same id/slug.
3. Show the diff in the confirmation.

## Deleting a vehicle

1. Confirm which car and that they want to remove it.
2. Delete the `vehicles.vehicle` memory.
3. Ask whether to also delete the service history (`vehicle:[slug]` tagged `vehicles.service`). Default: keep history.

## Rules

- Never write outside `vehicles.*`.
- Always tag service entries with `vehicle:[slug]` so per-car history is queryable.
- Always show the vehicle or entry after add/update for confirmation.
- Ask before bulk deletes.

## Data storage

All persistent data for this plugin lives in the `memory` MCP server (brian-mcp) at `https://brian.aldarondo.family/mcp`. Do not write to local files, other memory services, or any namespace outside `vehicles.*`.

## Email (brian-email MCP)

An `email` MCP server is available for outgoing email only. Use it when the user explicitly asks — e.g. "email the Forester service history to the insurance agent", "send me the list of upcoming renewals".

- Never send email without an explicit request.
- brian-email is send-only. Never treat it as storage — all drafts, logs, and content still live in memory under `vehicles.*`.
- Resolve recipient names against the `contacts` plugin (`contacts.contact`). If a name can't be resolved to an address, ask.
- Confirm recipient, subject, and a brief preview of the body before sending.
- Keep subjects short. Send a plain-text body.
