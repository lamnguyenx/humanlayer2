When documenting protocols with Mermaid sequence diagrams, choosing how to represent error paths depends entirely on the audience and the primary goal of the diagram.
In popular open-source projects (like Kubernetes, OpenID/OAuth, and various RFC-like specifications), readability is prioritized over strict UML compliance.
Here is a breakdown of how open-source projects use these three approaches, followed by a guide on which one to use based on your focus.
1. Inline Parenthetical / Multi-label Arrows
sequence diagram
Client->>Server: Request Data
Server-->>Client: Success Data (or Error Code)

• What it looks like: Server-->>Client: 200 OK / 401 Unauthorized or Server-->>Client: Result (or Error)
• Open-Source Prevalence: Very High (The Default for Overview Docs). You will see this constantly in OAuth2/OIDC documentation or API overviews where the focus is the "happy path," but developers need a quick reminder that an error can happen there.
• Best Use Case: When the diagram is meant to show the core flow and errors are a secondary concern. It completely avoids visual clutter, keeping the diagram linear and easy to read top-to-bottom.
• Downside: It cannot show what happens next if an error occurs (e.g., if the client needs to retry or clear its cache).
2. Mermaid’s break Directive
sequence diagram
Client->>Server: Initialize Session
critical Validate Token
    Server->>Auth: Check Token
    option Token Invalid
        break Error: 401 Unauthorized
            Server-->>Client: Return Error & Exit
        end
end
Server-->>Client: Session Created

• What it looks like: A boxed area labeled break that contains the error response and indicates the rest of the diagram is skipped.
• Open-Source Prevalence: Low to Moderate. While idiomatic to Mermaid for exceptions, many open-source maintainers avoid it because it renders as a heavy, nested box that can make the diagram look vertically bloated.
• Best Use Case: When an error results in an immediate abort or early exit of the entire sequence, and you want to explicitly show that subsequent steps are skipped without wrapping the entire rest of the diagram in an else clause.
• Downside: It can be jarring to read because it interrupts the visual flow, and it's less intuitive to non-technical stakeholders than an alt/else block.
3. Explicit alt / else Blocks
sequence diagram
Client->>Server: Submit Payment
alt Payment Successful
    Server-->>Client: 200 Success Receipt
else Insufficient Funds
    Server-->>Client: 402 Error (Declined)
else Timeout
    Server-->>Client: 504 Gateway Timeout
end

• What it looks like: A partitioned box (alt / else) branching into multiple distinct paths.
• Open-Source Prevalence: High (The Default for Technical/Implementation Docs). This is the standard when documenting state machines, cryptographic handshakes, or consensus protocols (like Raft or Paxos).
• Best Use Case: When errors are the focus or when the system behaves significantly differently depending on the error (e.g., Error A triggers a retry, while Error B triggers a fallback to a different service).
• Downside: If overused, it leads to "box fatigue." Nesting multiple alt blocks makes Mermaid diagrams incredibly wide, poorly spaced, and difficult to read on GitHub markdown pages.
Summary: Which approach should you use?
Rule 1: If the core flow is the focus (Errors are secondary)
Use Approach 1 (Inline text) or separate diagrams entirely.
If your goal is to onboarding a developer to how a feature works, do not use alt or break blocks for standard validation errors. Instead, use a dual-label arrow like Server-->>Client: 200 OK (or 4xx/5xx Error).
If an error path is complex but secondary, popular projects often use a two-diagram approach:
1. One clean diagram for the Happy Path.
2. A separate, dedicated diagram below it titled "Error Handling: Token Expiration" using alt blocks.
Rule 2: If errors are the focus (or change the system state)
Use Approach 3 (alt / else blocks).
If you are writing an architectural decision record (ADR) or documenting a security protocol where the error path is the core concern (e.g., how the system handles a partial network partition), use an alt/else block. It explicitly maps out the diverging logic.
Rule 3: Avoid break unless it's a critical fatal error
Reserve the break directive strictly for "unrecoverable system failure" or "early exit" guard clauses at the very beginning of a sequence (e.g., alt if unauthenticated -> break). For standard business-logic errors, an alt/else block or inline label is much more readable.