# 2026-10-07 — failure concepts map + Feed widget file coordination

## Intent

Map eight failure-mode concepts (invariants → structured concurrency) onto this
portfolio with honest **Present / Soft / Gap** labels, and close the named
App Group atomicity honesty gap: Feed widget snapshot store lacked
`NSFileCoordinator` while Share inbox already had it.

Base tip: `bc7f3fb` (post #93; originally drafted on `ffdcf2c` / #92).

## Changes

- `docs/engineering/failure-concepts-map.md` — concept → evidence table
  (Stackademic senior-patterns-map style).
- `FeedWidgetShared/FeedWidgetSnapshotStore.swift` — coordinate write / load /
  remove like `ShareInboxStore` (temp + `replaceItemAt` unchanged).
- `docs/architecture/cache-behavior.md` — honesty: SwiftData save and App Group
  publish are two steps; coordinated snapshot file access.
- Discoverability: `docs/portfolio.md`, `docs/README.md`, `docs/code-quality.md`,
  `docs/engineering/senior-coding-patterns-map.md`, this index.

## Not changed

- No ETag / conditional GET theater.
- No TaskGroup Dashboard fan-out (follow-up).
- No Items remote-merge invariants.
- No screenshots / companion phone-sync claims.
