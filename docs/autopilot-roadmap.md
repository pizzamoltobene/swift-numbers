# SwiftNumbers Autopilot Roadmap

Last updated: 2026-04-25
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

- [TODO] `SN-R12` Add grouped-table edit safety guard and diagnostics.
  - Definition of done: edits that would be unsafe on grouped tables fail fast with deterministic error + guidance instead of silent risk.
  - Validation: targeted grouped-table safety tests plus full `swift test`.

- [TODO] `SN-R13` Harden invalid selector UX in CLI (`sheet/table` name/index conflicts).
  - Definition of done: deterministic error messages for invalid or ambiguous selector combinations.
  - Validation: add CLI output tests and run `swift test --filter CLIOutputFormatTests`.

### M2 - CLI Expansion

- [TODO] `SN-R20` Add `export-csv` CLI command.
  - Definition of done: export table data to CSV with sheet/table selectors and optional formula/formatted output mode.
  - Validation: command help, fixture-based output tests, and docs updates.

- [TODO] `SN-R21` Add `import-csv` CLI command.
  - Definition of done: import CSV into a Numbers document with options for header/no-header and date parsing.
  - Validation: fixture-based import tests plus `swift test`.

- [TODO] `SN-R22` Add deterministic JSON snapshot tests for `read-cell`, `read-range`, and `read-table`.
  - Definition of done: goldens verify stable fields and no accidental key drops for all three commands.
  - Validation: `swift test --filter CLIOutputFormatTests`.

- [TODO] `SN-R23` Document and test CLI exit code contract.
  - Definition of done: docs define success/failure exit semantics; tests assert representative failures return non-zero.
  - Validation: docs updated and relevant test targets pass.

- [TODO] `SN-R24` Add compatibility tests around date/timezone formatting edge cases.
  - Definition of done: invalid timezone and locale-sensitive formatting paths are covered with deterministic assertions.
  - Validation: targeted date formatting tests plus full `swift test`.

- [TODO] `SN-R25` Add incremental formula-write support for basic arithmetic expressions.
  - Definition of done: support writing and round-tripping simple formulas (for example `=A1+B1`, `=SUM(A1:A5)`) with deterministic behavior.
  - Validation: targeted formula-write integration tests plus full `swift test`.

- [TODO] `SN-R26` Add pivot detection and structured pivot diagnostics in dump/read paths.
  - Definition of done: pivot structures are detected and exposed in diagnostics without unsafe mutation behavior.
  - Validation: fixture coverage for pivot detection and deterministic diagnostic output tests.

- [TODO] `SN-R27` Implement safe pivot-preserving write behavior.
  - Definition of done: non-pivot edits in documents containing pivots preserve pivot integrity or fail fast with explicit diagnostic.
  - Validation: roundtrip tests on pivot-containing fixtures.

### M3 - Native Tooling and Operations

- [TODO] `SN-R30` Remove remaining non-Swift dependencies from CI/release critical path.
  - Definition of done: CI and release scripts used in standard pipeline avoid Python/Node/Ruby runtime requirements.
  - Validation: run canonical CI script successfully without invoking non-Swift runtimes.

- [TODO] `SN-R31` Add "Autopilot Operations" documentation with unblock protocol.
  - Definition of done: docs explain roadmap-driven automation, pause/resume, and explicit unblock flow for `[BLOCKED]` tasks.
  - Validation: update docs hub and one dedicated operations doc.

- [TODO] `SN-R32` Add release checklist documentation aligned with current scripts.
  - Definition of done: release docs reference active scripts and expected artifacts.
  - Validation: update docs and run `swift build`.

### M4 - Continuous Releases

- [TODO] `SN-R40` Publish autonomous release policy for the repository.
  - Definition of done: repository docs explain cadence, quality gates, and when releases are paused.
  - Validation: policy doc linked from docs hub and README.

- [TODO] `SN-R41` Prepare next patch release from completed roadmap items.
  - Definition of done: version bump, changelog entry, and release notes prepared from `[DONE]` tasks.
  - Validation: release gate passes and changelog/release metadata are internally consistent.

- [TODO] `SN-R42` Move to recurring official releases for successful autonomous cycles.
  - Definition of done: successful release-eligible cycles consistently produce official Git releases.
  - Validation: multiple consecutive release cycles complete with passing gates and documented notes.

### M5 - Roadmap Renewal

- [TODO] `SN-R50` Enable automatic roadmap regeneration when backlog is exhausted.
  - Definition of done: when no `[TODO]` remains, automation generates the next milestone from `docs/autopilot-policy.md` with deterministic IDs and priority scoring.
  - Validation: simulated empty backlog produces a new milestone with at least 6 generated tasks.
