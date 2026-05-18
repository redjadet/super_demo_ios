# Agent Swift Guards

Short list of mistakes agents repeat in this repo. **Fix in code**, then keep
these rules so the next edit does not regress.

Config anchors: [`.editorconfig`](../.editorconfig) (4 spaces), [`.swiftformat`](../.swiftformat),
[`.swiftlint.yml`](../.swiftlint.yml), [`code-style.md`](code-style.md).

## After every Swift edit (agents)

Run **one** command from `superDemoApp/`:

```bash
./bin/verify-swift.sh
```

That runs `./bin/format.sh` then `./bin/lint.sh` in order. **Do not run
`./bin/lint.sh` alone** after editing Swift — you will hit 2-space `(indent)`
errors that format would have fixed.

`./bin/lint.sh` includes:

| Step | Script | Catches |
| --- | --- | --- |
| Indent | `tool/check_swift_two_space_indent.sh` | 2-space `func` / `private` / etc. (shows line numbers) |
| Patterns | `tool/check_agent_swift_patterns.sh` | MainActor `deinit` + `refreshTask`, UIKit in `deinit`, per-call `URLSession` |
| Style | SwiftLint + SwiftFormat lint | `opening_brace`, `wrapMultilineStatementBraces`, custom rules |
| Layers | `tool/check_layer_boundaries.sh` | Feature import boundaries |

Xcode **Build** runs the same lint via `Scripts/xcode-lint.sh` → `./bin/lint.sh`.
If Xcode fails on indent before compile, run `./bin/verify-swift.sh` locally first.

## Automated hooks (optional, recommended)

| When | What | Safe behavior |
| --- | --- | --- |
| Agent edits a `.swift` file under `superDemoApp/` | Cursor `afterFileEdit` / `afterTabFileEdit` | **SwiftFormat that file only** (fail open if tools missing) |
| `git commit` with staged `.swift` | `pre-commit` | **`./bin/verify-swift.sh`**, re-stages formatted files |

**Install once per machine / clone:**

```bash
# Cursor hooks → workspace ../.cursor/
./tool/install-cursor-rules.sh

# Git pre-commit → .git/hooks/
./tool/install-git-hooks.sh
```

Skip pre-commit: `SKIP_SWIFT_VERIFY=1 git commit` or `git commit --no-verify`.

Hooks do **not** replace `./bin/verify-swift.sh` before handoff — they reduce
2-space drift during edits; commit hook catches anything left.

## Indentation (4 spaces only)

| Wrong | Right |
| --- | --- |
| 2-space `func` / `case` / `private` at member level | 4-space per `.editorconfig` |
| Edit Swift in IDE with 2-space Tab size | Match repo: indent_size **4** |
| Run lint only, see `(indent)` on line 10+ | Run `./bin/format.sh` first |

SwiftFormat is the formatter; SwiftLint does not replace it. Both must pass.

### Multiline `class` / `struct` / `enum` braces

SwiftFormat (`wrapMultilineStatementBraces`) and SwiftLint (`opening_brace`) disagree
if you hand-format. **Do not** put `{` alone on the next line after a wrapped
inheritance list — run `./bin/format.sh`, or use a **single-line** declaration:

```swift
// Wrong — opening_brace after manual edit
final class ModuleCollectionViewController: UICollectionViewController,
    UICollectionViewDataSourcePrefetching
{

// Right — one line (under 120 cols) or let SwiftFormat wrap
final class ModuleCollectionViewController: UICollectionViewController, UICollectionViewDataSourcePrefetching {
```

## SwiftLint style pairs

### `extension_access_modifier`

Put access on the **extension**, not each member:

```swift
// Wrong
extension Duration {
    fileprivate var wholeMilliseconds: Int { ... }
}

// Right
fileprivate extension Duration {
    var wholeMilliseconds: Int { ... }
}
```

### `closure_parameter_position` + `trailing_closure`

- Closure parameters must sit on the **same line** as the opening `{`.
- Prefer **trailing** closure syntax when the closure is the last argument.

```swift
// Wrong — parameters on next line
try await gate.withSession(stubs: stubs) {
    session, _ in
    ...
}

// Wrong — labeled closure blocks trailing_closure
try await gate.withSession(stubs: stubs, body: { session in ... })

// Right — single-parameter trailing closure
try await gate.withSession(stubs: stubs) { session in
    ...
}

// Right — multi-parameter on one line
try await gate.withSession(stubs: stubs) { session, sessionID in
    ...
}
```

For tests, prefer a small helper (see `withStubSession` in
`URLSessionAPIClientTests.swift`) instead of splitting `session, _ in` across lines.

## Swift 6 concurrency

### `@MainActor` feature model initializers

Do **not** use default parameter values that call `SomeType()` on `@MainActor`
types. Default arguments are evaluated in the **caller's** isolation, which
breaks with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.

```swift
// Wrong
@MainActor
final class FeatureModel {
    init(load: LoadUseCase, score: ScoreUseCase = ScoreUseCase()) { ... }
}

// Right
@MainActor
final class FeatureModel {
    init(load: LoadUseCase) {
        self.load = load
        self.score = ScoreUseCase()
    }
}
```

Inject test doubles via explicit parameters from tests; production wiring lives
in `*Composition.swift`.

### Do not cancel `@MainActor` tasks in `deinit`

`deinit` is **nonisolated**. You cannot read `refreshTask` on a `@MainActor`
feature model — Swift 6 errors at compile time. `tool/check_agent_swift_patterns.sh`
flags this early.

```swift
// Wrong
deinit { refreshTask?.cancel() }

// Right — view lifecycle
.onDisappear { model.cancelRefresh() }
```

### `UIViewControllerRepresentable` teardown

Clear delegates and prefetch state on the **main thread** from
`dismantleUIViewController` / `viewDidDisappear`, not from `deinit` (UIKit is
unsafe there). `deinit` may only cancel detached `Task` handles.

### Shared `URLSession`

Do not return `URLSession(configuration:)` from every `makeDefault()` call — use
one process-wide session (`AppURLSession`). The pattern check enforces this.

## URLProtocol tests (no global stub queue)

Do **not** share one static `[Stub]` array across parallel tests. Use per-session
isolation:

- `StubURLSessionFactory.makeSession(stubs:)` + `X-Stub-Session-ID` header
- `StubURLProtocolGate.shared.withSession(stubs:) { session, sessionID in ... }`
- Reference: `superDemoAppTests/Shared/Networking/StubURLProtocol.swift`

See [`testing.md`](testing.md#urlprotocol-stubs).

## UI tests

Prefer **accessibility identifiers** on buttons/links (`productionRisksLink`,
`uikitShowcaseLink`), not visible text alone, so labels can change without
breaking smoke tests.

## When the same failure happens twice

Add or extend a **script, test, or this doc** — do not only re-prompt the agent.
