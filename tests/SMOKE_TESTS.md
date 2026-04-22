# Smoke Tests — brian-family-marketplace

Run these after any SKILL.md or config.json change. Each test is a manual procedure — execute each step and verify the result before marking it passed.

**Prerequisites:** `BRIAN_MCP_CLIENT_ID` and `BRIAN_MCP_CLIENT_SECRET` must be set in your environment. Brian memory endpoint must be live at `https://brian.aldarondo.family/mcp`.

---

## grocery-list

**Test: store → view → remove**

1. `/grocery add milk`
   - Expected: confirmation that "milk" was added
2. `/grocery list`
   - Expected: list includes "milk"
3. `/grocery remove milk`
   - Expected: confirmation that "milk" was removed
4. `/grocery list`
   - Expected: "milk" is no longer in the list

---

## recipes

**Test: add → search → delete**

1. `/recipes add` — provide a simple recipe (e.g. "Scrambled Eggs, tag: breakfast")
   - Expected: recipe stored, confirmation returned
2. `/recipes search breakfast`
   - Expected: Scrambled Eggs appears in results
3. `/recipes delete` — delete Scrambled Eggs by name or ID
   - Expected: confirmation that recipe was removed
4. `/recipes search breakfast`
   - Expected: Scrambled Eggs no longer appears

---

## prescriptions

**Test: add → view → remove (set `PRESCRIPTIONS_USER=charles` or your name)**

1. `/prescriptions add` — add a test supplement (e.g. "Test Vitamin D, 1000 IU, daily")
   - Expected: item stored under your user tag
2. `/prescriptions list`
   - Expected: "Test Vitamin D" appears in your list
3. `/prescriptions remove Test Vitamin D`
   - Expected: item removed
4. `/prescriptions list`
   - Expected: "Test Vitamin D" no longer appears

**Privacy check:** Set `PRESCRIPTIONS_USER` to a different name and run `/prescriptions list`. Verify you do NOT see the item you added above.

---

## health

**Test: evaluation runs without error (set `HEALTH_USER=charles` or your name)**

1. `/health status`
   - Expected: returns a health summary (may be sparse if vendor MCPs not connected — that's OK)
   - Expected: no errors or unhandled exceptions
2. Verify the output references prescriptions data if any items exist under your user tag.

---

## jellyfin

**Test: new-releases discovery (requires `NAS_IP` set)**

1. `/new-releases`
   - Expected: presents a list of recent movies/TV shows not yet in Jellyfin
   - Expected: no Radarr/Sonarr API errors
2. Select one item and confirm it queues — verify in Radarr or Sonarr UI that the item appears.

---

## JSON Validation

Run after any JSON file change:

```bash
bash tests/validate_json.sh
```

Expected: `All JSON files valid.` with exit code 0.
