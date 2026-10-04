# 2026-10-04 — Restore shared-URLSession pattern check after SPM adopt

## Summary

After #77 removed in-tree `AppURLSession.swift`, `tool/check_agent_swift_patterns.sh`
skipped the per-call `URLSession` guard. Scan all `Shared/Networking/*.swift` for
local `makeDefault` allocations; document that SPM `DefaultURLSession` owns the
process-wide session (`AppURLSession` typealias). Align architecture /
production-risks / senior-patterns map wording with the SPM adopt.
