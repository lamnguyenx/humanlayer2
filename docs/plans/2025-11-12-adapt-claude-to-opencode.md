# Adapt .claude/ to .opencode/ Configuration

## Overview

Adapt the existing `.claude/` configuration directory to OpenCode's `.opencode/` format, converting agents to subagents and updating all configuration files to match OpenCode's schema and conventions.

**IMPORTANT**: All adapted agents and commands must use the model `opencode/grok-code` (Grok Code Fast 1 via OpenCode Zen). Do not use any other models during this migration.

## Current State Analysis

The project currently uses Claude-specific configuration in `.claude/` with:
- 6 specialized agents in `agents/` directory
- 21 custom commands in `commands/` directory  
- Settings in `settings.json` with permissions, MCP config, and environment variables

All functionality needs to be preserved while migrating to OpenCode's format.

## Desired End State

- `.opencode/` directory with proper OpenCode structure
- All agents converted to subagents with correct frontmatter
- All commands updated to OpenCode format
- Configuration migrated to `opencode.json` with proper schema
- Full compatibility with OpenCode agent and command system

### Key Discoveries:
- Agents use Claude-specific frontmatter (`name`, `tools` as comma-separated)
- Commands have basic frontmatter but may need `agent` specifications
- Settings use custom permission format not matching OpenCode schema

## What We're NOT Doing

- Modifying agent prompt content or functionality
- Changing command behavior or templates
- Altering permission logic or environment variables
- Adding new agents or commands

## Implementation Approach

Incremental migration following OpenCode documentation:
1. Directory restructuring
2. Agent file format conversion
3. Command file updates
4. Configuration schema migration
5. Verification of compatibility

## Phase 1: Directory Restructuring

### Overview
Rename directories to match OpenCode structure and create new location.

### Changes Required:

#### 1. Directory Creation
**Command**: `cp -r .claude .opencode`

#### 2. Subdirectory Renames  
**Commands**:
```bash
cd .opencode
mv agents agent
mv commands command
```

### Success Criteria:

#### Automated Verification:
- [ ] Directory structure matches OpenCode: `.opencode/agent/`, `.opencode/command/`
- [ ] All files preserved in new locations
- [ ] `.claude/` directory remains intact as ground truth
- [ ] Git shows additions for `.opencode/`: `git status` shows new files, not renames

#### Manual Verification:
- [ ] No file content lost in moves
- [ ] Directory structure correct

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to content migration.

---

## Phase 2: Agent File Migration

### Overview
Convert all 6 agent files from Claude format to OpenCode subagent format.

### Changes Required:

#### 1. Frontmatter Updates
**Files**: `.opencode/agent/*.md`

For each agent file:
- Remove `name:` field
- Add `mode: subagent`
- Convert `tools:` from "Read, Grep, Glob, LS" to:
```yaml
tools:
  read: true
  grep: true
  glob: true
  list: true
```
- Update `model:` to `xai/grok-code-fast-1` for all agents (use this specific model for all adapted agents)

**Example transformation**:
```yaml
# Before
---
name: codebase-analyzer
description: Analyzes codebase implementation details...
tools: Read, Grep, Glob, LS
model: sonnet
---

# After  
---
description: Analyzes codebase implementation details...
mode: subagent
tools:
  read: true
  grep: true
  glob: true
  list: true
model: opencode/grok-code
---
```

### Success Criteria:

#### Automated Verification:
- [ ] All 6 agent files have valid YAML frontmatter
- [ ] No `name:` fields remain
- [ ] All files have `mode: subagent`
- [ ] Tools converted to object format
- [ ] All models set to `xai/grok-code-fast-1`

#### Manual Verification:
- [ ] Agent descriptions and prompts unchanged
- [ ] File naming matches intended agent names

---

## Phase 3: Command File Migration

### Overview
Review and update 21 command files to OpenCode format.

### Changes Required:

#### 1. Frontmatter Updates
**Files**: `.opencode/command/*.md`

For each command file:
- Update `model:` to `xai/grok-code-fast-1` for all commands (use this specific model for all adapted commands)
- Add `agent:` field where appropriate (for commands that should run as subagents)
- Ensure `description:` field exists

**Example**:
```yaml
# Before
---
description: Create git commits with user approval...
---

# After
---
description: Create git commits with user approval and no Claude attribution
agent: build
model: opencode/grok-code
---
```

### Success Criteria:

#### Automated Verification:
- [ ] All 21 command files have valid YAML frontmatter
- [ ] All models set to `xai/grok-code-fast-1`
- [ ] No syntax errors in frontmatter

#### Manual Verification:
- [ ] Command templates and descriptions preserved
- [ ] Agent assignments appropriate for command purposes

---

## Phase 4: Configuration Migration

### Overview
Convert `settings.json` to `opencode.json` with proper OpenCode schema.

### Changes Required:

#### 1. File Rename and Schema Conversion
**File**: `.opencode/opencode.json`

Convert from:
```json
{
  "permissions": {
    "allow": ["Bash(./hack/spec_metadata.sh)", "Bash(hack/spec_metadata.sh)", "Bash(bash hack/spec_metadata.sh)"]
  },
  "enableAllProjectMcpServers": false,
  "env": {
    "MAX_THINKING_TOKENS": "32000"
  }
}
```

To OpenCode format:
```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "bash": {
      "./hack/spec_metadata.sh": "allow",
      "hack/spec_metadata.sh": "allow", 
      "bash hack/spec_metadata.sh": "allow"
    }
  },
  "mcp": {
    "enableAllProjectMcpServers": false
  },
  "env": {
    "MAX_THINKING_TOKENS": "32000"
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Valid JSON with OpenCode schema
- [ ] Permissions converted to correct format
- [ ] MCP settings properly mapped
- [ ] Environment variables preserved

#### Manual Verification:
- [ ] Permission logic equivalent to original
- [ ] MCP configuration correct

---

## Testing Strategy

### Unit Tests:
- YAML frontmatter parsing for all agent/command files
- JSON schema validation for opencode.json

### Integration Tests:
- OpenCode can load the .opencode directory
- Agents appear in agent list with correct modes
- Commands appear in command list

### Manual Testing Steps:
1. Run `opencode` and verify .opencode directory is recognized
2. Check that all subagents are available with @ mentions
3. Test that commands appear in / command list
4. Verify configuration loads without errors

## Performance Considerations

Migration is configuration-only with no runtime impact. File operations are minimal.

## Migration Notes

- All original functionality preserved
- No breaking changes to agent/command behavior
- Configuration more structured and maintainable

## References

- OpenCode agents documentation: `docs/agents.mdx`
- OpenCode commands documentation: `docs/commands.mdx`
- OpenCode config documentation: `docs/config.mdx`