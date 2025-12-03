**Planning Task: How to Reuse HumanLayer's `dot-claude/` Files in Your Own Repository**

Create a practical, step-by-step plan for reusing HumanLayer's Claude Code command and agent files (from `__submodules__/humanlayer/humanlayer/dot-claude/`) in your own repository with minimal effort.

**Analysis Goals:**

1. **Identify what can be copied as-is** (no changes needed):
   - Which command files have no external dependencies?
   - Which agent files are generic and reusable?
   - Count files and estimate copy time

2. **Identify what needs adaptation** (minor edits):
   - Which files reference `humanlayer` CLI commands? (replaceable with manual instructions)
   - Which files reference `hack/` shell scripts? (replaceable with git/bash commands)
   - Which files have hardcoded paths (like `thoughts/shared/...` or `humanlayer-wui/`)?
   - Which files reference external systems (Linear, etc.)?
   - For each: estimate effort and provide search/replace patterns

3. **Map dependencies and integration points**:
   - Files that call other commands (dependency chain)
   - Files that require external services
   - Files with heavy repository-specific paths
   - Group files by adaptation complexity

4. **Create a reuse strategy with phases**:
   - **Phase 1 (Week 1)**: Copy foundation files, get started immediately
   - **Phase 2 (Week 2)**: Add files needing minor changes
   - **Phase 3 (Week 3)**: Integrate files with medium changes
   - **Phase 4+ (Weeks 4+)**: Complete system integration and customization
   - Include estimated time per phase

5. **Provide actionable templates**:
   - For each file type needing changes, show BEFORE/AFTER examples
   - Provide generic search/replace patterns applicable to multiple files
   - Create a copy/paste checklist
   - Show minimal vs. complete setup options

**Constraints to Address:**

- **The `humanlayer` CLI is not available** in your repo:
  - `humanlayer thoughts sync` → replace with file system operations
  - `humanlayer launch` → replace with Claude Code instructions
  - `npx humanlayer` → replace with manual workflows

- **The `hack/` scripts are specific to HumanLayer**:
  - `hack/create_worktree.sh` → replace with `git worktree` commands
  - `hack/spec_metadata.sh` → replace with manual YAML frontmatter
  - `hack/port-utils.sh` → likely not needed for your use case

- **Path structure is different**:
  - `thoughts/shared/plans/` → map to your docs structure
  - `humanlayer-wui/`, `hld/`, `hlyr/` → replace with your repo paths
  - `~/.humanlayer/` → replace with your config/log locations

- **External integrations must be adapted**:
  - Linear ticket references → adapt to your issue tracker
  - HumanLayer-specific workflows → adapt to your team's process

**Expected Output:**

A comprehensive reuse plan including:
1. List of files (grouped by complexity)
2. Dependency analysis (what calls what)
3. Tiered adaptation strategy (quick wins first)
4. Search/replace patterns for common changes
5. Before/after examples for key files
6. Copy/paste checklist
7. Quick start instructions (minimal setup)
8. Full setup checklist (complete integration)
9. File-by-file adaptation guide
10. Integration milestones and success metrics
