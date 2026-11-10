# Make session documentation module-aware

> Summary: Fix `dot-mini/write-all-we-have-done-into.md` so a session that spans the parent repo and one or more submodules writes a log, updates `docs/important/`, and updates `README.md` in **every** touched module, instead of piling everything into the parent.

**Date**: 2026-11-10
**Status**: Done
**Modules touched**: `humanlayer2` (parent) only. The one real submodule, `__submodules__/humanlayer/humanlayer`, was audited and is clean (§ Verification).

## Problem

The prompt used to end a working session said:

```
write down ... into docs/plans/...
then update @docs/important/ and @README.md
```

Every path in it is implicitly the parent repo. An agent that runs `git status` at the parent root sees a submodule as a single line — `M __submodules__/foo` — with no hint of which files changed inside it. So when the session edits both the parent and a submodule, the usual outcome is:

- one plan log, in the parent's `docs/plans/`;
- the parent's `docs/important/` and `README.md` updated;
- the submodule's own docs untouched, and the submodule work described only from the parent's point of view;
- paths in the log that silently assume the reader is at the parent root, even when the work happened at a different module root.

The submodule commit is then the only record of that half of the session, and the submodule's future readers never learn that the change was part of a larger cross-repo effort.

## What changed

1. **`dot-mini/write-all-we-have-done-into.md`** — now states the requirement at the module level: write the log, update `docs/important/`, and update `README.md` for every module touched this session (parent and submodules), not just the parent. The how-to detail lives in the docs, not in the prompt.
2. **`docs/important/session-docs/writing-session-docs.md`** — durable version of the workflow: what counts as a touched module, how to detect it, where each kind of doc belongs, and the failure modes.
3. **`README.md`** — refreshed. It still described the repo as `dot-claude/` + `hack/` only, listed a non-existent `dot-claude/agents/`, and had no docs index. It now maps the actual layout, points at `dot-mini/`, `docs/important/`, and the plan logs, and documents the submodule rule.
4. **This log** — written under the parent's own `docs/plans/YYYY/MM/DD/` convention, with every path relative to the parent root.

## Trials and errors

### Trial 1: detect submodule work with `git status --recurse-submodules=all`

Failed:

```
$ git status --short --recurse-submodules=all
error: unknown option `recurse-submodules=all'
```

`--recurse-submodules` is a `git diff` / `git log` option; `git status` does not accept it. The working commands are:

```bash
git status --short                                   # parent; submodule is one line
git submodule foreach --recursive 'git status --short'  # files inside each submodule
git diff --submodule=log                             # commit-level submodule changes
git submodule status                                 # '-' means uninitialised, cannot be audited
```

### Trial 2: "the submodule is one dirty line, so it is one dirty line in the log"

Rejected. The line `M __submodules__/x` carries no filenames and no commit range. Writing the parent log from it means guessing. The agent has to descend into the module before writing; the prompt only states the requirement, and the detection steps live in the workflow doc.

### Trial 3: "just also create docs in every submodule"

Rejected as the default. If the submodule is clean, creating `docs/plans/...` there dirties it for no reason, and that change then has to be committed in the submodule and re-pinned in the parent. The rule is: touched modules only, with a recorded audit that says which ones were checked and found clean.

### Error: a single set of `@docs/important/` and `@README.md` targets

The old prompt's `@` targets read as "the repo I am in", which an agent reasonably resolves to the parent. The fix is per-module wording, not a smarter agent. Any instruction that names one docs root will be interpreted as one docs root.

### Error: stale README discovered while updating it

The README claimed a `dot-claude/agents/` directory. The directory is actually `dot-claude/agents.old`; the current layout is commands + how-to guides + `shorts/` + `separators/`. Documentation written from memory of the repo, rather than from `ls`, goes stale exactly like this. The README rewrite was checked against the real tree.

## Lessons learnt

- **`git status` at the parent is module-blind by design.** A submodule is one line, and a clean line means nothing was done there — but a dirty line still does not say *what* was done. Audit per module, recursively, before writing.
- **"Update the docs" is ambiguous in a multi-repo workspace.** Name the module, the root, and the target path for every docs instruction. One docs root per instruction is the bug.
- **Docs written inside a module must resolve paths against that module's root.** A link that works from the parent root (`docs/plans/...`) is wrong inside a submodule, and `../` depth differs. Cross-module links need to be computed from the log's own directory.
- **A clean module is a valid audit result.** Record it (`audited, clean`) instead of silently omitting it; otherwise the next reader cannot tell "nothing happened" from "nobody checked".
- **One session is still one story.** Separate logs per module are fine as long as each links the others. The alternative — one log in the parent that describes submodule internals — is exactly the failure this change fixes.
- **Fix the instruction, not the agent's memory.** The durable fix belongs in the reusable prompt/checklist and in `docs/important/`; a note in one session's plan log would not survive the next session.

## Verification

Run in the parent:

```bash
git status --short
#  M README.md
#  M dot-claude/how-to-prompt/use-vlm-as-your-eye.md
#  M dot-mini/write-all-we-have-done-into.md
#  D minimal-readme-and-docs-index.md
# ?? docs/important/
# ?? docs/plans/2026/
# ?? dot-mini/do-this-without-focus-the-tab.md
# ?? dot-mini/minimal-readme-and-docs-index.md

git submodule foreach --recursive 'echo "--- $displaypath"; git status --short'
# Entering '__submodules__/humanlayer/humanlayer'
# --- __submodules__/humanlayer/humanlayer
# (no output: clean)
```

The submodule is at the upstream commit `50e204aa` with no local changes, so per the new rule it gets no log and no doc edits. The remaining uncommitted files (`use-vlm-as-your-eye.md`, the `minimal-readme-and-docs-index.md` move, `do-this-without-focus-the-tab.md`) are pre-existing edits from another change set and were left untouched.

Link check: every relative Markdown target in `README.md`, `docs/important/`, and this log resolves to an existing file.

## Related

- Prompt: [`dot-mini/write-all-we-have-done-into.md`](../../../../../dot-mini/write-all-we-have-done-into.md)
- Workflow doc: [`docs/important/session-docs/writing-session-docs.md`](../../../../important/session-docs/writing-session-docs.md)
- Earlier plan: [`docs/plans/2025-11-12-adapt-claude-to-opencode.md`](../../../2025-11-12-adapt-claude-to-opencode.md)
- Prompt snippets about submodule-relative paths: [`dot-mini/relative-to-this-submodule-root-dir.md`](../../../../../dot-mini/relative-to-this-submodule-root-dir.md)
