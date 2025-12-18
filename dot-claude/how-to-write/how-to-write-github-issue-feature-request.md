# How to Write a GitHub Issue Feature Request

1. **Start with clear frontmatter and title**. Include labels, priority (optional), and an action-oriented title that describes what will be built or changed.

2. **Provide overview and background context**. The overview states the goal in one sentence. The background (optional but recommended) explains why this matters now, referencing real problems, incidents, or gaps.

3. **Write a proper user story in the standard format**. Use "As a [role], I want to [action], So that [benefit]" to clarify who needs this and why.

4. **List functional requirements as concrete deliverables**. Focus on what must be built or configured, not how. Each requirement should be a noun phrase describing a tangible output.

5. **Define acceptance criteria as specific, testable checkboxes**. Each criterion should be verifiable (installed, runs, covers X, achieves Y%). Nest sub-criteria under main items when showing detailed coverage. Avoid vague terms like "basic" or "main."

6. **Include technical notes that guide implementation (optional)**. Reference existing project structure, patterns to follow, and specific directories or commands. This helps maintainers understand where the work fits.

7. **Add a proposed implementation section with numbered steps (optional)**. Show the logical sequence of work from installation to integration. Include specific commands and file paths.

8. **Define success metrics with numbers and timeframes (optional but valuable)**. State how you'll measure whether this feature succeeded (reduce bugs by X%, save Y hours, catch Z% of issues).

9. **Document alternatives considered with brief pros/cons (optional but recommended)**. List 2-3 alternatives and mark the chosen one with ✅. This shows you've done research and prevents "why not use X?" comments.

10. **Link related issues and specify dependencies (optional)**. Use "Depends on," "Blocks," "Related to" with issue numbers. This helps with project planning and prevents duplicate work.

11. **Estimate effort in concrete time units (optional)**. Give a range (2-3 days) with optional breakdown. This helps with sprint planning and prioritization.

---

## Required vs Optional Sections

| Section | Required? | When to Include |
|---------|-----------|-----------------|
| Title & Labels | Required | Always needed for categorization |
| Overview | Required | Always needed to state the goal |
| User Story | Required | Always needed to clarify who and why |
| Requirements | Required | Always needed to define deliverables |
| Acceptance Criteria | Required | Always needed for verification |
| Background | Optional | Include when justifying urgency or referencing incidents |
| Technical Notes | Optional | Include for complex codebases or specific patterns |
| Proposed Implementation | Optional | Include for complex tasks or to guide contributors |
| Success Metrics | Optional | Include when measuring performance or business impact |
| Alternatives Considered | Optional | Include when multiple approaches exist |
| Related Issues | Optional | Include when dependencies affect planning |
| Estimated Effort | Optional | Include to help with prioritization |
| Priority | Optional | Include if using formal priority system |

---

## Example:

```markdown
# RULE 1: Start with clear frontmatter and title
---
title: Add Automated Testing Framework
labels: feature-request, testing
priority: medium  # Optional
---

# Add Automated Testing Framework

## Feature Request

# RULE 2: Provide overview and background context
### Overview
Add an automated testing framework to ensure code reliability and catch regressions early.

### Background  # Optional but recommended
Current lack of automated testing led to production incidents (#234, #267). Manual testing takes 4+ hours per release.

# RULE 3: Write a proper user story in the standard format
### User Story
- **As a** developer
- **I want to** run automated tests
- **So that** I can verify changes without manual testing

# RULE 4: List functional requirements as concrete deliverables
### Requirements
- Testing framework installation and configuration
- Test scenarios for core features
- CI/CD pipeline integration
- Test documentation for team

# RULE 5: Define acceptance criteria as specific, testable checkboxes
### Acceptance Criteria
- [ ] Framework v2.0+ installed with config files
- [ ] Test suite covers:
  - [ ] Authentication (login/logout)
  - [ ] CRUD operations
  - [ ] Error handling
- [ ] Tests run in CI pipeline
- [ ] Test execution under 5 minutes
- [ ] 80% coverage of critical paths
- [ ] Documentation in TESTING.md

# RULE 6: Include technical notes (optional)
### Technical Notes
- Store tests in `tests/` directory
- Use Page Object pattern (see existing patterns)
- Configure 4 parallel workers for CI

# RULE 7: Add proposed implementation steps (optional)
### Proposed Implementation
1. Install: `npm install -D testing-framework`
2. Create config file with multi-environment setup
3. Create test helpers in `tests/helpers/`
4. Write test suite in `tests/specs/`
5. Update CI config to run tests
6. Document in TESTING.md

# RULE 8: Define success metrics (optional but valuable)
### Success Metrics
- Reduce production bugs by 50% in 3 months
- Catch 90% of regressions before merge
- Decrease manual testing from 4 hours to 30 minutes

# RULE 9: Document alternatives (optional but recommended)
### Alternatives Considered
- **Option A**: Mature but slower (2x execution time)
- **Option B**: Industry standard but complex setup
- **Option C**: ✅ Selected for speed and modern API
- **Option D**: Simple but lacks needed features

# RULE 10: Link related issues (optional)
### Related Issues
- Related to #189 (Improve code quality)
- Depends on #301 (Stabilize API)
- Blocks #234 (Deployment pipeline)

# RULE 11: Estimate effort (optional)
### Estimated Effort
**3-4 days** (1 day setup, 2 days tests, 1 day docs)
```

---

## Minimal Valid Example

```markdown
---
title: Add User Export Feature
labels: feature-request
---

# Add User Export Feature

## Feature Request

### Overview
Add ability to export user data to CSV for reporting and compliance.

### User Story
- **As an** administrator
- **I want to** export user data to CSV
- **So that** I can generate reports and meet compliance requirements

### Requirements
- Export button in admin panel
- CSV generation with all user fields
- Date range filtering
- Email delivery of export file

### Acceptance Criteria
- [ ] Export button on admin user list page
- [ ] CSV includes name, email, role, created date
- [ ] Date range filter for time periods
- [ ] Export sent to admin email within 5 minutes
- [ ] Handles 10,000+ users without timeout
```