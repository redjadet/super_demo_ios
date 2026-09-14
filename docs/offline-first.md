# Offline-First With SwiftData

Default product posture: local data first, sync opportunistically.

## Principles

- Reads should work from local storage when possible.
- Writes should be recorded locally before remote sync when feature allows it.
- Sync must be idempotent and retryable.
- Conflicts need explicit policy: local wins, remote wins, merge, or user choice.
- UI should distinguish offline, syncing, synced, and failed states when relevant.

## SwiftData Rules

- Keep SwiftData models in Data layer once features grow.
- Map SwiftData models to Domain entities before business logic.
- Avoid leaking `ModelContext` into Domain.
- Document model changes that can affect existing stores.
- Add in-memory container fixtures for previews/tests.
- Consider SwiftData history when widgets, App Intents, extensions, or sync
  processes need to observe store changes over time.

## Migration Prompt

Before changing a persisted model, answer:

- Which existing records are affected?
- Can old app versions still read data?
- Is lightweight migration enough?
- What happens if migration fails?
- Which test or manual run proves fresh install and existing-store behavior?

## App container recovery

`App/AppModelContainer.swift` prefers the configured store (disk or in-memory for
UI tests). If creation fails (corrupt store / schema mismatch), it logs a release
diagnostic and falls back to an in-memory container so the app can still launch.
Only a total in-memory failure remains fatal after diagnostics.
