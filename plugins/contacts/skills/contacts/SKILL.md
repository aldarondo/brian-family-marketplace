---
description: Use this skill to store, search, view, or update family contacts — emergency numbers, medical providers, the hospice / end-of-life care team, schools, and service providers. Triggers include "add contact", "who is mom's oncologist", "hospice nurse number", "after-hours line", "pharmacy", "school nurse", "plumber", "show the care team".
---

You have access to a shared memory layer (Brian's mcp-memory-service). All contact data uses the namespace prefix `contacts.`. Contacts are shared family data — no per-user scoping.

## Categories

Every contact carries a `category` tag. Use exactly one primary category:

| Category | For |
|---|---|
| `emergency` | 911 alternates, poison control, after-hours pediatric line, neighbors to call |
| `medical` | Primary care, specialists, dentists, therapists, pharmacies, labs — the ongoing care web for any family member |
| `care-team` | End-of-life / hospice / palliative care roles specifically (see below) |
| `school` | School main line, counselor, nurse, specific teachers, coaches |
| `household` | Plumber, electrician, HVAC, landscaper, locksmith, pest, appliance repair |
| `financial` | Accountant, bank relationship manager, insurance agent, attorney |
| `personal` | Close friends/family outside the household |
| `other` | Anything that doesn't fit — include a free-text note |

## Care team — special handling

The `care-team` category is for coordinating end-of-life, hospice, or palliative care for a family member. Treat this as first-class, not a subset of "medical." It is used when someone in the family is in terminal or serious ongoing care, and a quick, complete roster matters — especially at 2am, for a caregiver, or for a family member who just needs to know who to call.

Common `care-team` roles to prompt for when first setting up:

- **Case manager / care coordinator** — hospice agency point of contact
- **Primary nurse** and **after-hours on-call line** (these are often different numbers — capture both)
- **Physician** attending
- **Aide / CNA**
- **Social worker**
- **Chaplain / spiritual care** (if wanted)
- **Pharmacy** handling comfort meds (often a specific hospice-contracted pharmacy)
- **DME / medical equipment supplier** (oxygen, hospital bed, hoyer lift, etc.)
- **Funeral home / mortuary** if the family has chosen one

Every `care-team` contact should include:
- `for:` — which family member the contact serves (tag as `patient:[name]`)
- `role:` — one of the roles above, or a free-text description
- `after_hours:` — a second phone number if the day line differs from the on-call line
- `notes:` — anything a tired caregiver needs at 2am (gate code, direct cell for a specific nurse, "call this line first — they dispatch")

Tone when the user is working in `care-team`: calm, concrete, no filler. Don't narrate feelings, don't avoid the subject — just help them capture it accurately and retrieve it fast.

## Memory format

```
contacts.contact: [Display Name]
id: contacts-[slug]
category: [one of the categories above]
role: [e.g. "Oncologist", "Hospice on-call", "Plumber"]
organization: [practice / agency / company — optional]
phone: [primary]
phone_after_hours: [optional — required for care-team on-call roles]
email: [optional]
address: [optional]
website: [optional]
for: [family member this contact serves, if applicable — e.g. "Moriah", "mom", "shared"]
notes: [free text — gate code, direct extension, preferred contact time, anything important]
added_by: [person]
added_at: ISO 8601
```

Tags: `contacts.contact,contacts,category:[category]`, plus `patient:[name]` when `for` is set to a specific person.

## Adding a contact

1. Ask which category. If the user says "doctor," "nurse," or "pharmacy," confirm whether it's general `medical` or part of the `care-team` for a specific person — these get handled differently.
2. Collect the fields above. For `care-team` entries, always prompt for the after-hours line and which family member the contact is for.
3. Generate a slug from the display name.
4. Store the memory with all relevant tags.
5. Confirm with a clean readout of the saved contact.

## Searching / viewing contacts

Trigger examples: "who is the plumber", "mom's oncologist", "hospice after-hours line", "show the care team".

- By category: `memory_search(query: "contacts", tags: ["contacts.contact", "category:[category]"])`.
- For a family member's care team: `memory_search(query: "care team [name]", tags: ["contacts.contact", "category:care-team", "patient:[name]"])`. Display grouped by role, ordered: primary nurse, on-call, physician, social worker, chaplain, aide, pharmacy, DME, funeral home, other.
- By role/keyword: add the keyword to the query (e.g. "oncologist", "plumber").
- Single contact by name: match on display name or slug.

Always show phone numbers in a readable format. If an `after_hours` number exists and the time is outside 9–5, surface it first.

## Care team roster view

Trigger: "show the care team for [name]", "who's on the care team".

Output a dense, scannable roster:

```
Care team — [Name]

Case manager      [Name] — [day phone]
Primary nurse     [Name] — [day phone]  |  on-call: [after-hours phone]
Physician         [Name] — [phone]
Aide              [Name] — [phone]
Social worker     [Name] — [phone]
Chaplain          [Name] — [phone]
Pharmacy          [Name] — [phone]     notes: [e.g. "delivers M/W/F"]
DME               [Name] — [phone]
Funeral home      [Name] — [phone]     notes: [optional]
```

Only show roles that exist. If the user asks at night (local time), highlight the on-call number at the top.

## Updating a contact

1. Find the contact by name or slug.
2. Delete by `content_hash`, store updated version with the same id/slug.
3. Show what changed.

## Deleting a contact

1. Find the contact and show it.
2. Confirm explicitly ("Delete the contact for Dr. Smith? yes/no").
3. Delete by `content_hash`.

Never bulk-delete a category without a second confirmation.

## Rules

- Never write outside `contacts.*`.
- Always tag with `category:[category]` and (when applicable) `patient:[name]`.
- For `care-team` contacts, treat after-hours and on-call numbers as required fields — ask again if missing.
- When the user is searching during what is likely a stressful moment (keywords: "on-call", "after hours", "hospice", "emergency"), lead with the phone number — don't bury it under prose.
- Never editorialize about the care situation. Respect the user's framing.

## Data storage

All persistent data for this plugin lives in the `memory` MCP server (brian-mcp) at `https://brian.aldarondo.family/mcp`. Do not write to local files, other memory services, or any namespace outside `contacts.*`.

## Email (brian-email MCP)

An `email` MCP server is available for outgoing email only. This plugin is also the **recipient resolver** for other plugins — when another plugin (meal-plan, travel, vehicles, etc.) needs to turn a name into an email address, it reads from `contacts.contact`.

Use the email server directly when the user asks — e.g. "email the care team roster to my sister", "send the plumber's number to Moriah".

- Never send email without an explicit request.
- brian-email is send-only. Never treat it as storage — all contact data still lives in memory under `contacts.*`.
- For care-team rosters sent by email: lead with the on-call number, use plain text, include the `for:` patient name, and omit any field the user hasn't explicitly approved for sharing.
- Confirm recipient, subject, and a brief preview of the body before sending.
- Keep subjects short.
