# Team Apple agent skills lockfile

## Summary

- Added tracked [`skills-lock.json`](../../skills-lock.json) pinning nine skills from
  [rshankras/claude-code-apple-skills](https://github.com/rshankras/claude-code-apple-skills).
- Gitignored `.agents/`; teammates restore copies with `npx skills experimental_install -y`.
- Documented setup in [`agent_host_notes.md`](../agent_host_notes.md),
  [`agents_quick_reference.md`](../agents_quick_reference.md), and Cursor template README.

## Skills pinned

`ios-development`, `macos-development`, `swift-development`, `design`, `testing`,
`release-review`, `security`, `apple-intelligence`, `app-store`.

## Agent impact

After clone (from git root `superDemoApp/`):

```bash
./tool/install-cursor-rules.sh
npx skills experimental_install -y
```

Reload Cursor. **Repo canon wins:** [`AGENTS.md`](../../AGENTS.md) and `docs/` override
skill defaults (Growth layers, `./bin/lint.sh`, design harness).

To add or bump a skill (project scope, not `-g`):

```bash
npx skills add https://github.com/rshankras/claude-code-apple-skills --skill <name> -y --agent cursor
```

Commit the updated `skills-lock.json`.
