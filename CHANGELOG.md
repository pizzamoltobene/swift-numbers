# Changelog

All notable changes to this project are documented in this file.

## [0.2.0] - 2026-04-22

### Added

- Editable API layer:
  - `EditableNumbersDocument.open(at:)`
  - `sheet(named:)`, `table(named:)`
  - `setValue(_:at:)`, `appendRow(_:)`, `insertRow(_:at:)`, `appendColumn(_:)`
  - `addSheet(named:)`, `addTable(named:rows:columns:onSheetNamed:)`
  - `save(to:)`
  - `saveInPlace()`
- A1 addressing via `CellReference` plus `EditableCell` proxy (`table.cell("B3").value = ...`).
- `CellValue.date(Date)` support in the public value model.
- Dirty tracking (`clean`, `dataDirty`, `structureDirty`) and mutation operation journal.
- Swift-native editable save backend that persists metadata overlays without runtime Python dependencies.
- Initial low-level IWA writer path on real archive-backed documents for:
  - `setValue` (including `date` via stable marker encoding)
  - `appendRow`, `insertRow`, `appendColumn`
  - `addSheet`, `addTable`
- Round-trip editable tests and reference parser tests.
- Local release gate script: `scripts/release_check_020.sh` with machine-readable report output.

### Changed

- CI tests job now runs fully Swift-native for editable write tests (no Python writer bootstrap).
- README/quickstart docs updated for editable workflows and 0.2.0 release framing.
- Docs expanded into a full GitHub-friendly portal (`docs/index.md`) with dedicated API reference, cookbook,
  CLI reference, troubleshooting, architecture guide, and one-page-per-operation docs under
  `docs/operations/`.

### Notes

- Advanced Numbers features (formulas, pivots, charts, advanced formatting/layout fidelity) remain out of scope.
- `save(to:)` supports both new-path writes and same-path atomic in-place replace.

## [0.1.0] - 2026-04-22

### Added

- Public read-only API v0 for opening `.numbers` documents and reading sheets/tables/cells.
- CLI commands:
  - `swiftnumbers dump <file.numbers>`
  - `swiftnumbers list-sheets <file.numbers>`
  - JSON output mode via `--format json`.
- Real-read decode pipeline on typed Swift protobuf subset with structured diagnostics.
- Safe metadata fallback path with explicit reason tracking in dump output.
- Public synthetic fixture corpus and golden output tests.
- Local private-corpus integration flow with per-file expectations and helper scripts.
- CI baseline with format check, lint/warnings-as-errors build, tests, and coverage gate.
- Initial docs/branding package for GitHub presentation.

### Changed

- First-party coverage gate now evaluates only project-owned sources and tests.
- Protobuf asset layout and compatibility test naming were normalized for neutral terminology.

### Notes

- Real user files remain local-only and are intentionally excluded from version control.
- Formula engine, pivot tables, encrypted documents, and mutation APIs are out of scope for this release.
