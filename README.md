# brian-family-marketplace

Brian home server skill marketplace for the Leatherwood family. Distributes shared Claude Code skills (grocery list, recipes, prescriptions, meal planning, vehicles, contacts, maintenance, gifts, travel, and more) to household members via a single install command.

## Prerequisites

All plugins connect to the Brian home server via Cloudflare Access:

- **Memory (brian-mcp)** — `https://brian.aldarondo.family/mcp` — every plugin's data store
- **Outgoing email (brian-email)** — `https://brian.aldarondo.family/email` — send-only; used by plugins that can email itineraries, rosters, etc.

The same Cloudflare Access service token covers both. Set these env vars in your shell before using any plugin:

```bash
export BRIAN_MCP_CLIENT_ID="your-service-token-client-id"
export BRIAN_MCP_CLIENT_SECRET="your-service-token-client-secret"
```

Get your token from Charles.

## Install

```bash
/plugin marketplace add aldarondo/brian-family-marketplace
```

Then install the plugins you need:

```bash
/plugin install grocery-list@brian-family
/plugin install recipes@brian-family
/plugin install prescriptions@brian-family
/plugin install health@brian-family
```

## Available Plugins

| Plugin | Access | Description |
|---|---|---|
| `grocery-list` | All family | Shared grocery list — add, remove, view items |
| `recipes` | All family | Family recipe storage — add, search, import from URL |
| `prescriptions` | Per-user (private) | Medications, vitamins, and supplements — each person sees only their own list |
| `health` | Per-user (private) | Personal health aggregator — pulls from prescriptions (more sources over time) to produce a single health evaluation |
| `food-log` | Per-user (private) | Screenshot-based daily food + macro log |
| `jellyfin` | Charles only | Discover and queue movies/TV for the Jellyfin library |
| `roadmap` | Charles only | Personal project roadmap manager — registers projects in Brian memory and adds tasks to their GitHub ROADMAP.md files |
| `meal-plan` | All family | Weekly dinner plan built from `recipes.*`, can push missing ingredients to `grocery.*` |
| `vehicles` | All family | Family vehicle registry — service history, registration + insurance renewals |
| `contacts` | All family | Contact directory — emergency, medical, **care-team (hospice / end-of-life)**, school, household |
| `maintenance` | All family | Home maintenance — recurring tasks, last-done log, overdue/upcoming view |
| `gifts` | All family | Birthday and gift idea tracker with given-history and upcoming reminders |
| `travel` | All family | Trip planner — itineraries, packing lists, booking confirmations |

## Environment Variables

All env vars needed across every plugin:

| Variable | Required By | Description |
|---|---|---|
| `BRIAN_MCP_CLIENT_ID` | All plugins | Cloudflare Access service token client ID |
| `BRIAN_MCP_CLIENT_SECRET` | All plugins | Cloudflare Access service token client secret |
| `PRESCRIPTIONS_USER` | prescriptions | Your name tag (e.g. `charles`) — scopes data to your record |
| `HEALTH_USER` | health | Your name tag — scopes health evaluations to your record |
| `ROADMAP_USER` | roadmap | Your name tag — scopes the project registry to your record (falls back to `BRIAN_USER`) |
| `NAS_IP` | jellyfin | LAN IP of the Synology NAS running Radarr/Sonarr |

Get `BRIAN_MCP_CLIENT_ID` and `BRIAN_MCP_CLIENT_SECRET` from Charles. Set all env vars in your shell profile before installing plugins.

## Access Conventions

Each plugin README carries an **Access:** label. The label maps to the `access` field in `marketplace.json`:

| README Label | marketplace.json value | Who can install |
|---|---|---|
| All family | `"all"` | Everyone |
| Per-user (private) | `"per-user"` | Anyone, but data is isolated per user |
| Charles only | `"charles"` | Charles only |

There is no technical auth layer — this is a family trust model. Only install plugins appropriate for your role.

## Security Considerations

- **Credentials:** Never store `BRIAN_MCP_CLIENT_ID` or `BRIAN_MCP_CLIENT_SECRET` in a file that gets committed to git. Use your shell profile (`~/.zshrc`, `~/.bashrc`) or a `.env` file that is listed in `.gitignore`.
- **Token rotation:** If a service token is compromised, generate a new one in Cloudflare Access and notify Charles to update any other installs.
- **Privacy enforcement:** User isolation for prescriptions and health data is enforced at the skill layer via `user:[name]` memory tags. The brian-mcp memory service stores all data in a shared namespace — the tag convention is the only isolation mechanism. Do not store sensitive data under a prefix you don't own.
- **Rate limits:** The brian-mcp memory endpoint does not currently enforce rate limits. Avoid bulk operations in tight loops; a reasonable working cadence (a few reads/writes per skill invocation) is fine.

## Data Storage

**All persistent data for every plugin is stored in brian-mcp memory at `https://brian.aldarondo.family/mcp`.** No local files, no external databases, no other memory services. If something is worth saving, it lives in memory under the plugin's namespace.

Each plugin uses a unique prefix to prevent collisions:

| Plugin | Namespace |
|---|---|
| grocery-list | `grocery.` |
| recipes | `recipes.` |
| prescriptions | `prescriptions.` (+ `user:[name]` scoping) |
| health | `health.` (+ `user:[name]` scoping; reads `prescriptions.*` for same user) |
| food-log | `food.` (+ `user:[name]` scoping) |
| roadmap | `roadmap.` (+ `user:[name]` scoping) |
| meal-plan | `mealplan.` (reads `recipes.*`; writes `grocery.*` on request) |
| vehicles | `vehicles.` |
| contacts | `contacts.` |
| maintenance | `maintenance.` |
| gifts | `gifts.` |
| travel | `travel.` |

## Outgoing Email (brian-email MCP)

Several plugins expose a second MCP server named `email` pointing at `https://brian.aldarondo.family/email`. This is a **send-only** capability — brian-email is never used as storage. All state continues to live in brian-mcp memory.

| Plugin | Uses email |
|---|---|
| meal-plan | "email this week's plan / shopping list" |
| vehicles | "email the Forester's service history to the agent" |
| contacts | primary recipient resolver; "email the care-team roster" |
| maintenance | "email me this month's maintenance list" |
| gifts | "email upcoming birthdays to the family" |
| travel | "email the Colorado itinerary to everyone going" |

Rules every plugin follows when sending:
- Only send on explicit user request.
- Resolve recipient names against the `contacts` plugin. If unresolved, ask.
- Confirm recipient, subject, and a body preview before sending.
- Send plain-text bodies; keep subjects short.

## Architecture

```
GitHub (this repo) — plugin catalog + skill definitions
Brian Home Server  — mcp-memory-service (shared memory backend)
                   — brian-email (send-only outgoing email)
Cloudflare Tunnel  — https://brian.aldarondo.family/mcp    (memory)
                   — https://brian.aldarondo.family/email  (email)
```

Brian memory endpoint must be running before any plugin will work. Email-capable plugins additionally require brian-email reachable at the URL above. See [brian-mcp](https://github.com/aldarondo/brian-mcp) for memory server setup; see the brian-email project for the email MCP deployment.

## Emil Note

Emil interacts via Google Nest only. Brian's supervisor layer handles his skill routing directly. He is not a marketplace user and has no Claude Code install.

## Per-Person Install Plan

| Person | Plugins |
|---|---|
| Charles | grocery-list, recipes, prescriptions, health, food-log, meal-plan, vehicles, contacts, maintenance, gifts, travel, jellyfin, roadmap |
| Moriah | grocery-list, recipes, prescriptions, health, food-log, meal-plan, contacts, gifts, travel |
| Jack | grocery-list, recipes, meal-plan, contacts, gifts, travel |
| Quincy | grocery-list, recipes, meal-plan, contacts, gifts, travel |
| Emil | N/A — handled by Brian directly |

## Updating Plugins

When Charles pushes a new plugin version (updated SKILL.md, config changes, or a new plugin entirely), each family member updates their local install with two commands:

```bash
# Step 1 — pull the latest catalog from GitHub
/plugin marketplace update brian-family

# Step 2 — reinstall the specific plugin(s) that changed
/plugin install grocery-list@brian-family
/plugin install recipes@brian-family
/plugin install prescriptions@brian-family
```

Run both steps. Skipping Step 1 means you'll install from a stale catalog. You only need to reinstall the plugins that changed, not all of them.

### How to Know When to Update

Charles will announce changes in the family group chat with the affected plugin name and a brief summary of what changed. There's no automatic update check.

### Plugin Versioning

Plugin versions are tracked via git tags on this repo. The `marketplace.json` catalog lists the current version of each plugin. You can see what changed by checking the [commit history](https://github.com/aldarondo/brian-family-marketplace/commits/main).

### Adding a New Plugin (Charles Only)

1. Create `plugins/[name]/` following the layout in CLAUDE.md
2. Add an entry to `marketplace.json`
3. Write a `README.md` with the **Access:** label
4. Commit and push
5. Notify family to run the two-step update above

## Project Status

Phase 2 scaffolded. Memory layer (Phase 1) lives in [brian-mcp](https://github.com/aldarondo/brian-mcp). See [ROADMAP.md](ROADMAP.md) for what's planned.

---
**Publisher:** Xity Software, LLC
