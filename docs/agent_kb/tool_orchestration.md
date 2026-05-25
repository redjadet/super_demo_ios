# Tool Orchestration

Back: [Agent Knowledge Base](../agent_knowledge_base.md)

See also: [Agent Environment Setup](../agent_environment_setup.md) and
[Agent Quick Reference](../agents_quick_reference.md).

Use tools as an execution system, not decoration.

- Prefer direct repo scripts, Xcode build/test output, simulator proof, fixtures,
  and available MCP/connectors over model memory when they can observe the real
  system.
- Use external MCP/connectors only for state they own: GitHub/CI, browser
  runtime, databases, documents, or app-store/release services.
- Keep secrets out of prompts, logs, screenshots, docs, and generated artifacts.
- Tool docs/templates should name what tool does, when to use it, required
  inputs, side effects, retry safety, and common failure modes.
- Search tools find likely files; targeted raw reads still confirm before edits.
- Mechanical tools can perform repetitive edits only after scope, write set, and
  validation are fixed. Final judgment stays with coordinating agent.
- More agents/tools are not automatically better. Add them when they reduce
  uncertainty, isolate context, or verify a risky decision.
- Setup details live in [agent_environment_setup.md](../agent_environment_setup.md).
