# Writing session docs across modules

> Summary: How to record a working session that touched both the parent repo and one or more submodules, so each repo gets a log and an index update and no half of the work goes missing.

## The rule

A session is documented **per touched module**, not per session.

- A **module** is the parent repository or any git submodule, recursively.
- A module is **touched** if this session changed files there, committed there, or changed its gitlink from the parent.
- Every touched module gets:
  1. a plan log under its own `docs/plans/YYYY/MM/DD/YYYY-MM-DD-<name>.md`,
  2. an update to its own `docs/important/` when the session produced durable knowledge,
  3. an update to its own `README.md` when the change affects the front door or the docs index.
- Every untouched module gets nothing. Creating docs in a clean submodule dirties it for no reason and forces an extra submodule commit and gitlink update.
- All paths inside a module's docs are relative to **that module's root**. Cross-module references name the other module explicitly in addition to linking it.

## Finding the touched modules

Start at the parent root:

```bash
git status --short
git diff --submodule=log          # commit-level changes inside submodules
git submodule status              # '-' prefix = uninitialised, cannot be audited
```

Then descend:

```bash
git submodule foreach --recursive 'echo "--- $displaypath"; git status --short'
```

`git status` at the parent shows a dirty submodule as one line and hides the filenames, so it is not enough to decide whether — or what — to document. A failed attempt worth remembering:

```bash
git status --short --recurse-submodules=all
# error: unknown option `recurse-submodules=all'
```

`--recurse-submodules` belongs to `git diff` / `git log`, not `git status`.

An uninitialised submodule (`-` in `git submodule status`) cannot be audited. Say so in the parent log instead of guessing.

## Where each doc goes

| Doc | Location | Content |
|---|---|---|
| Session log | `<module>/docs/plans/YYYY/MM/DD/YYYY-MM-DD-<name>.md` | What changed, trials, errors, lessons, verification. Dated and immutable. |
| Durable topic doc | `<module>/docs/important/<topic>/<name>.md` | How things work *now*. No session chronology. |
| Front door | `<module>/README.md` | What the module is, where things are, quickstart, index of `docs/important/`. |

A topic doc states current truth; a plan log records how it was reached. The plan log links to the topic doc, and the topic doc may link back to the log as history — the topic doc is the source of truth.

## Cross-module links

In the parent log, link a submodule log from the parent log's directory. From `docs/plans/2026/11/10/`, the five `..` segments reach the repo root, then descend into the submodule. Use the resolved path as the link target, with a human label:

```text
label:   submodule log
target:  ../../../../../__submodules__/x/docs/plans/2026/11/10/2026-11-10-x.md
```

In a submodule log, a link back to the parent crosses the submodule boundary. It resolves in a superproject checkout but breaks if the submodule is cloned standalone. Write both the module name and the path, so the reference survives either way:

```text
Parent-repo log: `humanlayer2` → `docs/plans/2026/11/10/2026-11-10-x.md`
```

Then decide whether to add the working-tree link. It is convenience, not the reference of record. From `__submodules__/x/docs/plans/2026/11/10/`, seven `..` segments reach the superproject root:

```text
target:  ../../../../../../../docs/plans/2026/11/10/2026-11-10-x.md
```

Each log should name the other modules involved and summarize their side in one or two lines. The reader should not have to discover the rest of the session by browsing sibling repos.

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| Only the parent has a log | The instruction named one `docs/plans/` root | Audit per module and write per module |
| Submodule half of the session described only from the parent | Parent `git status` treated as complete | `git submodule foreach --recursive 'git status --short'` |
| Links in a submodule doc point at the parent's `docs/` as if it were local | Paths copied from the parent | Resolve every link against the doc's own directory |
| Clean submodule has a new log | "Write everywhere" instead of "write where touched" | Touched-module audit; record clean audits in the parent log |
| Parent README duplicates the submodule log | Copying instead of pointing | Parent README links to the submodule log |
| README describes directories that no longer exist | Written from memory | Check the README against `ls` / `git ls-files` |

## Checklist

- [ ] Listed the parent's changes and every recursive submodule's changes.
- [ ] Recorded which modules are clean, so omission is intentional.
- [ ] Wrote/updated one plan log per touched module.
- [ ] Used paths relative to each module's root.
- [ ] Named the other modules in each log and linked their logs.
- [ ] Updated `docs/important/` in each touched module, if the session taught something durable.
- [ ] Updated `README.md` in each touched module, if the layout or docs index changed.
- [ ] Ran a relative-link check over every file written.

## Related

- Plan log: [`docs/plans/2026/11/10/2026-11-10-module-aware-session-docs.md`](../../plans/2026/11/10/2026-11-10-module-aware-session-docs.md)
- Reusable prompt: [`dot-mini/write-all-we-have-done-into.md`](../../../dot-mini/write-all-we-have-done-into.md)
- Prompt for module-relative paths: [`dot-mini/relative-to-this-submodule-root-dir.md`](../../../dot-mini/relative-to-this-submodule-root-dir.md)
- README/docs organisation methodology: [`dot-mini/minimal-readme-and-docs-index.md`](../../../dot-mini/minimal-readme-and-docs-index.md)
