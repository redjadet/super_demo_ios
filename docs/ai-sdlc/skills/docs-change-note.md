# Skill: docs change note

Use after **durable** behavior, CI, or cross-cutting doc updates—not for typos
or single-line fixes unless they change reviewer-visible claims.

## Where

- Folder: [`../../changes/`](../../changes/README.md)
- Filename: `YYYY-MM-DD_short-slug.md`
- Index: add a bullet to [`../../changes/README.md`](../../changes/README.md)
  **Entries** section (newest first).

## Template

```markdown
# Short title

## Context
Why the change was needed (1–3 sentences).

## Change
- Bullet list of what moved.

## Proof
- Commands run (with outcomes or “not run on Linux VM”).
- Link to CI job or test name when relevant.

## Trade-offs / follow-ups
Optional; name residual risk or deferred work.
```

## Rules

1. **Honesty** — if a gate was not run locally, say so; name what CI will prove.
2. **No secrets** in notes or command output paste.
3. **Links** — relative paths only; `./bin/lint-markdown.sh` catches broken
   Markdown hrefs.
4. Keep notes **short**; ADRs live under [`../../adr/`](../../adr/README.md) for
   architectural decisions.

## Proof

- `./bin/lint-markdown.sh` on edited Markdown
- Included in `./bin/checklist-fast` common-issues link scan when paths touch
  guarded docs
