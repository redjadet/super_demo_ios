# UI test CI stability

## Summary

- Fixed GitHub Actions `iphone-test` failure: `testFeedTabIsReachable` failed with
  `Failed to terminate com.ilkersevim.superDemoApp` after a long prior UI test left
  the app running.
- `UiTestSupport.launchApplication()` now terminates before launch; `superDemoAppUITests`
  uses balanced `setUp` / `tearDown` with `terminateApplication` in `tearDown`.
- `SampleFeedRepository` + `FeedComposition` branch on `-UITesting` so Feed UI tests
  do not use live JSONPlaceholder (aligned with Production Readiness sample data).

## Proof

```bash
./bin/verify-swift.sh
# CI: re-run iphone-test job on push
```

## Docs

- [`testing.md`](../testing.md#ui-smoke-ci)
- [`agent_swift_guards.md`](../agent_swift_guards.md#ui-tests)
- [`sync-and-networking.md`](../sync-and-networking.md#portfolio-feed)
