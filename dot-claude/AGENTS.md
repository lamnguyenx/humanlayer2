# Git Repo Manager TUI - Implementation Guide

## Project Overview

This is a k9s-inspired terminal UI application written in Go that discovers and monitors git repositories. Users register parent directories, and the app recursively finds all git repos within them, displaying their status, branch, and last commit.

## Architecture

### Directory Structure

```
gg/
├── config/       # Configuration management (TOML persistence)
├── git/          # Git status queries (read-only operations)
├── models/       # Data structures (Directory, Repository, Config)
├── scanner/      # Recursive directory scanning with symlink safety
├── tui/          # Terminal UI (tview integration)
├── main.go       # Application entry point
├── go.mod        # Go module definition
└── README.md     # User documentation
```

### Core Components

**models/models.go**
- `Directory`: Represents a registered parent directory
- `Repository`: Represents a discovered git repo with status, branch, commit info
- `Config`: Container for registered directories

**config/config.go**
- `Manager`: Loads/saves configuration to `~/.config/gg/dirs.toml`
- Methods: `Load()`, `Save()`, `AddDirectory()`, `RemoveDirectory()`
- All paths are resolved to absolute paths and follow symlinks

**scanner/scanner.go**
- `Scanner`: Recursively discovers git repos in registered directories
- Prevents infinite loops by tracking visited real paths (post-symlink-resolution)
- Always recurses into subdirectories to find nested repos
- Returns `[]Repository` with relative names and absolute paths

**git/git.go**
- `GetStatus()`: Queries git status for a repository
- Queries: branch name, last commit message (truncated), clean/dirty state
- Sets status to "missing" if path doesn't exist
- Read-only operations (no git mutations)

**tui/tui.go**
- `App`: Main TUI application struct
- `NewApp()`: Initializes TUI, loads config, performs initial scan
- `buildUI()`: Constructs tview layout (list + details + status)
- `handleInput()`: Keyboard input (`:` for command mode, Ctrl+C/ESC to quit)
- `executeCommand()`: Parses and executes commands
- `performScan()`: Rescans all directories and queries git status

## Key Design Decisions

### 1. Discovered Repos NOT Stored in Config
- Only registered directories stored in `dirs.toml`
- Repos discovered at runtime via scanning
- Benefit: Config stays minimal, gracefully handles additions/deletions

### 2. Symlink Safety
- Use `filepath.EvalSymlinks()` to resolve symlinks to real paths
- Track visited real paths in a map to prevent loops
- Store absolute paths in results for clarity

### 3. Nested Repository Support
- Scanner always recurses into subdirectories (doesn't stop at first `.git`)
- Correctly discovers both `/projects/foo` and `/projects/foo/bar`
- Relative names use parent directory as reference

### 4. Git Status Only (Read-Only)
- No git mutations: push, pull, fetch, merge, etc.
- Safe read-only operations for monitoring
- Can be run on any directory without risk

### 5. Synchronous Scanning
- Initial version uses synchronous directory traversal and git queries
- Suitable for repositories <1000 repos
- Future versions can add async spinner/progress for large datasets

## Commands

| Command | Implementation |
|---------|-----------------|
| `:help` | Shows help modal with all keybindings and commands |
| `:quit` | Calls `app.Stop()` to cleanly exit |
| `:update` | Calls `performScan()` and refreshes UI |
| `:register <path>` | Calls `configManager.AddDirectory()`, then rescans |
| `:remove <path>` | Calls `configManager.RemoveDirectory()`, then rescans |

## UI Layout

```
┌────────────────────┬──────────────────────┐
│   Repositories     │                      │
│ ─────────────────  │      Details         │
│  app1 [clean]     │                      │
│  app2 [dirty]     │  Name: app1          │
│  nested/app3 [..] │  Path: /path/to/app1│
│                   │  Branch: main        │
│                   │  Status: clean       │
│                   │  Last Commit: ...    │
└────────────────────┴──────────────────────┘
Status: Ready
```

## Keybindings

```
:           - Enter command mode
ESC         - Exit command mode or app
Ctrl+C      - Quit app
Ctrl+U      - Trigger :update
Ctrl+H      - Show help modal
Arrow Keys  - Navigate repo list
```

## Testing Approach

### Manual Test Scenarios

1. **Initial Setup**
   - Start fresh with no registered directories
   - Verify empty repo list
   - Use `:register` to add a directory

2. **Directory Scanning**
   - Register multi-level directory with multiple repos
   - Verify all repos discovered with correct names
   - Use `:update` to rescan

3. **Nested Repos**
   - Create directory structure: `/projects/foo/.git` and `/projects/foo/bar/.git`
   - Verify both repos appear as "foo" and "foo/bar"

4. **Symlinks**
   - Create symlink to repo directory
   - Register via symlink
   - Verify repos show absolute paths (symlink resolved)
   - Create circular symlink, verify no infinite loop

5. **Status Detection**
   - Create clean repo (committed changes)
   - Create dirty repo (modified files)
   - Verify status display is correct
   - Test missing repo detection by deleting a repo

6. **Commands**
   - Test paths with spaces in `:register`
   - Test invalid commands
   - Verify error messages display

7. **UI Navigation**
   - Arrow keys navigate list
   - Detail pane updates on selection
   - Help modal opens/closes correctly

## Dependencies

- `github.com/rivo/tview` - Terminal UI framework
- `github.com/gdamore/tcell/v2` - Terminal control (via tview)
- `github.com/pelletier/go-toml/v2` - TOML parsing
- Standard library: `os`, `path/filepath`, `exec`, `time`, `strings`

## Build & Run

```bash
# Build binary
go build -o gg ./

# Run application
./gg
```

## Configuration File

Location: `~/.config/gg/dirs.toml`

Format (TOML):
```toml
[[directories]]
path = "/home/user/projects"

[[directories]]
path = "/home/user/work"
```

## Status Indicators

- **clean**: No uncommitted changes
- **dirty**: Has uncommitted changes or untracked files
- **missing**: Path no longer exists on disk
- **error**: Failed to query git status (permission error, etc.)
- **unknown**: Status not yet queried (initial state before `:update`)

## Performance Considerations

- Scanning: O(n) where n = number of directories and files
- Git status queries: Sequential, one per discovered repo
- Memory: All repos kept in memory (suitable for <10k repos)
- UI updates: Full redraw on significant changes, drawn with tview

## Future Enhancements

- Async scanning with spinner for large directory trees
- Filtered view (show only dirty repos)
- Search/fuzzy find repositories
- Git operations (pull, fetch status)
- Custom sorting (by branch, status, last update)
- Config file editor UI
- Repository statistics (commits today, last update time)
