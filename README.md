# superDemoApp

Universal SwiftUI app (iOS, iPadOS, macOS) with an AI-agent harness: lint gates,
multi-platform CI, and Cursor rules.

## Quick start

1. Open **`super_demo_ios/`** in Cursor (parent folder) or this directory in Xcode.
2. Install tools: `brew bundle --file Brewfile`
3. Install Cursor rules (from this directory): `./tool/install-cursor-rules.sh` then restart Cursor.
4. Proof: `./bin/ci.sh`

## Agents

Start at [`AGENTS.md`](AGENTS.md). Docs index: [`docs/README.md`](docs/README.md).

New feature work: [`docs/feature-template.md`](docs/feature-template.md).

## Validation

| When | Command |
| ------ | ------ |
| After Swift edits | `./bin/lint.sh` |
| Universal UI / navigation | `./bin/checklist` |
| Before merge/PR | `./bin/ci.sh` |
