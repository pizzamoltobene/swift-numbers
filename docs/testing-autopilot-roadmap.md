# SwiftNumbers Testing Autopilot Roadmap

Last updated: 2026-04-26
Target declared test count: `1000`
Baseline snapshot (`swift test` on 2026-04-26): `154` tests, `1` skipped, `0` failures.

## Goal

Run a deterministic, self-renewing testing-only loop that continuously increases first-party declared tests, hardens regression coverage, and protects output contracts across CLI/read/write paths.

Long-lived policy lives in [Testing Autopilot Policy](testing-autopilot-policy.md).

## Execution Contract (Mandatory)

1. This file is the single source of truth for testing-autopilot task order.
2. Execute only the first task marked `[TODO]`.
3. Exactly one task may be advanced per run.
4. If no `[TODO]` remains, run `./scripts/testing_backlog_synthesis.sh`.
5. Enforce run lock via `.local/testing-autopilot-lock.json`.
6. Set active task to `[IN_PROGRESS]` before edits and `[DONE]` or `[BLOCKED]` at run end.
7. Mandatory validation per run:
   - `swift build`
   - `swift test`
   - `./scripts/test-growth-report.sh --target 1000`
8. For user-visible test tooling or docs changes, update `README.md`, `docs/index.md`, and `CHANGELOG.md`.

## Status Legend

- `[TODO]`: queued
- `[IN_PROGRESS]`: currently being executed
- `[DONE]`: completed and validated
- `[BLOCKED]`: blocked with explicit root cause

## Ordered Backlog

### T0 - Testing Control Plane

- [DONE] `SN-T00` Add dedicated testing-autopilot policy, roadmap, and operations docs. (2026-04-26)
  - Definition of done: docs define test-only scope, cadence, synthesis rules, and unblock flow.
  - Validation: docs linked from hub and readable in-repo.

- [DONE] `SN-T01` Add deterministic test-growth reporting script. (2026-04-26)
  - Definition of done: script reports declared test count, target gap, suite distribution, and roadmap status.
  - Validation: `./scripts/test-growth-report.sh --target 1000`.

- [DONE] `SN-T02` Add deterministic testing backlog synthesis script. (2026-04-26)
  - Definition of done: synthesis appends scored `SN-TEST-YYYYMMDD-XX` TODO tasks with mandatory area coverage.
  - Validation: `./scripts/testing_backlog_synthesis.sh --dry-run`.

- [DONE] `SN-T03` Wire test-growth reporting into CI test workflow. (2026-04-26)
  - Definition of done: CI test job publishes growth summary every run.
  - Validation: `.github/workflows/ci.yml` includes growth report step.

### T1 - March to 300 Declared Tests

- [DONE] `SN-T10` Add CLI selector matrix tests for all conflict and missing-selector combinations. (2026-04-26)
  - Definition of done: CLI selector validation has deterministic coverage for command families (`read-cell`, `read-range`, `read-table`, `read-column`).
  - Validation: `swift test --filter CLIOutputFormatTests`.

- [DONE] `SN-T11` Add editable value-type matrix tests for package and single-file archives. (2026-04-26)
  - Definition of done: `setValue` coverage includes typed matrix for string/number/bool/date/formula/empty across both archive forms.
  - Validation: `swift test --filter EditableNumbersDocumentTests`.

- [DONE] `SN-T14` Add high-density `CellReference` round-trip matrix tests to accelerate deterministic declared-coverage baseline. (2026-04-26)
  - Definition of done: matrix adds deterministic A1 parse/format round-trip checks across broad row/column combinations with one assertion target per test.
  - Validation: `swift test --filter CellReferenceMatrixTests`.

- [TODO] `SN-T12` Add read API typed accessor mismatch matrix tests.
  - Definition of done: typed accessors are covered for nil and mismatch behavior with deterministic assertions.
  - Validation: `swift test --filter NumbersDocumentTests`.

- [TODO] `SN-T13` Add real-read formula fallback matrix for unsupported AST combinations.
  - Definition of done: fallback diagnostics and summaries stay deterministic across unsupported-node combinations.
  - Validation: `swift test --filter RealReadPipelineUnitTests`.

### T2 - March to 600 Declared Tests

- [TODO] `SN-T20` Expand structural mutation sequence matrix with save-to/saveInPlace permutations.
- [TODO] `SN-T21` Add grouped and pivot safety-guard matrix across write APIs.
- [TODO] `SN-T22` Add fixture variants for sparse, wide, and high-row-count tables.
- [TODO] `SN-T23` Add golden snapshots for list commands (`list-tables`, `list-formulas`) in text and JSON.

### T3 - March to 1000 Declared Tests

- [TODO] `SN-T30` Add deterministic integration matrix for import/export CSV workflows with typed coercion edges.
- [TODO] `SN-T31` Add private-corpus contract tests for manifest mismatch diagnostics and deterministic skip behavior.
- [TODO] `SN-T32` Add performance-smoke bounds for critical read commands on strict fixtures.
- [TODO] `SN-T33` Add periodic synthesis and growth reporting automation policy checks.
