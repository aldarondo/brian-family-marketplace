# travel

**Access:** All family members
**Namespace:** `travel.*`

Family trip planner. One record per trip with dates and travelers, plus itinerary items, booking confirmations, and a packing list.

## Install

```bash
/plugin install travel@brian-family
```

## Usage

```
# Plan
"Plan a trip — Colorado, July 10–17, Charles, Moriah, Jack, Quincy"

# Add bookings
"Add flight — AA 2194, PHX to DEN, July 10 8:10am, conf ABC123, $240/ea"
"Add lodging — Silverthorne cabin, check in July 10, check out July 17, conf BNB-442"

# Itinerary
"Show the Colorado itinerary"

# Packing
"Add to Colorado packing: boots, gloves, sunscreen"
"What's left to pack for Colorado?"

# Upcoming
"Upcoming trips"
```

## Memory namespace

| Tag | Meaning |
|---|---|
| `travel.trip` | A trip record |
| `travel.item` | Itinerary entry, booking, packing item — tagged `trip:[slug]` and `kind:[kind]` |

## Requirements

Brian memory endpoint live at `https://brian.aldarondo.family/mcp`. `BRIAN_MCP_CLIENT_ID` and `BRIAN_MCP_CLIENT_SECRET` set.
