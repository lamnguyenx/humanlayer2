**Research Task: Identify Commands Requiring Installation from This Repository**

Analyze all documentation files in the repository to identify which shell commands must be installed from this repository versus which are standard development tools or external dependencies.

**Research Steps:**

1. **Search for all command references** in documentation using patterns like:
   - Backtick-enclosed commands: `` `command` ``
   - Code blocks with shell commands
   - Any documentation mentioning executable commands

2. **For each command found, determine its source:**

   **Commands that MUST be installed from this repository:**
   - Built/compiled from this repository's source code
   - Distributed as binaries or packages from this repo
   - Custom tools specific to this project

   **Scripts included with the repository:**
   - Shell/utility scripts bundled in the repository
   - Helper scripts that are part of the codebase
   - Don't require separate installation

   **Standard development tools:**
   - Operating system commands (`ls`, `cd`, `bash`, etc.)
   - Version control (`git`, `svn`, etc.)
   - Package managers (`npm`, `pip`, `cargo`, etc.)
   - Build tools (`make`, `cmake`, etc.)
   - Language runtimes (`node`, `python`, `go`, etc.)

   **External/third-party tools:**
   - CLI tools from other projects (`gh`, `docker`, `kubectl`, etc.)
   - Platform-specific tools (`brew`, `apt`, etc.)

3. **Verify command implementations:**
   - Check package.json/package files for published binaries
   - Look for source code implementing custom commands
   - Examine build scripts and CI/CD for compilation steps
   - Check if commands are built from the repository's source

4. **Document findings** with:
   - List of repository-specific commands requiring installation
   - List of bundled scripts (no installation needed)
   - Confirmation that other commands are standard/external tools
   - Source locations for each repository command

**Expected Output:**
A clear categorization of all commands found, with installation requirements identified.
