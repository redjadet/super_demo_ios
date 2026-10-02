# 2026-10-03 — senior coding patterns map (Stackademic 7)

## Intent

Map the Stackademic “7 coding patterns” article onto this Swift portfolio app
with honest **present / gap / N/A** labels. Prefer docs polish over importing
Java/backend patterns (circuit breaker, DLQ, remote RC) that do not fit the
offline-first demo.

Tip at plan time: `c8df504` (#69).

## Changes

- `docs/engineering/senior-coding-patterns-map.md` — pattern → evidence table.
- `docs/engineering-standards.md` — short Senior habits subsection + link.
- `docs/code-quality.md`, `docs/README.md` — discoverability links.
- `docs/release-checklist.md`, `docs/development-feedback-loop.md` — qualify
  “feature flags” as launch-arg / composition toggles (no remote RC claim).
- `docs/changes/README.md` — index this note.

## Not changed

- No Swift / UITest / target / scheme edits.
- No remote feature-flag infrastructure.
- No P2-A screenshots; no visionOS companion / StoreKit purchase / APNs.
