# Module And Feature Structure

Current project is a single app target. Keep structure simple until features
need separation.

## Suggested Feature Layout

```text
superDemoApp/
  Features/
    Items/
      Presentation/
      Domain/
      Data/
  Shared/
    DesignSystem/
    Networking/
    Persistence/
    Logging/
```

## Extraction Rule

- Do not create empty folders for imaginary future features.
- Extract shared code after two real call sites or one strong platform boundary.
- Keep feature-private helpers inside feature folder.
- Move cross-feature contracts to `Shared` only when stable.

## File Placement

- SwiftUI views: `Presentation`
- View models: `Presentation`
- Entities/use cases/protocols: `Domain`
- SwiftData/API/mappers: `Data`
- App composition: app root or `Composition`
