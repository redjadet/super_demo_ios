# Senior coding patterns map (Stackademic 7)

Portfolio honesty map for the habits in
[Stackademic — 7 Coding Patterns Senior Engineers Use…](https://medium.com/stackademic/7-coding-patterns-senior-engineers-use-that-most-developers-learn-too-late-5670bbba0a80)
(friend-link article). This is **not** a mandate to import Java/backend
infrastructure into a SwiftUI offline-first demo.

**Tip pin (inventory):** `bf9b626` (post #70 map + #71/#74 Mac unsigned recipes
index; pattern table unchanged since #70).

| # | Pattern | Status | Where it shows up here | Do not claim |
| ---: | --- | --- | --- | --- |
| 1 | Design for failure (not only happy path) | **Present** (client-shaped) | [`sync-and-networking.md`](../sync-and-networking.md); SPM `IlkerSevimNetworking` retry/backoff/jitter; Feed stale + error/Retry; cancel ≠ server failure | Server circuit breakers / dead-letter queues for JSONPlaceholder |
| 2 | Prefer boring over clever | **Present** | [`layers.md`](../layers.md), [`state-management.md`](../state-management.md), [`agent_swift_guards.md`](../agent_swift_guards.md) | Clever one-liners as a style goal |
| 3 | Make changes easy to reverse | **Present** (demo toggles) / **absent** (remote flags) | Launch args in [`testing.md`](../testing.md) / `AppLaunchConfiguration`; composition factories (#67) | Remote feature-flag / Remote Config product |
| 4 | Idempotent operations | **Present** | `APIRequest.idempotencyKey`; Dashboard **Idempotent POST** demo; UITest honesty (#56) | Live server-side idempotency beyond the simulated transport |
| 5 | Read the error before searching | **Present** (process) | [`error-handling.md`](../error-handling.md), [`incident-playbook.md`](../incident-playbook.md) | A separate “debug product” feature |
| 6 | Delete dead code (trust VCS) | **Soft present** | Intentional thin `LegacyObjC` showcase only; prefer delete over comment-out | That every legacy path is debt to rip out without a plan |
| 7 | Write the *why*, not only the *what* | **Present** | [`adr/`](../adr/README.md), [`changes/`](../changes/README.md); why notes on simulated idempotent transport | Mass why-comment waves without freeze/review |

## Related

- Engineering habits summary: [`../engineering-standards.md`](../engineering-standards.md)
- Portfolio inventory: [`../portfolio.md`](../portfolio.md)
- Production risk honesty: [`../production-risks.md`](../production-risks.md)
