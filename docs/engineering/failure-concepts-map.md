# Failure concepts map (eight)

Portfolio honesty map for eight failure-mode concepts that show up when
networks, retries, concurrency, and shared state meet. This mirrors
[`senior-coding-patterns-map.md`](senior-coding-patterns-map.md): evidence in
this SwiftUI / SwiftData demo only — **not** a mandate to invent distributed
systems theater (circuit breakers, DLQs, multi-region consensus).

**Tip pin (inventory):** `bc7f3fb` (post #93 bookmark consistency; map + widget
coordination on top); update when behavior rows below change.

| # | Concept | Status | Where it shows up here | Do not claim |
| ---: | --- | --- | --- | --- |
| 1 | Invariants | **Present** | Named **OI-01…OI-08** in [`../offline-invariants.md`](../offline-invariants.md); `CachingFeedRepository` TTL / wholesale replace; `OutboxCoalescer` Domain plans | Items remote-merge invariants (OI-06 forbids) |
| 2 | Idempotency | **Present** | `APIRequest.idempotencyKey` + Dashboard **Idempotent POST** demo; outbox reuses same key on retry (`OutboxSyncEngine` / OI-08) | Live JSONPlaceholder durable idempotency beyond headers + simulated transport |
| 3 | Atomicity | **Present** (file) / **Soft** (cross-store) | `ShareInboxStore` + `FeedWidgetSnapshotStore`: `NSFileCoordinator` + temp/`replaceItemAt`; outbox `inFlight`→`pending` crash recovery; Items `failedUpdateDoesNotLeavePendingMutations` | One DB transaction spanning SwiftData cache save **and** App Group snapshot publish (crash window is real — see [`../architecture/cache-behavior.md`](../architecture/cache-behavior.md)) |
| 4 | Optimistic concurrency | **Present** (writes) / **Gap** (reads) | Optimistic `BookmarkedPost` + outbox; **409/412 → unresolved failure** (no invented server value; #93) | Feed GET conditional / ETag / `If-None-Match` (explicitly not implemented) |
| 5 | Backpressure | **Soft present** | Transport **429** + `Retry-After`; outbox flush coalesce (`isFlushing` / `pendingFlush`); `OutboxCoalescer`; `AsyncLoadController` cancels prior load; Share inbox **cap 20** | Unbounded task fan-out control / product rate-limit UI |
| 6 | State ownership | **Present** | [`../layers.md`](../layers.md), [`../state-management.md`](../state-management.md); App Group Feed/Share = **projection**; watch/tv companions are **local** App Group (not phone sync) | Cross-device SoT / WatchConnectivity sync |
| 7 | Immutability | **Soft present** | Domain `let` / `Sendable` values (`FeedPost`, outbox snapshots, widget/share DTOs); SwiftData `@Model` mutable by design in Data | “Everything immutable” or rewriting `@Model` classes |
| 8 | Structured concurrency | **Present** | `AsyncLoadController` + generation guards; OI-05 cancel restore; [`../architecture/native-cancellation.md`](../architecture/native-cancellation.md); `OutboxSyncEngine` **actor** | That every path uses `withTaskGroup` (few/no fan-out sites yet) |

## Highest-value follow-ups (not this map’s job alone)

1. **Read-side OCC (simulated)** — injectable cache validator + 304 path; do not claim live JSONPlaceholder ETags.
2. **TaskGroup where work is already independent** — e.g. Composite Dashboard sample∥remote; cancel-child proof in `native-cancellation.md`.
3. **Ownership SoT table** — optional `docs/architecture/state-ownership.md` stitching SwiftData / outbox / App Group / Presentation / HostBridge.

## Related

- Senior habits (Stackademic 7): [`senior-coding-patterns-map.md`](senior-coding-patterns-map.md)
- Offline rules: [`../offline-invariants.md`](../offline-invariants.md)
- Cancel talk track: [`../architecture/native-cancellation.md`](../architecture/native-cancellation.md)
- Performance + concurrency: [`../performance-lab.md`](../performance-lab.md)
- Portfolio inventory: [`../portfolio.md`](../portfolio.md)
