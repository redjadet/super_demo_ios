# Commit And PR Guidelines

## Commit

- Keep commits focused.
- Include docs/tests with behavior changes.
- Do not commit DerivedData, `xcuserdata`, secrets, or local-only files.
- Commit message should name user-facing or engineering outcome.

## PR

Include:

- summary,
- test/proof commands,
- screenshots for meaningful UI changes,
- migration notes for SwiftData model changes,
- known risks or follow-ups.

When `docs/ai-sdlc/features/<slug>/plan.md` exists for the change, reviewers
**check the diff against that plan** (write-set, acceptance, proof). Templates:
[`ai-sdlc/README.md`](ai-sdlc/README.md). Review protocol:
[`ai_code_review_protocol.md`](ai_code_review_protocol.md).

## Before Merge

- `git status --short` reviewed.
- Build/test command passed or blocker documented.
- Diff contains only intended files.
- Matching gates from [`ai-sdlc/gates.md`](ai-sdlc/gates.md) run (at least
  `./bin/checklist-fast` for docs; `./bin/checklist` + GHA `checklist` for merge).
