# 2026-09-26 — On-device Vision OCR demo (JP-P2-C)

## Summary

Adds one labeled **on-device Vision** Engineering demo using
`VNRecognizeTextRequest` on a synthetic sample bitmap (or optional asset
`VisionDemoSample` if added later).

## Honesty

- **Not** Apple Intelligence, Speech, or a shipped Core ML model file
- Unavailable / no-text / failed states are explicit
- Pick was **Vision** (preferred over Speech / tiny Core ML for this slice)

## Paths

- `superDemoApp/Shared/OnDeviceAI/OnDeviceVisionDemo.swift`
- `Features/ProductionReadiness/Presentation/OnDeviceVisionDemoView.swift`
- Tests: `OnDeviceVisionDemoTests` (spy)

## Proof

- Unit: spy-driven recognized / unavailable / noText
- Hosted GHA: compile
- Local: Engineering demos → On-device Vision OCR → Recognize
