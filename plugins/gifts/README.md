# gifts

**Access:** All family members
**Namespace:** `gifts.*`

Birthday and gift idea tracker. Keeps a running list of gift ideas per person, a history of what's been given, and a rolling view of upcoming birthdays and anniversaries.

## Install

```bash
/plugin install gifts@brian-family
```

## Usage

```
# People
"Add person — Grandma Ruth, mother-in-law, birthday May 14, loves gardening, no wool"

# Ideas
"Add a gift idea for Jack — Sony WH-1000XM5 headphones, $350, birthday, high priority"
"Gift ideas for Moriah?"

# Given
"Gave Jack the headphones for his birthday, $340"
"What have we given mom?"

# Upcoming
"Whose birthday is coming up?"
"Any birthdays this month?"
```

## Memory namespace

| Tag | Meaning |
|---|---|
| `gifts.person` | A person record (birthday, interests, sizes) |
| `gifts.idea` | An active gift idea, tagged `person:[slug]` and `status:active` |
| `gifts.given` | Historical record of a gift given, tagged `person:[slug]` |

## Requirements

Brian memory endpoint live at `https://brian.aldarondo.family/mcp`. `BRIAN_MCP_CLIENT_ID` and `BRIAN_MCP_CLIENT_SECRET` set.
