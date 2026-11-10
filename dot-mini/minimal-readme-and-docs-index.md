# Minimal README + topic docs: the methodology

How this repository's `README.md` and `docs/important/` are organised, and the
procedure used to get there (2026-10-29), written to be reused on other
projects.

## The rule

- **`README.md` is a front door, not a manual.** It answers three questions and
  stops: what is this, where are things, how do I get a first green run. Then
  it links everything else.
- **Long, specialised topics live in `docs/important/<topic>/`.** One doc per
  subject, grouped into topic subdirectories.
- **The README's docs index is the only index.** No per-subdir README or
  `index.md`, because a second list to keep in sync is a second list that
  drifts.
- **Dated work logs live elsewhere** (`docs/plans/YYYY/MM/DD/…`). A topic doc
  states how things are now; a plan log records how we got there. Topic docs
  link to plan logs, never the other way round as the source of truth.

### Why

A long README gets a section per feature, and each section half-duplicates a
doc. The two copies drift apart and new docs never make it into the README's
link list. Before this change the README was 1262 lines, and 9 of the 31 docs
in `docs/important/` were linked from nowhere.

## Shape of the README

1. **Title and one paragraph**: what the project is, in a few bullets at most.
2. **Layout**: a directory map, one line per directory.
3. **Quickstart**: the 3–6 commands every track shares, then one pointer per
   track ("for X, read Y").
4. **Docs index**: one `###` per topic subdir (linking the subdir itself), one
   bullet per doc, each as `[Title](path): when to read it`, in one or two
   lines.
   - **Depth:** two levels by default (group → doc). Add a third level only for
     very large docs, as an inline `·`-separated row of links to their key
     `##` sections.
5. **Elsewhere**: pointers to other entry points (secondary READMEs, the plans
   folder).

The summary line says what a reader gets from the doc, not what the doc
contains section by section.

## Choosing the topic subdirs

- Group by **what a reader is trying to do or which system they are touching**
  (e.g. `infra-135/`, `androidworld/`, `browser-fleet/`, `studio/`,
  `testing/`, `dev-env/`, `opencode-and-models/`), not by doc type (how-to vs.
  reference).
- Aim for 3–7 docs per group. A one-doc group is fine only if it is clearly
  going to grow.
- Keep existing filenames when moving (fix typos only). Renames on top of moves
  multiply the links to rewrite and break people's muscle memory and `grep`
  habits.
- Before moving anything, read each doc's title and first paragraph; filenames
  lie (`how-to-use-opencode-headless.md` turned out to be "use a VLM as your
  eyes").

## The procedure

Do it in this order. Each step is checkable on its own.

### 1. Inventory

- List every doc and its `# title` and line count:
  `for f in docs/important/**/*.md; do echo "$(wc -l <$f) $f :: $(grep -m1 '^# ' $f)"; done`.
- List the README's headings (`grep -n '^#' README.md`) and read it whole.
- Find which docs the README already links and which it does not.

### 2. Map every README section to a destination

For each README section, decide one of:

| Decision | When | How to confirm |
|---|---|---|
| **Keep in README** | It is the intro, the layout, or the shared quickstart | — |
| **Drop** | An existing doc already says it | `grep` the existing docs for 2–3 distinctive phrases from the section (a flag name, a number, an odd term) |
| **Move to a new doc** | Nothing covers it | — |

Write the mapping down as README line ranges, and check that the ranges cover
every line of the old README: no gap, no overlap.

### 3. Move the existing docs into subdirs

- Use plain `mv` (or `git mv`, if staging is wanted). Git detects the renames
  at commit time either way.
- Do this **before** carving new docs out of the README, so step 4 relinks
  everything once.

### 4. Rewrite every reference by resolving paths, not by matching names

Write a small script with an explicit `old path → new path` map and run it
over every tracked text file (docs, code comments, Makefile, compose,
`.gitignore`, env files). Rules that mattered:

- **Resolve, don't match basenames.** `model-fallback.md` was both a moved doc
  and the suffix of the plan file `2026-10-05-model-fallback.md`. A link is
  rewritten only if, resolved against its file's directory, it points at a
  moved path.
- **Handle every reference form:** repo-rooted mentions anywhere
  (`docs/important/x.md` in comments and prose), and relative Markdown links
  (`](x.md)`, `](../x.md)`, `](../../../../important/x.md)` from deep plan
  folders). Keep `#fragment`s.
- **Moved files need all their relative links recomputed**, including the ones
  to files that did not move (`../plans/…` becomes `../../plans/…`). Resolve
  each link against the file's *old* directory, then make it relative to the
  *new* one.
- **Dry-run first** and print the before/after of every changed line, then
  review a sample: one moved doc, one deep plan file, one code comment, and the
  basename-collision case.
- **Skip vendored and read-only trees** (`_refs/`, `_submodules/`, `exp/`,
  `runs/`). Submodule references go on a list for the user: editing them dirties
  the submodule.

### 5. Carve the README into new docs, verbatim

- Build each new doc **from README line ranges by script**, not by retyping.
  Retyping drifts and silently loses sentences.
- Give each new doc a `# Title`, an optional one-paragraph intro, and its own
  `##` headings in place of the README's.
- Rewrite links copied from the README (repo-rooted, like `docs/plans/…`) to
  paths relative to the new doc's location. Only rewrite targets that exist
  from the repo root.
- Fix the few sentences that pointed at a neighbouring README section ("the
  layer above", "see below") with an explicit link, and assert that each fixup's
  old text was found.
- Have the script **assert the README still matches the line numbers** (for
  example, that a known heading is at its expected line) and refuse to
  overwrite an existing doc.
- Do not dedupe while moving. Move verbatim first; trimming overlap is a
  separate, reviewable pass.

### 6. Write the new README

Follow the shape above, with one summary line per doc. Reuse the old README's
link descriptions where they existed, and write new ones for docs that had none.

### 7. Verify

- **Coverage:** every `docs/important/**/*.md` appears in the README:
  `for f in $(find docs/important -name '*.md'); do grep -q "($f)\|($f#" README.md || echo "NOT INDEXED: $f"; done`.
- **Links resolve:** a checker that resolves every relative `](target)` in the
  README and all docs, and reports targets that do not exist. Run it before the
  change too, so pre-existing breakage is not mistaken for new breakage.
- **Anchors exist:** for each `path#anchor` in the README, slug the target's
  headings the way GitHub does (lower-case, drop punctuation except `-`, spaces
  become `-`; `Starting / stopping` becomes `starting--stopping`) and confirm
  the anchor is among them.
- **Leftovers:** `grep -rn 'important/<old-name>\.md'` for every old name
  returns only the expected submodule hits.
- **Prose references to the old README:** `grep -rn 'the README'`, as in "see
  the note at the end of the README", and repoint them at the new doc and
  section.
- **Docs lint**, if the project has it (mermaid and PlantUML validators,
  etc.), on the new and moved docs.

## Keeping it this way

- A new long topic gets a doc in the right subdir **and** a bullet in the README
  index in the same change.
- A README section that grows past a screen is a doc waiting to be split out.
- Worth adding: a check (test or `make` target) that fails when a
  `docs/important/**/*.md` file is not linked from the README, or when a README
  link or anchor points at nothing. Step 7's first three checks are that check.

## Reusing this on another project

1. Pick the docs root (`docs/important/` here) and the plans root, if any.
2. Run steps 1–2 by hand: they are judgement.
3. Copy the shape of the scripts: a move map plus a path-resolving relinker
   (step 4), a line-range carver (step 5), and a link/anchor/coverage checker
   (step 7). Only the move map and the line ranges are project-specific.
4. Leave commits to the owner. Moves, relinks and the new README are large
   but mechanical diffs, so they are easiest to review as one change, or as two
   (moves and relinks first, then the README rewrite).
