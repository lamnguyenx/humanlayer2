# Adaptations Made

**Completed**: Phase 1 - Foundation (files copied)

## Status

### ✅ Phase 1 Complete - Files Copied
- **28 commands** → `.claude/commands/`
- **7 agents** → `.claude/agents/`
- **1 settings file** → `.claude/settings.json`
- **10 scripts** → `hack/`
- **Scripts made executable**

### ✅ Phase 2 Complete - Script Adaptation
- `create_worktree.sh` - Applied SWD pattern, removed HumanLayer thoughts init
- `cleanup_worktree.sh` - Applied SWD pattern, customized worktree base path
- Both scripts now work from any directory
- Tested: scripts callable from outside repo ✓

### ⚠️ Files Requiring Phase 3 Adaptation

#### Commands with External Dependencies (16 files)

**Pattern: `humanlayer` references**
- `ci_describe_pr.md` - HumanLayer tool references
- `create_handoff.md` - HumanLayer-specific workflow
- `create_plan.md` - References `humanlayer` CLI
- `create_plan_nt.md` - References `humanlayer` CLI
- `create_worktree.md` - References hack scripts
- `debug.md` - References `humanlayer` CLI
- `describe_pr.md` - References `humanlayer` CLI
- `iterate_plan.md` - References `humanlayer` CLI
- `linear.md` - Linear.app integration (references `humanlayer`)
- `local_review.md` - References `humanlayer thoughts sync`
- `oneshot.md` - Uses `npx humanlayer launch`
- `ralph_impl.md` - References hack scripts & `humanlayer`
- `ralph_plan.md` - References `humanlayer`
- `ralph_research.md` - References `humanlayer`
- `research_codebase.md` - References hack scripts & `humanlayer`
- `resume_handoff.md` - References `humanlayer`

**Pattern: `linear` references** (8 files)
- `create_plan_generic.md` - Linear.app references
- `create_plan_nt.md` - Linear.app references
- `create_plan.md` - Linear.app references
- `create_worktree.md` - Linear.app references
- `founder_mode.md` - Linear.app references
- `ralph_impl.md` - Linear.app references
- `ralph_plan.md` - Linear.app references
- `research_codebase_nt.md` - Linear.app references
- `research_codebase.md` - Linear.app references

### Scripts to Adapt (2 files)

**Hardcoded paths found:**
- `cleanup_worktree.sh` - Line 12: `WORKTREE_BASE_DIR="$HOME/.humanlayer/worktrees"`
- `create_worktree.sh` - Likely has similar issues
- `spec_metadata.sh` - Uses git rev-parse (OK, but verify)

**No adaptation needed:**
- `generate_*_icons.sh` - Skip (Tauri/icon generation, HumanLayer-specific)
- `generate_nightly_icons.sh` - Skip (HumanLayer-specific)
- `install_platform_deps.sh` - Adapt if needed for your project
- `port-utils.sh` - Generic utility, keep
- `run_silent.sh` - Generic utility, keep
- `setup_repo.sh` - Review for HumanLayer-specific setup

## Next Steps (Phase 3)

### Phase 3: Command Adaptation (Ready to Start)

**Quick decisions to make:**

1. **Keep commands** (no external dependencies):
   - `commit.md`, `ci_commit.md`, `describe_pr.md`
   - `implement_plan.md`, `validate_plan.md`
   - `create_plan_generic.md`, `research_codebase_generic.md`

2. **Adapt commands** (remove `humanlayer` references):
   - `create_plan.md` - Remove `humanlayer` CLI references
   - `research_codebase.md` - Keep, just remove HumanLayer-specific notes
   - `debug.md` - Remove HumanLayer tool references

3. **Replace or skip**:
   - `oneshot.md` - Remove `npx humanlayer launch`, keep prompt structure
   - `local_review.md` - Replace `humanlayer thoughts sync` with git workflow
   - `linear.md` - Adapt for GitHub Issues or skip if not needed

4. **Skip (HumanLayer-specific)**:
   - `create_handoff.md` - Handoff system specific
   - `resume_handoff.md` - Handoff system specific
   - `ralph_*` - HumanLayer-specific workflow

## Recommended Approach

1. **For `humanlayer` CLI references**: Since you don't have Node.js tooling, either:
   - Remove references (use manual Claude Code)
   - Create wrapper scripts in `hack/`
   
2. **For Linear.app references**: Either:
   - Replace with GitHub Issues variant
   - Use web search instead
   - Keep as reference; remove from everyday commands

3. **For hardcoded paths in scripts**: Apply SWD pattern (see REUSE_PLAN.md section 8)

## Files to Keep/Skip

### Keep (Generic & Reusable)
- `commit.md` - No external dependencies
- `ci_commit.md` - No external dependencies
- `ci_describe_pr.md` - (has humanlayer refs, but safe to adapt)
- `describe_pr.md` - (has humanlayer refs, but safe to adapt)
- `implement_plan.md` - No external dependencies
- `validate_plan.md` - No external dependencies
- `founder_mode.md` - (has linear refs, but safe to adapt)

### Skip (HumanLayer-Specific)
- `create_handoff.md` - Handoff system specific
- `resume_handoff.md` - Handoff system specific

### Decide Later (Tool-Specific)
- `linear.md` - Linear.app only
- `oneshot.md` - Requires npx
- `local_review.md` - Requires humanlayer sync
