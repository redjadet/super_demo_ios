# Design docs and Items reference feature

## Summary

- Added agent-readable [`DESIGN.md`](../../DESIGN.md) (DesignMD YAML + prose) and
  [`docs/design_system.md`](../design_system.md) (SwiftUI token map, locations, checklist).
- Added [`tool/check_design_md.sh`](../../tool/check_design_md.sh) (optional `@google/design.md` lint).
- Migrated list demo into `Features/Items/{Presentation,Domain,Data}/` with
  `App/ItemsComposition.swift` as composition root; removed flat `ContentView` / `Item`.
- `./bin/ci.sh` and GitHub Actions tests run serially by default to reduce simulator flakes.
- **Universal responsive UI:** `Shared/Presentation/AdaptiveNavigationShell.swift`
  (`NavigationSplitView` on all platforms), `featureScreenFrame()` /
  `featureSidebarColumnWidth()`, Items toolbar on screen root + empty-state Add for UI tests.
- **Previews:** `UniversalPreviewLayouts.swift` + iPhone / iPad / Mac / empty `#Preview`s on
  `ItemsView`.

## Agent impact

- UI work: read `DESIGN.md` + `docs/design_system.md` before editing Presentation code.
- Reference layout: `Features/Items/Presentation/` + shared shells in `Shared/Presentation/`.
- Master/detail: reuse `AdaptiveNavigationShell`; do not fork navigation per platform.
- `./bin/lint.sh` enforces layer imports; `./bin/checklist` / `./bin/checklist-fast` run
  DesignMD lint via `./tool/check_design_md.sh`.
- Platform proof: `./bin/ci-platform-builds.sh` (iPad + Mac) and full `./bin/ci.sh`.

## Proof

```bash
./bin/lint.sh
./bin/lint-markdown.sh
./tool/check_common_issues.sh
./bin/ci.sh
```
