# TestFlight Release Notes

Verify production readiness beta:

- Seeded reviewer walkthrough for Dashboard, Production Risks, Feed, and Items.
- Typed `superdemo://dashboard/risks` deep link with cold-start, warm-start, and invalid-route fallback.
- HTTPS universal-link paths on `superdemo.app` parse the same routes in-app
  (sample AASA includes `/feed/*`); public DNS does not currently resolve, so
  Safari handoff is not claimed — prefer `superdemo://` fixtures.
- App Shortcuts: Open Feed, Open Items, Open Production Risks, Refresh Feed,
  Open Feed Post.
- Dashboard, Production Risks, Feed, and Items launch paths.
- Offline cached feed fallback and networking error states.
- iPhone, iPad, and Mac layout polish before release sign-off.
