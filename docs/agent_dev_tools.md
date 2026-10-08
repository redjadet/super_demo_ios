# Agent Mac / Xcode tools (optional)

Optional host tooling that makes builds, SF Symbols, and Instruments traces
easier for coding agents. **Not** merge gates. Lint pins stay in `Brewfile`;
these installs are agent/host convenience.

Canon entry points: [`tooling_map.md`](tooling_map.md),
[`agents_quick_reference.md`](agents_quick_reference.md),
[`agent_host_notes.md`](agent_host_notes.md).

## Quick map

| Tool | Wrapper | Install | CI |
| --- | --- | --- | --- |
| **xcsift** | `./bin/xcsift-run` | `brew install xcsift` (~1.5.x) | Optional; do not require in Brewfile |
| **SF Symbols 27** | `./bin/sfsymbols` | `brew install --cask sf-symbols` (cask 27) | Host-only |
| **RocketTrace** | `./bin/rockettrace` | [rockettrace.app](https://rockettrace.app/) → Settings → CLI & Agent | Host-only (app must run) |

Smoke (wrappers + missing-tool exits): `./tool/smoke_agent_dev_tools.sh`.

## xcsift — sift xcodebuild for agents

Pipe any build/test command so agents get JSON/TOON instead of megabyte logs:

```bash
./bin/xcsift-run xcodebuild -project superDemoApp.xcodeproj -scheme superDemoApp \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build

./bin/xcsift-run --toon ./bin/lint.sh
```

Always capture stderr (`xcsift-run` does `2>&1`). Extra flags:
`XCSIFT_EXTRA_ARGS='-w' ./bin/xcsift-run …`.

Expected version note: `EXPECTED_XCSIFT_VERSION` in
`tool/expected_tool_versions.sh` (documentation pin; not enforced by CI).

## SF Symbols 27 — search / verify before SwiftUI

Repo deployment targets are **iOS / macOS 26.7**. Prefer `--min-platform iOS26`
(or the closest flag the installed CLI accepts).

```bash
./bin/sfsymbols search heart --min-platform iOS26
./bin/sfsymbols search heart.circle.fill --match-style exactName --min-platform iOS26 --json
# [] / empty → do not invent Image(systemName:)
```

Override binary: `SFSYMBOLS_BIN=/path/to/sfsymbols ./bin/sfsymbols …`.

## RocketTrace — Instruments findings for agents

Requires **macOS 26 + Xcode 27+** (this Mac mini host matches). CLI talks to a
**running** RocketTrace.app — not a standalone Instruments front end.

```bash
./bin/rockettrace status          # start here; use doctor only when unhealthy
./bin/rockettrace builds
./bin/rockettrace record start --label "Checkout" --dry-run
./bin/rockettrace record stop --wait
./bin/rockettrace results get --brief
```

Override: `ROCKETTRACE_BIN=/path/to/rockettrace`. Import `.trace` files through
the app Open panel, not by asking the CLI to parse a path.

## Portfolio honesty

These are **optional developer-host aids**. Do not list them as product
features in [`portfolio.md`](portfolio.md). Absence must not fail
`./bin/checklist` / GHA Delivery.
