---
description: Use this skill whenever a family member wants to log food, track what they ate, view their food log, or check their macros. Each person's log is completely private. Triggers: user sends a photo with "track", "log", "food", "ate", "calories", or "macros" in the caption; "what did I eat today"; "show my food log"; "what are my macros today"; "food summary this week"; "what did I eat on [date]"; "delete my food log for today"; image sent with no caption (default: ask if they want to log it).
---

# Skill: Food Log

**Storage**: Brian mcp-memory-service, namespace `food.*`, scoped per user via `user:[name]` tag.

---

## Identity & Privacy — Read This First

**Who is the current user?**

1. Check the current session context or env for `FOOD_LOG_USER` or `BRIAN_USER`. Use that value.
2. If not set, ask once: "Just to confirm — what's your name? (Charles, Moriah, Jack, or Quincy)"
3. Store the confirmed name for all operations this session.

**Privacy rules:**

| Rule | Behavior |
|---|---|
| Default: private | Only load and show memories tagged `user:[name]` where name = active user |
| Cross-person queries refused | "I keep food logs private. I can only show [Name]'s log to them directly." |

**Memory tag conventions:**
- All food log entries tagged: `food.entry,user:[name]`

---

## Memory Storage Format

One memory per day per user:

```
food.entry: [name] [YYYY-MM-DD]
id: food-[name]-[YYYY-MM-DD]
user: [name]
date: YYYY-MM-DD
source: screenshot | manual
items:
  - name: [food name]
    quantity: [e.g. "1 cup", "200g", "1 serving"]
    calories: [N or null]
    protein_g: [N or null]
    carbs_g: [N or null]
    fat_g: [N or null]
    notes: [e.g. "lunch", "snack" — if visible on screen]
totals:
  calories: [N or null]
  protein_g: [N or null]
  carbs_g: [N or null]
  fat_g: [N or null]
raw_ocr: [verbatim text extracted from screenshot, for reference]
logged_at: ISO 8601 timestamp
```

Tags: `food.entry,user:[name]`

**One entry per date.** If an entry exists for today, merge new items into it — never overwrite.

**To find today's entry:** `memory_search(query: "food entry [name] [YYYY-MM-DD]", tags: ["food.entry", "user:[name]"])`

**To update an entry:** delete the old memory by `content_hash`, then store the merged version.

---

## Step 1: Log from Image (primary flow)

**Trigger:** User sends a photo with caption containing "track", "log", "food", "ate", or "calories", OR sends a photo with no caption.

**No-caption case:** If a photo arrives with no caption, ask: "Want me to log this as today's food?"

**Steps:**
1. Identify user (see Identity section).
2. Read the image with Claude vision — extract all visible food items, quantities, calories, and macros.
3. Use visible totals from the screenshot if present; otherwise sum from items.
4. Check for existing entry today: `memory_search(query: "food entry [name] [today's date]", tags: ["food.entry", "user:[name]"])`.
5. If entry exists: merge new items into `items[]`, recalculate `totals`, append to `raw_ocr`.
6. If no entry: create a new entry with all extracted data.
7. Delete old entry (if updating), store merged/new entry.
8. Reply with confirmation:

```
Logged! Here's what I captured for today (April 22):

• Greek Yogurt — 1 cup — 130 cal | 17g P | 9g C | 0g F
• Banana — 1 medium — 105 cal | 1g P | 27g C | 0g F
• Chicken Breast — 6 oz — 280 cal | 53g P | 0g C | 3g F

Today's totals: 515 cal | 71g P | 36g C | 3g F

Say "show my food today" to see the full log, or send another screenshot to add more.
```

9. Flag uncertain items inline: `• [Item] — quantity unclear — 1 serving assumed`.

---

## Step 2: View Today's Log

**Trigger:** "what did I eat today", "show my food log", "what are my macros today"

1. Identify user.
2. Search for today's entry.
3. If none: "No food logged for today yet. Send a screenshot of your food tracker to get started."
4. Display formatted log (same format as Step 1 confirmation).

---

## Step 3: View a Past Day

**Trigger:** "what did I eat on Tuesday", "show my food log for April 20", "what did I have on [date]"

1. Identify user. Parse the date from the message.
2. Search for that date's entry.
3. Display log or: "Nothing logged for [date]."

---

## Step 4: Weekly Summary

**Trigger:** "food summary this week", "how many calories this week", "weekly macro summary"

1. Identify user.
2. Load entries for the current week (Monday through today, or last 7 days if mid-week).
3. Aggregate totals per day and an overall average.
4. Display:

```
Food Log — April 16–22

Mon  Apr 16:  1,840 cal | 142g P | 180g C | 52g F
Tue  Apr 17:  2,100 cal | 160g P | 210g C | 60g F
Wed  Apr 18:  no data
...

7-day avg:  1,960 cal/day | 149g P | 195g C | 55g F
```

5. Days with no entry: show "no data" — do not skip.

---

## Step 5: Delete / Correct an Entry

**Trigger:** "delete my food log for today", "that log was wrong, clear it", "remove my food log for [date]"

1. Identify user. Find the entry for the specified date.
2. Show the entry. Confirm: "Delete the food log for [date]? (yes/no)"
3. On yes: `memory_delete(content_hash: [hash])`.
4. Reply: "Cleared. Send a new screenshot whenever you're ready."

---

## Error / Edge Cases

| Situation | Handling |
|---|---|
| `BRIAN_USER` / `FOOD_LOG_USER` not set | Ask once: "What's your name — Charles, Moriah, Jack, or Quincy?" |
| Image unreadable / no food visible | "I couldn't make out any food items in that image. Try a clearer photo or describe what you ate." |
| Totals visible on screen | Use screen totals; note items if also visible |
| Totals not on screen | Sum from `items[]`; set null for any macro not shown |
| Same-day second screenshot | Always merge silently — show updated totals |
| Multi-page log (user sends multiple images) | Each image triggers a merge into the same day's entry |
| Entry not found for past date | "Nothing logged for [date]." |

---

## Tone

Food and nutrition are personal — straightforward and supportive, never judgmental. If extraction is uncertain, flag it without drama. Never share one person's food data with anyone else.
