# Agent Docs Lift From bloc_test_app — Implementation Plan

> **For agentic workers:** Execute checkboxes sequentially. Use `executing-plans`
> only when that skill is available in the host (it is **not** pinned in
> `skills-lock.json`). Do **not** start Tasks until a human approves this plan.

**Goal:** Port a *minimal* AI-harness routing layer from
`bloc_test_app/flutter_bloc_app` into `superDemoApp` — context ladder, iOS risk
index, safety contracts — without docs sprawl or Flutter tooling clone.

**Architecture:** Keep `AGENTS.md` a short map (≤ 70 lines). Add thin `docs/ai/`
with **three** files only (`README`, `context_loading`, `ai_failure_risks`). Add
`docs/agent_kb/agent_safety_contracts.md`. Extend **existing**
`tool/check_common_issues.sh` (no new KB checker script). Host/skills/MCP stay
in `agent_host_notes.md` + `tool_orchestration.md`. Finish gate stays in
`agent_knowledge_base.md` + `legibility_and_finish_gate.md`.

**Tech Stack:** Markdown docs, bash (`tool/check_common_issues.sh`),
`./bin/checklist-fast` / `./bin/lint-markdown.sh`. No app Swift in this plan.

**Spec:** This plan. Source patterns (read-only):
`/Users/ilkersevim/Flutter_SDK/projects/bloc_test_app/flutter_bloc_app`
(`docs/ai/context_loading.md`, `docs/ai/ai_failure_risks.md`,
`docs/agent_kb/agent_safety_contracts.md`). Destination git root:
`superDemoApp/` on branch `main`.

## Global Constraints

- Do **not** copy Flutter/BLoC/Hive/AIDLC/Supabase/gstack content verbatim.
- Do **not** add `bin/agent-maintain`, harness scorecards, badges, or a second
  `check_agent_knowledge_base.sh`.
- Do **not** add `docs/ai/governance.md` or `docs/ai/skill_routing.md` (host
  notes + finish gate already cover process/skills).
- Keep `AGENTS.md` ≤ **70** lines (hard). Map only; no learned sections.
- Link new files from `docs/README.md` and `docs/agent_knowledge_base.md` —
  **not** every file from `AGENTS.md` (map stays lean).
- New agent docs ≤ ~200 lines each.
- Validation proves **docs/tool wiring only** unless a risk row explicitly
  requires `./bin/checklist` / `./bin/ci.sh`.
- No commit unless user asks.

---

## Canonical owners (do not duplicate)

| Concern | Owner |
| --- | --- |
| Host / skills lock / Cursor MCP | `docs/agent_host_notes.md`, `docs/agent_kb/tool_orchestration.md` |
| Workflow / finish gate | `docs/agent_knowledge_base.md`, `docs/agent_kb/legibility_and_finish_gate.md` |
| Safety precedence | `docs/agent_kb/agent_safety_contracts.md` (new) |
| Risk → proof index | `docs/ai/ai_failure_risks.md` (new) |
| Context ladder | `docs/ai/context_loading.md` (new) |
| Swift indent/concurrency pitfalls | `docs/agent_swift_guards.md` |
| Validation chooser | `docs/engineering/validation_routing_fast_vs_full.md`, `docs/agents_quick_reference.md` |

---

## Gap analysis (evidence)

Record exact SHAs and file lists in Task 1 audit. Summary:

| Area | flutter_bloc_app | superDemoApp today | Action |
| --- | --- | --- | --- |
| Context ladder | `docs/ai/context_loading.md` | Ladder inside `agent_knowledge_base.md` | Extract thin ladder |
| Failure risks | `docs/ai/ai_failure_risks.md` | Scattered baseline / guards / playbook | Add iOS risk→proof index |
| Safety contracts | `agent_kb/agent_safety_contracts.md` | Preferences + baseline | Thin SAFETY contracts |
| KB lint | Large dedicated script | `check_common_issues.sh` required files | Extend common-issues only |
| Governance / skill routing / AIDLC / scorecard | Full harness | N/A | **Do not port** |

### Intentional non-ports

- `governance.md`, `skill_routing.md`, AIDLC, harness scorecard, `agent-maintain`
- Separate `tool/check_agent_knowledge_base.sh`
- Flutter SDK / BLoC / Hive / CODEMAP / CONTEXT_MAP / Repomix

---

## File map

### Create

- `docs/ai/README.md`
- `docs/ai/context_loading.md`
- `docs/ai/ai_failure_risks.md`
- `docs/agent_kb/agent_safety_contracts.md`
- `docs/changes/2026-09-15_agent-docs-bloc-patterns.md`
- `docs/audits/2026-09-15_agent-docs-vs-bloc-test-app.md`

### Modify

- `AGENTS.md` — Start / Task Map / Finish; point to `docs/ai/context_loading.md`;
  cut duplicated Read-next ladder so ≤ 70 lines
- `docs/agent_knowledge_base.md` — progressive disclosure → `docs/ai/`; no
  duplicate full ladder
- `docs/ai-agent-playbook.md` — slim with **rule-retention table** (see Task 3)
- `docs/README.md` — Start Here → `docs/ai/`
- `docs/agents_quick_reference.md` — Pre-Flight → `docs/ai/ai_failure_risks.md`
- `docs/audits/README.md`, `docs/changes/README.md` — index new entries
- `tool/check_common_issues.sh` — require new files; hard `AGENTS.md` ≤ 70;
  require AGENTS references `docs/ai/context_loading.md`

### Do not touch (already done / out of scope)

- `docs/plans/README.md` (already lists this plan)
- New standalone KB checker script

---

## Task 1: Auditable evidence

- [x] Capture destination `git rev-parse HEAD` and source Flutter repo
      `git -C …/flutter_bloc_app rev-parse HEAD` (or note if unavailable).
- [x] Write `docs/audits/2026-09-15_agent-docs-vs-bloc-test-app.md` with:
      inspected paths, gap table, selected patterns, Phase 0 non-ports.
- [x] Link from `docs/audits/README.md`.

**Proof:** file exists; `./bin/lint-markdown.sh`.

---

## Task 2: Safety contracts + `docs/ai/` (create together)

Create safety contracts **before or with** AI docs so cross-links resolve in the
same commit/diff.

- [x] `docs/agent_kb/agent_safety_contracts.md` — SAFETY-01 scope, SAFETY-02
      destructive, SAFETY-03 git, SAFETY-04 secrets, SAFETY-05 verification,
      SAFETY-06 Apple/repo boundaries, SAFETY-REPORT finish gate. Link deep
      owners; do not replace them.
- [x] `docs/ai/README.md` — index of the three AI docs + pointers to KB/safety.
- [x] `docs/ai/context_loading.md` — ladder + conditional owners (Features,
      DESIGN/SwiftUI, SwiftData, networking, App Intents, validation, review,
      host/MCP). Avoid-early list. Skills: one sentence pointing at
      `agent_host_notes.md` / lockfile — **no** separate skill_routing file.
- [x] `docs/ai/ai_failure_risks.md` — each row = trigger | owner | prevention |
      **honest proof** | recovery.
  - Script-backed examples: `RISK-ARCH-LAYER` →
    `./tool/check_layer_boundaries.sh`; `RISK-MAINACTOR` →
    `./bin/verify-swift.sh` + guards; `RISK-SECRET-LEAK` → common-issues secret
    scan.
  - **Manual-review** (say so explicitly): `RISK-DOC-DRIFT`,
    `RISK-SCOPE-CREEP`, `RISK-UNAPPROVED-GIT`.
  - `RISK-UNIVERSAL-UI` proof = `./bin/checklist` or `./bin/ci.sh` (**not**
    checklist-fast alone).
  - No Flutter script paths.

**Proof:** `./bin/lint-markdown.sh`; each new doc ≤ ~200 lines; links between
these four files resolve.

---

## Task 3: Migrate existing pointers (rule retention)

- [x] Update `docs/agent_knowledge_base.md` Progressive Disclosure / Context
      Ladder → `docs/ai/context_loading.md` (delete duplicated list).
- [x] Slim `docs/ai-agent-playbook.md` using a **rule-retention table** in the
      change note or playbook footer: every unique playbook rule maps to keep /
      move-to-X / drop. Must retain: MainActor / no `Type()` defaults,
      cancellation, previews, accessibility, Dynamic Type, SwiftData out of
      Domain, Apple-native APIs, report shape.
- [x] Update `docs/README.md` and `docs/agents_quick_reference.md`.

**Proof:** markdownlint; grep playbook for retained keywords
(`MainActor`, `cancel`, `[Pp]review`, `[Aa]ccessib`, `SwiftData`).

---

## Task 4: Refactor `AGENTS.md`

- [x] Reshape toward Start / Task Map / Finish; keep workspace table.
- [x] Single pointer to `docs/ai/context_loading.md` instead of long Read-next.
- [x] `wc -l AGENTS.md` ≤ 70 (**hard**). Cut content; do not raise the budget.

**Proof:** `wc -l AGENTS.md` ≤ 70; AGENTS contains `docs/ai/context_loading.md`.

---

## Task 5: Harden `tool/check_common_issues.sh` only

- [x] Add new files to `required_files`.
- [x] Enforce `AGENTS.md` line count ≤ 70 (fail if over).
- [x] Require AGENTS contains `docs/ai/context_loading.md`.
- [x] Require these **cross-link** needles (fail if missing):
  - `docs/README.md` contains `ai/README.md` (or `docs/ai/README.md`)
  - `docs/agent_knowledge_base.md` contains `ai/context_loading.md` **and**
    `agent_kb/agent_safety_contracts.md`
  - `docs/ai/README.md` contains `context_loading.md`, `ai_failure_risks.md`,
    and `agent_safety_contracts.md`
  - `docs/ai/context_loading.md` contains `agent_safety_contracts.md`
  - `docs/ai/ai_failure_risks.md` contains `agent_safety_contracts.md`
- [x] Do **not** add vague Flutter-path greps (`lib/features`, etc.).
- [x] **Mandatory** negative-path proof (same Task 5 turn; restore with `trap`):
  1. Temporarily move `docs/ai/README.md` aside → `./tool/check_common_issues.sh`
     must exit non-zero → restore.
  2. Temporarily append enough blank/comment lines to `AGENTS.md` so
     `wc -l` > 70 → check must exit non-zero → restore.
  3. Record both expected failures in the change note.

**Proof:**

```bash
bash -n tool/check_common_issues.sh
./tool/check_common_issues.sh
# negative paths as above (must fail then restore)
./bin/checklist-fast
```

States: docs/tool wiring only — not universal UI or full CI.

---

## Task 6: Change note + closeout

- [x] `docs/changes/2026-09-15_agent-docs-bloc-patterns.md` — why, files,
      rule-retention summary, Codex plan fixes applied.
- [x] Index in `docs/changes/README.md`.
- [x] Final `./bin/checklist-fast`.
- [x] Report: files changed, proof commands, residual risk.

**Stop criteria:** Tasks 1–6 done; no Flutter clone; no governance/skill_routing/
standalone KB script/scorecard.

---

## Rollback (exact files)

Delete only:

- `docs/ai/README.md`
- `docs/ai/context_loading.md`
- `docs/ai/ai_failure_risks.md`
- `docs/agent_kb/agent_safety_contracts.md`
- `docs/changes/2026-09-15_agent-docs-bloc-patterns.md`
- `docs/audits/2026-09-15_agent-docs-vs-bloc-test-app.md`

Revert modifications to: `AGENTS.md`, `docs/agent_knowledge_base.md`,
`docs/ai-agent-playbook.md`, `docs/README.md`, `docs/agents_quick_reference.md`,
`docs/audits/README.md`, `docs/changes/README.md`, `tool/check_common_issues.sh`.

Do **not** `rm -rf docs/ai/` if other files appear later.

---

## Codex review (2026-09-15)

Consult session `01a0a509-dc27-7e22-857e-8bd043b124e9`.

1. Initial review → cut sprawl; reorder create-together; honest risk proofs;
   hard AGENTS ≤ 70; exact rollback.
2. Readiness #1 → **NO**: cross-link assertions + mandatory negative-path.
   Task 5 updated.
3. Readiness #2 → **YES**. Remaining P0/P1: **NONE**. Plan ready to build.

## Approval gate

**Implemented** (2026-09-15): Tasks 1–6 complete. Human asked to build E2E.
