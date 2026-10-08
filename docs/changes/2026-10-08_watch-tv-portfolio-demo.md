# Change — Watch and Apple TV portfolio demo

**Date:** 2026-10-08

## Behavior

Previously, the companions showed technical seed headlines, wrote sample data
into the real App Group, read storage on the main actor, and refreshed only on
initial display or a manual reload. Headline rows had no detail navigation.

Both companions now offer a native headline walkthrough and seven explicit
sample states. Samples stay in memory; stored data remains read-only. A shared
Observation model reads storage away from the main actor, rejects canceled or
superseded reads, reloads on foreground, and polls while visible. Expiry keeps
the headlines and original timestamp; Reload never silently renews a sample.

Watch uses a scrollable native list and detail page. Apple TV uses native remote
focus, Select, Back, and Up/Down scrolling for long headlines. Both have source
labels, recovery controls, system fonts/colors, and branded icons from the
existing main-app artwork. The TV
icon uses native layered assets instead of an unsupported single-image icon set.

## Tests and discovery

- Shared model regressions run in both hosted XCTest targets: request ordering,
  cancellation, source transitions, expiry, argument parsing, and unchanged
  stored bytes across every sample scenario.
- Platform integration fixtures remain isolated in temporary directories.
  Real App Group smoke tests read existing data without writing or restoring it.
- Swift lint now includes tvOS, both platform test folders, and shared tests;
  format and lint scripts include the shared test folder.
- [Demo walkthrough](../watch-tv-demo.md) includes launch steps, source map,
  screenshots, and precise device-local data boundaries.

## Local verification

Watch and TV each passed 15 hosted tests on their version 27 Simulator runtimes.
The main app passed 202 unit tests and 27 UI tests; iPad and Mac builds passed.
Swift verification, Markdown lint, architecture checks, and checklist checks
passed. The final unsharded run hit an iPhone unit-runner launch hang before
unit execution; its UI tests passed. A Simulator restart and the unit shard of
the checklist passed the unit tests and remaining platform checks.

Manual review covered Watch 40 mm and largest Text Size, TV light/dark focus and
navigation, empty-state recovery, long-headline scrolling, source switching,
and branded Home icons. Stored TV fixture bytes stayed unchanged. Only the
disposable fixture Simulator was deleted; existing simulator data was preserved.

## Scope boundary

No WatchConnectivity or phone-to-TV transport is added. No signing, entitlement,
storage schema, third-party dependency, or hosted CI workflow changes are made.
Physical-device behavior and an App Store release remain outside this proof.
