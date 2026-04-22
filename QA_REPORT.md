# QA Report — brian-family-marketplace
**Date:** 2026-04-22
**Auditor:** Claude Code QA Analysis

---

## Executive Summary

Well-structured plugin marketplace with clear architecture, but several critical issues found.

---

## 1. Bugs

### Critical

**Test Script Broken: JSON Validation Fails on All Files**
- File: `tests/validate_json.sh`
- Uses `python3` for JSON validation, broken on Windows (app execution aliases). Test fails on all JSON files — no automated validation runs.
- Fix: Replace Python with `jq` or Node.js.

### Major

**GitHub Username Inconsistency in README**
- File: `README.md` line 119
- Line 69 uses `https://github.com/aldarondo/brian-mcp` (correct); line 119 uses `https://github.com/charlesleatherwood/brian-mcp` (incorrect → 404).

**Plugin Health Configuration Inconsistency**
- File: `plugins/health/.claude-plugin/plugin.json` line 5
- Only health plugin declares `"mcpServers": "mcp/config.json"`. Other plugins omit this field. Unclear if intentional.

---

## 2. Test Coverage

### Critical

**No Test Coverage Exists**
- No unit tests, integration tests, or end-to-end tests for any skill logic.
- Only artifact: `tests/validate_json.sh` — currently broken.
- Missing: grocery CRUD, recipe management, medication interaction checks, user isolation (prescriptions), health evaluator logic.

### Major

**Smoke Tests Mentioned But Not Repeatable**
- ROADMAP.md references smoke tests that passed, but no test artifacts, logs, or repeatable procedures exist.

---

## 3. Code Quality

### Major

**Inconsistent Version Numbering**
- health plugin: `0.1.0`; all others: `1.0.x`. No rationale documented.

**Undocumented Environment Variable**
- `plans/food-log-plugin.md` line 92 introduces `BRIAN_USER` fallback not documented elsewhere.

### Minor

**Inconsistent Access Control Documentation**
- README uses `[Access: X]` labels; `marketplace.json` uses `"access"` field values (`"all"`, `"per-user"`, `"charles"`). No mapping between the two formats documented.

---

## 4. Documentation

### Major

**Incomplete Setup Instructions for Environment Variables**
- Variables scattered across files: `BRIAN_MCP_CLIENT_ID`/`SECRET` in README, `PRESCRIPTIONS_USER` only in prescriptions README, `HEALTH_USER` only in health README, `FOOD_LOG_USER` only in plans/, `NAS_IP` only in jellyfin README.
- Fix: Centralized env var table in main README.

**Missing Instructions for Food-Log Plugin Completion**
- `plans/food-log-plugin.md` exists but `plugins/food-log/` directory was never created.

### Minor

- No CHANGELOG.md
- Phase gaps in roadmap (Phases 3 and 5 undescribed)
- `@~/Documents/GitHub/CLAUDE.md` reference in CLAUDE.md line 51 is confusing

---

## 5. Organization

### Major

**Uncommitted Changes in Working Tree**
- `ROADMAP.md` modified but not staged.
- `plans/` directory entirely untracked — referenced from ROADMAP.md but not in git history.

### Minor

- `.githooks/` is in `.gitignore` — see Security section.

---

## 6. Security

### Critical

**Pre-Commit Hook Bypassed by Gitignore**
- Files: `.gitignore` line 21, `.githooks/pre-commit`
- `.githooks/` is listed in `.gitignore`, so the token-scanning pre-commit hook is never committed. Cloners won't get it.
- Fix: Remove `.githooks/` from `.gitignore`; commit the hook directory.

### Major

**Private Data Scoping Not Auditable**
- prescriptions and health skills claim per-user memory isolation via tags, but there are no tests or documentation verifying the memory service enforces these boundaries.

### Minor

- README doesn't warn about credential rotation or .env commit risks.
- No rate limiting documentation.

---

## Summary

| Category | Critical | Major | Minor |
|---|---|---|---|
| Bugs | 1 | 2 | — |
| Test Coverage | 1 | 1 | — |
| Code Quality | — | 2 | 2 |
| Documentation | — | 2 | 3 |
| Organization | — | 2 | 1 |
| Security | 1 | 1 | 1 |
| **Total** | **3** | **10** | **7** |

## Top 3 Most Important

1. **[Security/Critical]** `.githooks/` in `.gitignore` — token-scan pre-commit hook is never enforced for anyone cloning the repo.
2. **[Bug/Critical]** JSON validation test broken on Windows — no automated integrity checks run at all.
3. **[Test/Critical]** Zero test coverage — no way to verify any skill logic works correctly.
