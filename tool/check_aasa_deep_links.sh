#!/usr/bin/env bash
# Ensure sample AASA path components stay aligned with AppDeepLink routes.
# Prevents Safari handoff gaps when custom-scheme / HTTPS parse gains new paths.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AASA="$ROOT/Config/associated-domains/apple-app-site-association"

if [[ ! -f "$AASA" ]]; then
  echo "error: missing $AASA" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 required to validate AASA JSON" >&2
  exit 1
fi

# Paths AppDeepLink supports today (keep in sync with App/AppNavigation.swift).
# `/feed/*` covers `https://superdemo.app/feed/<id>` (Open Feed Post / deep link).
REQUIRED_PATHS=(
  "/dashboard"
  "/dashboard/risks"
  "/feed"
  "/feed/*"
  "/items"
)

python3 - "$AASA" "${REQUIRED_PATHS[@]}" <<'PY'
import json
import sys

path = sys.argv[1]
required = sys.argv[2:]

with open(path, encoding="utf-8") as handle:
    data = json.load(handle)

try:
    details = data["applinks"]["details"]
except (KeyError, TypeError) as exc:
    raise SystemExit(f"error: AASA missing applinks.details: {exc}") from exc

if not isinstance(details, list) or not details:
    raise SystemExit("error: AASA applinks.details must be a non-empty list")

patterns = set()
for detail in details:
    if not isinstance(detail, dict):
        continue
    for component in detail.get("components") or []:
        if isinstance(component, dict):
            pattern = component.get("/")
            if isinstance(pattern, str):
                patterns.add(pattern)

missing = [p for p in required if p not in patterns]
if missing:
    print(
        "error: AASA components missing AppDeepLink paths: "
        + ", ".join(missing),
        file=sys.stderr,
    )
    print("present:", ", ".join(sorted(patterns)) or "(none)", file=sys.stderr)
    raise SystemExit(1)

print("AASA deep-link paths OK:", ", ".join(required))
PY
