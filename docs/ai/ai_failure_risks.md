# AI Failure Risks (iOS)

Pre-Flight for non-trivial work (app code, harness docs, validation scripts,
architecture policy). Map the task to rows below before first edit.

## Pre-Flight

1. Read this register; pick matching rows.
2. Read [`../agent_kb/agent_safety_contracts.md`](../agent_kb/agent_safety_contracts.md).
3. Load owners via [`context_loading.md`](context_loading.md) — not whole trees.
4. Before done: run **honest proof** for each applied row.

## Priority

| Tier | When | Example IDs |
| --- | --- | --- |
| P0 — stop before edit | Secrets, destructive ops, unclear scope, unapproved Git | `RISK-SECRET-LEAK`, `RISK-SCOPE-CREEP`, `RISK-UNAPPROVED-GIT` |
| P1 — during implementation | Layers, MainActor, SwiftData, tests, universal UI | `RISK-ARCH-LAYER`, `RISK-MAINACTOR`, `RISK-SWIFTDATA`, `RISK-UNIVERSAL-UI`, `RISK-SIM-RUNTIME-DEVICE`, `RISK-VALIDATION-SHORTCUT` |
| P2 — session hygiene | Doc drift (manual) | `RISK-DOC-DRIFT` |

## Risk register

| ID | Trigger | Owner | Prevention | Honest proof | Recovery |
| --- | --- | --- | --- | --- | --- |
| `RISK-ARCH-LAYER` | `Features/` edit | [`layers.md`](../layers.md) | Presentation → Domain ← Data | `./tool/check_layer_boundaries.sh` | Move type; rerun check |
| `RISK-MAINACTOR` | Feature model / UI async | [`agent_swift_guards.md`](../agent_swift_guards.md) | `@MainActor` models; no isolated `deinit` misuse | `./bin/verify-swift.sh` | Fix isolation; format+lint |
| `RISK-SWIFTDATA` | Schema / ModelContainer | [`offline-first.md`](../offline-first.md) | Document recovery; migration thinking | Unit tests for container wipe/recreate; review store path | Recreate store path or in-memory fallback |
| `RISK-UNIVERSAL-UI` | Shared SwiftUI layout | [`universal-apple-platforms.md`](../universal-apple-platforms.md) | `AdaptiveNavigationShell`; no phone-only assumptions | `./bin/checklist` or `./bin/ci.sh` (**not** checklist-fast alone) | Fix layout; re-run iPad/Mac proof |
| `RISK-SIM-RUNTIME-DEVICE` | CI / local Simulator provision | [`testing.md`](../testing.md) + `tool/check_simulator_runtime_compat.sh` | Create only types in runtime `supportedDeviceTypes`; no blind global preferred | `./tool/check_simulator_runtime_compat.sh` (also via checklist-fast / lint) | Fix preferred list or install matching runtime; re-run gate before UI tests |
| `RISK-SECRET-LEAK` | Tokens / keys in diff | baseline + common-issues | Placeholders; no printed secrets | `./tool/check_common_issues.sh` secret scan | Remove; rotate externally |
| `RISK-VALIDATION-SHORTCUT` | Claiming done | validation routing | Match change type to gate | Named command from quick reference | Run correct gate |
| `RISK-DOC-DRIFT` | New durable rule | owning doc + `docs/changes/` | Land rule in owner file | **Manual review** of diff vs chat | Add owner entry + change note |
| `RISK-SCOPE-CREEP` | Extra files / cleanup | [`agent_safety_contracts.md`](../agent_kb/agent_safety_contracts.md) | Write-set discipline | **Manual review** of changed paths vs request | Revert out-of-scope agent edits |
| `RISK-UNAPPROVED-GIT` | Commit/push without ask | preferences | Wait for explicit ask | **Manual review** of git intent | Stop; report status |

## Related

- Finish gate: [`../agent_kb/legibility_and_finish_gate.md`](../agent_kb/legibility_and_finish_gate.md)
- Commands: [`../agents_quick_reference.md`](../agents_quick_reference.md)
