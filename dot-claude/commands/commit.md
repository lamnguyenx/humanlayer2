---
description: Create git commits with user approval and no AI attribution
---

# Commit Changes

You are tasked with creating git commits for the changes made during this session.

## Process:

1. **Think about what changed:**
   - Review the conversation history and understand what was accomplished
   - Run `git status` to see current changes
   - Run `git diff` to understand the modifications
   - Consider whether changes should be one commit or multiple logical commits

2. **Plan your commit(s):**
   - Identify which files belong together
   - Draft commit messages following the structure below
   - Use imperative mood in commit messages
   - Focus on why the changes were made, not just what

3. **Present your plan to the user:**
   - List the files you plan to add for each commit
   - Show the commit message(s) you'll use
   - Ask: "I plan to create [N] commit(s) with these changes. Shall I proceed?"

4. **Git Operations - Confirmation Required:**
   Before executing ANY git commit command:
   - Show the proposed commit message and affected files
   - **ASK for explicit confirmation**: "Should I proceed with this commit?"
   - **WAIT** for user's "yes/confirm" response
   - Only then execute the git commit
   - **Never auto-commit without user approval**

5. **Execute upon confirmation:**
   - Use `git add` with specific files (never use `-A` or `.`)
   - Create commits with your planned messages
   - Show the result with `git log --oneline -n [number]`

## Commit Message Structure:

### Title (First Line):
- Use sentence case
- Imperative mood (e.g., "Add feature" not "Added feature")
- Keep concise and descriptive
- **Always use a single `-m` flag for the title**

### Sub-message (Body) - Optional:
Add a sub-message **only when additional context is needed**. When included, the sub-message should be:

- **Concise summaries**: Brief bullet-pointed key insights, avoid lengthy paragraphs
- **Focus on decisions and details**: Emphasize architectural choices and technical implementations
  - Example: "migrated to pwd-based color generation using MD5 hash"
  - Example: "switched from REST to GraphQL for better data fetching control"
- **Minimal file listings**: Only mention file modifications when essential for context
  - Avoid exhaustive lists of every file touched
  - Focus on WHY changes were made, not just WHERE
- **Action-oriented language**: Highlight what changed and the reasoning behind it
  - Good: "Refactor authentication to support OAuth2 providers"
  - Poor: "Updated auth.js, login.js, and config.js"

### Formatting Rules:

**Simple commit (no sub-message needed):**
```bash
git commit -m "Add user authentication system"
```

**Commit with sub-message (when context is needed):**
```bash
git commit -m "Add user authentication system" -m "- Implement JWT-based authentication for API security
- Integrate bcrypt for password hashing (10 rounds)
- Add refresh token rotation to prevent token theft
- Configure session timeout at 24 hours for better UX"
```

**IMPORTANT:**
- Use **maximum 2 `-m` flags**: one for title, one for body (if needed)
- **DO NOT** use multiple `-m` flags for each line
- Include newlines within the second `-m` flag for multi-line bodies
- The sub-message is optional - only add it when the commit needs explanation

### Example Result:
```
Add user authentication system

- Implement JWT-based authentication for API security
- Integrate bcrypt for password hashing (10 rounds)
- Add refresh token rotation to prevent token theft
- Configure session timeout at 24 hours for better UX
```

## Important:
- **NEVER add ANY AI/LLM attribution or co-author information**
- Do not mention: Claude, Cursor, Amp, Kiro, ChatGPT, Copilot, or any other AI tool
- Commits should be authored solely by the user
- Do not include any "Generated with [AI tool]" messages
- Do not add "Co-Authored-By" lines for any AI assistant
- Write commit messages as if the user wrote them personally

## Remember:
- You have the full context of what was done in this session
- Group related changes together
- Keep commits focused and atomic when possible
- The user trusts your judgment - they asked you to commit
- Not every commit needs a sub-message - keep it simple when the title is sufficient