---
description: Use this skill to plan and recall family trips — create a trip, add travelers, build an itinerary, track confirmations (flights/hotels/rentals), and manage packing lists. Triggers include "plan a trip", "add flight", "what's on the itinerary", "packing list for Colorado", "upcoming trips".
---

You have access to a shared memory layer (Brian's mcp-memory-service). All trip data uses the namespace prefix `travel.`.

## Data model

### `travel.trip` — one per trip

```
travel.trip: [Destination] — [YYYY-MM-DD] to [YYYY-MM-DD]
id: travel-[slug]                 # e.g. travel-colorado-2026-07
destination: [city / region]
start_date: YYYY-MM-DD
end_date: YYYY-MM-DD
travelers: [comma-separated names]
purpose: [optional — "vacation", "family visit", "funeral", "college tour"]
status: planned | booked | in_progress | complete | cancelled
notes: [free text — themes, budget, etc.]
created_by: [person]
created_at: ISO 8601
```

Tags: `travel.trip,travel,status:[status]`.

### `travel.item` — itinerary entries, confirmations, packing items

```
travel.item: [title]
trip_id: travel-[slug]
kind: [flight | lodging | rental-car | activity | reservation | packing | note]
date: YYYY-MM-DD              # for itinerary items
time: HH:MM                   # optional, local
confirmation: [code]          # flight PNR, hotel conf, rental conf
vendor: [airline / hotel / company]
details: [free text — addresses, flight numbers, checkin times]
cost: [USD or null]
packed: true | false          # only for kind=packing
for: [optional — "everyone", "Moriah", etc.]
```

Tags: `travel.item,travel,trip:[slug],kind:[kind]`.

## Creating a trip

1. Ask: destination, dates, travelers, purpose.
2. Generate slug: `[destination-lowercased]-[YYYY]-[MM]`.
3. Store `travel.trip` with `status: planned`.
4. Confirm and offer: "Add flights, lodging, or a packing list?"

## Adding items (flights / hotels / rentals / activities)

1. Identify the trip (match by destination or offer a picker of recent trips).
2. Collect fields based on `kind`:
   - flight: airline, flight #, date, time, confirmation, seats, cost
   - lodging: hotel/Airbnb name, checkin/checkout dates, conf, address, cost
   - rental-car: vendor, pickup/dropoff, conf, cost
   - activity / reservation: name, date, time, conf if any, notes, cost
3. Store tagged with `trip:[slug]` and `kind:[kind]`.
4. Flip the trip's `status` to `booked` once at least one booking exists.

## Itinerary view

Trigger: "show the itinerary", "what's on the Colorado trip".

1. Resolve trip.
2. Load items tagged `trip:[slug]`, excluding `kind:packing`.
3. Sort by `date` then `time`. Render as a day-by-day agenda:

```
Colorado — Jul 10–17 (Charles, Moriah, Jack, Quincy)

Thu Jul 10
  08:10  Flight AA 2194  PHX → DEN   conf ABC123
  13:00  Budget SUV pickup — DEN airport   conf RENT-98
  17:30  Check in — Silverthorne cabin   conf BNB-442

Fri Jul 11
  ...
```

## Packing list

Trigger: "packing list for Colorado", "what do I still need to pack".

1. Resolve trip.
2. Load items tagged `trip:[slug]` and `kind:packing`.
3. Group by `for` (everyone / per-person). Show `packed: false` first, then packed items.
4. For adds: accept lists like "add boots, gloves, sunscreen to packing" — create one `travel.item` per.
5. For toggles: "pack boots" → flip `packed: true` on that item.

## Upcoming trips

Trigger: "upcoming trips", "what trips are coming up".

1. Load all `travel.trip` with `status in (planned, booked)` and `start_date >= today`.
2. Sort by `start_date`. Display destination, dates, travelers, status, and days-until.

## Confirmations lookup

Trigger: "flight confirmation for the Colorado trip", "hotel address for Colorado".

1. Resolve trip.
2. Filter items by `kind`. Show the confirmation codes and key details only.

## Completing / cancelling a trip

1. Update the `travel.trip` memory's `status`.
2. Keep all items for historical reference.

## Rules

- Never write outside `travel.*`.
- Tag every item with `trip:[slug]` and `kind:[kind]`.
- Confirm before deleting a trip — ask whether to purge items or keep them.
- Always show the itinerary grouped by date, not a flat list.

## Data storage

All persistent data for this plugin lives in the `memory` MCP server (brian-mcp) at `https://brian.aldarondo.family/mcp`. Do not write to local files, other memory services, or any namespace outside `travel.*`.

## Email (brian-email MCP)

An `email` MCP server is available for outgoing email only. Use it when the user explicitly asks — e.g. "email the Colorado itinerary to everyone going", "send the flight confirmations to Moriah".

- Never send email without an explicit request.
- brian-email is send-only. Never treat it as storage — all trip and item data still lives in memory under `travel.*`.
- Resolve recipient names against the `contacts` plugin (`contacts.contact`). For travelers on the trip, also check the trip's `travelers` field — if those names don't resolve, ask for addresses.
- Confirm recipients, subject, and a brief preview of the body before sending.
- For itineraries, send as plain-text with the same day-grouped format used on screen. Keep subjects short.
