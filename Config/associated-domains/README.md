# Associated Domains (universal links)

App entitlement: `applinks:superdemo.app` (+ `?mode=developer` for local
developer-signed proof without a live AASA CDN). Apex only — do **not** add
`www.superdemo.app` to `AppDeepLink.associatedHosts` unless entitlement and a
live www AASA ship together. Gate:
`./tool/check_aasa_deep_links.sh` (paths + host↔entitlement parity + live-host
DNS honesty).

## Live host status

Public DNS for `superdemo.app` **does not currently resolve**. Safari → app
universal-link handoff is therefore **not** available and is **not** claimed.
The sample AASA below plus the entitlement document the intended hosting shape;
in-app HTTPS URL parsing still accepts apex paths. Prefer `superdemo://…` for
reviewer cold-path demos until DNS + a hosted AASA exist. The gate probes DNS
and requires this honesty marker while the host is unresolved.

## Hosting (when DNS exists)

Serve `apple-app-site-association` from the domain root **or**
`https://superdemo.app/.well-known/apple-app-site-association` with:

- `Content-Type: application/json` (no `.json` extension on the file name)
- HTTPS only
- No redirects on the AASA path

Replace the team ID prefix in `appIDs` if the signing team changes.

## Paths (must match `AppDeepLink`)

| HTTPS URL (parse-only until live host) | App result |
| --- | --- |
| `https://superdemo.app/dashboard` | Dashboard |
| `https://superdemo.app/dashboard/risks` | Production Risks |
| `https://superdemo.app/feed` | Feed |
| `https://superdemo.app/feed/<id>` | Feed + select post when loaded (`/feed/*` in AASA) |
| `https://superdemo.app/items` | Items |

Custom scheme `superdemo://…` is the supported reviewer / UI-test path today.
Gate: `./tool/check_aasa_deep_links.sh` (also via `./tool/check_common_issues.sh`).
