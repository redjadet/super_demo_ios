# 2026-10-05 — Portfolio reviewer polish (cold path)

## Intent

Remove high-confidence amateur signals for technical reviewers without new product
scope or architecture churn.

## Before

- Seeded Feed copy said **“UI Test Post”** in `-ReviewerDemoMode` and sample
  repositories — reads like unfinished test scaffolding on a portfolio cold path.
- [`portfolio.md`](../portfolio.md) **Platform surfaces** opened with a long
  internal PR/changelog wall and agent-store backlog references.
- README lacked a single cold-path honesty table (seeded data, demos, assets,
  universal links).
- Host bridge demo idle copy sounded like a placeholder instruction string.

## After

- Professional seeded Feed titles/bodies in `ReviewerDemoFixtures`,
  `SampleFeedRepository`, `Localizable.xcstrings`, and matching UITest label.
- Portfolio platform intro trimmed; deferred items listed once; history points to
  [`changes/README.md`](README.md).
- README **Portfolio honesty** table for reviewers.
- Host bridge response area shows neutral idle text until Ping runs.

## Left alone

- App Icon PNG was an Xcode placeholder at the time; the
  [follow-up](2026-10-05_reviewer-facing-polish.md) adds the app icon assets.
- Architecture, CI workflows, CocoaPods trunk publishing, visionOS companion.
- No Xcode build or simulator run on this Linux agent host.

## Proof (Linux)

- `./tool/check_markdown_relative_links.sh`
- `./tool/check_router_doc_paths.sh`
- `./tool/check_common_issues.sh`
