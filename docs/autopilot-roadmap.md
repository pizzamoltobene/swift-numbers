# SwiftNumbers Autopilot Roadmap

Last updated: 2026-04-26
Scope baseline: `v0.3.2`

## Goal

Run a deterministic, self-renewing autonomous development loop for `swift-numbers` where every cycle executes one planned task, validates changes, updates user-facing docs, and moves toward frequent official releases.

## Public Project Direction

`SwiftNumbers` is positioned as an experimental library built through automated development and recurring delivery.
The roadmap below defines what the automation is allowed to do and in what order.
Long-lived improvement policy is defined in [Autopilot Policy](autopilot-policy.md).

## Perpetual Improvement Themes

- read reliability and compatibility
- write reliability and safe persistence
- formula read/write support
- pivot read/write safety and feature coverage
- deterministic CLI behavior and strong docs/releases

## Execution Contract (Mandatory)

1. This file is the single source of truth for Autopilot scope.
2. Autopilot must execute only the first task marked `[TODO]` in `## Ordered Backlog`.
3. Exactly one backlog task may be advanced per run.
4. If no `[TODO]` exists, run backlog synthesis from `docs/autopilot-policy.md`, append a new milestone, and then continue from the first generated `[TODO]`.
5. Enforce run mutex/lease via `.local/autopilot-lock.json`:
   - fresh lock from another run => exit without changing tasks
   - stale lock => recover and continue with explicit takeover note
6. Before edits, set current task status to `[IN_PROGRESS]` and keep lock heartbeat updated during execution.
7. No out-of-roadmap work is allowed unless a task is marked `[BLOCKED]` with a clear reason.
8. Every implementation run must execute:
   - `swift build`
   - `swift test`
9. For any user-visible behavior change, update relevant docs (`README.md`, `CONTRIBUTING.md`, and `docs/*`) plus `CHANGELOG.md`.
10. On successful release-eligible runs, follow release flow: changelog entry, version bump, tag/release notes preparation, and publish.
11. When a task is completed, change status from `[IN_PROGRESS]` to `[DONE]` and add completion date in parentheses.
12. If blocked, change status to `[BLOCKED]`, add reason, release lock, and stop. Do not start the next task in the same run.

## Status Legend

- `[TODO]`: queued, not started
- `[IN_PROGRESS]`: actively being executed by a lock holder run
- `[DONE]`: completed and validated
- `[BLOCKED]`: cannot proceed without external decision/input

## Ordered Backlog

### M0 - Control Plane and Release Engine

- [DONE] `SN-R00` Lock automation execution to this roadmap file. (2026-04-25)
  - Definition of done: the automation prompt explicitly points to this file and enforces first-`[TODO]` execution.
  - Validation: inspect `/Users/bondp/.codex/automations/swift-numbers-scout/automation.toml`.

- [DONE] `SN-R01` Remove Python dependency from coverage gate tooling. (2026-04-25)
  - Definition of done: `scripts/coverage-summary.sh` no longer calls `python`/`python3`; coverage JSON parsing is implemented in Swift-native tooling.
  - Validation: `rg -n "python|python3" scripts/coverage-summary.sh` returns no matches; `./scripts/coverage-summary.sh --skip-test --threshold 70` succeeds.

- [DONE] `SN-R02` Replace `scripts/release_check_020.sh` with a version-agnostic release gate script. (2026-04-25)
  - Definition of done: release check script name and payload no longer hard-code `0.2.0`; report includes dynamic target version.
  - Validation: run `./scripts/release_check.sh` and confirm dynamic `releaseTarget` + `releaseTargetSource` fields in report JSON.

- [DONE] `SN-R03` Publish public docs describing the autonomous development model. (2026-04-25)
  - Definition of done: `README.md`, `CONTRIBUTING.md`, and docs hub explain the automated cadence and documentation/release expectations.
  - Validation: each document contains autonomous development guidance with no competitor references.

- [DONE] `SN-R04` Implement official release automation flow for successful cycles. (2026-04-25)
  - Definition of done: release pipeline can commit/tag/publish with release notes after gates pass.
  - Validation: dry-run plus at least one successful official release.

- [DONE] `SN-R05` Add release-note template and changelog completeness checks. (2026-04-25)
  - Definition of done: release output always includes human-readable summary, breaking-change note, and rollback hint.
  - Validation: CI/release gate fails when required release metadata is missing.

### M1 - Reliability Advantage

- [DONE] `SN-R10` Add regression coverage for mixed mutation sequences before save. (2026-04-25)
  - Definition of done: tests cover combinations of `setValue`, `insertRow`, `appendColumn`, and `saveInPlace`.
  - Validation: targeted tests pass and `swift test` remains green.

- [DONE] `SN-R11` Add regression test for package vs single-file archive consistency on read APIs. (2026-04-25)
  - Definition of done: same logical fixture is exercised in both container forms with equivalent read results.
  - Validation: new consistency test plus full `swift test`.

- [DONE] `SN-R12` Add grouped-table edit safety guard and diagnostics. (2026-04-25)
  - Definition of done: edits that would be unsafe on grouped tables fail fast with deterministic error + guidance instead of silent risk.
  - Validation: targeted grouped-table safety tests plus full `swift test`.

- [DONE] `SN-R13` Harden invalid selector UX in CLI (`sheet/table` name/index conflicts). (2026-04-25)
  - Definition of done: deterministic error messages for invalid or ambiguous selector combinations.
  - Validation: add CLI output tests and run `swift test --filter CLIOutputFormatTests`.

### M2 - CLI Expansion

- [DONE] `SN-R20` Add `export-csv` CLI command. (2026-04-25)
  - Definition of done: export table data to CSV with sheet/table selectors and optional formula/formatted output mode.
  - Validation: command help, fixture-based output tests, and docs updates.

- [DONE] `SN-R21` Add `import-csv` CLI command. (2026-04-25)
  - Definition of done: import CSV into a Numbers document with options for header/no-header and date parsing.
  - Validation: fixture-based import tests plus `swift test`.

- [DONE] `SN-R22` Add deterministic JSON snapshot tests for `read-cell`, `read-range`, and `read-table`. (2026-04-25)
  - Definition of done: goldens verify stable fields and no accidental key drops for all three commands.
  - Validation: `swift test --filter CLIOutputFormatTests`.

- [DONE] `SN-R23` Document and test CLI exit code contract. (2026-04-25)
  - Definition of done: docs define success/failure exit semantics; tests assert representative failures return non-zero.
  - Validation: docs updated and relevant test targets pass.

- [DONE] `SN-R24` Add compatibility tests around date/timezone formatting edge cases. (2026-04-25)
  - Definition of done: invalid timezone and locale-sensitive formatting paths are covered with deterministic assertions.
  - Validation: targeted date formatting tests plus full `swift test`.

- [DONE] `SN-R25` Add incremental formula-write support for basic arithmetic expressions. (2026-04-25)
  - Definition of done: support writing and round-tripping simple formulas (for example `=A1+B1`, `=SUM(A1:A5)`) with deterministic behavior.
  - Validation: targeted formula-write integration tests plus full `swift test`.

- [DONE] `SN-R26` Add pivot detection and structured pivot diagnostics in dump/read paths. (2026-04-25)
  - Definition of done: pivot structures are detected and exposed in diagnostics without unsafe mutation behavior.
  - Validation: fixture coverage for pivot detection and deterministic diagnostic output tests.

- [DONE] `SN-R27` Implement safe pivot-preserving write behavior. (2026-04-26)
  - Definition of done: non-pivot edits in documents containing pivots preserve pivot integrity or fail fast with explicit diagnostic.
  - Validation: roundtrip tests on pivot-containing fixtures.

### M3 - Native Tooling and Operations

- [DONE] `SN-R30` Remove remaining non-Swift dependencies from CI/release critical path. (2026-04-26)
  - Definition of done: CI and release scripts used in standard pipeline avoid Python/Node/Ruby runtime requirements.
  - Validation: run canonical CI script successfully without invoking non-Swift runtimes.

- [DONE] `SN-R31` Add "Autopilot Operations" documentation with unblock protocol. (2026-04-26)
  - Definition of done: docs explain roadmap-driven automation, pause/resume, and explicit unblock flow for `[BLOCKED]` tasks.
  - Validation: update docs hub and one dedicated operations doc.

- [DONE] `SN-R32` Add release checklist documentation aligned with current scripts. (2026-04-26)
  - Definition of done: release docs reference active scripts and expected artifacts.
  - Validation: update docs and run `swift build`.

### M4 - Capability Parity Program

- [DONE] `SN-R40` Establish external capability baseline matrix and prioritized gap list. (2026-04-26)
  - Definition of done: docs include a current capability matrix for read/write/style/formatting/pivot/group behavior and a ranked implementation queue.
  - Validation: matrix doc added, linked from docs hub, and roadmap priorities updated from matrix output.

- [DONE] `SN-R41` Expand read style fidelity for font and text-color metadata. (2026-04-26)
  - Definition of done: read model exposes font name, font size, bold/italic state, and text color when present in source document.
  - Validation: unit/integration tests cover style extraction and `swift test` passes.

- [DONE] `SN-R42` Add writable style application API for editable tables. (2026-04-26)
  - Definition of done: editable API can apply style bundles to target cells with deterministic roundtrip behavior.
  - Validation: save/reopen tests assert style persistence across package and single-file archives.

- [DONE] `SN-R43` Add writable cell-format API for number/date/currency/custom formats. (2026-04-26)
  - Definition of done: editable API supports setting core format types and preserves display output after save/reopen.
  - Validation: fixture tests assert formatted output and style hints for each format mode.

- [DONE] `SN-R44` Add merge/unmerge mutation operations. (2026-04-26)
  - Definition of done: editable API can create and remove merge ranges safely with deterministic merge metadata updates.
  - Validation: merge roundtrip tests pass for read-cell/read-range/read-table behavior.

- [DONE] `SN-R45` Add table presentation metadata APIs (caption/table-name visibility and caption text). (2026-04-26)
  - Definition of done: table metadata read/write includes caption text and visibility toggles where supported.
  - Validation: save/reopen tests confirm metadata persistence.

- [DONE] `SN-R46` Add grouped-table safe edit mode for non-structural writes. (2026-04-26)
  - Definition of done: grouped tables remain protected for unsafe structural edits but allow safe cell updates with deterministic row mapping.
  - Validation: grouped fixture tests pass and unsafe operations still fail fast with explicit diagnostics.

- [DONE] `SN-R47` Expand pivot support with structured read surface while keeping safe-write guarantees. (2026-04-26)
  - Definition of done: pivot-linked structures are surfaced in read APIs/diagnostics with stable identifiers; unsafe writes remain blocked.
  - Validation: pivot fixtures expose deterministic read payloads and write-guard tests remain green.

### M5 - Continuous Releases

- [DONE] `SN-R50` Publish autonomous release policy for the repository. (2026-04-26)
  - Definition of done: repository docs explain cadence, quality gates, and when releases are paused.
  - Validation: policy doc linked from docs hub and README.

- [TODO] `SN-R51` Prepare next patch release from completed roadmap items.
  - Definition of done: version bump, changelog entry, and release notes prepared from `[DONE]` tasks.
  - Validation: release gate passes and changelog/release metadata are internally consistent.

- [TODO] `SN-R52` Move to recurring official releases for successful autonomous cycles.
  - Definition of done: successful release-eligible cycles consistently produce official Git releases.
  - Validation: multiple consecutive release cycles complete with passing gates and documented notes.

### M6 - Roadmap Renewal

- [TODO] `SN-R60` Enable automatic roadmap regeneration when backlog is exhausted.
  - Definition of done: when no `[TODO]` remains, automation generates the next milestone from `docs/autopilot-policy.md` with deterministic IDs and priority scoring.
  - Validation: simulated empty backlog produces a new milestone with at least 6 generated tasks.

### M7 - Code-Verified numbers-parser Conveyor

Code baseline source for this milestone:
`docs/numbers-parser-code-capability-map.md` (commit `65076c1` snapshot).

- [TODO] `SN-R70` Add deterministic code-parity refresh workflow.
  - Definition of done: parity map is refreshed from code references with stable sections and explicit snapshot metadata.
  - Validation: map update script/process can regenerate matrix without manual reformatting drift.

- [TODO] `SN-R71` Add row/column deletion mutations to editable API.
  - Definition of done: editable tables support `deleteRow` and `deleteColumn` with deterministic index semantics.
  - Validation: package + single-file roundtrip tests cover delete behavior and bounds errors.

- [TODO] `SN-R72` Add explicit unmerge mutation support.
  - Definition of done: merged ranges can be removed through public editable API with deterministic merge metadata updates.
  - Validation: merge/unmerge roundtrip tests pass for read-cell/read-range/read-table and metadata paths.

- [TODO] `SN-R73` Add header-row/header-column mutation API.
  - Definition of done: editable API can set table header row/column counts and persists values after save/reopen.
  - Validation: fixture tests confirm header semantics and selector behavior in CLI/read APIs.

- [TODO] `SN-R74` Add table geometry mutation/read API (row height, column width, coordinates).
  - Definition of done: geometry metadata can be read and mutated through supported APIs with persistence guarantees.
  - Validation: save/reopen tests assert geometry values on edited cells/tables.

- [TODO] `SN-R75` Add document style registry APIs.
  - Definition of done: editable document API can create/list reusable styles and apply them by identifier.
  - Validation: style registry tests cover create/apply/save/reopen and duplicate-name handling.

- [TODO] `SN-R76` Add document custom-format registry APIs.
  - Definition of done: editable document API can create/list named custom formats and apply them to cells.
  - Validation: custom format tests cover datetime/number/text variants and persistence.

- [TODO] `SN-R77` Add border mutation API for editable cells.
  - Definition of done: editable API can set cell borders by side with deterministic conflict handling for merged ranges.
  - Validation: border roundtrip tests verify side-specific persistence and merged-edge behavior.

- [TODO] `SN-R78` Expand format write API with extended numeric families.
  - Definition of done: format API supports base, fraction, percentage, and scientific modes in addition to existing core formats.
  - Validation: formatting snapshot tests verify rendered and typed outputs for each new mode.

- [TODO] `SN-R79` Add interactive control format support.
  - Definition of done: editable API supports tickbox, rating, slider, stepper, and popup formatting modes where supported.
  - Validation: regression fixtures verify serialization and readback behavior for control-formatted cells.

- [TODO] `SN-R80` Add categorized/grouped data read surface.
  - Definition of done: read API exposes grouped/categorized table data without enabling unsafe structural writes.
  - Validation: grouped fixtures return deterministic categorized payloads and existing safety guards remain active.

- [TODO] `SN-R81` Expose table presentation metadata in read/CLI surfaces.
  - Definition of done: caption and table-name visibility metadata are exposed in read models and CLI JSON output.
  - Validation: `dump`/`list-tables`/`read-table` JSON tests include stable presentation fields.

- [TODO] `SN-R82` Add `cat-numbers` parity switches to CLI output commands.
  - Definition of done: CLI supports parity-level formula/formatted-output toggles with sheet/table filtering and deterministic text/JSON behavior.
  - Validation: CLI snapshot tests cover flag combinations and filtering edge cases.

- [TODO] `SN-R83` Add `csv2numbers`-style transform pipeline to import workflow.
  - Definition of done: import workflow supports rename/delete/transform stages plus date parsing options with deterministic ordering.
  - Validation: import-csv integration tests verify transform correctness on fixture datasets.

- [TODO] `SN-R84` Add unpack/inspection CLI command for low-level diagnostics.
  - Definition of done: CLI can emit structured low-level object/container diagnostics with optional redaction and compact output.
  - Validation: fixture-based CLI tests verify stable machine-readable output schemas.

- [TODO] `SN-R85` Add parity scoring gate into autonomous queueing.
  - Definition of done: each cycle can compute outstanding parity tasks from the code map and queue next eligible backlog item deterministically.
  - Validation: simulated cycle run generates expected next-task order from matrix scores.
