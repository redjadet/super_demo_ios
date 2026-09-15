# Associated Domains (universal links)

App entitlement: `applinks:superdemo.app` (+ `?mode=developer` for local
developer-signed proof without a live AASA CDN).

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
| `https://superdemo.app/items` | Items |

Custom scheme `superdemo://…` remains supported for UI tests and reviewers.
