# superDemoApp

Universal SwiftUI app (iOS, iPadOS, macOS): layered `Features/`, SwiftData, lint
gates, and multi-platform CI.

## Quick start

1. Open `superDemoApp.xcodeproj` in Xcode (run `./bin/*` from this directory).
2. Install tools: `brew bundle --file Brewfile`
3. Verify: `./bin/ci.sh`

Reviewers: [Portfolio](#portfolio-reviewers) and [`docs/portfolio.md`](docs/portfolio.md).

## Portfolio (reviewers)

**Purpose:** Universal SwiftUI + SwiftData baseline with recruiter-oriented docs,
clean-arch posture, `./bin/*` gates, and a **Feed** feature (network client,
repository, concurrency) — see **`docs/portfolio.md`**.

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

## AI-assisted development

Optional agent setup (rules, MCP, skills): [`AGENTS.md`](AGENTS.md),
[`docs/README.md`](docs/README.md). New feature work:
[`docs/feature-template.md`](docs/feature-template.md).

## Validation

- After Swift edits: `./bin/lint.sh`.
- SwiftUI/universal/nav smoke: `./bin/checklist`.
- Before merge / PR: `./bin/ci.sh`.
