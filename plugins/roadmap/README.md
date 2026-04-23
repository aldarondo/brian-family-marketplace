# roadmap

**Access:** Charles only (per-user tagged — can be widened later by changing `access` in `marketplace.json`)
**Namespace:** `roadmap.*` (scoped per user via `user:[name]` tag)

Personal project roadmap manager. Registers your projects in Brian memory and adds tasks straight into each project's GitHub `ROADMAP.md` file.

## Install

```bash
/plugin install roadmap@brian-family
```

## Usage

```
"List my projects"
"Register a new project: brian-mcp at aldarondo/brian-mcp"
"Add 'Document Cloudflare Access OTP rotation' to my brian-mcp roadmap"
"Add 'Wire up Whoop integration' to my health roadmap under Phase 4"
"Log 'shipped roadmap plugin' as done on the brian-family-marketplace roadmap"
"Show my recent roadmap additions"
"What's on my brian-mcp roadmap?"
```

## How It Works

1. **Project registry** lives in Brian memory under `roadmap.project` entries — one per project — with the GitHub repo, roadmap file path, default branch, and (optionally) a local clone path.
2. **Add an entry** and the skill resolves the project, picks the right section in `ROADMAP.md`, and commits the change to GitHub.
3. **Entry log** (`roadmap.entry`) records every addition with the commit SHA and URL so you can audit what was added when.

## Write Flows

The skill picks the best path automatically:

| Flow | When | Mechanism |
|---|---|---|
| **A. Local clone** | Project memory has `local_clone` set | `git pull` → edit → `git commit` → `git push` |
| **B. `gh` CLI remote** | Default — no local clone | `gh api` to fetch + `PUT` the updated contents |
| **C. github MCP** | Session has `mcp__github__*` tools wired up | `get_file_contents` + `create_or_update_file` |

## Requirements

- Brian memory endpoint live at `https://brian.aldarondo.family/mcp`
- `BRIAN_MCP_CLIENT_ID` + `BRIAN_MCP_CLIENT_SECRET` env vars (Cloudflare Access service token)
- `ROADMAP_USER` (or `BRIAN_USER`) env var — your name tag (e.g. `charles`)
- `gh` CLI authenticated (`gh auth login`) for Flow B — or a local clone path on each project for Flow A

## Privacy

Each person's project registry is private — entries are tagged `user:[name]` and only loaded for the active user.
