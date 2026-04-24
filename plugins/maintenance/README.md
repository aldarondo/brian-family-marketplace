# maintenance

**Access:** All family members
**Namespace:** `maintenance.*`

Home maintenance tracker. Recurring tasks (HVAC filters, smoke detector batteries, gutters, water softener, seasonal yard work) with last-done dates, next-due computation, and a "what's overdue" view.

## Install

```bash
/plugin install maintenance@brian-family
```

## Usage

```
# Set up a recurring task
"Add maintenance task — HVAC filter upstairs, every 90 days, last done April 10, Charles"

# Mark a task done
"Filter changed today"
"Gutters cleaned — Charles did it, April 22"

# Check what's due
"What maintenance is due this month?"
"Anything overdue?"

# History
"When did we last clean the gutters?"
"Show HVAC filter history"
```

## Memory namespace

| Tag | Meaning |
|---|---|
| `maintenance.task` | A recurring task definition |
| `maintenance.log` | One completion event, tagged `task:[slug]` |

## Requirements

Brian memory endpoint live at `https://brian.aldarondo.family/mcp`. `BRIAN_MCP_CLIENT_ID` and `BRIAN_MCP_CLIENT_SECRET` set.
