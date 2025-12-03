# Reuse Plan: HumanLayer's `dot-claude/` Commands & Scripts

## Overview

Adopt HumanLayer's proven Claude Code workflow by:
1. **rsync hack scripts** to your repo, adapt them to work from any directory
2. **Copy dot-claude/commands** as-is (generic, no adaptation needed)
3. **Replace Node.js-dependent commands with prompts** (oneshot.md, linear.md)

---

## 1. Hack Scripts: Clone & Adapt

### Strategy
- `rsync` all scripts from `humanlayer/hack/` to your `./hack/`
- Adapt scripts to use `SWD=$(realpath "$0")` pattern for working-directory independence
- Keep only those relevant to your workflow; discard HumanLayer-specific ones

### Relevant Scripts to Copy

| Script | Purpose | Needs Adaptation | Priority |
|--------|---------|------------------|----------|
| `create_worktree.sh` | Creates git worktrees for branches | YES (hardcoded paths) | HIGH |
| `cleanup_worktree.sh` | Cleans up worktrees | YES (hardcoded paths) | HIGH |
| `run_silent.sh` | Run commands silently, log output | NO | MEDIUM |
| `setup_repo.sh` | Initial repo setup | YES (project-specific) | LOW |
| `spec_metadata.sh` | Generate metadata frontmatter | YES (path refs) | MEDIUM |
| `port-utils.sh` | Port discovery utilities | NO | LOW |

### Scripts to Skip
- `generate_*_icons.sh` - HumanLayer-specific (Tauri/icon generation)
- `generate_nightly_icons.py` - HumanLayer-specific
- `rotate_icon_colors.py` - HumanLayer-specific
- `visualize.ts` - Requires Node.js build
- `linear/` - Linear-specific integrations

### Adaptation Pattern

**Before** (hardcoded paths):
```bash
REPO_ROOT="$HOME/humanlayer"
WORKTREE_BASE="$HOME/wt/humanlayer"
```

**After** (script-location-based):
```bash
SWD=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SWD/.." && pwd)
WORKTREE_BASE="${WORKTREE_BASE:-$HOME/wt/$(basename "$REPO_ROOT")}"
```

This makes scripts callable from anywhere: `./hack/create_worktree.sh` or `cd /tmp && /path/to/hack/create_worktree.sh`

---

## 2. `dot-claude/commands/` Files: Copy As-Is

### Strategy
- **Copy all** command files as a baseline
- Categorize post-copy: which have external dependencies vs. generic prompts
- Adapt only those that reference external tools/services
- Source of truth: scan files for `humanlayer`, `npx`, `hack/`, `linear`, or hardcoded paths

### How to Categorize

**Run this to find commands needing adaptation:**
```bash
cd your-repo/dot-claude/commands

# Find files referencing humanlayer CLI
grep -l "humanlayer " *.md

# Find files referencing node/npm commands
grep -l "npx\|npm run" *.md

# Find files referencing hack scripts
grep -l "hack/" *.md

# Find files referencing Linear or external services
grep -l "linear\|Linear" *.md
```

### Typical Categories (Examples)

#### Generic & Reusable (Copy Directly)
Commands that are pure prompts with no external dependencies:
- `create_plan*.md` - Planning workflows
- `iterate_plan*.md` - Iteration workflows
- `implement_plan.md` - Implementation guidance
- `research_codebase*.md` - Codebase analysis
- `validate_plan.md` - Validation steps
- `describe_pr*.md` - PR description generation
- `commit.md` - Commit message generation
- `ci_*.md` - CI workflows
- `debug.md` - Debugging guidance
- `founder_mode.md` - Founder mode instructions

#### Commands to Adapt or Replace (Common Patterns)
| Pattern | Commands | Solution |
|---------|----------|----------|
| `npx humanlayer launch` | oneshot*.md | Replace with Claude Code manual instructions |
| `humanlayer thoughts sync` | ralph*.md, local_review.md | Replace with your workflow (git, docs, etc.) |
| `linear.app` references | linear.md, others | Adapt for your issue tracker or use web search |
| `hack/` script references | create_worktree.md, research_codebase.md | Keep; adapt scripts in Phase 1 |

#### Commands to Skip (Project-Specific)
- Handoff-related files (if not needed)
- Any file tightly coupled to a specific service/platform

### Discovery Process
Instead of listing what to copy, **copy everything, then filter**:
```bash
# Copy all
rsync -havP --stats source/dot-claude/commands/ dest/dot-claude/commands/

# Find what needs work
cd dest/dot-claude/commands
echo "=== External Dependencies Found ==="
grep -h "humanlayer\|npx\|hack/\|linear" *.md | sort | uniq
```

---

## 3. Node.js-Dependent Commands → Prompts

### Commands That Need Replacement

#### `oneshot.md`
**Current**: Uses `npx humanlayer launch --model opus ...`
**Replacement**: Create Claude Code session manually with prompt at top:
```
# Oneshot Plan for [TICKET-ID]

[paste the plan content here]

---

Now execute the plan step-by-step...
```

#### `linear.md`
**Current**: Uses HumanLayer's Linear MCP integration
**Replacement Options**:
1. Use Claude's native web search + manual Linear updates
2. Adapt to your issue tracker (GitHub Issues, Jira, etc.)
3. Keep as reference; create variant for your system

---

## 4. `dot-claude/agents/` Files

### Strategy
- Copy all agent files (they're pure prompt definitions)
- No code dependencies or external service calls
- Rename any project-specific ones if needed

### How to Categorize
```bash
ls -1 source/dot-claude/agents/*.md | while read f; do
  basename "$f"
done
# Copy all; rename only if filenames reference specific projects
```

### Typical Agents (Examples)
- `*analyzer.md` - Code/doc analysis prompts
- `*locator.md` - Search and discovery guidance
- `*researcher.md` - Research and investigation workflows
- `*finder.md` - Pattern discovery

**Copy all agents; they're reusable across projects.**

---

## 5. Phased Rollout

### Phase 1: Foundation (Day 1)
**Goal**: Get basic commands working immediately

**Tasks**:
```bash
# 1. Copy core files
rsync -havP --stats source/dot-claude/commands/ dest/dot-claude/commands/
rsync -havP --stats source/dot-claude/agents/ dest/dot-claude/agents/
rsync -havP --stats source/dot-claude/settings.json dest/dot-claude/

# 2. Copy and adapt scripts
mkdir -p dest/hack
rsync -havP --stats source/hack/*.sh dest/hack/
chmod +x "dest/hack/"*.sh

# 3. Find what needs adaptation
cd dest/dot-claude/commands
grep -l "humanlayer\|npx\|linear" *.md > /tmp/adapt_list.txt
cat /tmp/adapt_list.txt
```

- [ ] All command files copied
- [ ] All agent files copied
- [ ] All shell scripts copied to `hack/`
- [ ] List of files needing adaptation identified
- [ ] Test: `./hack/create_worktree.sh TEST-001 test-branch` works from any directory?

**Time**: 30–45 minutes

### Phase 2: Script Adaptation (Day 2)
**Goal**: Make scripts location-independent

**For each script in `hack/` that runs independently:**
```bash
# Add at the top of the script
SWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SWD/.." && pwd)

# Replace hardcoded paths:
# OLD: REPO_ROOT="/path/to/repo"
# NEW: REPO_ROOT=$(cd "$SWD/.." && pwd)
```

- [ ] Review each `.sh` file for hardcoded paths
- [ ] Apply SWD pattern to location-dependent scripts
- [ ] Test from different directories
- [ ] Document which scripts have been adapted

**Time**: 1–2 hours (depends on number of scripts)

### Phase 3: Command Adaptation (Day 3–4)
**Goal**: Replace external tool references

**For each command file in `/tmp/adapt_list.txt`:**
1. **If it references `npx humanlayer launch`**: Replace with manual Claude Code instruction
2. **If it references `humanlayer thoughts sync`**: Replace with your workflow (git, file sync, etc.)
3. **If it references `linear.app`**: Either adapt for your issue tracker or remove
4. **If it references `hack/` scripts**: Keep; now you have adapted versions

- [ ] Review each flagged command file
- [ ] Create replacements for npx/humanlayer references
- [ ] Test: Can you run `/your_command` in Claude Code?

**Time**: 1–3 hours (depends on complexity of referenced tools)

### Phase 4+: Customization & Integration (Ongoing)
- Add your own commands to `dot-claude/commands/`
- Add team-specific agents to `dot-claude/agents/`
- Add custom scripts to `hack/`
- Update scripts as your project needs evolve

---

## 6. File Structure

After completing phases 1–3:

```
your-repo/
├── dot-claude/
│   ├── settings.json           (from source repo)
│   ├── commands/               (from source repo)
│   │   ├── *.md                (generic: copied as-is)
│   │   ├── *_adapted.md        (your versions replacing external tools)
│   │   └── ...
│   └── agents/                 (from source repo)
│       ├── *.md
│       └── ...
│
├── hack/                        (from source repo)
│   ├── *.sh                    (adapted with SWD pattern)
│   └── ...
│
└── docs/                        (optional: your workflow docs)
    ├── claude-code-setup.md
    └── command-guide.md
```

**Key**: No fixed file counts. Structure expands as you add commands and scripts.

---

## 7. Quick-Start Checklist

### One-Command Setup
```bash
# Define source and destination
SOURCE_REPO="__submodules__/humanlayer/humanlayer"
DEST_REPO="."

# Copy all core files
rsync -havP --stats "$SOURCE_REPO/dot-claude/" "$DEST_REPO/dot-claude/"
mkdir -p "$DEST_REPO/hack"
rsync -havP --stats "$SOURCE_REPO/hack/" "$DEST_REPO/hack/"
chmod +x "$DEST_REPO/hack/"*.sh

# Identify what needs adaptation
echo "=== Files needing adaptation ==="
cd "$DEST_REPO/dot-claude/commands"
grep -l "humanlayer\|npx\|linear\|hack/" *.md 2>/dev/null | sort
cd - > /dev/null
```

### Test Core Functionality
```bash
# Test: Can you run commands in Claude Code?
# (Open Claude Code in your IDE and try: /create_plan)

# Test: Can scripts run from anywhere?
cd /tmp
/path/to/your-repo/hack/create_worktree.sh TEST-001 test-branch

# Test: Do copied files reference external tools?
cd your-repo/dot-claude/commands
grep -E "humanlayer|npx|linear.app" *.md | head -10
```

---

## 8. Script Adaptation Pattern

### The SWD Pattern (Script Working Directory)

**Problem**: Scripts with hardcoded paths (`$HOME/humanlayer`, `/absolute/path`) only work in one place.

**Solution**: Use `SWD` to make scripts location-independent.

### Before (Hardcoded)
```bash
#!/bin/bash
REPO_ROOT="$HOME/humanlayer"     # Only works if your repo is here
WORKTREE_BASE="$HOME/wt/humanlayer"
```

### After (Location-Independent)
```bash
#!/bin/bash
# Script's own directory (works from anywhere)
SWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SWD/.." && pwd)  # One level up from hack/

# Allow override via env var
WORKTREE_BASE="${WORKTREE_BASE:-$HOME/wt/$(basename "$REPO_ROOT")}"
```

### How to Apply

**Step 1**: Identify hardcoded paths in script
```bash
grep -E "^\s*(export\s+)?(REPO|PATH|BASE|DIR|ROOT)" your-script.sh
```

**Step 2**: Replace with SWD pattern
```bash
# Find and replace pattern
OLD='REPO_ROOT="$HOME/humanlayer"'
NEW='SWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); REPO_ROOT=$(cd "$SWD/.." && pwd)'

sed -i "s|$OLD|$NEW|" your-script.sh
```

**Step 3**: Test from different directories
```bash
cd /tmp && /path/to/your-repo/hack/your-script.sh arg1 arg2
cd ~/projects && /path/to/your-repo/hack/your-script.sh arg1 arg2
```

### Example: Full Before/After

**Before**:
```bash
#!/bin/bash
REPO_ROOT="/home/user/humanlayer"
HACK_DIR="$REPO_ROOT/humanlayer/hack"
WORKTREE_BASE="$HOME/wt/humanlayer"

do_something() {
  cd "$REPO_ROOT"
  git worktree add -b "$1" "$WORKTREE_BASE/$1" origin/main
}
```

**After**:
```bash
#!/bin/bash
SWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SWD/.." && pwd)
HACK_DIR="$SWD"
WORKTREE_BASE="${WORKTREE_BASE:-$HOME/wt/$(basename "$REPO_ROOT")}"

do_something() {
  cd "$REPO_ROOT"
  git worktree add -b "$1" "$WORKTREE_BASE/$1" origin/main
}
```

**Works from anywhere now:**
```bash
/path/to/your-repo/hack/your-script.sh arg1
/another/path/hack/your-script.sh arg1  # Same script, different location
```

---

## 9. Common Adaptation Patterns

### Pattern 1: `humanlayer thoughts sync`
**Problem**: Syncs docs to HumanLayer's backend (not available in your repo)

**Solutions**:
- **Option A**: Use git (docs stay in repo)
  ```bash
  git add .
  git commit -m "docs: update with research"
  git push
  ```
- **Option B**: Rsync to a shared location
```bash
rsync -havP --stats ./thoughts/ ~/shared-docs/
```
- **Option C**: Remove the step (keep docs local)
  ```
  # Edit command file: delete the "sync" instruction
  ```

### Pattern 2: `hack/spec_metadata.sh` or Similar Helper Scripts
**Problem**: Script references paths specific to another project

**Solution**: Use SWD pattern (see section 8) to make paths relative to script location
```bash
#!/bin/bash
SWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SWD/.." && pwd)

# Now REPO_ROOT works from anywhere
echo "Working in: $REPO_ROOT"
```

### Pattern 3: `npx humanlayer launch` or Similar CLI Tools
**Problem**: Node.js-dependent tool not available in your environment

**Solutions**:
- **Option A**: Remove the CLI call, use Claude Code manually
  ```
  # BEFORE: "Run: npx humanlayer launch --model opus '/oneshot_plan TICKET-123'"
  # AFTER: "Open Claude Code and paste this prompt, then execute it"
  ```
- **Option B**: Replace with equivalent tool (if you have one)
  ```bash
  my-tool launch --prompt "$(cat ./your_prompt.md)"
  ```
- **Option C**: Create a wrapper script in `hack/`
  ```bash
  #!/bin/bash
  # hack/launch.sh - wrapper for your tool
  # ... implementation
  ```

### Pattern 4: Linear, GitHub, Jira, or Other Issue Trackers
**Problem**: Commands reference a specific issue tracker

**Solutions**:
- **Option A**: Create a variant for your tracker
  ```
  Copy: linear.md → github.md
  Edit: Replace all Linear API calls with GitHub API calls
  ```
- **Option B**: Keep as reference, use web search instead
  ```
  # Let Claude use web search to find / link issues
  # No API integration needed
  ```
- **Option C**: Use manual linking
  ```
  # Add step: "Link this plan to TICKET-123 manually"
  ```

### General Approach
1. **Identify the dependency**: `grep -E "pattern" commands/*.md`
2. **Choose replacement**: Pick option A, B, or C above
3. **Edit the file**: Update the command file with your approach
4. **Test**: Try the command in Claude Code
5. **Document**: Add a comment explaining the adaptation

---

## 10. Settings & Customization

### `dot-claude/settings.json`
This file controls Claude Code behavior. Customize as needed:

```json
{
  "instructions": "You are an expert software engineer. Your role is to...",
  "models": {
    "default": "claude-3-5-sonnet-20241022",
    "planning": "claude-3-7-opus-20250219"
  }
}
```

**Common customizations**:
- `instructions`: Add your project-specific guidelines
- `models`: Choose your preferred Claude models
- Add your own fields for team-specific settings

Copy from source repo and adapt to your needs.

---

## 11. Known Limitations & Workarounds

| Limitation | Workarounds |
|-----------|-------------|
| No `humanlayer thoughts sync` | See Pattern 1 in section 9: git, rsync, or remove sync step |
| No Node.js-dependent CLIs | See Pattern 3 in section 9: manual Claude Code, wrapper script, or alternative tool |
| No issue-tracker integration | See Pattern 4 in section 9: variant for your tracker, web search, or manual linking |
| Hardcoded paths in scripts | See section 8: Use SWD pattern for location-independence |
| Project-specific workflows | Copy → adapt → test. Use grep to find references |

---

## 12. Success Metrics

After completing the plan:
- [ ] All `dot-claude/commands/` files copied to your repo
- [ ] All `dot-claude/agents/` files copied to your repo
- [ ] All `hack/` scripts copied and made location-independent
- [ ] `grep -r "humanlayer" dot-claude/commands/ | wc -l` returns 0 (or only in adapted files)
- [ ] `grep -r "npx " dot-claude/commands/ | wc -l` returns 0 (or only in adapted files)
- [ ] Can run any command starting with `/` in Claude Code
- [ ] Can run `./hack/create_worktree.sh TICKET-001 branch-name` from any directory
- [ ] No external service dependencies except what your team wants

---

## 13. Maintenance & Evolution

### Keep Commands Fresh
```bash
# Periodically check for improvements in source repo
cd source-repo/dot-claude/commands
git log --oneline -n 10 -- .

# Sync generic commands (create_plan, iterate_plan, etc.)
# Don't sync project-specific ones
```

### Extend Your Setup
- **New commands**: Add to `dot-claude/commands/`
- **New agents**: Add to `dot-claude/agents/`
- **New scripts**: Add to `hack/`, apply SWD pattern
- **Team docs**: Document your adaptations in `docs/`

### Track Adaptations
Keep a file like `ADAPTATIONS.md`:
```markdown
# Adaptations Made

## Commands
- `oneshot.md` → Removed npx humanlayer launch, use manual Claude Code
- `linear.md` → Not adapted (HumanLayer-specific, use web search instead)

## Scripts
- `create_worktree.sh` → Applied SWD pattern, works from any directory
- `spec_metadata.sh` → Not used in our project

## Known Issues
- None yet
```

