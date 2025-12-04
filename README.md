# humanlayer2

> **Summary**: A repository extracting reusable Claude Code workflow components from HumanLayer, providing dependency-free prompts and scripts for general project integration.

## Purpose

This repo extracts and adapts reusable parts from the HumanLayer submodule, focusing on:

- **Claude Code commands** (`dot-claude/commands/`) - Generic prompts and workflows
- **Agent definitions** (`dot-claude/agents/`) - Reusable analysis and research agents
- **Utility scripts** (`hack/`) - Location-independent shell scripts for git worktrees, setup, etc.

The goal is to provide a clean, dependency-free starting point for integrating Claude Code workflows into any project, without the full HumanLayer stack.

## What's Included

Based on the [REUSE_PLAN.md](REUSE_PLAN.md):

- **`dot-claude/commands/`**: Copied command files, with adaptations to remove HumanLayer-specific dependencies (e.g., replacing `npx humanlayer` with manual Claude Code instructions)
- **`dot-claude/agents/`**: All agent definitions (pure prompts, no external deps)
- **`hack/`**: Adapted shell scripts using the SWD pattern for location-independence
- **`REUSE_PLAN.md`**: Detailed documentation on the extraction and adaptation process

## Usage

1. **Clone this repo** as a submodule or copy into your project
2. **Copy the `dot-claude/` directory** to your target repo
3. **Copy `hack/` scripts** and make them executable (`chmod +x hack/*.sh`)
4. **Adapt as needed** - see REUSE_PLAN.md for common patterns

### Quick Setup

```bash
# Copy to your project
cp -r dot-claude/ /path/to/your-repo/
cp -r hack/ /path/to/your-repo/
chmod +x /path/to/your-repo/hack/*.sh

# Test a script from anywhere
cd /tmp && /path/to/your-repo/hack/create_worktree.sh TEST-001 test-branch
```

## Key Adaptations

- **Scripts**: Use `SWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)` for location-independence
- **Commands**: Replace `npx humanlayer launch` with manual Claude Code prompts
- **External deps**: Remove Linear integrations; use web search or adapt for your tracker

## Structure

```
humanlayer2/
├── dot-claude/
│   ├── commands/     # Adapted Claude Code commands
│   ├── agents/       # Reusable agent prompts
│   └── settings.json # Claude Code config
├── hack/             # Adapted utility scripts
├── REUSE_PLAN.md     # Extraction and adaptation guide
└── README.md         # This file
```

## Contributing

This repo is for curated, reusable components only. Updates should maintain compatibility with the REUSE_PLAN.md process.

## License

See HumanLayer submodule for original licensing. Adaptations here are for general reuse.