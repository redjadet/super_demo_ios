# SAFETY-REPORT closeout template

Fill this before claiming non-trivial work done. Canon:
[`agent_safety_contracts.md`](agent_safety_contracts.md) (`SAFETY-REPORT`) and
[`legibility_and_finish_gate.md`](legibility_and_finish_gate.md).

Print reminders: `./bin/agent-maintain closeout`.

A teammate who was not in the session should reconstruct the run in
**~10 minutes** from this report + the named proof command output.

---

## SAFETY-REPORT

### What We Learned

- …

### Files Changed

| File | Summary |
| --- | --- |
| `path` | … |

### Verification

| Command | Result |
| --- | --- |
| `./bin/…` | Pass / Fail (+ note) |

### Evidence (reconstructability)

| Field | Value |
| --- | --- |
| Model / agent (if known) | e.g. Cursor cloud / Codex / local — name or “unknown” |
| Where it ran | host / VM / CI job / worktree path |
| Tools used | repo scripts, MCP, `gh`, Simulator, etc. (names only) |
| What changed | write-set summary or `git diff --stat` pointer |
| Risk approvals | SAFETY-02 actions: who approved, target, effect — or **None** |

### Known limitations

- …

### Follow-up Actions

- …

### Destructive / costly / external actions

None. *(Or list approved targets + effect + approver.)*

---

Do not treat an empty template as proof. Cite real command output.
Do not paste secrets, tokens, or credential values into evidence fields.
