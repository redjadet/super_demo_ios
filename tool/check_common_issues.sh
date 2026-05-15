#!/usr/bin/env bash
# Focused iOS project guardrails for AI agents and local development.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

failures=0

section() {
  printf '\n==> %s\n' "$1"
}

fail() {
  echo "error: $1" >&2
  failures=$((failures + 1))
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

section "Required agent docs"
required_files=(
  AGENTS.md
  superDemoApp/AGENTS.md
  docs/README.md
  docs/agent_knowledge_base.md
  docs/agent_project_context.md
  docs/agent_environment_setup.md
  docs/agent_host_notes.md
  docs/agents_quick_reference.md
  docs/ai_code_review_protocol.md
  docs/apple-development-practices.md
  docs/universal-apple-platforms.md
  docs/state-management.md
  docs/testing.md
  docs/code-style.md
)

for path in "${required_files[@]}"; do
  require_file "$path"
done

section "Universal Apple platform settings"
project_file="superDemoApp.xcodeproj/project.pbxproj"
require_file "$project_file"

if [[ -f "$project_file" ]]; then
  rg -q 'SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx' "$project_file" \
    || fail "project must support iOS simulator/device and macOS platforms"
  rg -q 'TARGETED_DEVICE_FAMILY = "1,2,7"' "$project_file" \
    || fail "project must target iPhone, iPad, and Mac device families"
fi

section "SwiftUI and state anti-patterns"
swift_paths=(superDemoApp superDemoAppTests superDemoAppUITests)

check_absent() {
  local pattern="$1"
  local message="$2"
  local matches
  matches="$(rg -n "$pattern" "${swift_paths[@]}" || true)"
  if [[ -n "$matches" ]]; then
    echo "$matches" >&2
    fail "$message"
  fi
}

check_absent '\bNavigationView\s*\(' "use NavigationStack or NavigationSplitView instead of NavigationView"
check_absent '\bObservableObject\b' "use SwiftUI Observation for new feature state; ObservableObject is legacy-only"
check_absent '@Published\b' "use @Observable state instead of @Published"
check_absent '@EnvironmentObject\b' "avoid EnvironmentObject as a global service locator"
check_absent '\bprint\s*\(' "use OSLog/Logger instead of print()"
check_absent 'try!' "handle thrown errors explicitly; avoid try!"
check_absent '\bTask\s*\.\s*detached\b' "avoid Task.detached; prefer structured concurrency or actor-owned tasks"
check_absent '\bDispatchQueue\s*\.\s*main\s*\.\s*async\b' "prefer @MainActor or MainActor.run over DispatchQueue.main.async"
check_absent '\b(?:UIScreen|NSScreen)\s*\.\s*main\b' "avoid screen-bounds layout; use adaptive SwiftUI layout"
check_absent '\bUIApplication\s*\.\s*shared\b' "avoid UIApplication.shared in universal app code"

section "Linter rule policy"
require_lint_rule() {
  local rule="$1"
  rg -q "^[[:space:]]*-[[:space:]]*$rule$|^[[:space:]]*$rule:" .swiftlint.yml \
    || fail "missing required SwiftLint rule: $rule"
}

required_lint_rules=(
  accessibility_label_for_image
  accessibility_trait_for_button
  async_without_await
  balanced_xctest_lifecycle
  discarded_notification_center_observer
  discouraged_assert
  discouraged_optional_collection
  empty_xctest_method
  final_test_case
  force_unwrapping
  function_default_parameter_at_end
  identical_operands
  implicitly_unwrapped_optional
  incompatible_concurrency_annotation
  legacy_objc_type
  no_dispatch_main_async
  no_force_try
  no_navigation_view
  no_print_debug
  no_screen_bounds_layout
  no_task_detached
  no_uiapplication_shared
  prefer_key_path
  private_swiftui_state
  prohibited_interface_builder
  quick_discouraged_focused_test
  quick_discouraged_pending_test
  reduce_into
  shorthand_optional_binding
  sorted_first_last
  test_case_accessibility
  unhandled_throwing_task
  unavailable_function
)

for rule in "${required_lint_rules[@]}"; do
  require_lint_rule "$rule"
done

section "Tracked secret literal scan"
secret_matches="$(
  rg -n \
    -g '*.swift' -g '*.yml' -g '*.yaml' -g '*.json' -g '*.plist' -g '*.xcconfig' \
    -g '!superDemoApp.xcodeproj/**' -g '!**/xcuserdata/**' \
    'sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|ghp_[A-Za-z0-9_]{36}|xox[baprs]-' . \
    || true
)"
if [[ -n "$secret_matches" ]]; then
  echo "$secret_matches" >&2
  fail "possible tracked secret literal found"
fi

section "XcodeBuildMCP profile"
mcp_config="../.xcodebuildmcp/config.yaml"
if [[ -f "$mcp_config" ]]; then
  rg -q 'activeSessionDefaultsProfile: superDemoApp' "$mcp_config" \
    || fail "XcodeBuildMCP config exists but active profile is not superDemoApp"
  rg -q 'scheme: superDemoApp' "$mcp_config" \
    || fail "XcodeBuildMCP config exists but scheme is not superDemoApp"
else
  echo "info: XcodeBuildMCP config not found at $mcp_config; skipping host-local MCP check."
fi

if ((failures > 0)); then
  echo
  echo "Common issue checks failed: $failures"
  exit 1
fi

echo
echo "Common issue checks passed."
