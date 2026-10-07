#!/usr/bin/env bash
# Boot the CI iPhone simulator and wait until ready, with one retry.
# Intended for UI shard jobs after artifact download (no useful overlap with I/O).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# shellcheck source=resolve_platform_destination.sh
source "$ROOT/tool/resolve_platform_destination.sh"

max_attempts="${CI_SIM_BOOT_MAX_ATTEMPTS:-2}"
attempt=1

while ((attempt <= max_attempts)); do
  boot_dir="${CI_SIM_BOOT_DIR:-${RUNNER_TEMP:-/tmp}/ci-sim-boot}"
  rm -rf "$boot_dir"
  mkdir -p "$boot_dir"
  export CI_SIM_BOOT_DIR="$boot_dir"

  echo "==> Simulator boot attempt ${attempt}/${max_attempts}"
  ./tool/ci_simulator_boot_bg.sh
  if ./tool/ci_simulator_await.sh; then
    exit 0
  fi

  echo "warn: simulator boot attempt ${attempt} failed" >&2
  if [[ -n "${CI_SIMULATOR_DEST:-}" ]]; then
    udid="$(destination_udid "${CI_SIMULATOR_DEST}")"
    if [[ "$udid" =~ ^[0-9A-F-]{36}$ ]]; then
      echo "==> Shutting down ${udid} before retry" >&2
      xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
    fi
  fi

  attempt=$((attempt + 1))
  if ((attempt <= max_attempts)); then
    sleep 5
  fi
done

echo "error: simulator boot failed after ${max_attempts} attempts" >&2
exit 1
