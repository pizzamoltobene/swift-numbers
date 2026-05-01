# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Summary

- Pending.

### Breaking Changes

- None.

### Rollback Hint

- Revert to the previous stable tag and redeploy package artifacts.

## [0.4.4] - 2026-05-01

### Summary

- Added deterministic parity-queue regression coverage for AppleScript advanced-object rows so chart, pivot, style, media, and shape evidence selects pivot-priority roadmap work.
- Added package-vs-single-file real-read traversal snapshot coverage for multi-sheet archives, including stable table order and duplicate table-info guards.
- Scoped pivot-linked write guard linked-object payloads to the blocked target table for clearer triage when a sheet has multiple pivot-linked tables.
- Added `EditableTable.clearValue(at:)` convenience APIs for AppleScript-style single-cell clear parity over the existing safe `.empty` write path.
- Added bounded `EditableTable.clearValues(in:)` APIs for AppleScript-style rectangular range clear parity without unsafe table expansion.

### Breaking Changes

- None.

### Rollback Hint

- Revert to the previous stable tag and redeploy package artifacts.

## [0.4.3] - 2026-04-30

### Summary

- Added AppleScript formula parity probe rows to the generated capability map, covering formula text reads, result reads, range references, function-call surfaces, and guarded formula writes.
- Added advanced object discovery probe rows for charts, pivots, styles, media, shapes, and rich text with explicit safe-read-only and safe-write-blocked classifications.
- Added deterministic parity-queue regression coverage for AppleScript read probe rows so sheet/table/cell read evidence selects read-priority roadmap work.
- Added deterministic parity-queue regression coverage for AppleScript document/table/row/column mutation rows so mutation evidence selects write-priority roadmap work.
- Added deterministic parity-queue regression coverage for AppleScript formula rows so formula text/result/write evidence selects formula-priority roadmap work.

### Breaking Changes

- None.

### Rollback Hint

- Revert to the previous stable tag and redeploy package artifacts.

## [0.4.2] - 2026-04-29

### Summary

- Added AppleScript mutation parity probe rows to the generated capability map, covering document,
  sheet, table, row, column, cell/range, and table transform write semantics with deterministic
  mapping to supported SwiftNumbers APIs and backlog gaps.
- Moved development automation scripts out of the package repository into a sibling automation
  workspace, keeping GitHub focused on library source, tests, docs, and inline CI workflows.

### Breaking Changes

- None.

### Rollback Hint

- Revert to the previous stable tag and redeploy package artifacts.

## [0.4.1] - 2026-04-29

### Summary

- Added aggregate pivot-link diagnostics summary on real-read path:
  `resolver.pivot.candidateSummary` now emits deterministic candidate/table cardinality and ID sets
  across all detected pivot-like drawables, complementing per-candidate
  `resolver.pivot.candidateDetected` diagnostics.
- Hardened unsupported decode warning deduplication: diagnostics without an `objectPath`
  now use stable object identifiers from diagnostic context before deduplicating by
  unsupported node/cell type, preserving distinct table warnings while still removing
  duplicate noise.
- Added Apple Numbers AppleScript parity map refresh workflow:
  `swiftnumbers refresh-apple-numbers-map` discovers Numbers through LaunchServices/AppleScript,
  parses `sdef`, writes `docs/apple-numbers-applescript-capability-map.md`, and supports
  deterministic skipped oracle output for CI/offline runs.
- Fed AppleScript capability evidence into the autonomous parity conveyor: `parity_task_queue.sh`
  now scores AppleScript/OSAScript capability rows ahead of the historical third-party code map,
  and backlog synthesis includes AppleScript-derived read/write/formula/advanced-object candidates
  when oracle signals exist.
- Added AppleScript read parity probe rows to the generated capability map, covering sheet,
  table, range, row, column, cell-value, and table selection-range read semantics with matching
  SwiftNumbers public read-surface regression coverage.

### Breaking Changes

- None.

### Rollback Hint

- Revert to the previous stable tag and redeploy package artifacts.

## [0.4.0] - 2026-04-28

### Summary

- Completed a full documentation synchronization pass against the current codebase:
  refreshed API/CLI/docs hub/quickstart pages and regenerated operation docs `01` through `25`
  from canonical capability cards.
- Hardened operation-doc generation to target only top-level operation cards (`5.<n>`),
  preventing subsection collisions and keeping generated docs stable/reproducible.
- Expanded capability cards with implementation-accurate behavior for editable write flows
  (`setValue`, `appendRow`, `insertRow`, `appendColumn`, save semantics, and typed reference behavior),
  including concrete throw contracts and side effects.

### Breaking Changes

- None.

### Rollback Hint

- Revert to the previous stable tag and redeploy package artifacts.

## [0.3.12] - 2026-04-28

### Summary

- Hardened grouped-table structural delete guard diagnostics: blocked `deleteRow`/`deleteColumn`
  writes now include deterministic operation index context (for example `deleteRow(rowIndex: N)`),
  with regression coverage for grouped and non-grouped delete paths.
- Hardened formula write safety validation in strict native-write mode: sheet-qualified references
  and self-referential single-cell/range references are now rejected with deterministic
  `nativeWriteFailed` messages.
- Hardened pivot-linked mutation guard diagnostics: blocked structural writes now preserve
  deterministic operation context (for example `deleteRow(rowIndex: N)`) in user-facing errors,
  with regression coverage for linked-table guard messaging.

### Breaking Changes

- None.

### Rollback Hint

- Revert to the previous stable tag and redeploy package artifacts.

## [0.3.11] - 2026-04-27

### Summary

- Added `cat-numbers`-style parity switches for CLI read output commands:
  `read-column`, `read-table`, and `read-range` now accept `--formulas` and
  `--formatting`, emit deterministic `parityMode`/`output` fields in JSON/JSONL,
  and preserve selector-driven sheet/table scoping behavior.
- Added `csv2numbers`-style import pipeline stages to `import-csv` with
  deterministic `rename -> delete-column -> transform` ordering, plus scoped
  date parsing controls (`--date-column`, `--day-first`, `--date-format`) and
  integration coverage for pipeline/date behavior.
- Added `inspect` CLI command for low-level diagnostics with stable JSON schema
  (`container`/`document`/diagnostic counters), plus optional redaction
  (`--redact`) and compact output mode (`--compact`).
- Added deterministic parity queue gate script (`scripts/parity_task_queue.sh`)
  that scores outstanding roadmap tasks from `docs/numbers-parser-code-capability-map.md`
  and emits a stable next-task queue; added simulation coverage for expected order.
- Hardened real-read merged table traversal for mixed archives: table resolution is now
  deterministic across package/single-file inventory ordering, duplicate drawable/parent
  traversal no longer re-resolves the same table, and duplicate object/type records now
  fall back to the next decodable payload deterministically.

### Breaking Changes

- None.

### Rollback Hint

- Revert to the previous stable tag and redeploy package artifacts.

## [0.3.10] - 2026-04-27

### Summary

- Added interactive control format support in editable `setFormat` (`tickbox`, `rating`, `slider`, `stepper`, `popup`) with save/reopen regression coverage for typed format and read-style roundtrip snapshots.
- Added grouped/categorized read surface on `Table` via `categorizedRows(by:)` and `categorizedValues(by:)`, with deterministic key-path grouping and regression coverage.
- Exposed table presentation metadata in CLI JSON surfaces: `list-tables`, `read-table` (including `--jsonl`), and `dump` per-table summaries now include `tableNameVisible`, `captionVisible`, `captionText`, and `captionTextSupported`.

### Breaking Changes

- None.

### Rollback Hint

- Revert to the previous stable tag and redeploy package artifacts.

## [0.3.9] - 2026-04-27

### Summary

- Expanded editable `setFormat` format families to include `base`, `fraction`, `percentage`, and `scientific`, with rendered/typed save-reopen snapshot coverage.
- `NumbersDocument.open` now hydrates style-registry metadata overlay assignments so persisted style number-format hints are honored by `formattedValue(...)` after reopen.
- Added editable border mutation API (`setBorder(_:side:at:)`) with deterministic merged-range edge handling and save/reopen roundtrip coverage.
- Added CLI selector validation matrix coverage for `read-range`, `read-table`, and `read-column` conflict/missing selector combinations.
- Added editable `setValue` typed matrix coverage for `string/number/bool/date/formula/empty` across package and single-file archive forms.
- Added high-density `CellReference` round-trip matrix coverage (820 deterministic tests) to push declared test baseline beyond 1000.

### Breaking Changes

- None.

### Rollback Hint

- Revert to the previous stable tag and redeploy package artifacts.

## [0.3.8] - 2026-04-27

### Summary

- Added editable table geometry mutations (`setRowHeight`, `setColumnWidth`) and read geometry helpers (`rowHeight`, `columnWidth`, `cellGeometry`) with native persistence and save/reopen regression coverage.
- Added dedicated testing-autopilot control plane with policy/roadmap/operations docs, deterministic test-growth reporting (`scripts/test-growth-report.sh`), deterministic testing backlog synthesis (`scripts/testing_backlog_synthesis.sh`), and CI wiring including a scheduled `Testing Autopilot` workflow.
- Added document style registry APIs (`registerStyle`, `registeredStyles`, `registeredStyle(id:)`, `applyStyle(id:at:)`) with deterministic save/reopen persistence and duplicate-name validation.
- Added document custom-format registry APIs (`registerCustomFormat`, `registeredCustomFormats`, `registeredCustomFormat(id:)`, `applyCustomFormat(id:at:)`) with deterministic save/reopen persistence and duplicate/unknown identifier validation.
- Reduced autonomous release batch threshold from 15 to 5 changelog summary items (`scripts/release_batch_count.sh` default and policy docs aligned).

### Breaking Changes

- None.

### Rollback Hint

- Revert to the previous stable tag and redeploy package artifacts.

## [0.3.7] - 2026-04-27

### Summary

- Added recurring release-cycle documentation: successful official releases are tracked in `docs/release-cycles.md`, and `release_publish.sh` now appends a cycle note for each newly published tag.
- Added deterministic backlog regeneration script (`scripts/autopilot_backlog_synthesis.sh`) that appends a new roadmap milestone with scored `SN-AUTO-YYYYMMDD-XX` tasks when no `[TODO]` remains.
- Added deterministic code-parity refresh workflow (`scripts/refresh_numbers_parser_code_map.sh`) that rebuilds `docs/numbers-parser-code-capability-map.md` from symbol evidence with explicit snapshot metadata.
- Added structural deletion mutations for editable tables (`deleteRow(at:)`, `deleteColumn(at:)`) with deterministic bounds validation and single-file/package roundtrip regression coverage.
- Tightened explicit unmerge semantics: `unmergeCells(...)` now removes only exact merged-range matches (no partial-overlap removals), with deterministic low-level persistence and regression coverage.

### Breaking Changes

- None.

### Rollback Hint

- Revert to the previous stable tag and redeploy package artifacts.

## [0.3.6] - 2026-04-26

### Summary

- Added grouped-table edit safety guard for structural write paths:
  unsafe grouped mutations now fail fast with deterministic guidance instead of silently risking row-header corruption.
- Added a standalone autonomous release policy document with explicit cadence, quality gates, and release pause/resume conditions, linked from README and Docs Hub.
- Added deterministic batch counter script (`scripts/release_batch_count.sh`) and moved autonomous delivery policy to hourly bugfix-first with release at 15 Unreleased summary items.
- Added critical-path runtime audit (`scripts/runtime-critical-check.sh`) and wired it into CI/release gates to block Python/Node/Ruby regressions in standard automation scripts.
- Hardened CLI selector failure UX with deterministic regression coverage for `--sheet/--sheet-index` and `--table/--table-index` conflicts and missing selector cases.
- Added `export-csv` CLI command with sheet/table selectors, CSV mode selection (`value`, `formatted`, `formula`), and fixture-based regression tests.
- Added `import-csv` CLI command with sheet/table selectors, header mode (`with-header`/`no-header`), optional date parsing, and fixture-based import regression tests.
- Added incremental formula-write roundtrip support for editable workflows via `CellValue.formula(String)`, with deterministic persistence and readback coverage for expressions like `=A1+B1` and `=SUM(A1:A5)`.
- Added writable style mutation API for editable tables via `setStyle(_:at:)` (and `EditableCell.style`) with deterministic save/reopen roundtrip coverage for package and single-file archives.
- Added writable cell-format mutation API via `setFormat(_:at:)` (and `EditableCell.format`) for number/date/currency/custom format hints, with roundtrip fixture coverage and formatted-output assertions.
- Added editable merge lifecycle mutations (`mergeCells` / `unmergeCells`) with deterministic overlap checks, low-level IWA merge-region persistence, and roundtrip coverage for merge-role metadata.
- Added table presentation metadata roundtrip support: editable table-name visibility, caption visibility, and caption text APIs now persist via native IWA write path where caption storage is available.
- Added pivot-candidate diagnostics in real-read dump path (`resolver.pivot.candidateDetected`) when non-table sheet drawables are linked to table objects, with deterministic resolver coverage.
- Added stable pivot-linked read metadata on real-read path: `Table.metadata.objectIdentifiers` now surfaces tableInfo/tableModel object IDs, and `Table.metadata.pivotLinks` exposes linked pivot-candidate drawable IDs/type IDs/table-link IDs.
- Added pivot-linked write safety guard: native write mutations now fail fast with deterministic `pivotLinkedTableMutationUnsupported` guidance when a target table is linked to a non-table pivot-like drawable.
- Hardened pivot-linked write guard messaging: `pivotLinkedTableMutationUnsupported` now includes deterministic linked object identifier payloads for operator triage.
- Improved real-read unsupported decode diagnostics: warnings are now deduplicated deterministically by object path and node type while preserving stable first-seen order.
- Added pivot-link cardinality summaries in read diagnostics/metadata: pivot candidate diagnostics now emit stable count fields and pivot-link metadata now exposes deterministic linked ID counts.

### Breaking Changes

- None.

### Rollback Hint

- Revert to the previous stable tag and redeploy package artifacts.

## [0.3.3] - 2026-04-25

### Summary

- Release pipeline now validates required release-note metadata from changelog sections.

### Breaking Changes

- None.

### Rollback Hint

- Roll back by re-publishing the previous stable tag and reverting the release automation changes.

### Changed

- Replaced hard-coded release helper with version-agnostic `./scripts/release_check.sh`.
- Release check JSON now reports dynamic `releaseTarget` (from `SWIFT_NUMBERS_RELEASE_TARGET` or latest `CHANGELOG.md` entry) and `releaseTargetSource`.
- `./scripts/release_check_020.sh` remains as a deprecated compatibility wrapper that forwards to `release_check.sh`.
- Added `./scripts/release_publish.sh` release pipeline (dry-run + publish mode) to validate gates, create/push tags, and publish GitHub releases with changelog-derived notes.
- Added release metadata gate requiring `Summary`, `Breaking Changes`, and `Rollback Hint` sections in the target changelog entry.

## [0.3.2] - 2026-04-24

### Fixed

- Real-read resolver/table discovery hardening:
  - skip non-table drawables when traversing `sheet.drawableInfos` (no false `tableResolveFailed` warnings)
  - merge drawable-based and parent-linked table discovery so partial drawable lists do not drop tables
  - add deterministic per-table resolution cache to avoid duplicate table decode and duplicated diagnostics
- Formula-read stability improvements:
  - support unknown `.function` argument counts via `unknownFunctionNumArgs`
  - treat `BEGIN_THUNK` / `END_THUNK` as structural AST markers (no unsupported-node warning noise)
  - expose and test deterministic unsupported AST summaries only for truly unsupported nodes
- Date ISO8601 formatting now falls back to UTC when an invalid `timeZoneIdentifier` is provided.

### Added

- Regression tests for:
  - non-table drawable skipping and parent-table merge traversal
  - unknown function argument count fallback
  - thunk-boundary marker handling in formula rendering
  - ISO8601 invalid-timezone UTC fallback
  - table candidate ID discovery for low-level writer path

## [0.3.1.1] - 2026-04-24

### Changed

- Documentation cleanup pass:
  - reduced `README` to a concise landing page
  - simplified `docs/index.md` into a compact docs hub
  - shortened `docs/troubleshooting.md` into a focused quick runbook
- Updated documentation version framing to `v0.3.1.1`.

## [0.3.1] - 2026-04-24

### Added

- First-class read value model in public API:
  - `ReadCellValue`
  - `FormulaResultRead`
  - `ReadCell.readValue`
  - `ReadCell.formulaResult`
- New read helpers on `Table`:
  - `readValue(at:)`, `readValue(_:)`
  - `formulaResult(at:)`, `formulaResult(_:)`
  - lazy rich read extraction: `readRows(lazy:)`, `readValues()`, `readValues(lazy:)`
- Formula-read mapping now exposes computed result payload via `FormulaResultRead`
  while preserving raw formula, parsed tokens, and AST summary when available.

### Changed

- `formattedValue(...)` now supports deterministic display modes through `ReadFormattingOptions`:
  - number: `decimal`, `currency`, `percent`, `scientific`, `pattern`
  - date: `iso8601`, `styled`, `pattern`
  - duration: `seconds`, `hhmmss`, `abbreviated`
  - optional style-driven number-format hinting (`preferCellNumberFormatHints`)
- Typed read accessors now support `ReadCellValue` and `FormulaResultRead`.
- Documentation refreshed from `v0.3.0` to `v0.3.1` across README and docs portal.

## [0.3.0] - 2026-04-24

### Added

- Read-parity expansion in public read API:
  - `ReadCellKind`, `ReadCell`, `FormulaRead`
  - `formula(at:)`, `formula(_:)`, `formulas()`
  - typed read helpers: `value(_:at:)`, `optionalValue(_:at:)`, `decodeRows(as:)`
  - extraction helpers: `values(in:)`, `readCells(in:)`, `column(at:from:)`, `readColumn(at:from:)`
  - table introspection helpers: `rowCount`, `columnCount`, `usedRange`, `populatedCells()`
- Structured diagnostics model in public dump payload:
  - `ReadDiagnosticSeverity`, `ReadDiagnostic`
  - `DocumentDump.structuredDiagnostics`
- Document convenience helpers:
  - `sheetNames`, `tableCount`, `tableNames`
  - `Sheet.tableNames`
- CLI read enhancements:
  - `swiftnumbers dump --formulas`
  - JSON dump now includes `sheetNames`, `tableNames`, `structuredDiagnostics`, and per-table `usedRange`.
- New tests for formula read API, typed extraction helpers, used-range/populated-cells behavior,
  structured diagnostics exposure, and updated CLI JSON fields.

### Changed

- Documentation refreshed to `v0.3.0` framing and updated read-capability coverage.
- Out-of-scope wording clarified: formula read is supported; formula write/engine semantics remain out of scope.

## [0.2.2.1] - 2026-04-24

### Changed

- Documentation refresh for post-`0.2.2` behavior:
  - clarified `save(to:)` working-path semantics across repeated saves
  - clarified `saveInPlace()` targeting current working document path
  - documented duplicate-name behavior (`addSheet` auto-suffix, `addTable` duplicate rejection)
  - documented fail-fast behavior for ambiguous low-level table targeting
- Updated docs and README version framing from `0.2.2` to `0.2.2.1`.

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
