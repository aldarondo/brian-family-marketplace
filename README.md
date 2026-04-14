# brian-family-marketplace

Brian home server skill marketplace for the Leatherwood family. Distributes shared Claude Code skills (grocery list, family calendar, Proof Bread orders, and more) to household members via a single install command.

## Install

```bash
/plugin marketplace add charlesleatherwood/brian-family-marketplace
```

Then install the plugins you need:

```bash
/plugin install grocery-list@brian-family
/plugin install family-calendar@brian-family
# proof-bread-orders: Charles + Moriah only
/plugin install proof-bread-orders@brian-family
```

## Available Plugins

| Plugin | Access | Description |
|---|---|---|
| `grocery-list` | All family | Shared grocery list — add, remove, view items |
| `family-calendar` | All family | Shared calendar events and reminders |
| `proof-bread-orders` | Charles + Moriah only | Catering inquiry tracking |
| `home-tasks` | All family | Household to-do list and chore tracking |
| `recipes` | All family | Family recipe storage — add, search, import from URL |

## Access Conventions

Each plugin README carries an **Access:** label:

- **Access:** All family members
- **Access:** Charles + Moriah only
- **Access:** Charles only

There is no technical auth layer — this is a family trust model. Only install plugins appropriate for your role.

## Memory Namespace Isolation

All plugins store data in Brian's shared memory layer. Each plugin uses a unique prefix to prevent collisions:

| Plugin | Namespace |
|---|---|
| grocery-list | `grocery.` |
| family-calendar | `calendar.` |
| proof-bread-orders | `proof.` |
| home-tasks | `tasks.` |
| recipes | `recipes.` |

## Architecture

```
GitHub (this repo) — plugin catalog + skill definitions
Brian Home Server  — mcp-memory-service (shared memory backend)
Cloudflare Tunnel  — https://brian.aldarondo.us/memory
```

Brian memory endpoint must be running before any plugin will work. See [brian-mcp](https://github.com/aldarondo/brian-mcp) for the server setup.

## Emil Note

Emil interacts via Google Nest only. Brian's supervisor layer handles his skill routing directly. He is not a marketplace user and has no Claude Code install.

## Per-Person Install Plan

| Person | Plugins |
|---|---|
| Charles | All |
| Moriah | grocery-list, family-calendar, proof-bread-orders |
| Jack | grocery-list, family-calendar |
| Quincy | grocery-list, family-calendar |
| Emil | N/A — handled by Brian directly |

## Project Status

Phase 2 scaffolded. Memory layer (Phase 1) lives in [brian-mcp](https://github.com/charlesleatherwood/brian-mcp). See [ROADMAP.md](ROADMAP.md) for what's planned.

---
**Publisher:** Xity Software, LLC
