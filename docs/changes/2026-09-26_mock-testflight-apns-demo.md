# 2026-09-26 — Mock / demo TestFlight + APNs checklist (JP-P2-E)

## Summary

Documents a **portfolio-honest** TestFlight + APNs proof path that allows
**labeled fake/mock** environments when real ASC credentials, push certs, or
device APNs are unavailable. Prefer real Simulator/local proofs when possible.

## User waiver

Portfolio demo (not production): mock TestFlight upload IDs and mock APNs
token/receipt notes are acceptable when clearly labeled **DEMO / MOCK**.

## Paths

- `docs/release-checklist.md` — new “Portfolio demo / mock proofs” section
- `docs/portfolio.md` — platform row for push / TestFlight honesty
- Optional fixture notes under `docs/release-notes/` unchanged for real lane

## Proof

- Docs lint (`./bin/lint-markdown.sh` / checklist-fast docs lane)
- No fake production App Store / millions-of-users claim
