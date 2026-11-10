# humanlayer2

> **Summary**: Reusable Claude Code / OpenCode commands, agent prompts, how-to guides, and location-independent shell helpers extracted from HumanLayer, plus the notes for adapting them.

## What this is

This repo extracts the reusable parts of [HumanLayer](https://github.com/humanlayer/humanlayer) and keeps them free of HumanLayer-specific dependencies:

- **`dot-claude/`** — commands, how-to guides, separators, short prompts, and archived agent definitions.
- **`dot-mini/`** — one-line prompt snippets for steering an agent during a session (see below).
- **`hack/`** — shell scripts that work from any directory (worktrees, repo setup, icons, metadata).
- **`docs/important/`** — durable, topic-organised documentation.
- **`docs/plans/`** — dated session logs (what changed, trials, errors, lessons).
- **`__submodules__/`** — upstream checkouts used as reference: `humanlayer/humanlayer` and an `opencode-docs` snapshot.

## Layout

```
humanlayer2/
├── dot-claude/
│   ├── commands/          # Claude Code / OpenCode slash commands
│   ├── how-to-*/          # Code, git, plan, prompt, refactor, test, write guides
│   ├── shorts/            # Short reusable prompts
│   ├── separators/        # Prompt separator snippets
│   ├── agents.old/        # Archived Claude agent definitions
│   └── settings.json      # Claude Code settings
├── dot-mini/              # One-line session prompts
├── hack/                  # Standalone helper scripts
├── sourcegraph/amp/       # Sourcegraph AMP material
├── docs/
│   ├── important/         # Durable docs, grouped by topic
│   └── plans/YYYY/MM/DD/  # Dated session logs
├── __submodules__/        # Upstream reference checkouts
├── bach_lite.sh           # Small shell helper library
├── Makefile               # OpenCode command installation
└── README.md              # This file
```

## Quickstart

```bash
# Install the commands into OpenCode (symlinks dot-claude/commands)
make

# Or copy the pieces into another project
cp -r dot-claude /path/to/project/
cp -r hack /path/to/project/ && chmod +x /path/to/project/hack/*.sh

# Test a script from anywhere
cd /tmp && /path/to/this/repo/hack/create_worktree.sh TEST-001 test-branch
```

**Using `dot-mini/`:** each file is a ready-to-paste prompt, not a script. Open the file, copy its text into your agent, and fill in the date/topic placeholders. For example, [`dot-mini/write-all-we-have-done-into.md`](dot-mini/write-all-we-have-done-into.md) records a session across the parent repo and its submodules; [`dot-mini/minimal-readme-and-docs-index.md`](dot-mini/minimal-readme-and-docs-index.md) describes the README + topic-docs layout this repo uses.

## Docs index

### Session docs

- [Writing session docs across modules](docs/important/session-docs/writing-session-docs.md): how to log a session that touched both the parent repo and submodules, and why `git status` at the parent is not enough.

### Work logs

Dated logs live under [`docs/plans/`](docs/plans/), with newer entries in `YYYY/MM/DD/` folders. Recent entries:

- [2026-11-10 — module-aware session docs](docs/plans/2026/11/10/2026-11-10-module-aware-session-docs.md): fixes the parent-only documentation failure mode.
- [2025-11-12 — adapt dot-claude to OpenCode](docs/plans/2025-11-12-adapt-claude-to-opencode.md): directory, agent, command, and config migration plan.

## Submodules

The submodules are reference checkouts, not copies of this repo's prompts. A session that changes both the parent and a submodule documents each module in its own `docs/`; see [Writing session docs across modules](docs/important/session-docs/writing-session-docs.md). Don't create docs in a submodule you did not change — it dirties an otherwise clean checkout.

## Contributing

This repo is for curated, reusable components. Keep the parent-only pieces dependency-free and location-independent, and update the relevant `docs/important/` topic plus this README's index in the same change.

## License

See the HumanLayer submodule for original licensing. Adaptations here are intended for general reuse.
