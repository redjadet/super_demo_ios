# Sync And Networking

No network layer exists yet. Use this when adding remote data.

## Networking Rules

- Use typed request and response models.
- Keep URLSession details in Data.
- Decode into DTOs, then map to Domain.
- Support cancellation.
- Set explicit timeout and retry policy where product needs it.
- Never build URLs with unescaped string concatenation.

## Sync Rules

- Local write first when offline-first requirement applies.
- Queue pending operations with stable IDs.
- Make retries idempotent.
- Track sync state per record or operation.
- Handle conflict policy explicitly.
- Surface durable failure state to users when action cannot complete.

## Security

- Keep secrets out of repo and logs.
- Use least-privilege API tokens.
- Validate server trust and auth state before mutation.
- Document privacy-label impact for any collected, linked, tracking, diagnostic,
  or third-party-shared data.
- Prefer background/off-main processing for parsing, sync reconciliation, image
  processing, and other heavy work.
