# Priority fix list — cache TTL filter rows

- Offline fallback filters cache rows by `effectiveCachedAt` instead of
  admitting every row when the newest timestamp is fresh.
- Migrated / missing `cachedAt` values count as expired (`distantPast`).
- Cancellation from remote fetch rethrows and does not publish widget snapshots.
