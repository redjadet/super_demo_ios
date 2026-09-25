# Design tokens ↔ Figma / DesignMD

Local mapping from [`../DESIGN.md`](../DESIGN.md) (DesignMD YAML + prose) to runtime
SwiftUI / asset roles. **No live Figma file is required** — this table is the
reviewer-facing token link for design-tool fluency.

| Token / role (DESIGN.md) | Runtime source | Notes |
| --- | --- | --- |
| `colors.primary` (`#0066CC`) | Semantic accent / filled button role | YAML for DesignMD WCAG; UI uses system-adjacent semantic colors |
| `colors.on-primary` | Filled button label | Light-on-primary |
| `colors.surface` / `on-surface` | List / form backgrounds + primary text | Light/dark via system |
| `colors.surface-container-low` / `highest` | Grouped surfaces, chrome | Asset + SwiftUI materials where used |
| `colors.outline-variant` | Separators / borders | Prefer system separators |
| `colors.error` / `success` | Error banner / status chips | Align with `ContentUnavailable` / diagnostics chrome |
| `typography.*` (System sizes) | SwiftUI text styles (`.title2`, `.headline`, `.body`, …) | Prefer semantic text styles over raw pt |
| `rounded.sm` / `md` | Card / chip corner radius | Keep consistent with `DESIGN.md` prose |
| `spacing.*` + `row-min: 44px` | Padding + hit targets | Meet Apple HIG minimum |
| Components (`button-filled`, `list-row`, `error-banner`, …) | Feature Presentation + shared chrome | See [`design_system.md`](design_system.md) |

**Authority:** When YAML and runtime diverge, update SwiftUI / assets first, then
sync `DESIGN.md`. Validate with `./tool/check_design_md.sh` (via
`./bin/checklist-fast`).

**Figma:** Optional export can mirror this table later; do not claim a linked
Figma library until a file URL is published by the maintainer.
