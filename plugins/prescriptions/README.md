# prescriptions

**Access:** All family members (each person sees only their own data)
**Namespace:** `prescriptions.*`

Private medication, prescription, vitamin, and supplement tracker. Each person's list is completely private — scoped by user tag in the shared memory layer. No one can see another person's list.

**Exception:** Moriah manages Emil's list as his power of attorney.

## Install

```bash
/plugin install prescriptions@brian-family
```

## Setup (required after install)

Add your identity to your project or user CLAUDE.md so the skill knows who you are:

```markdown
## Prescriptions Plugin
PRESCRIPTIONS_USER: charles
```

Valid values: `charles`, `moriah`, `jack`, `quincy`
(Emil has no Claude Code — Moriah manages his list with `PRESCRIPTIONS_USER: moriah` and says "for Emil")

## Usage

- "What medications am I on?"
- "Add Vitamin D 5000 IU to my list"
- "I picked up my Finasteride today"
- "What do I need to refill soon?"
- "My doctor changed my dosage for Berberine"
- "Give me my medication list for my appointment"
- "Remove CoQ10 from my list"
- "What's my refill date for Magnesium?"

## Privacy

All memory reads and writes are filtered by `user:[name]` tag. No cross-person access — the skill refuses if asked about another person's data. Only Moriah can access Emil's list.

## Migrated From

`C:\Brian\skills\prescriptions` — the standalone Brian skill with file-based JSON storage. Now backed by the shared mcp-memory-service.
