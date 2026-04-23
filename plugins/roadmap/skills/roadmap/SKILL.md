---
description: Use this skill to manage your personal project roadmap registry and add tasks to any of your projects' ROADMAP.md files on GitHub. Triggers - "list my projects", "what projects do I have", "register a new project", "track [owner/repo]", "add [task] to my [project] roadmap", "add to [project] roadmap [task]", "log [task] on the [project] roadmap", "update [project] roadmap with [task]", "what's on my [project] roadmap", "show my recent roadmap additions", "remove project [name]".
---

# Skill: Roadmap

**Storage**: Brian mcp-memory-service, namespace `roadmap.*`, scoped per user via `user:[name]` tag.
**Writes to**: GitHub via `gh` CLI (default), local git clone (when configured), or github MCP tools (when available).

---

## Identity & Privacy — Read This First

**Who is the current user?**

1. Check session context / env for `ROADMAP_USER` or `BRIAN_USER`. Use that value.
2. If neither is set, ask once: "Just to confirm — what's your name? (Charles, Moriah, Jack, or Quincy)"
3. Store the confirmed name as the active user for all operations this session.

**Privacy rules:**

| Rule | Behavior |
|---|---|
| Default: private | Only read and write memories tagged `user:[name]` where name = active user |
| Cross-person queries refused | "Project registries are private. I can only show [Name]'s projects to them directly." |

**Memory tag conventions (writes):**
- Project registration: `roadmap.project,user:[name]`
- Roadmap entry log: `roadmap.entry,user:[name]`

---

## Memory Storage Format

### Project Registration (one memory per project)

```
roadmap.project: [name]
user: [name]
github: [owner/repo]
roadmap_path: ROADMAP.md
default_branch: main
default_section: Backlog
tag_key: [Code]                 # optional — role tag the project prefixes items with
local_clone: /abs/path/to/repo  # optional — when set, prefer the local-edit flow
description: [one-liner]
added: [YYYY-MM-DD]
```

Tags: `roadmap.project,user:[name]`

**One memory per project name per user.** To update a project, delete the old memory by `content_hash` and store a new one.

### Roadmap Entry Log (one memory per add)

```
roadmap.entry: [project] — [YYYY-MM-DD] — [short summary]
user: [name]
project: [name]
github: [owner/repo]
section: [section heading]
text: [exact line written into ROADMAP.md]
commit: [sha]
url: [github commit URL]
added_at: [ISO 8601 timestamp]
```

Tags: `roadmap.entry,user:[name]`

---

## Step 1: List Projects

**Trigger:** "list my projects", "what projects do I have", "show my project registry"

1. Identify user.
2. Search: `memory_search(query: "roadmap project", tags: ["roadmap.project", "user:[name]"], limit: 50)`.
3. If none: "No projects registered yet. Say 'register a new project' to add one."
4. Display:

```
Your projects (N)

1. brian-family-marketplace — aldarondo/brian-family-marketplace
   Plugin marketplace for the Leatherwood family
2. brian-mcp — aldarondo/brian-mcp
   Memory service backend
...

Say "add [task] to [project] roadmap" to log a new item.
```

---

## Step 2: Register a New Project

**Trigger:** "register a new project", "track [owner/repo] as a project", "add [name] to my roadmap registry"

1. Identify user.
2. Collect — ask for any field the user did not provide:
   - **name** — short slug, e.g. `brian-mcp`
   - **github** — `owner/repo`
   - **roadmap_path** — default `ROADMAP.md`; ask if file is somewhere else (e.g. `docs/roadmap.md`)
   - **default_branch** — default `main`
   - **default_section** — default `Backlog`
   - **tag_key** — optional, e.g. `[Code]` for projects that prefix items with role tags (this repo uses `[Code]` / `[Cowork]` / `[Human]`)
   - **local_clone** — optional absolute path; if present, the add-entry flow will use git directly
   - **description** — one-liner
3. Verify the roadmap file exists on GitHub before saving:
   ```
   gh api /repos/[owner]/[repo]/contents/[roadmap_path]?ref=[branch]
   ```
   If 404: "I can't find [path] in [owner]/[repo] on branch [branch]. Want me to register anyway, or fix the path?"
4. Check for an existing project with the same `name` for this user — if one exists, confirm before overwriting.
5. Store the project memory.
6. Reply: "Registered [name]. Try 'add [task] to [name] roadmap' next."

---

## Step 3: Add an Entry to a Project's Roadmap

**Trigger:** "add [task] to my [project] roadmap", "add to [project] roadmap: [task]", "log [task] on the [project] roadmap", "update [project] roadmap with [task]"

1. Identify user.
2. Resolve the project:
   - If user named it, find the matching `roadmap.project` memory for this user.
   - If no name given, list registered projects and ask which one.
   - If unknown name: "I don't have a project called [name]. Say 'register a new project' first, or pick from: [list]."
3. Determine the section:
   - If user specified one (e.g. "in progress", "blocked", "Phase 6"), use it.
   - Otherwise use the project's `default_section`.
4. Determine the status:
   - Default: backlog item, unchecked — `- [ ]`
   - If user says "log this as done" / "completed" / "shipped": completed item — `- [x]` and prefix with today's date.
5. Build the entry line. Format follows the project's convention:
   - With `tag_key`, unchecked: `- [ ] \`[tag_key]\` [task text]`
   - With `tag_key`, completed: `- [x] \`[tag_key]\` [YYYY-MM-DD] — [task text]`
   - Without `tag_key`, unchecked: `- [ ] [task text]`
   - Without `tag_key`, completed: `- [x] [YYYY-MM-DD] — [task text]`
6. Apply the change (see **GitHub Write Flows** below).
7. Store an entry log memory with the schema above.
8. Reply:

```
Added to [project] roadmap → [section]:
  [exact line]

Commit: [short-sha]
[github commit URL]
```

---

## GitHub Write Flows

Choose based on the project memory and tools available — try in this order:

### Flow A — Local clone (preferred when `local_clone` is set)

```bash
cd [local_clone]
git fetch origin [default_branch]
git checkout [default_branch]
git pull --ff-only origin [default_branch]
```

Use the Edit tool to modify `[roadmap_path]` in place — find the section heading, insert the new line at the bottom of that section.

```bash
git add [roadmap_path]
git commit -m "roadmap: add [short summary] to [section]"
git push origin [default_branch]
```

Capture the commit SHA from `git rev-parse HEAD` and build the URL: `https://github.com/[owner]/[repo]/commit/[sha]`.

### Flow B — `gh` CLI remote edit (when no local clone)

1. Fetch current contents:
   ```bash
   gh api /repos/[owner]/[repo]/contents/[roadmap_path]?ref=[default_branch]
   ```
   Capture `.sha` (file SHA) and decode `.content` (base64) into the current file text.
2. Edit the section in memory using the rules under **Section-Insertion Rules**.
3. PUT the update:
   ```bash
   gh api -X PUT /repos/[owner]/[repo]/contents/[roadmap_path] \
     -f message="roadmap: add [short summary] to [section]" \
     -f content="$(printf '%s' "$NEW_CONTENT" | base64 -w0)" \
     -f sha="$OLD_FILE_SHA" \
     -f branch="[default_branch]"
   ```
4. The response contains `.commit.sha` and `.commit.html_url` — capture both for the entry log and confirmation.

### Flow C — github MCP (when `mcp__github__create_or_update_file` is available)

If the running session has the `mcp__github__*` tools wired up and the target repo is allowlisted, use them instead of `gh`:
1. `mcp__github__get_file_contents` to fetch current contents and SHA.
2. Edit in memory.
3. `mcp__github__create_or_update_file` with the new content and the old SHA.

### Section-Insertion Rules

- Find the section by heading text — case-insensitive substring match. "backlog" matches `## 🔲 Backlog` or `## Backlog`. "in progress" matches `## 🔄 In Progress`.
- If the user named a sub-heading (e.g. "Phase 6"), insert under that sub-heading.
- Insert the new line as the **last** item in that section, immediately before the next `##` / `###` heading or before any closing HTML comment that belongs to the next section.
- Strip placeholder comments inside the section (e.g. `<!-- nothing active right now -->`, `<!-- none -->`) when adding the first real item there.
- Never reorder existing lines.
- If the section doesn't exist, ask: "I don't see a '[section]' heading in [project]'s ROADMAP. Add it as a new section, or pick an existing one: [list]?"

---

## Step 4: Show Recent Roadmap Additions

**Trigger:** "show my roadmap additions", "what did I add to roadmaps lately", "recent roadmap entries"

1. Identify user.
2. Search: `memory_search(query: "roadmap entry", tags: ["roadmap.entry", "user:[name]"], limit: 20)`.
3. Sort by `added_at` descending.
4. Display:

```
Recent roadmap additions

• 2026-04-23 · brian-mcp · Backlog
  Add Cloudflare Access OTP rotation runbook
  → [commit url]

• 2026-04-22 · brian-family-marketplace · Phase 6
  Confirm GitHub accounts for Moriah, Jack, Quincy
  → [commit url]
```

---

## Step 5: View a Project's Current Roadmap

**Trigger:** "what's on my [project] roadmap", "show the [project] roadmap", "read [project]'s ROADMAP"

1. Identify user. Resolve the project from memory.
2. Fetch the file contents (Flow B step 1, or Flow A `git show HEAD:[roadmap_path]`, or Flow C `get_file_contents`).
3. Render the file as-is, lightly trimmed if very long (offer to show full file).

---

## Step 6: Remove or Update a Project Registration

**Trigger:** "remove project [name]", "update project [name]", "change [name]'s default branch to [x]"

1. Identify user. Find the matching `roadmap.project` memory.
2. Removal: confirm "Remove project [name] from your registry? (yes/no)" — on yes, `memory_delete(content_hash)`. The entry log memories are preserved; they record real work.
3. Update: edit the relevant fields, delete the old memory by `content_hash`, store the updated version.

---

## Error / Edge Cases

| Situation | Handling |
|---|---|
| No projects registered, user asks to add a roadmap entry | "I don't have any projects registered yet. Want me to register one now?" |
| `gh` not authenticated | "GitHub CLI isn't authenticated. Run `gh auth login` and try again." |
| Neither `gh` nor a local clone available | Ask whether to set up `gh auth` or provide a local clone path. |
| ROADMAP file not found at registered path | "I couldn't find [path] in [owner]/[repo] on [branch]. Want me to update the project registration?" |
| Section heading not found | List the project's existing top-level headings; ask which to use or whether to create a new one. |
| Push rejected (non-fast-forward) | Pull / rebase / re-apply, then retry the push once. If it fails again, surface the error verbatim. |
| `gh` PUT fails with 409 (sha mismatch) | Re-fetch the file SHA and retry once. If it fails again, surface the error. |
| User names a project Claude can't find | Show the full list of registered projects. |
| Cross-person request | Refuse: "I keep project registries private. Each person manages their own." |
| Memory read fails | "I couldn't reach the memory service. Try again in a moment, or check the Brian tunnel." |

---

## Tone

Concise and operational. This is a developer tool — no fluff. After every successful add, show the exact line that was written and the commit URL so the user can click through and verify.
