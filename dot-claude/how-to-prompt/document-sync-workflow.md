---
title: "Documentation Sync Workflow"
created: 2026-04-01
updated: 2026-04-01
status: active
version: 1.0.0
contributors:
  - Claude Opus 4.6 (original workflow)
  - Gemini 3.1 Pro (hardening & failure modes)
  - Monica (severity tagging, decisions framework, cross-references)
How to use this:
  - Drop it into your repo as docs/DOCUMENTATION_SYNC_WORKFLOW.md
  - Create the initial docs/DEVIATIONS.md using the template from Section 1
  - Add the PR checklist to your .github/PULL_REQUEST_TEMPLATE.md
  - Paste the relevant prompt snippets into your AI agent's system prompt
  - Optionally install the pre-commit hook from Section 4
---

# 📄 Documentation Sync Workflow


> **Philosophy:** After implementation, the **code is the source of truth** — not the plan.
> This workflow closes the loop between what you *planned* and what you *built*.

> **Pattern:** Asynchronous event-sourced deviation logging — not synchronous approval gates.
> The agent unblocks itself, logs as it goes, and reconciles at the end.

---

## Table of Contents

- [📄 Documentation Sync Workflow](#-documentation-sync-workflow)
  - [Table of Contents](#table-of-contents)
  - [1. During Implementation: Passive Deviation Logging](#1-during-implementation-passive-deviation-logging)
    - [Why this is better than "stop and ask"](#why-this-is-better-than-stop-and-ask)
    - [`docs/DEVIATIONS.md` File](#docsdeviationsmd-file)
    - [Entry Types Explained](#entry-types-explained)
    - [Severity Levels](#severity-levels)
  - [2. Circuit Breaker Rule](#2-circuit-breaker-rule)
    - [Why this matters](#why-this-matters)
  - [3. Post-Implementation: The Documentation Sync Prompt](#3-post-implementation-the-documentation-sync-prompt)
  - [4. Git Integration: Make It Stick](#4-git-integration-make-it-stick)
    - [Commit Convention](#commit-convention)
    - [PR Checklist](#pr-checklist)
    - [Optional: Pre-Commit Hook](#optional-pre-commit-hook)
  - [5. Scaling Guide](#5-scaling-guide)
  - [6. Templates \& References](#6-templates--references)
    - [Plan File Frontmatter](#plan-file-frontmatter)
    - [Useful Grep Commands](#useful-grep-commands)
    - [Example Deviation Entry (Filled)](#example-deviation-entry-filled)
    - [Example Decision Entry (Filled)](#example-decision-entry-filled)
  - [7. Workflow Diagram](#7-workflow-diagram)
  - [Credits](#credits)

---

## 1. During Implementation: Passive Deviation Logging

Instead of stopping to ask permission on every deviation (which kills flow), instruct the agent to **log as it goes**.

> **Instruction to add to your implementation prompt:**
>
> *"If you deviate from the implementation plan — due to bugs, technical constraints, or better approaches discovered during coding — append a brief entry to `docs/DEVIATIONS.md` with the format specified in that file's template header, then continue working."*

### Why this is better than "stop and ask"

- ✅ Zero interruption to flow state
- ✅ Deviations are captured in real-time (not recalled from memory later)
- ✅ Creates a reviewable audit trail
- ✅ Reduces token waste (no round-trip approval conversations)
- ✅ Acts as externalized memory (LLMs lose track during long sessions)

---

### `docs/DEVIATIONS.md` File

> **Important:** Keep the template block at the top of the file at all times.
> This ensures the agent sees the correct format every time it opens the file.

```markdown
# Deviations Log

> **Format Template — DO NOT DELETE.**
> Copy the block below for each new entry. Use strict markdown structure.

<!--
## [YYYY-MM-DD HH:MM] — <Short Title>

- **Type:** 🔀 Deviation | 🧭 Decision
- **Severity:** 🟢 Minor | 🟡 Moderate | 🔴 Major
- **Plan Reference:** `docs/plans/<plan-file>.md#<section-anchor>`
- **Planned:** <What the plan said to do>
- **Actual:** <What was actually done>
- **Reason:** <Why the change was necessary>
- **Impact:** <New deps, env vars, CLI flags, or architectural changes>
-->

---

<!-- ENTRIES BELOW THIS LINE -->
```

### Entry Types Explained

| Type            | When to Use                                                                                   |
| --------------- | --------------------------------------------------------------------------------------------- |
| 🔀 **Deviation** | The plan was clear, but you had to do something different (bug, constraint, better approach). |
| 🧭 **Decision**  | The plan was ambiguous or silent on this point. You made a judgment call.                     |

### Severity Levels

| Severity       | Definition                                                 | Examples                                                                      |
| -------------- | ---------------------------------------------------------- | ----------------------------------------------------------------------------- |
| 🟢 **Minor**    | No architectural impact. Cosmetic or naming changes.       | Renamed a variable, used a different utility function, reordered steps.       |
| 🟡 **Moderate** | Localized structural change. Affects one module.           | Changed a function signature, added a helper module, modified a schema field. |
| 🔴 **Major**    | Cross-cutting change. Affects architecture, deps, or APIs. | Swapped REST for WebSocket, changed the data model, added a new service.      |

---

## 2. Circuit Breaker Rule

> ⚠️ **Without this, an agent may cheerfully rewrite your entire architecture
> while dutifully logging each step.**

Add this to your implementation prompt:

> *"If you accumulate more than **3 entries with 🔴 Major severity** in `docs/DEVIATIONS.md`,
> **STOP implementation immediately**. This means the original plan is likely invalid.
> Summarize the situation and ask for a human review before continuing."*

### Why this matters

- Prevents "polite catastrophe" — the agent being helpful while derailing the project
- Forces a re-planning step when the plan-to-reality gap is too large
- Minor and moderate deviations are expected and healthy; major ones signal plan failure

---

## 3. Post-Implementation: The Documentation Sync Prompt

Once the feature is working, run this prompt:

```
The implementation is complete. Perform a Documentation Sync:

1. Review `docs/DEVIATIONS.md` for all changes logged during implementation.

2. Update `docs/plans/<relevant-plan>.md`:
   - Revise architecture/logic sections to reflect the actual implementation.
   - For each entry with a **Plan Reference**, update that specific section.
   - Add a "## Deviations & Lessons Learned" section at the bottom,
     summarizing entries from DEVIATIONS.md with rationale.
   - Add a "## Decisions Made" section for all 🧭 Decision entries,
     documenting the ambiguity and the choice made.
   - Update the `updated:` timestamp in the frontmatter. Do NOT change `created:`.
   - Update the `status:` to `implemented`.
   - Set `deviations:` to the total count of entries logged.

3. Update `docs/issues/feature-requests/<relevant-issue>.md`:
   - Ensure the delivered scope matches reality.
   - Document any discovered edge cases under "## Edge Cases."
   - Note any scope that was cut or deferred under "## Deferred."

4. Update project config docs:
   - If new environment variables were added → update `.env.example` and README.
   - If new dependencies were added → verify they're in package.json/requirements.txt.
   - If new CLI flags were added → update the CLI help text and README.

5. Archive or delete `docs/DEVIATIONS.md`:
   - If archiving: move to `docs/archive/deviations/YYYY-MM-DD-<feature-name>.md`
   - Then recreate a fresh `docs/DEVIATIONS.md` with only the format template header.
   - Do NOT leave a stale file with old entries.

Output a summary of all changes made, grouped by file.
```

---

## 4. Git Integration: Make It Stick

Documentation updates should live **in the same PR** as the code. Otherwise they rot.

### Commit Convention

```bash
# Feature code
git add src/
git commit -m "feat: implement <feature>"

# Documentation sync (same branch, same PR)
git add docs/ .env.example README.md
git commit -m "docs: sync documentation post-implementation"
```

### PR Checklist

Add to your PR template (`.github/PULL_REQUEST_TEMPLATE.md`):

```markdown
## Pre-Merge Checklist

### Code
- [ ] Code compiles and tests pass
- [ ] No unresolved TODOs related to this feature

### Documentation Sync
- [ ] `docs/DEVIATIONS.md` has been reviewed and reconciled
- [ ] Implementation plan updated to reflect actual architecture
- [ ] All 🧭 Decisions documented with rationale
- [ ] Feature request doc updated with delivered scope
- [ ] New env vars / deps / CLI flags documented
- [ ] `DEVIATIONS.md` archived or reset to clean template

### Circuit Breaker
- [ ] No more than 3 🔴 Major deviations (or re-planning was done)
```

### Optional: Pre-Commit Hook

Add a git pre-commit hook to catch stale deviations:

```bash
#!/bin/bash
# .git/hooks/pre-commit (or use husky/pre-commit framework)

# Check if DEVIATIONS.md has real entries (not just the template)
if [ -f "docs/DEVIATIONS.md" ]; then
  ENTRY_COUNT=$(grep -c "^## \[" docs/DEVIATIONS.md)
  if [ "$ENTRY_COUNT" -gt 0 ]; then
    echo "⚠️  WARNING: docs/DEVIATIONS.md has $ENTRY_COUNT unreconciled entries."
    echo "   Run the Documentation Sync prompt before merging."
    echo "   To bypass: git commit --no-verify"
    exit 1
  fi
fi

# Check for plans stuck in 'planned' status
STALE=$(grep -rl "status: planned" docs/plans/ 2>/dev/null)
if [ -n "$STALE" ]; then
  echo "⚠️  WARNING: The following plans are still in 'planned' status:"
  echo "$STALE"
fi
```

---

## 5. Scaling Guide

| Team Size            | Recommended Approach                                                                                                                                                                                     |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Solo**             | Keep it lean — single `DEVIATIONS.md`, update the plan, skip feature request sync if you're the only stakeholder. You can omit the PR checklist.                                                         |
| **Small team (2–5)** | Full workflow. PR checklist enforces discipline. Deviations log helps async teammates understand *why* things changed.                                                                                   |
| **Larger team (5+)** | Add a "Documentation Review" step to your PR review process. Assign a reviewer specifically for doc accuracy. Consider per-feature deviation files (`DEVIATIONS-<feature>.md`) to avoid merge conflicts. |
| **Multi-agent**      | Each agent gets its own deviation log prefix or section. Merge during sync.                                                                                                                              |

---

## 6. Templates & References

### Plan File Frontmatter

```markdown
---
title: "<Feature Name>"
created: 2026-03-28
updated: 2026-03-28
status: planned        # planned | in-progress | implemented | deprecated
deviations: 0          # total deviations from original plan
decisions: 0           # total ambiguity-driven decisions made
---
```

### Useful Grep Commands

```bash
# Find all plans that were never updated after implementation
grep -rl "status: planned" docs/plans/

# Find plans with high deviation counts
grep -r "deviations:" docs/plans/ | awk -F': ' '$2 > 5 {print}'

# Find all major deviations across archived logs
grep -r "🔴 Major" docs/archive/deviations/

# Find all unresolved decisions
grep -r "🧭 Decision" docs/archive/deviations/
```

### Example Deviation Entry (Filled)

```markdown
## [2026-03-28 14:30] — Switched from REST Polling to WebSocket

- **Type:** 🔀 Deviation
- **Severity:** 🔴 Major
- **Plan Reference:** `docs/plans/realtime-notifications.md#step-3-data-transport`
- **Planned:** REST polling every 5 seconds to `/api/notifications`
- **Actual:** WebSocket connection with automatic reconnection (exponential backoff)
- **Reason:** Polling at 5s intervals caused unacceptable latency for chat-style notifications.
  Load testing showed 200ms p99 with WebSocket vs 5200ms with polling.
- **Impact:**
  - New dependency: `ws@8.16.0`
  - New env var: `WS_URL` (added to `.env.example`)
  - New env var: `WS_HEARTBEAT_INTERVAL_MS` (default: 30000)
  - Client-side reconnection logic added to `src/lib/socket.ts`
```

### Example Decision Entry (Filled)

```markdown
## [2026-03-28 15:45] — Chose UUIDv7 for Primary Keys

- **Type:** 🧭 Decision
- **Severity:** 🟡 Moderate
- **Plan Reference:** `docs/plans/user-service.md#database-schema`
- **Planned:** Plan said "use unique IDs" — no specific format mentioned.
- **Actual:** Used UUIDv7 (time-sortable) instead of UUIDv4 or auto-increment.
- **Reason:** UUIDv7 gives us time-sorted inserts (better B-tree performance)
  while remaining globally unique. Auto-increment leaks row count.
- **Impact:**
  - New dependency: `uuidv7@1.0.0`
  - All `id` columns are `VARCHAR(36)` instead of `BIGINT`
```

---

## 7. Workflow Diagram

```
┌──────────────────────────┐
│   START CODING            │
│   (with implementation    │
│    plan loaded)           │
└───────────┬──────────────┘
            │
            ▼
┌──────────────────────────┐
│  Deviation or Decision    │──No──▶ Keep coding
│  found?                   │
└───────────┬──────────────┘
            │ Yes
            ▼
┌──────────────────────────┐
│  Log to DEVIATIONS.md     │
│  (with type + severity)   │──────▶ Keep coding (don't stop)
└───────────┬──────────────┘
            │
            ▼
┌──────────────────────────┐
│  🔴 Major count > 3?     │──Yes──▶ ⛔ STOP. Request human review.
│  (Circuit Breaker)        │
└───────────┬──────────────┘
            │ No
            ▼
      Keep coding...
            │
            │ (feature complete)
            ▼
┌──────────────────────────┐
│  Run Documentation        │
│  Sync Prompt              │
└───────────┬──────────────┘
            │
            ▼
┌──────────────────────────┐
│  Archive DEVIATIONS.md    │
│  Reset to clean template  │
└───────────┬──────────────┘
            │
            ▼
┌──────────────────────────┐
│  Commit docs in same PR   │
│  as feature code          │
└───────────┬──────────────┘
            │
            ▼
┌──────────────────────────┐
│  PR Review includes       │
│  doc accuracy check       │
└──────────────────────────┘
```

---

## Credits

This workflow was collaboratively designed through an LLM review chain:

- **Claude Opus 4.6** — Original workflow design (passive logging, sync prompt, git integration, scaling guide)
- **Gemini 3.1 Pro** — Hardening review (circuit breaker rule, format drift prevention, ghost file cleanup)
- **Monica (Claude Opus 4.6)** — Consolidation & enhancements (severity tagging, deviation vs. decision taxonomy, plan cross-references, pre-commit hook)