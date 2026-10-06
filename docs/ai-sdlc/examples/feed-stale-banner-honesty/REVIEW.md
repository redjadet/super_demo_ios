# REVIEW — feed-stale-banner-honesty

## Checklist

- [x] Diff matched plan write-set (Feed Data/Presentation + tests + offline docs)
- [x] Spec acceptance / OI-01…OI-05 evidenced in tests + docs matrix
- [x] `./bin/verify-swift.sh` / CI lint green historically for the slice
- [x] Stale banner + diagnostic present; `-UITesting` stays sample-backed
- [x] No secrets; no new entitlements

## Diff vs plan

| Planned | Delivered | Notes |
| --- | --- | --- |
| Caching fallback + TTL | Shipped | See offline-invariants OI-* |
| Stale UI | Shipped | Feed stale `Label` + diagnostic |
| Mutation outbox | Deferred | Separate feature / open PR lane |

## Proof

```text
Focused: CachingFeedRepositoryTests + FeedFeatureModelTests (scheme filter)
Merge lane: ./bin/checklist → GHA checklist
```

## Residual risk

- Deterministic stale demo flags (`-StaleFeedDemo`) are portfolio helpers — do not
  confuse with production OAuth or APNs.
- Widget snapshot `writtenAt` uses oldest surviving `cachedAt` (OI-02 nuance).

## Decision

- [x] Approve for merge (historical / teaching example)
- [ ] Request changes
- [ ] Reject / spike only
