#!/usr/bin/env bash
# Ensure sample AASA path components stay aligned with AppDeepLink routes,
# AppDeepLink.associatedHosts matches applinks: entitlements (no www handoff
# claim without entitlement + live AASA), and live-host DNS honesty docs stay
# truthful when public DNS for entitlement hosts does not resolve.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AASA="$ROOT/Config/associated-domains/apple-app-site-association"
ENTITLEMENTS="$ROOT/superDemoApp/superDemoApp.entitlements"
NAVIGATION="$ROOT/superDemoApp/App/AppNavigation.swift"
PORTFOLIO="$ROOT/docs/portfolio.md"
ASSOC_README="$ROOT/Config/associated-domains/README.md"
NAV_DOC="$ROOT/docs/navigation.md"

if [[ ! -f "$AASA" ]]; then
  echo "error: missing $AASA" >&2
  exit 1
fi

if [[ ! -f "$ENTITLEMENTS" ]]; then
  echo "error: missing $ENTITLEMENTS" >&2
  exit 1
fi

if [[ ! -f "$NAVIGATION" ]]; then
  echo "error: missing $NAVIGATION" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 required to validate AASA / Associated Domains" >&2
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

python3 - "$AASA" "$ENTITLEMENTS" "$NAVIGATION" "$PORTFOLIO" "$ASSOC_README" "$NAV_DOC" "${REQUIRED_PATHS[@]}" <<'PY'
import json
import re
import socket
import sys
import xml.etree.ElementTree as ET

aasa_path = sys.argv[1]
entitlements_path = sys.argv[2]
navigation_path = sys.argv[3]
portfolio_path = sys.argv[4]
assoc_readme_path = sys.argv[5]
nav_doc_path = sys.argv[6]
required = sys.argv[7:]

with open(aasa_path, encoding="utf-8") as handle:
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

# --- Entitlement applinks hosts ↔ AppDeepLink.associatedHosts ---

root = ET.parse(entitlements_path).getroot()
plist_dict = root.find("dict")
if plist_dict is None:
    raise SystemExit("error: entitlements plist missing root dict")

entitlement_hosts: set[str] = set()
children = list(plist_dict)
index = 0
while index < len(children):
    node = children[index]
    if node.tag == "key" and (node.text or "") == "com.apple.developer.associated-domains":
        array = children[index + 1] if index + 1 < len(children) else None
        if array is None or array.tag != "array":
            raise SystemExit("error: associated-domains entitlement is not an array")
        for item in array:
            if item.tag != "string" or not item.text:
                continue
            value = item.text.strip()
            if not value.startswith("applinks:"):
                continue
            host = value.removeprefix("applinks:").split("?", 1)[0].strip().lower()
            if host:
                entitlement_hosts.add(host)
        break
    index += 1

if not entitlement_hosts:
    raise SystemExit("error: no applinks: hosts in superDemoApp.entitlements")

with open(navigation_path, encoding="utf-8") as handle:
    navigation = handle.read()

hosts_match = re.search(
    r"static let associatedHosts:\s*Set<String>\s*=\s*\[(.*?)\]",
    navigation,
    flags=re.DOTALL,
)
if hosts_match is None:
    raise SystemExit("error: could not find AppDeepLink.associatedHosts in AppNavigation.swift")

swift_hosts = {
    host.lower()
    for host in re.findall(r'"([^"]+)"', hosts_match.group(1))
}
if not swift_hosts:
    raise SystemExit("error: AppDeepLink.associatedHosts is empty")

extra_in_swift = sorted(swift_hosts - entitlement_hosts)
missing_in_swift = sorted(entitlement_hosts - swift_hosts)
if extra_in_swift or missing_in_swift:
    print(
        "error: AppDeepLink.associatedHosts must match applinks: entitlement hosts",
        file=sys.stderr,
    )
    if extra_in_swift:
        print(
            "  in Swift only (no entitlement — Safari handoff cannot work): "
            + ", ".join(extra_in_swift),
            file=sys.stderr,
        )
    if missing_in_swift:
        print(
            "  in entitlement only (parser will reject HTTPS): "
            + ", ".join(missing_in_swift),
            file=sys.stderr,
        )
    raise SystemExit(1)

print(
    "Associated Domains host parity OK:",
    ", ".join(sorted(entitlement_hosts)),
)

# --- Live-host DNS honesty (sample AASA ≠ Safari handoff) ---

def host_resolves(host: str) -> bool:
    try:
        socket.getaddrinfo(host, 443)
        return True
    except OSError:
        return False


unresolved = sorted(host for host in entitlement_hosts if not host_resolves(host))
resolved = sorted(host for host in entitlement_hosts if host not in set(unresolved))

if resolved:
    print("Live Associated Domains DNS resolved:", ", ".join(resolved))
if unresolved:
    print(
        "Live Associated Domains DNS NOT resolved (sample AASA only — "
        "Safari → app handoff not claimed):",
        ", ".join(unresolved),
    )
    # Stable honesty marker reviewers + CI can grep; must appear in cold-path docs.
    # Normalize whitespace so Markdown wrapping cannot dodge the check.
    marker = "does not currently resolve"
    honesty_files = {
        "docs/portfolio.md": portfolio_path,
        "Config/associated-domains/README.md": assoc_readme_path,
        "docs/navigation.md": nav_doc_path,
    }
    missing_markers: list[str] = []
    for label, path in honesty_files.items():
        try:
            text = open(path, encoding="utf-8").read()
        except OSError as exc:
            raise SystemExit(f"error: cannot read {label}: {exc}") from exc
        collapsed = re.sub(r"\s+", " ", text)
        if marker not in collapsed:
            missing_markers.append(label)
    if missing_markers:
        print(
            "error: entitlement host DNS unresolved, but honesty marker "
            f"'{marker}' missing from: " + ", ".join(missing_markers),
            file=sys.stderr,
        )
        print(
            "  Document that public DNS for the Associated Domains host "
            "does not currently resolve; prefer superdemo:// for reviewer "
            "cold-path until DNS + hosted AASA exist.",
            file=sys.stderr,
        )
        raise SystemExit(1)
    print(
        "Live-host honesty docs OK (marker present while DNS unresolved):",
        ", ".join(honesty_files),
    )
else:
    print("Live Associated Domains DNS OK for all entitlement hosts")
PY
