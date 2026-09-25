# SonarCloud decision

**Decision (2026-09-25):** **Skip** standing up SonarCloud for this portfolio demo.

| Field | Value |
| --- | --- |
| Decision | Default **no-go** |
| Why | No free org / maintainer-owned SonarCloud account is configured for this repo. Layer lint, SwiftLint, and `./bin/ci.sh` already gate merge quality. |
| Revisit when | Maintainer explicitly opts in with an org, secrets policy, and a named owner for triage. |
| Non-goals | Do not commit Sonar tokens, do not add unpaid cloud analysis that cannot run in CI. |

Existing gates remain authoritative: `./bin/verify-swift.sh`, `./bin/lint.sh` (including `tool/check_layer_boundaries.sh`), local/`GHA` CI map in [`ci-cd-map.md`](ci-cd-map.md).

ADR index entry: [`adr/0004-sonarcloud-skip.md`](adr/0004-sonarcloud-skip.md).
