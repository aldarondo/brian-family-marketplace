# vehicles

**Access:** All family members
**Namespace:** `vehicles.*`

Shared family vehicle registry. Tracks each car's identifying info, registration and insurance renewals, inspection, and a running service history.

## Install

```bash
/plugin install vehicles@brian-family
```

## Usage

- "Add a car — 2019 Subaru Forester, VIN JF2…"
- "Log oil change on the Forester today, 52,100 mi, at Bridgestone, $89"
- "What's the service history on the Odyssey?"
- "When was the last oil change on the Forester?"
- "What renewals are due in the next 60 days?"

## Memory namespace

| Tag | Meaning |
|---|---|
| `vehicles.vehicle` | One car record |
| `vehicles.service` | One service event, tagged `vehicle:[slug]` |

## Requirements

Brian memory endpoint live at `https://brian.aldarondo.family/mcp`. `BRIAN_MCP_CLIENT_ID` and `BRIAN_MCP_CLIENT_SECRET` set.
