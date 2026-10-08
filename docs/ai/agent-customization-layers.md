# Agent customization layers (Cursor / Codex)

Pick the **lightest** layer that solves the problem; stop at the first match.
There is no in-editor “mod” layer like Claude Code plugins—use repo scripts and CI
for hard guarantees.

## Decision ladder

Walk down; use the first row that fits.

| # | Need | Use | This repo |
| --- | --- | --- | --- |
| 1 | Stable project facts, routing, “where is X?” | Always-loaded map + `docs/` | [`../../AGENTS.md`](../../AGENTS.md), [`context_loading.md`](context_loading.md) |
| 2 | Style / policy on every turn for one host | Thin Cursor rules (maps only) | [`../../tool/cursor-template/rules/`](../../tool/cursor-template/rules/) via `./tool/install-cursor-rules.sh` |
| 3 | Same multi-step workflow twice+ with proof | **Repo skill** (tool-agnostic) | [`../ai-sdlc/skills/`](../ai-sdlc/skills/README.md) |
| 4 | Apple-platform recipes (host-installed) | Lockfile skills | [`skills-lock.json`](../../skills-lock.json) → `.agents/skills/` (gitignored); see [`../agent_host_notes.md`](../agent_host_notes.md) |
| 5 | Nudge at a fixed moment (format on save, block a read) | **Cursor hooks** (convenience) | [`../../tool/cursor-template/hooks/`](../../tool/cursor-template/hooks/) |
| 6 | Must pass before merge / commit | **Git hooks + scripts + GHA** | [`../ai-sdlc/gates.md`](../ai-sdlc/gates.md), `./bin/checklist`, `./tool/install-git-hooks.sh` |

**Codex:** Prefer repo `docs/` + `bin/` gates. Host skills install to
`.agents/skills/` with the same lockfile as Cursor (`npx skills experimental_install -y`).
Do not add Claude-only config (`.claude/`, `CLAUDE.md`).

**Cursor:** Rules/hooks install to the workspace `.cursor/` directory (default:
parent `super_demo_ios/.cursor/`). Re-run `./tool/install-cursor-rules.sh` after
template changes.

## Hooks are convenience, not guarantees

Cursor hooks (for example `afterFileEdit` → SwiftFormat one file) only see the
events they subscribe to. Edits made via shell scripts, generators, or another
tool may bypass them—the same lesson as a “tests green” commit gate that trusts
edit detection instead of re-running the suite.

| Goal | Reliable layer | Weak-only layer |
| --- | --- | --- |
| Formatted Swift before commit | `pre-commit` → `./bin/verify-swift.sh` | Cursor `afterFileEdit` (fail open) |
| Lint / layers / tests before merge | `./bin/checklist` + GHA `checklist` | Any agent hook |
| Keep secrets out of agent context | `.gitignore` + never commit; [`.cursorignore`](../../tool/cursor-template/.cursorignore) at workspace root | `beforeReadFile` deny (enforcement has been unreliable in Agent mode—prefer ignore list) |

Treat hook scripts like application code: small, reviewed, no network, no secret
logging. They run with the user’s permissions.

## Secrets and sensitive reads

1. **Do not commit** secrets ([`../security-checklist.md`](../security-checklist.md),
   SAFETY-04 in [`../agent_kb/agent_safety_contracts.md`](../agent_kb/agent_safety_contracts.md)).
2. **Install** tracked [`.cursorignore`](../../tool/cursor-template/.cursorignore)
   at the Cursor workspace root (`./tool/install-cursor-rules.sh` copies it next to
   `.cursor/`). Blocks agent reads of local `.env`, keys, and signing material
   patterns.
3. **Shell redaction** is not a substitute: a command may still run and leak to
   telemetry; hooks cannot undo execution.

## Related

- Deterministic gates table: [`../ai-sdlc/gates.md`](../ai-sdlc/gates.md)
- Swift hook matrix: [`../agent_swift_guards.md`](../agent_swift_guards.md#automated-hooks-optional-recommended)
- Cursor install README: [`../../tool/cursor-template/README.md`](../../tool/cursor-template/README.md)

## Proof / tests

| Item | Covered by |
| --- | --- |
| Template files present | `./tool/check_common_issues.sh` (checklist-fast lane) |
| CI shard contract | `python3 ./tool/check_ci_contracts.py` |
| Markdown links in new docs | `./bin/lint-markdown.sh` |
| Cursor hook scripts | Manual: install + edit a `.swift` file (host with SwiftFormat) |
| `.cursorignore` effect | **Untested in CI** — manual: file listed in ignore should not appear in Agent @-mentions |
