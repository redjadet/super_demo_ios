# ADR 0005 — CI PR-lane vs local-test honesty

- **Status:** Accepted
- **Date:** 2026-09-25
- **Owners:** [`../ci-cd-map.md`](../ci-cd-map.md),
  [`../testing.md`](../testing.md),
  [`../engineering/validation_routing_fast_vs_full.md`](../engineering/validation_routing_fast_vs_full.md)

## Context

Hosted GitHub Actions and local `./bin/ci.sh` share Fastlane lanes, but PR jobs
are not a silent guarantee of full local suite parity (UI smoke may be limited;
authors still re-run merge proof locally). Claiming “CI = all tests green”
without the stage map misleads reviewers and agents.

## Decision

Treat **PR / GHA lanes and local merge proof as related but not identical**:

| Lane | Role |
| --- | --- |
| GHA `lint` / `iphone-test` / `platform-builds` → `lint-build-test` | Hosted PR gate |
| Local `./bin/ci.sh` | Authoritative **merge proof** |
| Docs / tooling-only | `./bin/checklist-fast` (validation routing) |

Record local test results separately from hosted CI build results when they
diverge. Do not assume every local `xcodebuild test` path ran on every PR job —
see [`../ci-cd-map.md`](../ci-cd-map.md) and [`../testing.md`](../testing.md).

Bitrise rows in the CI map are **equivalents only** — this repo does not run on
Bitrise today.

## Consequences

- Finish reports must name the exact proof command used (`checklist-fast`,
  `lint.sh`, `ci.sh`, or named GHA jobs) — not “CI passed” alone.
- Quality badges and scorecard rows cite the stage that actually ran.
- Archive / TestFlight / credentialed beta stay off the normal PR path
  (`release-smoke.yml` / Fastlane beta are manual or secret-gated).
- Agents choose proof via validation routing; empty/truncated tool output is
  not proof ([`../agent_kb/agent_safety_contracts.md`](../agent_kb/agent_safety_contracts.md)).
