---
description: Use this skill whenever a family member wants to manage their medications, prescriptions, vitamins, or supplements. Each person's list is completely private. Triggers: "add [medication] to my list", "what medications am I on", "when do I need to refill [medication]", "remind me to refill [medication]", "update my refill date", "remove [medication]", "I got a refill", "what supplements am I taking", "what's my RX number for [medication]", "my doctor changed my dosage", "give me my medication list for my appointment", "what do I need to refill soon"
---

# Skill: Prescription & Medication Manager

**Storage**: Brian mcp-memory-service, namespace `prescriptions.*`, scoped per user via `user:[name]` tag.

---

## Identity & Privacy — Read This First

**Who is the current user?**

1. Check the current session context or CLAUDE.md for `PRESCRIPTIONS_USER: [name]`. Use that value.
2. If not set, ask once: "Just to confirm — what's your name? (Charles, Moriah, Jack, or Quincy)"
3. Store the confirmed name as the active user for all operations this session.

**Privacy rules:**

| Rule | Behavior |
|---|---|
| Default: private | Only load and show memories tagged `user:[name]` where name = active user |
| Moriah ↔ Emil | Moriah can read and write Emil's data; if Moriah says "for Emil" or "Emil's [medication]" → use `user:emil` |
| Cross-person queries refused | "I keep medication lists private. I can only share [Name]'s list with them directly." |
| Emil | No Claude Code — Moriah is his proxy |

**Memory tag conventions:**
- All prescription items tagged: `prescriptions.item,user:[name]`
- Prescriptions also tagged: `prescriptions.prescription`
- OTC/vitamins/supplements also tagged: `prescriptions.otc`
- Pending items tagged: `prescriptions.pending`

---

## Memory Storage Format

Each medication is one memory entry with this content structure:

```
prescriptions.item: [Name] [Dosage]
id: [slug — lowercase name+dosage, hyphens, e.g. metformin-500mg]
user: [name]
type: prescription | otc
dosage: [value]
frequency: [how often]
schedule: [morning | lunch | evening | bedtime | as needed — can be multiple]
rx_number: [value or null]
doctor: [value or null]
pharmacy: [value or null]
auto_refill: true | false
supply_days: [N or null]
refills_remaining: [N or null]
prescription_expires: [YYYY-MM-DD or null]
last_filled: [YYYY-MM-DD or null]
next_refill: [YYYY-MM-DD or null]
refill_lead_days: [N — default 7]
refill_reminder_days: [N or null]
refill_reminder_active: true | false
reminder_task_id: [id or null]
renewal_needed: true | false
doctor_reminder_date: [YYYY-MM-DD or null]
doctor_reminder_task_id: [id or null]
notes: [text or null]
added_date: [YYYY-MM-DD]
```

Tags: `prescriptions.item,user:[name],prescriptions.[type]`

**To find all items for a user:** `memory_search(query: "prescriptions item", tags: ["prescriptions.item", "user:[name]"])`

**To find one item:** `memory_search(query: "[medication name]", tags: ["prescriptions.item", "user:[name]"])`

**To update an item:** delete by `content_hash`, then re-store with updated content.

---

## Step 0: Identify Requester and Target

1. Confirm the active user (see Identity section above).
2. Determine target: default = active user; Moriah saying "for Emil" → target is `user:emil`.
3. All memory operations filter by `user:[target]` tag.

---

## Step 1: First-Time Intake Session

**When to trigger**: Active user has no existing memories tagged `prescriptions.item,user:[name]`, OR they explicitly ask for full setup.

### 1.1 Offer intake

```
Before I add that, since this is your first time setting up your medications with me — would you like to go through all of them at once? I'll ask a few questions for each one (dosage, refill dates, reminders, etc.).

Just say YES for a full setup, or NO to add only the one you mentioned.
```

### 1.2 Guided intake loop

Work through medications one at a time. 2–3 questions per message — never a wall.

**Opening:**
```
Great! Tell me the name of your first medication or supplement — and the dosage if you know it (like "Metformin 500mg" or "Vitamin D 2000 IU").
```

**Round 1** — after name/dosage:
```
Got it — [name] [dosage]. Two quick questions:
1. How often do you take it?
2. Is this a prescription, or an OTC vitamin/supplement?
```

**Round 2** — after frequency/type:

*Prescription:*
```
A few details:
1. Who's the prescribing doctor?
2. Which pharmacy?
3. RX number? (on the bottle — skip if you don't have it)
```
Then: "When did the doctor say to take it — morning, with meals, bedtime?"

*OTC:* Look up in **OTC Timing Recommendations** and offer the suggestion. Ask: "Where do you buy it — brand or store? (Optional)"

**Round 3** — supply and refill:
```
How much do you have right now? E.g. "just filled — 30-day supply", "about 2 weeks left", "bottle is half full".
```
Calculate: `supply_days`, `last_filled`, `next_refill = last_filled + supply_days - refill_lead_days`

*Prescription only:*
```
Refills remaining on the bottle? And when does the prescription itself expire?
```

**Round 4** — reminders:

*Prescription:*
```
1. Auto-refill at the pharmacy, or do you call it in?
2. Want a refill reminder? If yes, how many days ahead? (Suggest: 7 for 30-day, 14 for 90-day)
```
If `prescription_expires` within 90 days: offer doctor renewal reminder.

*OTC:*
```
Want a reminder when you're running low? How many days before?
```

**After each item**: save immediately to memory (do not batch). Run **Interaction Check** against existing items. Then: "Saved! Another medication to add, or say 'done'?"

### 1.3 Wrap-up

```
All set! Here's your list:
[display full list — Step 3 format]

Upcoming refills:
• [Name] — [date] ([X] days away)
```

---

## Step 2: Add a Single Item

**Trigger**: Adding to a non-empty list, or user declined full intake.

1. Run Step 0.
2. Check for empty list — if empty, offer Step 1 first.
3. Extract what was provided. Ask for missing required fields in Round groupings.
4. Assign `id`: `[name-dosage]` slug.
5. Check for duplicate: search by name — if found, offer to update instead.
6. Run **Interaction Check** against existing items. Surface warnings before saving.
7. Store the memory.
8. If `refill_reminder_active` and `next_refill` set: schedule reminder.
9. Reply:
```
Added [name] ([dosage], [frequency])!
Take: [schedule]
[Next refill: [date] — if set]
[I'll remind you [X] days before on [date] — if reminder set]
[Heads up — this will be your last refill. — if refills_remaining = 1]
```

---

## Step 3: View Medication List

**Trigger**: "What medications am I on?", "Show my list", "What's my RX number for [name]?"

1. Run Step 0.
2. Search: `memory_search(query: "prescriptions item", tags: ["prescriptions.item", "user:[name]"], limit: 50)`
3. If empty: "Your medication list is empty. Want to add something?"
4. Single item lookup (RX number, refill date, etc.): find and return just that field.
5. Full list — group by type:

```
Your Medications & Supplements
────────────────────────────────
PRESCRIPTIONS
• Metformin 500mg — twice daily  |  Take: morning and evening with meals
  RX#: 1234567  |  Refills left: 2  |  Expires: Jun 1, 2026
  Next refill: Apr 1  |  Auto-refill: Yes  |  Reminder: 7 days before
  Doctor: Dr. Smith  |  Pharmacy: Walgreens

VITAMINS & SUPPLEMENTS
• Vitamin D 5000 IU — once daily  |  Take: lunch with meal
  Next refill: Apr 15  |  Reminder: 7 days before
```

6. Filter on request ("just my vitamins", "only prescriptions needing renewal", etc.).

---

## Step 4: Update Refill Info

**Trigger**: "I picked up my [medication]", "Just refilled [medication], 90-day supply"

1. Find the item. Update:
   - `last_filled` → today (or parsed date)
   - `supply_days` → update if new duration mentioned
   - `next_refill` → recalculate: `last_filled + supply_days - refill_lead_days`
   - `refills_remaining` → decrement by 1 if tracked
2. Delete old memory, store updated.
3. Cancel and reschedule reminder if active.
4. Check `refills_remaining` after decrement:
   - `=== 1`: "Heads up — this is your last refill. Call Dr. [name] before your next one."
   - `=== 0`: "That was your last refill! You'll need a new prescription. Want me to set a doctor reminder?"
5. Reply:
```
Updated! [Name] refilled on [date].
Next refill: [date]  |  Refills remaining: [N]
[Reminder rescheduled for [date].]
```

---

## Step 5: Update Dosage

**Trigger**: "My doctor changed my [medication] to [new dosage]"

1. Find item. Confirm: "Updating [name] from [old] to [new] — confirm?"
2. On confirm: update `dosage`, update `id` slug, append to `notes`: "Dosage changed from [old] to [new] on [date]".
3. For OTC: re-run OTC Timing Recommendations — surface if recommendation changes.
4. For prescription: ask if frequency, timing, or refills also changed.
5. Delete old memory, store updated.
6. Reply: "Done! Updated [name] to [new dosage]."

---

## Step 6: Set or Update Reminders

**Trigger**: "Remind me X days before my [medication] refill", "Turn off the reminder for [name]"

**Refill reminders:**
1. Find item. Turning off: set `refill_reminder_active: false`, cancel scheduled task.
2. Adding/changing: update `refill_reminder_days`, recalculate date, reschedule.
3. If `next_refill` not set: "Saved. I'll schedule the reminder once I have your refill date."

**Doctor/renewal reminders:**
1. Parse date. Schedule via `mcp__scheduled-tasks__create_scheduled_task` at 9:00 AM Eastern.
2. Reply: "Done! Reminder set for [date] to schedule a visit with [doctor] about [medication]."

---

## Step 7: Remove an Item

**Trigger**: "Remove [medication] from my list", "I stopped taking [name]"

1. Find item. Show it. Confirm: "Remove [name] from your list?"
2. On YES: `memory_delete(content_hash: [hash])`, cancel all reminders.
3. Reply: "Done, removed [name] from your list."

---

## Step 8: Upcoming Refills Summary

**Trigger**: "What do I need to refill soon?", "Any prescriptions coming up?", "What's due in 2 weeks?"

1. Load all items for user. Calculate days until `next_refill`.
2. Flag: `refills_remaining === 0` or `prescription_expires` within 60 days.
3. Display sorted by soonest:

```
Upcoming Refills
────────────────────────────────
In 3 days:
• Metformin 500mg — Apr 1  [Walgreens, auto-refill]

In 12 days:
• Lisinopril 10mg — Apr 10  [0 refills left — call Dr. Smith first]

Prescriptions expiring soon:
• Lisinopril 10mg — expires Jun 1 (71 days away)

Nothing else due in the next 30 days.
```

---

## Step 9: Export for Doctor Appointment

**Trigger**: "Give me my medication list for my appointment", "Print my meds", "Export my prescription list"

1. Load all items. Format as clean plain text:

```
MEDICATION LIST — [Full Name]
As of [today's date]
--------------------------------

PRESCRIPTIONS

Finasteride 1.25mg
  Take: once daily, morning
  Doctor: [doctor]  |  Pharmacy: [pharmacy]
  RX#: [number]  |  Refills left: [N]  |  Last filled: [date]

VITAMINS & SUPPLEMENTS

Vitamin D 5000 IU
  Take: once daily, lunch with meal

[...all items...]

--------------------------------
```

2. Follow with: "Screenshot this or copy it for your doctor. Want to update anything before your appointment?"

---

## Interaction Check

Run whenever adding a new item. Compare new item name against all existing items. Surface warnings **before** saving:

```
Heads up — [new item] and [existing item] can interact. [Brief explanation.] Check with your pharmacist. Still add it?
```

Always add if person confirms — this is a flag, not a block. No message if no interactions found.

| Item A | Item B | Flag |
|---|---|---|
| Iron | Calcium | Don't take within 2 hours — compete for absorption |
| Iron | Magnesium | Don't take within 2 hours — compete for absorption |
| Iron | Antacid, Omeprazole, Pantoprazole, Famotidine, Ranitidine | Reduces iron absorption — space 2 hours |
| Calcium | Levothyroxine, Synthroid | Space 4 hours apart |
| Calcium | Zinc | Compete for absorption |
| Fiber, Psyllium, Metamucil | Any prescription | Space 2 hours from all Rx |
| Vitamin K | Warfarin, Coumadin, Eliquis, Xarelto | Vitamin K affects blood thinner effectiveness |
| Fish oil, Omega-3 | Warfarin, Coumadin, Eliquis, Xarelto, Aspirin | Increased bleeding risk |
| Vitamin E | Warfarin, Coumadin, Eliquis, Xarelto, Aspirin | Increased bleeding risk at high doses |
| Magnesium | Fluoroquinolone, Ciprofloxacin, Levofloxacin, Tetracycline, Doxycycline | Space 2 hours |
| Zinc | Fluoroquinolone, Ciprofloxacin, Levofloxacin, Tetracycline, Doxycycline | Space 2 hours |
| CoQ10 | Warfarin, Coumadin | May reduce anticoagulant effectiveness |
| Melatonin | Warfarin, Coumadin | May increase anticoagulant effect |
| Potassium | Lisinopril, Enalapril, Losartan, Valsartan, Spironolactone | Risk of high potassium |
| St. John's Wort | Any prescription | Can reduce effectiveness of many drugs |
| Berberine | Finasteride | CYP enzyme interaction — monitor |
| Quercetin | Any blood thinner, Aspirin | Mild antiplatelet — additive effect |

---

## OTC Timing Recommendations

Use when adding OTC and `schedule` not provided.

| Item (partial match, case-insensitive) | Best Time | Reason |
|---|---|---|
| Vitamin D, Vitamin A, Vitamin E, Vitamin K | Morning with breakfast or lunch with fat | Fat-soluble |
| Vitamin C | Morning or with any meal | Water-soluble |
| B vitamins, B12, B complex | Morning | Can boost energy — may interfere with sleep |
| Iron | Morning on empty stomach | Best absorbed without food |
| Calcium carbonate | With a meal | Needs stomach acid |
| Calcium citrate | Anytime | Does not require food |
| Magnesium glycinate, Magnesium | Evening or bedtime | Promotes relaxation |
| Zinc | With a small meal | Can cause nausea on empty stomach |
| Fish oil, Omega-3 | With a meal | Reduces aftertaste; fat-soluble |
| Probiotics | Morning on empty stomach | Better stomach acid survival |
| Melatonin | 30–60 min before bed | Sleep aid only |
| CoQ10 | Morning or midday with food | Fat-soluble; may boost energy |
| Turmeric, Curcumin | With a meal with fat | Fat-soluble; black pepper improves absorption |
| Fiber, Psyllium, Metamucil | With any meal, plenty of water | Space 2 hours from all Rx |
| Collagen | Morning or post-workout | Consistency matters most |
| Multivitamin | Morning with breakfast | Steady nutrient levels |
| Creatine | Morning with food | Consistency matters most |
| L-Citrulline | Morning pre-workout | Pre-exercise |
| Berberine | With meals | Take with food to reduce GI side effects |
| Resveratrol | With meals containing fat | Fat-soluble; avoid around intense exercise window |
| Quercetin | With meals | Avoid around intense exercise (±3hr window) |
| Apigenin | Morning or evening with food | CD38 inhibitor; supports NAD+ |
| TMG, Trimethylglycine | Morning or with meals | Methyl donor; supports NR/NAD+ stack |
| Broccoli Sprout Extract, Sulforaphane | Morning or lunch | Can be taken anytime with food |
| Hyaluronic Acid | Morning or evening | Take consistently; with or without food |
| NMN, Nicotinamide Riboside, Tru Niagen | Morning (first dose) + evening | Supports NAD+ — split dosing |

---

## Reminder Scheduling

**Refill reminders**: `next_refill - refill_reminder_days` at 9:00 AM Eastern.

Schedule via `mcp__scheduled-tasks__create_scheduled_task`. Store task ID as `reminder_task_id`.

Message (auto-refill): `"Hey [Name]! Your [medication] should be ready for pickup — refill date is [date]."`
Message (call-in): `"Hey [Name]! Time to call [pharmacy] for your [medication] refill — due [date]."`

**Doctor/renewal reminders**: at 9:00 AM Eastern on `doctor_reminder_date`.
Message: `"Hey [Name]! Reminder to schedule a visit with [doctor] to renew your [medication] prescription."`

To cancel/update: use `mcp__scheduled-tasks__list_scheduled_tasks` to find by stored task ID.

Default doctor reminder when `prescription_expires` is set: 30 days before expiration.

---

## Error / Edge Cases

| Situation | Handling |
|---|---|
| `PRESCRIPTIONS_USER` not set | Ask once per session: "What's your name — Charles, Moriah, Jack, or Quincy?" |
| Item not found | "I don't see '[name]' on your list. Did you mean one of these?" + list current items |
| Supply estimate vague ("almost out") | Map: "almost out" → 3–5 days; "a lot left" → ask for better estimate |
| `refills_remaining === 0` after decrement | Flag and offer doctor reminder |
| `prescription_expires` within 30 days, no doctor reminder set | Proactively offer: "Your [name] expires in [N] days — want a reminder to schedule renewal?" |
| Interaction confirmed | Add the item; no further warnings unless another conflicting item is added |
| Scheduled task creation fails | Save item, set `refill_reminder_active: false`, reply: "Saved but couldn't schedule the reminder. Say 'remind me X days before my [name] refill' to try again." |
| Duplicate item | "You already have [name] on your list. Want to update it instead?" |

---

## Tone

Health info is personal — warm, matter-of-fact, never clinical. During intake, be patient: "No worries, you can always update that later." Interaction warnings: helpful, not alarming. Never share one person's health data with anyone else.
