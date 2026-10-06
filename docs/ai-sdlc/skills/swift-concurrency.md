# Skill: Swift concurrency

Agents repeat MainActor / cancellation mistakes. Canon:
[`../../agent_swift_guards.md`](../../agent_swift_guards.md).

## Rules

1. After **any** Swift edit: `./bin/verify-swift.sh` (format then lint).
2. Feature models: `@Observable` + `@MainActor`; no heavy work in `SwiftUI.View.body`.
3. Tie refresh `Task`s to lifecycle; **cancel restores prior UI** (Feed/Items).
4. Respect default MainActor isolation; mark background work `nonisolated` or on
   actors explicitly — do not suppress sendability diagnostics.
5. No `try!` / unjustified force unwrap; prefer typed errors.
6. Avoid per-call `URLSession()` when composition already injects a session.
7. Indentation is **4 spaces** (`.editorconfig`); 2-space member indent fails CI.

## Proof

```bash
./bin/verify-swift.sh
# then focused Swift Testing / UI as needed
```
