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
  DESIGN.md
  README.md
  docs/README.md
  docs/agent_knowledge_base.md
  docs/agent_baseline.md
  docs/agent_preferences.md
  docs/agent_project_context.md
  docs/agent_environment_setup.md
  docs/agent_host_notes.md
  docs/agents_quick_reference.md
  docs/ai_code_review_protocol.md
  docs/ai/README.md
  docs/ai/context_loading.md
  docs/ai/ai_failure_risks.md
  docs/agent_kb/agent_safety_contracts.md
  docs/apple-development-practices.md
  docs/design_system.md
  docs/architecture.md
  docs/layers.md
  docs/module-structure.md
  docs/dependency-injection.md
  docs/feature-template.md
  docs/universal-apple-platforms.md
  docs/state-management.md
  docs/testing.md
  docs/code-style.md
  docs/agent_swift_guards.md
)

for path in "${required_files[@]}"; do
  require_file "$path"
done

section "AGENTS map constraints"
agents_lines="$(wc -l < AGENTS.md | tr -d '[:space:]')"
if ((agents_lines > 70)); then
  fail "AGENTS.md has ${agents_lines} lines; keep map at or below 70"
fi
rg -q 'docs/ai/context_loading.md' AGENTS.md \
  || fail "AGENTS.md must reference docs/ai/context_loading.md"

section "Agent doc cross-links"
require_contains() {
  local path="$1"
  local needle="$2"
  if [[ ! -f "$path" ]]; then
    fail "Cannot scan missing file for cross-link: $path"
    return
  fi
  rg -qF -- "$needle" "$path" || fail "$path must reference: $needle"
}

require_contains docs/README.md "ai/README.md"
require_contains docs/agent_knowledge_base.md "ai/context_loading.md"
require_contains docs/agent_knowledge_base.md "agent_kb/agent_safety_contracts.md"
require_contains docs/ai/README.md "context_loading.md"
require_contains docs/ai/README.md "ai_failure_risks.md"
require_contains docs/ai/README.md "agent_safety_contracts.md"
require_contains docs/ai/context_loading.md "agent_safety_contracts.md"
require_contains docs/ai/ai_failure_risks.md "agent_safety_contracts.md"

section "Universal Apple platform settings"
project_file="superDemoApp.xcodeproj/project.pbxproj"
require_file "$project_file"

if [[ -f "$project_file" ]]; then
  rg -q 'SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx' "$project_file" \
    || fail "project must support iOS simulator/device and macOS platforms"
  rg -q 'TARGETED_DEVICE_FAMILY = "1,2,7"' "$project_file" \
    || fail "project must target iPhone, iPad, and Mac device families"
fi

section "Clean Architecture layer boundaries"
./tool/check_layer_boundaries.sh

section "Agent Swift pattern checks"
require_file tool/check_agent_swift_patterns.sh
[[ -x tool/check_agent_swift_patterns.sh ]] || fail "tool/check_agent_swift_patterns.sh must be executable"
./tool/check_agent_swift_patterns.sh

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

check_absent_in_paths() {
  local pattern="$1"
  local message="$2"
  shift 2
  local matches
  matches="$(rg -n "$pattern" "$@" || true)"
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

section "Light and dark color policy"
presentation_paths=()
[[ -d superDemoApp/Features ]] && presentation_paths+=(superDemoApp/Features)
[[ -d superDemoApp/Shared ]] && presentation_paths+=(superDemoApp/Shared)
if ((${#presentation_paths[@]} > 0)); then
  check_absent_in_paths 'Color\.(white|black)\b' \
    "use semantic colors or asset catalog Any+Dark; Color.white/black breaks appearance support" \
    "${presentation_paths[@]}"
  check_absent_in_paths 'UIColor\.(white|black)\b' \
    "use semantic colors; avoid fixed UIColor white/black in Presentation" \
    "${presentation_paths[@]}"
fi

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
  indentation_width
  legacy_objc_type
  no_dispatch_main_async
  no_empty_block
  no_fixed_appearance_colors
  no_force_try
  no_navigation_view
  no_observable_object_new_code
  no_print_debug
  no_screen_bounds_layout
  no_task_detached
  no_uiapplication_shared
  prefer_self_in_static_references
  swift_two_space_member_indent
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
  unneeded_escaping
  unused_parameter
  variable_shadowing
  xct_specific_matcher
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

section "Fastlane / Bundler"
fastlane_files=(
  Gemfile
  Gemfile.lock
  fastlane/Fastfile
  fastlane/Appfile
  bin/fastlane-run
)
for path in "${fastlane_files[@]}"; do
  require_file "$path"
done
[[ -x bin/fastlane-run ]] || fail "bin/fastlane-run must be executable"
[[ -x tool/bootstrap_fastlane.sh ]] || fail "tool/bootstrap_fastlane.sh must be executable"

section "Release diagnostics claims"
crash_provider_matches="$(
  rg -n \
    'FirebaseCrashlytics|Crashlytics|Sentry|Bugsnag|PLCrashReporter' \
    superDemoApp superDemoApp.xcodeproj Package.resolved \
    2>/dev/null \
    || true
)"
crash_overclaims="$(
  rg -n \
    'Crash reporting configured|crash reporting is configured|Crashlytics configured|Sentry configured' \
    README.md docs \
    || true
)"
if [[ -n "$crash_overclaims" && -z "$crash_provider_matches" ]]; then
  echo "$crash_overclaims" >&2
  fail "docs claim crash reporting is configured, but no crash provider is wired in app source or project settings"
fi
if [[ -z "$crash_provider_matches" ]]; then
  rg -q 'OSLogCrashMonitor' docs/release-checklist.md \
    || fail "docs/release-checklist.md must mention OSLogCrashMonitor while no vendor crash SDK is wired"
  rg -q 'OSLogCrashMonitor' README.md \
    || fail "README.md must mention OSLogCrashMonitor while no vendor crash SDK is wired"
  rg -q 'OSLogCrashMonitor' superDemoApp/Shared/Diagnostics/CrashMonitoring.swift \
    || fail "OSLogCrashMonitor must exist in Shared/Diagnostics while docs claim it"
fi

section "Cursor agent template"
cursor_template_files=(
  tool/cursor-template/README.md
  tool/cursor-template/mcp.json
  tool/cursor-template/rules/agents-map.mdc
  tool/cursor-template/rules/agent-execution-ios.mdc
  tool/cursor-template/rules/ios-swift-quality.mdc
  tool/install-cursor-rules.sh
  tool/resolve_platform_destination.sh
  tool/check_layer_boundaries.sh
  Gemfile
  Gemfile.lock
  fastlane/Fastfile
  bin/ci-platform-builds.sh
  bin/fastlane-run
  bin/verify-swift.sh
  tool/bootstrap_fastlane.sh
  tool/check_agent_swift_patterns.sh
  tool/install-git-hooks.sh
  tool/git-hooks/pre-commit
  tool/cursor-template/hooks/hooks.json
  tool/cursor-template/hooks/format-swift-after-edit.sh
  tool/select_xcode.sh
  tool/ios_simulator_runtime.sh
  tool/check_simulator_runtime_compat.sh
)

for path in "${cursor_template_files[@]}"; do
  require_file "$path"
done

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

section "Simulator runtime ↔ device-type compat"
if [[ -x tool/check_simulator_runtime_compat.sh ]]; then
  ./tool/check_simulator_runtime_compat.sh || fail "simulator runtime compat check failed"
else
  fail "tool/check_simulator_runtime_compat.sh must be executable"
fi

if ((failures > 0)); then
  echo
  echo "Common issue checks failed: $failures"
  exit 1
fi

echo
echo "Common issue checks passed."
