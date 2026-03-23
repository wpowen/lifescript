# LifeScript-Solo

Single-story interactive novel app scaffold.

## Current shape

- shared single-story shell: entry, reading, dossier, route map, settlement, settings
- shared runtime and models reused from `LifeScript-iOS`
- SKU-style packaging via `project.yml`, so one codebase can generate multiple single-novel apps
- current sample targets:
  - `LifeScriptSolo` -> `xianxia_001` / `命书·弃徒`
  - `LifeScriptSoloCultivation` -> `cultivation_full_001` / `残剑问仙`

## Generate and build

```bash
cd LifeScript-Solo
xcodegen generate
xcodebuild -project LifeScriptSolo.xcodeproj -scheme LifeScriptSolo -destination 'generic/platform=iOS' build-for-testing CODE_SIGNING_ALLOWED=NO
xcodebuild -project LifeScriptSolo.xcodeproj -scheme LifeScriptSoloCultivation -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
```

## SKU configuration

Each app target can override these `Info.plist` keys through `project.yml`:

- `SoloStoryID`
- `SoloPalettePreset`
- `SoloEntryEyebrow`
- `SoloPromise`
- `SoloContinueHint`
- `SoloCurrentRunTitle`
- `SoloRecapTitle`
- `SoloStageTitle`
- `SoloObjectiveTitle`
- `SoloDossierTitle`
- `SoloRouteMapTitle`
- `SoloSettlementTitle`
- `SoloChapterUnitName`
- `SoloAtmosphereLine`
- `SoloOrnamentSymbol`
