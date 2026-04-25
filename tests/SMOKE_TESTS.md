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

## meal-plan

**Test: build → view → clear**

1. `/meal-plan build` — ask for a week's plan (ensure at least one recipe exists in `recipes.*` first, or the skill may propose an empty plan)
   - Expected: a 7-day plan is proposed with variety; meals reference existing recipes or placeholder names
2. `/meal-plan view`
   - Expected: current week's plan is displayed
3. `/meal-plan clear`
   - Expected: asks for confirmation; on confirm, clears the plan and reports it's empty

**Grocery push check:** After building, run `/meal-plan grocery` or "what do I need to buy".
- Expected: missing ingredients (vs. current grocery list) are listed and optionally pushed to `grocery.*`

---

## vehicles

**Test: add → view → delete**

1. `/vehicles add` — add a test vehicle (e.g. "Test Car, 2020 Toyota Camry, plate: TEST123, vin: 1HGCM82633A123456")
   - Expected: vehicle stored under `vehicles.vehicle`, confirmation returned with slug
2. `/vehicles show Test Car` or "show my vehicles"
   - Expected: Test Car appears with make/model/year/plate
3. `/vehicles delete Test Car`
   - Expected: asks for confirmation; on confirm, vehicle removed
4. "show my vehicles"
   - Expected: Test Car no longer appears

---

## contacts

**Test: add → search → delete**

1. `/contacts add` — add a test contact (e.g. "Test Plumber, category: home-services, phone: 555-0100")
   - Expected: contact stored under `contacts.contact`, confirmation returned
2. `/contacts search plumber` or "who is the plumber"
   - Expected: Test Plumber appears in results with phone number
3. `/contacts delete Test Plumber`
   - Expected: asks for confirmation; on confirm, contact removed
4. `/contacts search plumber`
   - Expected: Test Plumber no longer appears

**Care team check:** Add a care-team contact (e.g. "Test Nurse, category: care-team, for: mom, phone: 555-0200, after_hours: 555-0201").
- Expected: contact stored with `patient:mom` tag; `/contacts care-team mom` shows Test Nurse first

---

## maintenance

**Test: add → view due → mark done → delete**

1. `/maintenance add` — add a test task (e.g. "Test Air Filter, category: HVAC, frequency: 3 months, last done: today")
   - Expected: task stored under `maintenance.task`, confirmation returned with next-due date
2. `/maintenance due` or "what maintenance is due"
   - Expected: no error; Test Air Filter may appear if due date is soon
3. `/maintenance done Test Air Filter` — mark the task as done today
   - Expected: logs a completion entry, calculates new next-due date, confirms
4. `/maintenance delete Test Air Filter`
   - Expected: asks for confirmation; on confirm, task removed

---

## gifts

**Test: add person → add idea → view → delete**

1. `/gifts add person` — add a test person (e.g. "Test Person, birthday: 1990-06-15")
   - Expected: person stored under `gifts.person`, confirmation returned
2. `/gifts add idea` — add a gift idea for Test Person (e.g. "Test Book, for: Test Person, budget: $20, occasion: birthday")
   - Expected: idea stored under `gifts.idea`, confirmation returned
3. `/gifts ideas for Test Person`
   - Expected: Test Book appears in the list
4. `/gifts delete idea Test Book`
   - Expected: idea removed
5. `/gifts delete person Test Person`
   - Expected: person removed

**Birthday check:** Run `/gifts upcoming` — verify Test Person's birthday appeared while they were in the list.

---

## travel

**Test: create trip → add item → view → cancel**

1. `/travel add trip` — create a test trip (e.g. "Test Trip, destination: Phoenix, start: next Monday, end: next Friday")
   - Expected: trip stored under `travel.trip`, confirmation returned with slug
2. `/travel add flight` — add a flight to Test Trip (e.g. "AA123, depart: PHX 8am, arrive: SFO 9am, confirmation: TESTXYZ")
   - Expected: flight stored under `travel.item`, linked to Test Trip
3. `/travel itinerary Test Trip`
   - Expected: itinerary shows the trip and the AA123 flight
4. `/travel cancel Test Trip`
   - Expected: asks for confirmation; on confirm, trip and items removed

---

## energy

**Test: status check → manual note → rollup request**

*(Coordinator MCPs are not yet writing telemetry — `energy.*` will be empty. This test verifies the skill responds gracefully with no data.)*

1. "Energy status right now" or "How much solar did we make today?"
   - Expected: responds without error; reports no coordinator data or returns an empty snapshot
   - Expected: no unhandled exceptions
2. "Note: panels washed today" (or ask the skill to add a manual note)
   - Expected: note stored under `energy.note`, confirmation returned
3. "Energy report for this week"
   - Expected: responds without error; returns an empty or zero-filled rollup, or states no data is available
   - Expected: no unhandled exceptions
4. Delete the test note: "delete that energy note" or ask to clear it
   - Expected: test note removed from `energy.*`; subsequent status check no longer shows it

---

## JSON Validation

Run after any JSON file change:

```bash
bash tests/validate_json.sh
```

Expected: `All JSON files valid.` with exit code 0.
