# Change: agent harness boundaries + evidence

Date: 2026-09-29

## Summary

Tighten agent harness around **boundaries** (credentialed / costly / hard-to-reverse
approvals) and **evidence** (~10 minute reconstructability), and slim one duplicated
context-ladder scaffold. Maps in `AGENTS.md` unchanged as routing.

## What changed

- [`agent_kb/agent_safety_contracts.md`](../agent_kb/agent_safety_contracts.md) —
  SAFETY-02 costly/external + SAFETY-04 credentials; SAFETY-REPORT reconstructability
- [`ai/ai_failure_risks.md`](../ai/ai_failure_risks.md) — `RISK-UNAPPROVED-EXTERNAL`
- [`agent_kb/safety-report-template.md`](../agent_kb/safety-report-template.md) —
  Evidence table (model/host, tools, changes, approvals)
- `./bin/agent-maintain closeout` — evidence reminders
- [`ai/harness-scorecard.md`](../ai/harness-scorecard.md) — Evidence area
- [`agent_knowledge_base.md`](../agent_knowledge_base.md) — drop duplicate Progressive
  Disclosure list; harness belief → boundaries + evidence
- PR template — Agent / AI checklist when harness/policy docs change

## Proof

```bash
./bin/agent-maintain closeout
./bin/checklist-fast
```
