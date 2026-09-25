# ADR 0002 — Offline-first product posture

- **Status:** Accepted
- **Date:** 2026-09-25
- **Owners:** [`../offline-first.md`](../offline-first.md),
  [`../offline-invariants.md`](../offline-invariants.md),
  [`../sync-and-networking.md`](../sync-and-networking.md)

## Context

Feed and Items demonstrate different persistence shapes (JSON cache vs local
SwiftData). Reviewers need a clear product rule: local-first with opportunistic
sync — not “online-only with a cache hint,” and not a full multi-device conflict
engine.

## Decision

Default posture: **local data first, sync opportunistically.**

- Reads prefer local storage when available.
- Writes record locally before remote sync when the feature allows it.
- Sync must be idempotent and retryable; conflicts need an explicit policy
  (local wins / remote wins / merge / user choice) — never silent overwrite.
- Named Feed/Items/store rules live in
  [`../offline-invariants.md`](../offline-invariants.md) (OI-01…OI-07) with
  evidence rows (test, script, or explicit N/A).
- Portfolio scope: no new remote-merge engine for Items (local-only is an honest
  N/A, not a gap to hide).

## Consequences

- UI should distinguish offline / syncing / synced / failed when relevant.
- Domain stays free of `ModelContext`; Data owns SwiftData and cache TTL.
- Store recovery prefers recreate / in-memory for this demo cache (see
  offline-first) rather than claiming production-grade migration theater.
- Scorecards and portfolio claims must cite invariants + tests — not invent
  sync capabilities Items does not have.
