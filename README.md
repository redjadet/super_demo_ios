# superDemoApp

Universal SwiftUI app (iOS, iPadOS, macOS) with an AI-agent harness: lint gates,
multi-platform CI, and Cursor rules.

## Quick start

1. Open **`super_demo_ios/`** in Cursor (parent folder) or this directory in Xcode.
2. Install tools: `brew bundle --file Brewfile`
3. Install Cursor rules (from this directory): `./tool/install-cursor-rules.sh` then restart Cursor.
4. Restore team Apple agent skills: `npx skills experimental_install -y` (requires Node/npx).
5. Proof: `./bin/ci.sh`

## Portfolio (reviewers)

**Purpose:** Universal SwiftUI + SwiftData baseline with recruiter-oriented docs,
clean-arch posture, `./bin/*` gates, optional **Feed** narrative (clients,
repos, concurrency) — see **`docs/portfolio.md`**.

**Skill map:**

- **Layered architecture** — `Features/Items/` and `Features/Feed/` (typed domain/data/presentation folders).
- **SwiftData** — `Item` and **`CachedFeedPost`** (Feed cache).
- **Networking** — `Features/Feed/Data/` with injectable **`URLSession`**.
- **Structured concurrency / cancel** — Feed feature model + refresh cancel.
- **Universal UI** — `Shared/Presentation/` + shared design modifiers.
- **Testing** — `superDemoAppTests/`, `superDemoAppUITests/`.

**Guided tour:** [`docs/portfolio.md`](docs/portfolio.md).

**Architecture tour:** [`docs/architecture.md`](docs/architecture.md),
[`docs/feature-template.md`](docs/feature-template.md).

## Agents

Start at [`AGENTS.md`](AGENTS.md). Docs index: [`docs/README.md`](docs/README.md).

New feature work: [`docs/feature-template.md`](docs/feature-template.md).

## Validation

- After Swift edits: `./bin/lint.sh`.
- SwiftUI/universal/nav smoke: `./bin/checklist`.
- Before merge / PR: `./bin/ci.sh`.
