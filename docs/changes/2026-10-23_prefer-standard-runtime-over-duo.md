# Change — Prefer standard runtime over Duo/27.1

**Date:** 2026-10-23

## What

Simulator selection now walks **standard-capable runtimes first** (newest among
those), then exotic-only runtimes (Duo/Fold/Air) as a true last resort.

- `select_ios_runtime_ids_prefer_standard` / `ios_runtime_is_exotic_only`
- `find_iphone_udid_on_newest_runtime`, `ensure_ci_simulator` create/boot walks
- Preferred list includes **iPhone 17e**; `is_standard_iphone` accepts letter
  suffixes (`17e`)
- `check_simulator_runtime_compat.sh` guards + live assertion against locking
  onto Duo when a standard runtime exists
- `docs/testing.md` honesty: Duo/27.1 avoided when 27.0 + standard device exists
  (PosterBoard crashes on Duo/27.1)

## Why

PR 109 made Duo a last-resort *device type* on an exotic-only newest runtime so
SDK and runtime stayed aligned. On Mac mini hosts with **both** iOS 27.1
(Duo-only) and iOS 27.0 (17e / 18 Pro), that still selected Duo first and hit
PosterBoard `PRPosterDescriptor _initWithPath:` crashes during UI work.
Preferring 27.0 + standard iPhone is more stable; Duo remains available when it
is the only provisionable option.

## Proof

- `./tool/check_simulator_runtime_compat.sh --self-test`
- `./tool/check_simulator_runtime_compat.sh` (live: pick is 17e/standard, not Duo)
- `CI_IPHONE_TEST_SHARD=unit ./bin/ci-iphone-test.sh` destination ≠ Duo when
  27.0 devices exist
