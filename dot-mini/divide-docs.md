Divide `ALL.md` into focused technical documents under `docs/important/*.md`.

Use **two signals** to decide how to split:
1. The `------` section dividers (coarse boundaries)
2. The inline cross-references like `See [app-live-translation-loop.md](...)` — these reveal the intended file names and topic groupings. Follow them where they make sense.

The doc also already contains a "Documentation" table near the end (line ~1663) mapping topics to file names — treat this as a **checklist** for the final split, but use your judgment to merge or separate content where it improves coherence.

Then create `README.md` in the repo root as an **index/glue** — brief overview, quick-start commands, and a TOC linking to each `docs/important/*.md` with 1-line descriptions. Do not duplicate the full content.

After creating the files, update any internal cross-references so they point to the correct new relative paths.
