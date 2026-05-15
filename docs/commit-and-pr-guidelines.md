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

## Before Merge

- `git status --short` reviewed.
- Build/test command passed or blocker documented.
- Diff contains only intended files.
