# Adaptive Execution

Back: [Agent Knowledge Base](../agent_knowledge_base.md)

Use one small loop by default. Scale effort only when risk or uncertainty
requires it.

## Contract

1. Classify complexity, risk, scope, and uncertainty.
2. Define `Goal / Context / Boundaries / Verification` before non-trivial work.
3. Keep intent, spec, and implementation separate:
   - Intent: why, constraints, success shape.
   - Spec: measurable behavior and evaluation.
   - Implementation: current Apple repo architecture and validation.
4. Plan once, then execute end-to-end.
5. Ask only hard blockers: missing credentials/tooling, unsafe ambiguity below
   95% confident, or user-owned decision.
6. Do not edit until goal, scope, and approach are at least 95% confident.
7. Vague/risky work: state assumptions, data flow, failure handling, smallest
   verifiable slice, and what could be false about the codebase.
8. Debug work: reproduce or reason from concrete evidence, isolate cause, fix
   cause, verify.
9. Before report: check edge cases, failure paths, readability, operational
   clarity, and breakage impact.
10. Stop when value is met, material risks are handled, and proof matches scope.

## Search Budget

- Use one observe/revise loop before expanding search.
- Branch only when evidence pays: architecture, security, SwiftData migrations,
  CI, performance, release, or unclear root cause.
- Compare two or three approaches only when tradeoffs are real, then continue
  with one implementation.
- If verifier/critique rejects the patch, retry with concrete evidence once or
  twice, then replan or escalate.
- If output is almost correct, stop regenerating whole files. Patch minimal diff
  against current repo seams.
- Empty, truncated, or malformed tool output is missing proof. Retry narrower,
  inspect raw output, or report blocker.
- Use stable repo instructions before task-specific context.
- Trust senior-agent judgment inside boundaries; constrain outcomes and safety,
  not folder counts or order unless repo canon requires it.
