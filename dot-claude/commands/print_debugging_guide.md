I'm encountering [ERROR/ISSUE] in my application. Please propose and show code changes to add targeted diagnostics that I can copy-paste.

## Debugging Guidelines:

### 0) Collections and iterations logging:
- For collections: log size, empty status, and up to first N sample items (e.g., 3)
- For large collections, avoid full dumps; truncate with "…(N of size=XYZ)"
- For maps/dictionaries: sample a few key→value pairs; mask sensitive data
- **For loops/iterations: use sparse progress logging at milestones (e.g., every 5%, 10%, 25%)**
  - Log iteration details (current item, index, state) only at these milestones
  - Include: progress percentage, current item details, elapsed time
  - Example: "Processing item 50/1000 (5%): recordId=abc123, size=2048KB, elapsed=1.2s"

### 1) Insert logging statements at key execution points:
- Entry/exit of public functions/methods and critical code paths
- Before/after network calls, database operations, file I/O, and inter-process communication
- Before/after conditional branches and early returns
- At error boundaries and exception handlers

### 2) Print object/variable state with safety:
- For each relevant object/parameter: log null/undefined status, type, identity (hash/reference), and key fields
- Use safe rendering to avoid errors during logging (null checks, toString guards)
- For complex data structures (dictionaries, maps, request/response objects): log keys/types and representative values
- Avoid circular reference issues in object serialization

### 3) Track framework lifecycle (if applicable):
- For components with lifecycle (Activities, Components, Services, Controllers, etc.): add logs to initialization, mounting, updating, and cleanup phases
- Include instance identity and state information
- Log parent-child relationships and dependency injection points

### 4) Log concurrency/async context:
- Include thread/process/worker name and identifier
- For async operations (promises, futures, coroutines, async/await): log execution context, state, and dispatcher/executor info
- Around context switches: log before/after with execution environment details
- Track async operation start, completion, cancellation, and timeout

### 5) Error and exception handling:
- Wrap risky operations in try-catch/error handling blocks
- On error: log error message, cause/inner exception, and stack trace
- Add unique correlation IDs to tie related logs together across async boundaries
- Log error context: what operation was being performed, with what inputs

### 6) Performance and timing:
- Add timing markers and duration measurements around potentially slow operations
- For iterations: track cumulative time and log at progress milestones
- Log memory usage if relevant to the issue
- Track resource acquisition and release (connections, file handles, locks)

### 7) Privacy and safety:
- Do not log PII (personally identifiable information), authentication tokens, passwords, or sensitive payloads
- Mask or hash sensitive data when logging is necessary
- Truncate large payloads; log metadata instead of full content
- Follow your organization's security and compliance guidelines

### 8) Log formatting best practices:
- Use appropriate log levels: DEBUG/TRACE for verbose info, WARN for anomalies, ERROR for failures
- Include timestamps (ISO 8601 format preferred)
- Use structured logging when possible (JSON or key-value pairs)
- Add contextual tags: component name, operation type, correlation ID
- Make logs grep-able and searchable

## Context to provide:

- **Language/Framework**: [e.g., Python/Django, JavaScript/Node.js, Java/Spring Boot]
- **Error/Issue**: [Describe the specific problem you're encountering]
- **Affected code**: [Mention relevant files, classes, or modules]
- **Environment**: [Version numbers, logging library, async model if applicable]
- **Constraints**: [Any performance concerns, production limitations, or logging restrictions]

