# Associated Domains (universal links)

App entitlement: `applinks:superdemo.app` (+ `?mode=developer` for local
developer-signed proof without a live AASA CDN). Apex only — do **not** add
`www.superdemo.app` to `AppDeepLink.associatedHosts` unless entitlement and a
live www AASA ship together. Gate:
`./tool/check_aasa_deep_links.sh` (paths + host↔entitlement parity).

## Hosting

Serve `apple-app-site-association` from the domain root **or**
`https://superdemo.app/.well-known/apple-app-site-association` with:

- `Content-Type: application/json` (no `.json` extension on the file name)
- HTTPS only
- No redirects on the AASA path

Replace the team ID prefix in `appIDs` if the signing team changes.

## Paths (must match `AppDeepLink`)

| HTTPS URL | App result |
| --- | --- |
| `https://superdemo.app/dashboard` | Dashboard |
| `https://superdemo.app/dashboard/risks` | Production Risks |
| `https://superdemo.app/feed` | Feed |
| `https://superdemo.app/feed/<id>` | Feed + select post when loaded (`/feed/*` in AASA) |
| `https://superdemo.app/items` | Items |

Custom scheme `superdemo://…` remains supported for UI tests and reviewers.
Gate: `./tool/check_aasa_deep_links.sh` (also via `./tool/check_common_issues.sh`).
