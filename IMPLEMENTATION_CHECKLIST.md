# Implementation Checklist: HumanLayer Reuse Plan

## Phase 1: Foundation ✅ COMPLETE

### File Copying
- [x] Copy `.claude/commands/` (27 files)
- [x] Copy `.claude/agents/` (6 files)
- [x] Copy `.claude/settings.json`
- [x] Copy `hack/` scripts (10 files)
- [x] Make scripts executable

### Inventory & Analysis
- [x] Identify files with external dependencies
- [x] Locate hardcoded paths in scripts
- [x] Create ADAPTATIONS.md tracking document
- [x] List files ready to use immediately

**Time**: ~15 minutes

---

## Phase 2: Script Adaptation ✅ COMPLETE

### Core Worktree Scripts
- [x] Apply SWD pattern to `create_worktree.sh`
  - Added: SWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  - Removed: HumanLayer thoughts init logic
- [x] Apply SWD pattern to `cleanup_worktree.sh`
  - Added: SWD pattern for location independence
  - Updated: WORKTREE_BASE_DIR variable
  - Removed: HumanLayer thoughts cleanup
- [x] Test scripts from different directories

### Script Status
- [x] `create_worktree.sh` - Location-independent ✓
- [x] `cleanup_worktree.sh` - Location-independent ✓
- [ ] `setup_repo.sh` - Review for HumanLayer-specific logic
- [ ] `install_platform_deps.sh` - Review dependencies
- [x] `port-utils.sh` - Generic, no changes needed
- [x] `run_silent.sh` - Generic, no changes needed
- [ ] Icon generation scripts - Can be skipped if not needed

**Time**: ~20 minutes

---

## Phase 3: Command Adaptation (READY TO START)

### Generic Commands (Ready to Use - No Adaptation Needed)
- [x] `commit.md`
- [x] `ci_commit.md`
- [x] `implement_plan.md`
- [x] `validate_plan.md`
- [x] `create_plan_generic.md`
- [x] `research_codebase_generic.md`
- [x] `founder_mode.md`
- [x] All agents (`.claude/agents/*.md`)

### Commands Needing Minor Adaptation
- [ ] `create_plan.md` - Remove HumanLayer references
- [ ] `research_codebase.md` - Remove HumanLayer-specific notes
- [ ] `describe_pr.md` - Remove HumanLayer tool references
- [ ] `ci_describe_pr.md` - Remove HumanLayer tool references
- [ ] `iterate_plan.md` - Remove HumanLayer references
- [ ] `debug.md` - Remove HumanLayer tool references

### Commands Needing Replacement
- [ ] `oneshot.md` - Remove `npx humanlayer launch`
- [ ] `local_review.md` - Replace `humanlayer thoughts sync` with git
- [ ] `linear.md` - Create GitHub variant or skip

### Commands to Skip (HumanLayer-Specific)
- [ ] `create_handoff.md` - Mark as skipped
- [ ] `resume_handoff.md` - Mark as skipped
- [ ] `ralph_impl.md` - Mark as skipped
- [ ] `ralph_plan.md` - Mark as skipped
- [ ] `ralph_research.md` - Mark as skipped

**Time**: 1-2 hours (depends on adaptation depth)

---

## Files Reference

### Currently Available & Tested
```
✅ .claude/commands/ (27 files)
   - 9 ready to use (no external dependencies)
   - 14 need minor adaptation
   - 4 can be skipped

✅ .claude/agents/ (6 files)
   - All generic and reusable

✅ hack/ (10 scripts)
   - 2 adapted (create_worktree.sh, cleanup_worktree.sh)
   - 4 ready to use (port-utils.sh, run_silent.sh, etc.)
   - 4 specialized (icon generation - optional)
```

### Documentation Generated
- `REUSE_PLAN.md` - Original plan from HumanLayer
- `ADAPTATIONS.md` - Detailed adaptation tracking
- `IMPLEMENTATION_SUMMARY.md` - Quick reference of what's done
- `IMPLEMENTATION_CHECKLIST.md` - This file

---

## Quick Start

### Try These Commands Now (No Adaptation Needed)
```bash
# List all available commands
ls -1 .claude/commands/

# View a command
cat .claude/commands/commit.md

# Test a script
./hack/cleanup_worktree.sh
```

### Test Case: Create & Clean Worktree
```bash
# Create a worktree
./hack/create_worktree.sh my-feature main

# List worktrees
git worktree list

# Clean it up
./hack/cleanup_worktree.sh my-feature
```

---

## Decision Points for Phase 3

### Decision 1: HumanLayer CLI References
**Commands affected**: 14 files

**Options**:
- **Skip**: Don't use these commands, remove from repo
- **Strip**: Remove HumanLayer references, keep structure
- **Adapt**: Replace with equivalent manual workflow

**Recommendation**: Strip (remove `humanlayer` tool calls, keep planning structure)

### Decision 2: Linear.app Integration
**Commands affected**: 8 files

**Options**:
- **Skip**: Don't use Linear integration, remove or ignore
- **Adapt**: Create GitHub variant if needed
- **Keep**: Use web search instead of API integration

**Recommendation**: Skip Linear-specific commands, use web search instead

### Decision 3: Oneshot & Handoff Workflows
**Commands affected**: 4 files (`oneshot.md`, `create_handoff.md`, `resume_handoff.md`)

**Options**:
- **Skip**: These are HumanLayer-specific
- **Adapt**: Recreate for your workflow (complex)

**Recommendation**: Skip (HumanLayer-specific, no direct equivalent)

---

## Success Criteria

### Phase 1 ✅
- [x] All files copied
- [x] Scripts executable
- [x] No errors during copy

### Phase 2 ✅
- [x] SWD pattern applied
- [x] Scripts work from any directory
- [x] HumanLayer dependencies removed from scripts

### Phase 3 (Pending)
- [ ] Decide on HumanLayer CLI references
- [ ] Decide on Linear.app references
- [ ] Decide on HumanLayer-specific workflows
- [ ] Adapt selected commands
- [ ] Test all retained commands
- [ ] Update documentation of changes

---

## Next Actions

1. **Review** this checklist and IMPLEMENTATION_SUMMARY.md
2. **Decide** which Phase 3 approach to use (see Decision Points)
3. **Start** adapting commands based on your decision
4. **Test** commands in Claude Code
5. **Document** any customizations in ADAPTATIONS.md

---

## Notes

- All scripts are location-independent and can be called from anywhere
- Generic commands are ready to use immediately
- Phase 3 is optional if you don't need the specialized commands
- All changes are documented in ADAPTATIONS.md for future reference
