# Changelog

All notable changes to this project are documented in this file.

## [0.2.2] - 2026-04-24

### Fixed

- `saveInPlace()` semantics now target the current working document path after `save(to:)`
  (instead of implicitly mutating only the original open-path).
- Repeated save calls no longer replay structural operations; mutation journal and dirty flags
  are cleared only after a successful write.
- Source baseline for subsequent saves now tracks the last successful destination, preventing
  stale-source copy behavior across multi-save workflows.
- Low-level write success now refreshes editable overlay metadata when source documents were
  originally overlay-backed, avoiding stale overlay values on reopen.
- Guarded invalid negative `CellAddress` writes to prevent inconsistent in-memory state.
- Added overflow-safe A1 column parsing for very long column labels.
- Protected editable date marker encoding by escaping conflicting user strings to avoid
  string/date misclassification on round-trip.
- Container metadata reads now return `nil` when package metadata directory is absent instead
  of throwing.
- Added duplicate-name hardening for write paths:
  - duplicate table names in a sheet are rejected in editable API
  - duplicate sheet names created via `addSheet(named:)` are auto-suffixed
  - ambiguous low-level `addTable` targeting now fails fast with a clear error

### Added

- Regression tests for:
  - replay-safe repeated saves
  - latest-path in-place save semantics
  - date-marker-looking string round-trip
  - overlay refresh correctness after low-level writes
  - duplicate table-name rejection
  - duplicate sheet-name suffixing
  - ambiguous `addTable` fail-fast behavior
  - metadata read behavior when `Metadata/` directory is missing

## [0.2.1] - 2026-04-23

### Fixed

- Fixed a runtime crash when decoding certain high-magnitude decimal payloads
  in real-read (`unpackDecimal128` no longer overflows `Int64`).
- Added explicit encrypted-document detection for `.numbers` files containing
  encryption markers (`.iwpv2` / `.iwph`).
- `NumbersDocument.open(at:)` now throws a clear unsupported error for encrypted
  documents instead of returning a misleading empty-sheet success path.

### Added

- Unit coverage for decimal128 overflow-safe decoding.
- Compatibility tests for encrypted marker detection and unsupported open-path
  behavior.

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
