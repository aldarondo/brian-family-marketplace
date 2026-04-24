# meal-plan

**Access:** All family members
**Namespace:** `mealplan.*` (reads `recipes.*`, writes `grocery.*` on request)

Weekly family meal plan. Builds a 7-day dinner menu from recipes already saved in the `recipes` plugin, then optionally pushes missing ingredients to the shared grocery list.

## Install

```bash
/plugin install meal-plan@brian-family
```

## Usage

- "Plan meals for this week" / "build a meal plan for next week"
- "What's for dinner today?"
- "What's the meal plan this week?"
- "Swap Tuesday's dinner for tacos"
- "Send missing ingredients to grocery"

## Depends on

- `recipes` plugin — the planner only picks from recipes already stored
- `grocery-list` plugin — when pushing ingredients, entries follow that plugin's format

## Requirements

Brian memory endpoint live at `https://brian.aldarondo.family/mcp`. `BRIAN_MCP_CLIENT_ID` and `BRIAN_MCP_CLIENT_SECRET` set.
