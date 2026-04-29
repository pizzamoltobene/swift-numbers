# SwiftNumbers Testing Autopilot Policy

Last updated: 2026-04-26

## Purpose

Define perpetual rules for a dedicated testing-only automation loop in `swift-numbers`.

This loop owns test growth, regression hardening, fixture expansion, and deterministic output contracts.
It does not own feature expansion except when a tiny production fix is strictly required to unblock a test that captures an existing expected contract.

## Target Outcome

- Reach and sustain at least `1000` declared tests in first-party test suites.
- Keep first-party line coverage at or above the baseline gate.
- Preserve deterministic behavior across CLI outputs, read/write APIs, and low-level parser diagnostics.

## Scope Boundaries

In scope:
- test additions and refactors under `Tests/`
- test fixtures and goldens
- test-only helper APIs
- test automation docs and scripts

Out of scope unless explicitly unblocking a failing regression assertion:
- feature work in production modules
- broad architecture changes unrelated to test reliability

## Cadence and Delivery Model

- Execution cadence: hourly or scheduled recurring runs.
- Exactly one testing roadmap task per run.
- Prefer small, reviewable test diffs over large batch commits.
- Test-growth loop runs independently from feature roadmap loop.

## Perpetual Focus Areas (Priority Order)

1. CLI deterministic contracts and selector validation
2. Editable mutation safety and roundtrip reliability
3. Read-surface compatibility and typed accessor contracts
4. Real-read pipeline diagnostics and fallback determinism
5. Fixture diversity (sparse, wide, grouped, pivot-linked)
6. Golden snapshot stability and regression detection
7. Performance-smoke bounds for critical read commands

## Continuous Input Signals

Testing backlog synthesis must score signals from:

- failing or flaky tests
- coverage hotspots in first-party sources
- changed source files without nearby regression tests
- TODO/FIXME markers in sources and tests
- CLI output drift against goldens
- parser diagnostic instability
- integration skip-rate and private corpus drift

## Backlog Synthesis Rules (When No `[TODO]` Exists)

1. Run synthesis command:
   - `../swift-numbers-automation/scripts/testing_backlog_synthesis.sh`
2. Produce at least `12` candidate testing tasks.
3. Score each candidate:
   - Impact: `1..5`
   - Risk: `1..5`
   - Effort: `1..5`
   - Confidence: `1..5`
   - EstimatedTests: positive integer estimate
4. Compute rank with growth weighting:
   - `priorityScore = (Impact * Confidence) - (Risk + Effort) + GrowthWeight`
   - `GrowthWeight = ceil(EstimatedTests / 20)`
5. Select top tasks with mandatory area coverage:
   - at least 1 task for `cli`
   - at least 1 task for `editable`
   - at least 1 task for `read`
   - at least 1 task for `pipeline`
6. Append selected tasks to `docs/testing-autopilot-roadmap.md`.
7. Assign deterministic IDs:
   - `SN-TEST-YYYYMMDD-01`, `SN-TEST-YYYYMMDD-02`, ...

## Validation Gates Per Run

Every testing-autopilot run must execute:

- `swift build`
- `swift test`
- `../swift-numbers-automation/scripts/test-growth-report.sh --target 1000`
- `../swift-numbers-automation/scripts/coverage-summary.sh --threshold 70`

## Growth Guardrails

- Declared test count must be non-decreasing in normal operation.
- New tests should target behavior contracts, edge cases, and deterministic output stability.
- Avoid flaky patterns:
  - no random seed dependence without fixed seed
  - no wall-clock dependence without deterministic clock control
  - no unordered dictionary/string rendering assumptions without explicit normalization

## Concurrency and Lease

- Lock file: `.local/testing-autopilot-lock.json`
- Fresh lock from another run: exit `busy` with no roadmap mutation.
- Stale lock: allow takeover with explicit takeover note in run report.
- Never advance a second task while a fresh `[IN_PROGRESS]` exists.
