# Lint/format toolchain for superDemoApp (agents + local dev + CI)
# Pins (enforced by tool/check_swiftformat_version.sh + .swiftlint.yml):
#   swiftlint  0.65.1  — see .swiftlint.yml swiftlint_version
#   swiftformat 0.63.1 — see tool/expected_tool_versions.sh
# CI: setup-ios-ci runs tool/ensure_lint_tool_pins.sh after brew bundle so
# runners with HOMEBREW_NO_AUTO_UPDATE still match the SwiftFormat pin.
brew "swiftlint"
brew "swiftformat"
brew "ripgrep"

# Optional agent-host tools (NOT required in CI Brewfile — keep PR lanes lean).
# Install on Mac mini / agent hosts when useful; wrappers soft-fail if absent.
#   xcsift          brew install xcsift                 (~1.5.2) → ./bin/xcsift-run
#   SF Symbols 27   brew install --cask sf-symbols      (cask 27) → ./bin/sfsymbols
#   RocketTrace     https://rockettrace.app/ + CLI&Agent → ./bin/rockettrace
# See docs/agent_dev_tools.md and tool/expected_tool_versions.sh.
