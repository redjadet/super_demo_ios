# 2026-09-15 — SwiftData store recreate-before-in-memory

## Why

Adding `CachedFeedPost.cachedAt` (and similar schema drift) can make an existing
on-disk store fail to open. Jumping straight to in-memory left disk stores
broken across launches and hid a recoverable path.

## Changes

- `AppModelContainer.make` recovery order for disk stores:
  1. Prefer configured store
  2. Wipe store + `-shm`/`-wal`, recreate on disk (`fallback: recreated-store`)
  3. In-memory only if recreate fails (`fallback: in-memory`)
- `removePersistentStoreFiles(at:)` shared wipe helper
- Unit coverage: wipe sidecars; recreate after incompatible file

## Decision

Demo keeps **delete/recreate** (and in-memory last resort) instead of a
`SchemaMigrationPlan`. Feed cache and Items are disposable portfolio data;
formal versioned migration can land when a real shipping schema needs it.

## Proof

- `AppModelContainerTests` recreate + wipe cases
- Commit `c6e38cf` on main
