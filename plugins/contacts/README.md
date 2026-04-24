# contacts

**Access:** All family members
**Namespace:** `contacts.*`

Shared family contact directory. One place for emergency numbers, medical providers, the hospice / end-of-life care team, school contacts, service providers, and personal contacts — so any family member can pull up who to call without digging through a phone.

## Install

```bash
/plugin install contacts@brian-family
```

## Usage

```
# Add
"Add a contact — Dr. Patel, oncologist at MD Anderson, for mom"
"Add the plumber — Joe's Plumbing, 602-555-0133"
"Add the hospice on-call line — 602-555-0199, care team for mom"

# Search
"Who is mom's oncologist?"
"Show the care team for mom"
"After-hours hospice number"
"Who's the plumber we used last time?"
"Show all emergency contacts"
```

## Categories

| Category | For |
|---|---|
| `emergency` | 911 alternates, poison control, pediatric after-hours, neighbors |
| `medical` | Primary care, specialists, dentists, therapists, pharmacies |
| `care-team` | Hospice / palliative / end-of-life roles for a specific family member |
| `school` | School lines, counselors, nurses, teachers, coaches |
| `household` | Plumber, electrician, HVAC, landscaper, locksmith, pest, repair |
| `financial` | Accountant, banker, insurance agent, attorney |
| `personal` | Close friends and extended family |
| `other` | Anything else |

## Care team

The `care-team` category is built for coordinating end-of-life care. When a family member is in hospice or terminal care, this plugin keeps the full care roster — case manager, primary nurse and on-call line, physician, social worker, chaplain, pharmacy, DME supplier, funeral home — retrievable in one request. After-hours numbers are tracked separately from day lines and surfaced first when it's late.

## Memory namespace

| Tag | Meaning |
|---|---|
| `contacts.contact` | A contact record |
| `category:[name]` | Primary category |
| `patient:[name]` | Family member this contact serves (for medical / care-team) |

## Requirements

Brian memory endpoint live at `https://brian.aldarondo.family/mcp`. `BRIAN_MCP_CLIENT_ID` and `BRIAN_MCP_CLIENT_SECRET` set.
