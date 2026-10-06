# Institutional skills (tool-agnostic)

Short reusable policy docs any agent can load. Not Claude-only skills or
Anthropic slash commands. Prefer these over conflicting vendor skill text when
the topic is this repo.

Apple platform skills restored from [`../../../skills-lock.json`](../../../skills-lock.json)
remain host-installed under gitignored `.agents/skills/` — see
[`../../agent_host_notes.md`](../../agent_host_notes.md). **Repo policy skills** live here.

| Skill | Load when |
| --- | --- |
| [`security.md`](security.md) | Auth, Keychain, logs, privacy, secrets, ATS |
| [`swift-concurrency.md`](swift-concurrency.md) | `async`/`await`, MainActor, cancellation, Tasks |
| [`offline-outbox.md`](offline-outbox.md) | Offline writes, queues, Feed cache, sync rules |
| [`flutter-add-to-app.md`](flutter-add-to-app.md) | `flutter_module/`, MethodChannel, embed scripts |

Cursor always-apply rules (installed from `tool/cursor-template/`) stay thin maps
into `AGENTS.md` + verify commands — they do not replace these skills.
