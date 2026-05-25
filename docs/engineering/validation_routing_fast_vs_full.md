# Validation Routing: Fast Vs Full

Entrypoint list: [Agent Quick Reference](../agents_quick_reference.md).

Choose validation during Verify. Report exact proof command, or report blocker
when proof cannot run.

## Fast Path

Use for narrow low-risk edits where architecture, release, signing, routing,
and platform support are unchanged.

- Docs/tooling only: `./bin/checklist-fast`.
- Small Swift edit: `./bin/verify-swift.sh` plus focused test if behavior changed.
- Markdown only: `./bin/lint-markdown.sh` or `./bin/checklist-fast`.
- Design doc touched: `./tool/check_design_md.sh` plus `./bin/checklist-fast`.

## Scoped Code Path

Use focused proof first, then broaden only when blast radius requires it.

| Changed surface | Minimum proof |
| --- | --- |
| `Features/*/Domain` | `./bin/verify-swift.sh` + targeted unit tests |
| `Features/*/Data`, SwiftData, networking | `./bin/verify-swift.sh` + targeted repository/client tests |
| `Features/*/Presentation`, SwiftUI state | `./bin/verify-swift.sh` + targeted feature-model/UI proof |
| Layering or feature structure | `./tool/check_layer_boundaries.sh` + `./bin/lint.sh` |
| Shared networking, retry, token refresh, idempotency | targeted networking tests + `./bin/checklist` |
| SwiftData model/schema changes | targeted persistence tests + migration note + `./bin/checklist` |
| Privacy manifest, required-reason API, entitlement, keychain, background mode | targeted proof + release/privacy note + `./bin/checklist` |
| Strict concurrency, actors, shared mutable state | `./bin/verify-swift.sh` + focused async/concurrency tests |
| Performance, hang, memory, sanitizer risk | focused test/profile/sanitizer proof + `./bin/checklist` when shared |
| UI layout, navigation, light/dark, universal behavior | targeted UI proof + `./bin/checklist` |
| Release/Fastlane/signing | relevant `./bin/fastlane-run ...` lane or documented credential blocker |

## Full Path

Use for broad, medium/high-risk, or pre-ship changes.

Typical triggers:

- shared architecture or dependency-injection changes
- SwiftData schema/migration work
- networking, retry, sync, lifecycle, diagnostics, or release changes
- privacy/signing/entitlement/permission/required-reason API changes
- strict-concurrency, shared mutable state, performance, memory, sanitizer, or broad OSLog/signpost changes
- changes spanning multiple features or shared infrastructure
- UI/navigation work requiring iPhone, iPad, and Mac confidence
- work where smallest honest proof is broader than one focused test

Commands:

```bash
./bin/checklist
./bin/ci.sh
./bin/fastlane-run ci
```

## Docs And Agent Guidance Path

For `AGENTS.md`, `docs/agent*`, `docs/ai_code_review_protocol.md`,
`docs/engineering/**`, `tool/cursor-template/**`, and workflow docs:

1. Self-verify final wording against request, changed docs, blockers, and risk.
2. Run `./bin/lint-markdown.sh` or `./bin/checklist-fast`.
3. Run `./tool/install-cursor-rules.sh` only when Cursor template behavior
   changed and local install proof is needed.
4. Escalate to `./bin/checklist` when docs materially change delivery policy,
   validation routing, or repo-wide operating rules.

## Production-Failure Path

For hotfixes and reliability defects:

1. Reproduce or reason clearly from failure evidence.
2. Add focused guard or regression proof.
3. Fix cause, not symptom.
4. Run targeted validation for changed surface.
5. Add `./bin/checklist` or `./bin/ci.sh` when failure touches shared
   infrastructure, lifecycle, networking, retries, release, SwiftData, or broad
   UI/navigation.
