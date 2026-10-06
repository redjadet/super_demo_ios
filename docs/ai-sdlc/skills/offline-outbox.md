# Skill: offline / outbox

Offline-first and pending-mutation rules for this portfolio app.

Canon: [`../../offline-first.md`](../../offline-first.md),
[`../../offline-invariants.md`](../../offline-invariants.md),
[`../../sync-and-networking.md`](../../sync-and-networking.md).

## Feed (read-through cache) — shipped

Named invariants **OI-01…OI-05** (wholesale replace, fresh fallback, TTL miss,
visible stale, cancel-safe). Do not invent empty remote-merge tests for Feed’s
read model.

## Items — local-first

**OI-06:** Items persist via SwiftData only today — no remote merge queue unless
a feature explicitly adds one.

## Mutation outbox (when implementing writes)

Follow Sync Rules in `sync-and-networking.md`:

1. Local write first when offline-first applies.
2. Queue pending ops with **stable IDs**; retries **idempotent**.
3. Track sync state per record/operation; durable failure visible in UI.
4. Explicit conflict policy (local wins / remote wins / merge / user choice).
5. Do not let stale remote overwrite newer local without policy tests.

If an outbox PR is already open, **do not** edit its core feature files from an
unrelated docs/kit PR — coordinate write-sets.

## Proof

- Unit: repository + feature model tests listed in offline-invariants matrix
- Merge: `./bin/checklist` / GHA `checklist`
