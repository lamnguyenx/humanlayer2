# How to Write a GitHub Issue for Minor Improvement Tracking

1. **Use a descriptive prefix in the title**. Start with `[Cleanup]`, `[Improvement]`, `[Refactor]`, `[Docs]`, or `[Dependencies]` followed by a brief category description. This immediately signals the type of work and helps with filtering.

2. **Write a one-sentence overview**. State what category of improvements this covers and why it matters. Keep it under 20 words.

3. **Define scope boundaries explicitly**. Use "Included:" and "Not Included:" to prevent scope creep. This stops the issue from becoming a dumping ground for unrelated tasks.

4. **Make each checkbox item specific and verifiable**. Include (1) file paths or line numbers, (2) specific version numbers for dependencies, (3) links to related issues or PRs when completed. Each item should be concrete enough that someone can mark it done without debate.

5. **Group related items under category subheadings**. Use `####` headings to organize tasks by file, component, type, or priority. This makes it easier to scan and assign work.

6. **Add verification commands when applicable**. Include the command to run that confirms all tasks are complete. This makes the definition of "done" objective and testable.

7. **Track progress visibly at the bottom**. Add a progress line showing completed vs total tasks. GitHub auto-generates a progress bar from checkboxes, but a manual count helps when viewing the issue body directly.

## Example:

````markdown
# RULE 1: Use a descriptive prefix in the title
---
title: [Cleanup] Fix all ESLint warnings in /src/components
labels: cleanup, code-quality, tracking
---

# [Cleanup] Fix all ESLint warnings in /src/components

## Minor Improvement Tracking

# RULE 2: Write a one-sentence overview
### Overview
Remove all ESLint warnings from component files to enable strict linting in CI.

# RULE 3: Define scope boundaries explicitly
### Scope
**Included:** ESLint warnings in `/src/components` directory only
**Not Included:** TypeScript migration (tracked in #789), performance optimizations, test files

# RULE 4: Make each checkbox item specific and verifiable
# RULE 5: Group related items under category subheadings
### Checklist

#### Authentication Components (High Priority)
- [x] Remove unused imports in `src/components/Login.js:3, 7` - Fixed in #442
- [x] Add PropTypes to `src/components/Signup.js` - Fixed in #445
- [ ] Fix accessibility labels in `src/components/PasswordReset.js:23`
- [ ] Remove console.log in `src/components/AuthContainer.js:67, 89`

# RULE 4: Make each checkbox item specific and verifiable (variation: with version numbers)
#### Dependencies to Update
- [x] axios: 0.21.1 → 1.6.2 - Fixed in #892
- [ ] react-router-dom: 5.2.0 → 6.8.0
- [ ] lodash: 4.17.20 → 4.17.21

# RULE 5: Group related items under category subheadings (variation: by file location)
#### Dashboard Components
- [ ] Fix unused variable warning in `src/components/Header.js:45`
- [ ] Add missing key prop in `src/components/UserList.js:102`
- [ ] Remove deprecated lifecycle method in `src/components/Sidebar.js:34`

# RULE 5: Group related items under category subheadings (variation: by type of work)
#### Utility Components
- [x] Fix prop-types validation in `src/components/Button.js` - See commit a1b2c3d
- [ ] Add default props to `src/components/Modal.js`
- [ ] Fix exhaustive-deps warning in `src/components/Dropdown.js:56`

# RULE 6: Add verification commands when applicable
### Verification
Run: `npm run lint -- src/components`
Expected: 0 warnings

# RULE 6: Add verification commands when applicable (variation: multiple commands)
Alternative verification:
Run: `npm audit --production`
Expected: 0 high/critical vulnerabilities

### Notes
- Follow existing patterns in `src/components/Avatar.js` for PropTypes
- Use ESLint disable comments only if absolutely necessary (document why)
- Tag @frontend-team for review on accessibility fixes

# RULE 7: Track progress visibly at the bottom
---

**Progress: 3 of 10 tasks completed (30%)**
*Last updated: 2025-12-31*

*Please link your PR to this issue when addressing any item.*

# RULE 7: Track progress visibly at the bottom (variation: with deadline)
---

**Progress: 1 of 6 packages updated (17%)**
*Target completion: End of Q1 2025*
*Last updated: 2025-12-31*
````