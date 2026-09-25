# SAFETY-REPORT — closeout template

Copy this shape into the session closeout (PR body, change note, or chat
report). Canonical contract:
[`agent_safety_contracts.md`](agent_safety_contracts.md) (`SAFETY-REPORT`).
Self-verify first via
[`legibility_and_finish_gate.md`](legibility_and_finish_gate.md).

Do not invent proof. Cite exact commands and outcomes. No secrets.

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
| `./bin/…` | Pass / Fail + brief note |

### Known Limitations

- … (or “None for this slice”)

### Follow-up Actions

- … (or “None”)

### Destructive / external actions

None. *(If any: name targets, approval message, and effect.)*

---

## Minimal fill rules

| Section | Required |
| --- | --- |
| What We Learned | ≥1 durable lesson, or “N/A — routine docs/wiring” |
| Files Changed | Every path in the write-set (or link to `git diff --stat`) |
| Verification | Honest gate from [`../agents_quick_reference.md`](../agents_quick_reference.md) |
| Known Limitations | Residual risk, skipped lanes, or explicit none |
| Follow-up Actions | Next slice, human merge, or none |
| Destructive / external | Always state none or name approved action |

Sanitized teaching sample (Flutter parity shape, not iOS proof): see plan sources
under Flutter `docs/ai/sanitized_aidlc_safety_report_sample.md` — do not paste as
real evidence.
