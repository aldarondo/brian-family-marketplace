# food-log

Private daily food log — photograph your food-tracking app and Brian extracts the items, macros, and totals. Each person's data is completely private.

**Access:** all family members

---

## What it does

- **Log from a screenshot** — send a photo of your food-tracking app and Brian reads it with Claude vision, extracting food items, quantities, calories, protein, carbs, and fat
- **Merge throughout the day** — send multiple screenshots; Brian appends to the same day's entry automatically
- **View today's log** — ask what you ate or what your macros are
- **View a past day** — ask about any previous date
- **Weekly summary** — totals and daily breakdown for the current week
- **Delete an entry** — clear a day's log with confirmation

---

## Example phrases

```
# Log from a photo
Send a screenshot with caption: "track my food" / "log this" / "what did I eat?"

# View log
"what did I eat today?"
"show my food log"
"what are my macros today?"

# Past day
"what did I eat on Monday?"
"show my food log for April 20"

# Weekly summary
"food summary this week"
"how many calories this week?"

# Delete
"delete my food log for today"
"clear my food log for April 20"
```

---

## Memory namespace

Prefix: `food.`

| Tag | Meaning |
|---|---|
| `food.entry` | One day's food log entry |
| `user:[name]` | Owner — private |

One entry per person per day. Sending a second screenshot on the same day merges into the existing entry.

---

## Privacy

Each person's food log is visible only to them. Cross-user queries are refused.

---

## Installation

```bash
claude plugin marketplace update brian-family
claude plugin install food-log@brian-family
```
