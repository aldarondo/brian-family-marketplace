# Plan: food-log Plugin

**Goal**: Let family members photograph their food-tracking app, send via Telegram, and have Brian extract the food data from the image and store it as a daily food log in brian-mcp.

---

## Use Case

Charles is using a food-tracking app that has no export. He screenshots the day's food log, sends the image to Brian on Telegram with a caption like *"track my food"* or *"log this"*, and Brian:
1. Reads the image with Claude vision
2. Extracts food items, quantities, and nutritional data visible on screen
3. Stores a structured entry tagged to today's date in brian-mcp
4. Replies with a confirmation summary

---

## What Already Exists

| Component | Status |
|---|---|
| Telegram image pipeline | ✅ Done — photos downloaded and passed as `--image` to Claude CLI |
| Plugin scaffold pattern | ✅ Done — follows prescriptions/grocery-list conventions |
| Memory endpoint | ✅ Live at `https://brian.aldarondo.family/mcp` |

---

## Plugin Structure

```
plugins/food-log/
  .claude-plugin/plugin.json
  skills/food-log/SKILL.md
  mcp/config.json
  README.md
```

---

## Memory Namespace

Prefix: `food.`

| Tag | Meaning |
|---|---|
| `food.entry` | One day's food log entry |
| `user:[name]` | Owner — private, same as prescriptions |

No cross-user access. Each person's food data is private.

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

**One entry per date.** If an entry already exists for today, merge/append items rather than overwrite.

---

## Skill Operations

### Log from Image (primary flow)

**Trigger**: User sends a photo with caption containing "track", "log", "food", "ate", "calories", or sends a photo with no caption (default action: ask if they want to log it).

**Steps**:
1. Identify user from `FOOD_LOG_USER` in session context or `BRIAN_USER` env var.
2. Read the image — extract all visible food items, quantities, calories, macros.
3. Check for existing entry today: `memory_search(query: "food entry [name] [date]", tags: ["food.entry", "user:[name]"])`.
4. If entry exists: append new items to `items[]`, recalculate `totals`, update `raw_ocr`.
5. If no entry: create new entry with extracted data.
6. Delete old entry (if updating), store new.
7. Reply with confirmation:

```
Logged! Here's what I captured for today (April 22):

• Greek Yogurt — 1 cup — 130 cal | 17g protein | 9g carbs | 0g fat
• Banana — 1 medium — 105 cal | 1g protein | 27g carbs | 0g fat
• Chicken Breast — 6 oz — 280 cal | 53g protein | 0g carbs | 3g fat
...

Today's totals: 820 cal | 83g protein | 64g carbs | 12g fat

Say "show my food today" to see the full log, or send another screenshot to add more.
```

8. If extraction is uncertain about an item: flag it inline — `• [Item] — quantity unclear — 1 serving assumed`.

---

### View Today's Log

**Trigger**: "what did I eat today", "show my food log", "what are my macros today"

1. Search for today's entry.
2. If none: "No food logged for today yet. Send a screenshot of your food tracker to get started."
3. Display formatted log (same as confirmation format above).

---

### View a Past Day

**Trigger**: "what did I eat on Tuesday", "show my food log for April 20"

1. Parse date from message.
2. Search for that date's entry.
3. Display or "Nothing logged for [date]."

---

### Weekly Summary

**Trigger**: "food summary this week", "how many calories this week", "weekly macro summary"

1. Load entries for current week (Mon–today or last 7 days).
2. Aggregate totals per day and overall.
3. Display:

```
Food Log — April 16–22

Mon  Apr 16:  1,840 cal | 142g P | 180g C | 52g F
Tue  Apr 17:  2,100 cal | 160g P | 210g C | 60g F
...

7-day avg:  1,960 cal/day | 149g P | 195g C | 55g F
```

---

### Delete / Correct an Entry

**Trigger**: "delete my food log for today", "that log was wrong, clear it"

1. Find entry. Confirm: "Delete the food log for [date]? (yes/no)"
2. On yes: `memory_delete`.
3. Reply: "Cleared. Send a new screenshot whenever you're ready."

---

## Access Control

| User | Access |
|---|---|
| charles | ✅ |
| moriah | ✅ |
| jack | ✅ |
| quincy | ✅ |

Access: `all` in `PLUGIN_ACCESS` (bot.js).

---

## brian-telegram Wiring

1. Add to `PLUGIN_VERSIONS` in [src/bot.js](../../../brian-telegram/src/bot.js):
   ```js
   'food-log': '1.0.0',
   ```
2. Add to `PLUGIN_ACCESS`:
   ```js
   'food-log': 'all',
   ```
3. Add `/help food` entry to `SKILL_HELP_ALL` in the `/help` handler.
4. No changes needed to the image pipeline — already passes `--image` to Claude.

---

## Implementation Sequence

| Step | Work | Where |
|---|---|---|
| 1 | Write `plugins/food-log/.claude-plugin/plugin.json` | brian-family-marketplace |
| 2 | Write `plugins/food-log/mcp/config.json` (copy from prescriptions, same endpoint) | brian-family-marketplace |
| 3 | Write `plugins/food-log/skills/food-log/SKILL.md` (this plan → skill instructions) | brian-family-marketplace |
| 4 | Write `plugins/food-log/README.md` | brian-family-marketplace |
| 5 | Add `food-log` entry to `marketplace.json` | brian-family-marketplace |
| 6 | Wire plugin into bot.js (`PLUGIN_VERSIONS` + `PLUGIN_ACCESS` + `/help`) | brian-telegram |
| 7 | Install plugin on NAS: `claude plugin marketplace update brian-family && claude plugin install food-log@brian-family` | Human (Charles) |
| 8 | Smoke test: send food screenshot via Telegram, verify memory stored | Human (Charles) |

---

## Open Questions

- **Append vs. replace**: When a second screenshot arrives on the same day, should Brian merge items into the existing entry or ask? → Proposed: always merge silently, show updated totals.
- **Totals visibility**: Some food apps show aggregate totals on screen; others don't. Claude should use visible totals if present, otherwise sum from items.
- **Multi-page screenshots**: If the day's log spans multiple screens, the user sends multiple images in sequence. Brian should detect same-day and append automatically.
- **App-specific formatting**: Different apps lay out data differently. No special-casing — rely entirely on Claude vision to read whatever is on screen.
