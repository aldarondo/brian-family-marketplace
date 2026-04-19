---
description: Use this skill whenever a family member wants an aggregated view or evaluation of their health. Pulls data from multiple sources (currently prescriptions; labs, vitals, sleep, exercise will be added later) and produces a single assessment. Triggers: "how is my health", "give me a health summary", "health check", "evaluate my health", "what does my medication list say about my health", "any health concerns I should know about", "health report", "run a health evaluation", "what are my health risks", "do I have any interaction risks", "what's my current polypharmacy load", "build my health snapshot"
---

# Skill: Personal Health Aggregator & Evaluator

**Storage**: Brian mcp-memory-service, namespace `health.*`, scoped per user via `user:[name]` tag.
**Reads from**: `prescriptions.*` (same user only). Future sources will be added as new sections in this file.

---

## Identity & Privacy — Read This First

**Who is the current user?**

1. Check the current session context or CLAUDE.md for `HEALTH_USER: [name]`. Fall back to `PRESCRIPTIONS_USER: [name]` if set.
2. If neither is set, ask once: "Just to confirm — what's your name? (Charles, Moriah, Jack, or Quincy)"
3. Store the confirmed name as the active user for all operations this session.

**Privacy rules:**

| Rule | Behavior |
|---|---|
| Default: private | Only read memories tagged `user:[name]` where name = active user, across both `health.*` and `prescriptions.*` |
| Moriah ↔ Emil | Moriah can read and evaluate Emil's data; if Moriah says "for Emil" or "Emil's health" → target is `user:emil` |
| Cross-person queries refused | "I keep health data private. I can only evaluate [Name]'s health with them directly." |
| No medical advice | This skill summarizes and flags patterns. It is not a diagnosis. Always recommend following up with a clinician for anything flagged. |

**Memory tag conventions (writes):**
- Saved evaluations: `health.evaluation,user:[name]`
- Saved vitals: `health.vital,user:[name]`
- Saved lab results: `health.lab,user:[name]`
- Saved health notes: `health.note,user:[name]`

---

## Step 0: Identify Requester and Target

1. Confirm the active user (see Identity section above).
2. Determine target: default = active user; Moriah saying "for Emil" → target is `user:emil`.
3. All memory reads and writes filter by `user:[target]` tag.

---

## Data Source Registry

The evaluator walks this registry in order. Each source contributes a **findings block** to the final evaluation. Sources that return nothing are skipped silently.

| Source | Status | Memory query | Produces |
|---|---|---|---|
| Prescriptions & supplements | Active | `memory_search(query: "prescriptions item", tags: ["prescriptions.item", "user:[name]"], limit: 50)` | Medication count, polypharmacy load, interaction flags, upcoming refills, expiring prescriptions, adherence risk |
| Vitals (BP, HR, weight, etc.) | Planned | `memory_search(tags: ["health.vital", "user:[name]"])` | Trends, out-of-range flags — stub only; will be fleshed out when vitals source is added |
| Lab results | Planned | `memory_search(tags: ["health.lab", "user:[name]"])` | Abnormal markers, trend deltas — stub only |
| Sleep / activity | Planned | `memory_search(tags: ["health.activity", "user:[name]"])` | Weekly averages, deviation from baseline — stub only |
| Self-reported symptoms | Planned | `memory_search(tags: ["health.note", "user:[name]"])` | Recent complaints, recurring issues — stub only |

When adding a new source later: add a row above, add a matching section under **Source Evaluators**, and update the **Overall Assessment** synthesis if the new source changes the risk model.

---

## Step 1: Run a Health Evaluation

**Trigger**: "health check", "health summary", "evaluate my health", "run a health evaluation", "what are my health risks"

1. Run Step 0.
2. Walk each **Active** source in the registry. For each, call the memory query and run its evaluator (see **Source Evaluators** below).
3. Synthesize an overall assessment (see **Overall Assessment**).
4. Display the report (see **Report Format**).
5. Offer to save: "Want me to save this evaluation so we can compare next time? (yes/no)"
6. If yes: store a `health.evaluation` memory with the full report plus a `date: [YYYY-MM-DD]` field.

**Important**: If every Active source returns nothing, reply: "I don't have enough data yet to evaluate [name]'s health. Add medications via the prescriptions plugin first, or tell me about any recent vitals/labs."

---

## Source Evaluators

### Prescriptions & Supplements

Input: list of items from `prescriptions.*` memory search, filtered to `user:[target]`.

Compute:
- `rx_count` — items where `type === "prescription"`
- `otc_count` — items where `type === "otc"`
- `total_count` — all items
- `polypharmacy_flag`:
  - `rx_count >= 5` → "High polypharmacy load — 5+ prescriptions. Worth a medication review with your primary doctor."
  - `total_count >= 10` → "High total pill burden — 10+ items between prescriptions and supplements. Consider a consolidation review."
- `interaction_flags` — run the same **Interaction Check** table the prescriptions skill uses (see prescriptions/SKILL.md). Collect every pair that triggers, not just the first.
- `refill_risk`:
  - Any item with `refills_remaining === 0` and `renewal_needed !== true` → "At least one prescription is out of refills and has no renewal scheduled."
  - Any item with `prescription_expires` within 30 days and no `doctor_reminder_date` → list each.
- `adherence_risk` (heuristic):
  - Items where `next_refill` is more than 14 days in the past → "Possible missed refill: [name] was due [date]."
- `load_by_schedule` — count how many items are taken at each schedule tag (morning / lunch / evening / bedtime / as needed). Flag if any one slot exceeds 8 items: "Heavy [slot] load — [N] items at [slot]. Consider splitting."

Output block:

```
MEDICATIONS & SUPPLEMENTS
• Active items: [total_count] ([rx_count] prescription, [otc_count] OTC)
• Load by schedule: morning [N] | lunch [N] | evening [N] | bedtime [N] | as-needed [N]
[• Polypharmacy: [flag text] — if triggered]
[• Interactions to review:
   – [item A] + [item B] — [reason]
   (repeat for each pair)
 — if any]
[• Refill risk:
   – [item] — out of refills, no renewal scheduled
   – [item] — prescription expires [date] ([N] days)
 — if any]
[• Possible missed refills:
   – [item] — due [date], [N] days overdue
 — if any]
```

### Vitals (Planned)

Stub — render nothing today. When implemented, this block will aggregate BP, HR, weight, glucose, etc. from `health.vital` memories, flag out-of-range values, and summarize trends over 30/90/365 days.

### Lab Results (Planned)

Stub — render nothing today. When implemented, will pull `health.lab` memories and flag abnormal markers against standard reference ranges (with a per-user override allowed on the memory entry).

### Sleep / Activity (Planned)

Stub — render nothing today.

### Self-Reported Symptoms (Planned)

Stub — render nothing today.

---

## Overall Assessment

Combine signals from all active source blocks into a single **status + key concerns + suggested next steps** summary at the top of the report.

**Status** — one of:
- `Stable` — zero flags across all sources
- `Watch` — one or more informational flags (e.g. moderate interactions, upcoming expirations), no urgent items
- `Action suggested` — at least one flag with clinical or refill urgency (out of refills with no renewal; prescription expiring < 14 days; possible missed refill on a chronic med)

**Key concerns**: up to 3 bullets drawn from the strongest flags across all sources.

**Suggested next steps**: concrete, short. Examples:
- "Schedule a medication review with Dr. [name] — [rx_count] prescriptions, [polypharmacy reasoning]."
- "Call [pharmacy] to renew [medication] — expires [date]."
- "Ask your pharmacist about spacing [item A] and [item B]."

---

## Report Format

```
HEALTH EVALUATION — [Full Name]
As of [today's date]
────────────────────────────────

STATUS: [Stable | Watch | Action suggested]

Key concerns:
• [bullet]
• [bullet]
• [bullet]

Suggested next steps:
• [bullet]
• [bullet]

────────────────────────────────
[Source blocks in order — skip any that produced no findings]

[Prescriptions block]

[Vitals block — when available]

[Labs block — when available]

────────────────────────────────
Data sources used: [list active sources that contributed]
Not a diagnosis — share with your clinician for anything flagged.
```

---

## Step 2: Save an Evaluation Snapshot

**Trigger**: User answers "yes" to the save prompt, or explicitly says "save this evaluation", "snapshot my health".

Content structure:

```
health.evaluation: [Full Name] — [YYYY-MM-DD]
user: [name]
date: [YYYY-MM-DD]
status: [Stable | Watch | Action suggested]
rx_count: [N]
otc_count: [N]
polypharmacy_flag: [true | false]
interaction_pairs: [count]
refill_risks: [count]
report: |
  [full report text from Report Format]
```

Tags: `health.evaluation,user:[name]`

Reply: "Saved. Next time, say 'compare my health' and I'll diff against this snapshot."

---

## Step 3: Compare to a Previous Snapshot

**Trigger**: "compare my health", "did anything change since last time", "diff my health"

1. Run Step 0.
2. Load all `health.evaluation` memories for the user, sorted newest first.
3. If fewer than 2: "I only have [0 or 1] snapshot for you. Run a health check and save it, then come back after your next one."
4. Run Step 1 to produce today's evaluation (do not save yet).
5. Diff key numeric fields vs. most recent saved snapshot:
   - `rx_count` delta, `otc_count` delta
   - Newly appeared interaction pairs, dropped pairs
   - Newly appeared refill risks
   - Status change (e.g. Watch → Action suggested)
6. Display today's report first, then:

```
CHANGES SINCE [prev snapshot date]
• Prescriptions: [prev] → [now] ([+/-N])
• Interactions to review: [prev] → [now]
[• New flags since then:
   – [flag]
 — if any]
[• Resolved since then:
   – [flag]
 — if any]
```

7. Offer to save the new snapshot.

---

## Step 4: Record a Vital / Lab / Note (Stub — light support today)

**Trigger**: "log my BP [systolic]/[diastolic]", "record lab: [name] [value] [unit]", "note: [text]"

Even though the planned source evaluators are not implemented yet, accept the write so data accumulates for when evaluators come online.

1. Parse: source type (vital | lab | note), name, value, unit, date (default today).
2. Store memory:
   ```
   health.[type]: [name] [value] [unit]
   user: [name]
   date: [YYYY-MM-DD]
   value: [value]
   unit: [unit]
   notes: [optional]
   ```
   Tags: `health.[type],user:[name]`
3. Reply: "Logged. I'll factor this in once the [vitals/labs/notes] evaluator is live — today's summary still only uses prescriptions."

---

## Error / Edge Cases

| Situation | Handling |
|---|---|
| `HEALTH_USER` and `PRESCRIPTIONS_USER` both unset | Ask once per session: "What's your name — Charles, Moriah, Jack, or Quincy?" |
| No prescription items and no other data | "I don't have enough data yet. Add medications via the prescriptions plugin first." |
| Cross-person request (except Moriah→Emil) | "I keep health data private. I can only evaluate [Name]'s health with them directly." |
| Memory read fails | "I couldn't reach the memory service. Try again in a moment, or check the Brian tunnel." |
| Interaction table disagreement with prescriptions skill | Source of truth is `prescriptions/SKILL.md`. When that table changes, update this skill to match. |
| User asks for a diagnosis | Decline gently: "I can summarize patterns and flag things worth asking a clinician, but I won't diagnose. Want me to pull together a list for your next appointment?" |

---

## Tone

Calm, concrete, never alarmist. Frame flags as "worth discussing" rather than "wrong". Always close with a reminder that this is a summary for self-awareness, not medical advice. No emoji, no dramatic language.
