# Intent — feed-stale-banner-honesty

## Problem

When JSONPlaceholder is unreachable but a fresh Feed cache exists, users could
see empty/error UI instead of last-known posts, hiding that data may be stale.

## Outcome

Offline (or failed remote) with fresh cache shows cached posts plus a visible
stale banner; diagnostics record cache-fallback. Expired cache still surfaces
failure honestly.

## Non-goals

- Full mutation outbox / write sync engine
- Changing JSONPlaceholder contract
- Mac-only or iPhone-only layout

## Stakes

Agentic — touches Domain result shape, Data cache policy, Presentation banner.

## Constraints

- Platforms: iPhone / iPad / Mac Feed tab
- Respect OI-01…OI-04 ([`../../../offline-invariants.md`](../../../offline-invariants.md))
- Must not invent live HTTP in UI tests (`-UITesting` sample path)

## Success signal

Reviewer can fail the network, still see posts + stale label, and point at a
unit test that asserts `isStale` + diagnostic.
