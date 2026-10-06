#!/usr/bin/env bash
# Build iPhone test products once for CI shards (build-for-testing).
# Uploads products under IPHONE_DERIVED_DATA_PATH/Build/Products for
# test-without-building consumers (bin/ci-iphone-test.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "${CI:-}" == "true" ]]; then
  # shellcheck source=../tool/select_xcode.sh
  source "$ROOT/tool/select_xcode.sh"
else
  export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"
fi

# shellcheck source=../tool/xcode_env.sh
source "$ROOT/tool/xcode_env.sh"

echo "==> Simulator runtime ↔ device-type compat (before build-for-testing)"
./tool/check_simulator_runtime_compat.sh

CI_SIMULATOR_REUSE_ONLY="${CI_SIMULATOR_REUSE_ONLY:-1}"
if [[ "${CI:-}" == "true" && -z "${CI_SIMULATOR_DEST:-}" ]]; then
  if [[ "${CI_SIMULATOR_REUSE_ONLY}" == "1" ]]; then
    # Prefer an already-installed device; build-for-testing does not need boot.
    # shellcheck source=../tool/ci_simulator_pick_existing.sh
    source "$ROOT/tool/ci_simulator_pick_existing.sh" || exit $?
  else
    CI_PREPARE_IPAD="${CI_PREPARE_IPAD:-0}" source "$ROOT/tool/ensure_ci_simulator.sh" || exit $?
  fi
fi

# shellcheck source=../tool/resolve_platform_destination.sh
source "$ROOT/tool/resolve_platform_destination.sh"
# shellcheck source=../tool/xcodebuild_sandbox_flags.sh
source "$ROOT/tool/xcodebuild_sandbox_flags.sh"
# shellcheck source=../tool/xcode_warnings_as_errors_flags.sh
source "$ROOT/tool/xcode_warnings_as_errors_flags.sh"

if [[ -n "${CI_SIMULATOR_DEST:-}" ]]; then
  SIMULATOR_DEST="$CI_SIMULATOR_DEST"
else
  SIMULATOR_DEST="$(resolve_iphone_destination)"
fi
echo "==> iPhone destination: $SIMULATOR_DEST"

if [[ -z "${IPHONE_DERIVED_DATA_PATH:-}" ]]; then
  IPHONE_DERIVED_DATA_PATH="$(mktemp -d)/DerivedData-iPhone"
  export IPHONE_DERIVED_DATA_PATH
fi
mkdir -p "$IPHONE_DERIVED_DATA_PATH"

echo "==> iPhone build-for-testing ($XCODEBUILD)"
assert_xcodebuild_matches_developer_dir
python3 "$ROOT/tool/run_with_timeout.py" \
  --timeout "${CI_IPHONE_XCODEBUILD_TIMEOUT_SECONDS:-1800}" \
  -- "$XCODEBUILD" \
  -project superDemoApp.xcodeproj \
  -scheme superDemoApp \
  -destination "$SIMULATOR_DEST" \
  -configuration Debug \
  -derivedDataPath "$IPHONE_DERIVED_DATA_PATH" \
  ${XCODEBUILD_SANDBOX_FLAGS+"${XCODEBUILD_SANDBOX_FLAGS[@]}"} \
  ${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS+"${XCODEBUILD_WARNINGS_AS_ERRORS_FLAGS[@]}"} \
  build-for-testing

products_dir="$IPHONE_DERIVED_DATA_PATH/Build/Products"
xctestrun="$(find "$products_dir" -maxdepth 1 -name '*.xctestrun' | sort | head -n 1 || true)"
if [[ -z "$xctestrun" || ! -f "$xctestrun" ]]; then
  echo "error: no .xctestrun under $products_dir after build-for-testing" >&2
  find "$IPHONE_DERIVED_DATA_PATH" -name '*.xctestrun' 2>/dev/null | head -20 >&2 || true
  exit 1
fi

echo "==> build-for-testing products ready"
echo "IPHONE_PRODUCTS_DIR=$products_dir"
echo "XCTESTRUN=$xctestrun"

# Persist destination metadata for shard jobs (test-without-building).
metadata="$products_dir/ci-iphone-build-metadata.env"
{
  echo "CI_SIMULATOR_DEST=$SIMULATOR_DEST"
  echo "XCTESTRUN_BASENAME=$(basename "$xctestrun")"
} >"$metadata"
echo "Wrote $metadata"
