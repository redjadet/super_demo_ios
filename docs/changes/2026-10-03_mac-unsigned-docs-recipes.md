# Mac unsigned compile-proof — standalone docs recipes

**Date:** 2026-10-03  
**Tip base:** `c8df504` (#69)

## Why

[#69](https://github.com/redjadet/super_demo_ios/pull/69) made `./bin/ci-platform-builds.sh`
default to unsigned Mac compile-proof (`CODE_SIGNING_ALLOWED=NO`,
`CODE_SIGN_IDENTITY=-`). Three standalone
`xcodebuild … -destination 'platform=macOS' build` recipes still documented the
pre-#69 signed path and would hit missing Mac Development profiles locally.

## Change

Align Mac recipes with #69 in:

- `docs/agents_quick_reference.md`
- `docs/testing.md`
- `docs/universal-apple-platforms.md`

Prefer `./bin/ci-platform-builds.sh` (or `CI_MAC_REQUIRE_CODE_SIGN=1` for signed builds when profiles exist).

## Non-goals

No script, scheme, or product changes. Does not touch portfolio tip pins or senior-coding-patterns docs.
