# SwiftNumbers Autopilot Policy

Last updated: 2026-04-25

## Purpose

Define infinite, self-renewing improvement rules for the `swift-numbers` autonomous development loop.

This policy is stable and long-lived. The roadmap is finite and consumable.
When roadmap tasks run out, the automation must generate new roadmap tasks from this policy.

## Perpetual Focus Areas (Priority Order)

1. Read reliability and compatibility
2. Write reliability and data safety
3. Formula support:
   - read fidelity
   - write capability
4. Pivot support:
   - pivot detection and read diagnostics
   - safe write behavior and incremental pivot support
5. CLI usability and deterministic output contracts
6. Performance and memory efficiency on large documents
7. Documentation quality and release clarity

## Cadence and Delivery Model

- Execution cadence: hourly loop.
- Delivery focus: bugfix-first (reliability/correctness hardening before feature expansion).
- Release model: batched release after accumulation threshold, not per-fix release.

## Continuous Input Signals

Autopilot must collect and score signals from:

- failing/unstable tests
- build warnings/errors
- coverage hotspots in first-party code
- parser diagnostics and unsupported node summaries
- code-parity drift between `docs/numbers-parser-code-capability-map.md` and current source symbols
- TODO/FIXME markers in first-party sources
- CLI regression or output instability
- docs drift versus current behavior
- release incident patterns (rollback/fix frequency)

## Backlog Synthesis Rules (When No `[TODO]` Exists)

1. Run `Backlog Synthesis` before implementation.
   - preferred command:
     - `./scripts/autopilot_backlog_synthesis.sh`
2. Produce at least 10 candidate tasks from current signals.
3. Score each candidate with:
   - Impact: `1..5`
   - Risk: `1..5`
   - Effort: `1..5`
   - Confidence: `1..5`
4. Compute rank using:
   - `priorityScore = (Impact * Confidence) - (Risk + Effort)`
5. Select top 6 tasks with mandatory distribution:
   - at least 1 task for read reliability
   - at least 1 task for write reliability
   - at least 1 task for formula support
   - at least 1 task for pivot support
6. Append selected tasks to `docs/autopilot-roadmap.md` as a new milestone.
7. Assign deterministic task IDs:
   - `SN-AUTO-YYYYMMDD-01`, `SN-AUTO-YYYYMMDD-02`, ...
8. Start implementation from the first newly added `[TODO]`.

## Code-Parity Refresh Rule

- Keep `docs/numbers-parser-code-capability-map.md` regenerated from symbols before parity-gap planning:
  - `./scripts/refresh_numbers_parser_code_map.sh`
- The map must include snapshot metadata (commit/date) and deterministic section ordering.
- Compute deterministic parity queue candidates from roadmap + code map before renewal planning:
  - `./scripts/parity_task_queue.sh --roadmap ./docs/autopilot-roadmap.md --code-map ./docs/numbers-parser-code-capability-map.md`

## Execution Safety Rules

- Exactly one task advanced per run.
- Small, reviewable diffs only.
- Mandatory validation gates:
  - `swift build`
  - `swift test`
- User-visible behavior changes require docs updates and `CHANGELOG.md` updates.
- Release only after quality gates pass and batch threshold is met.
- Batch threshold rule:
  - release when `CHANGELOG.md` `## [Unreleased] -> ### Summary` has at least `5` non-placeholder bullets
  - compute count with `./scripts/release_batch_count.sh --changelog ./CHANGELOG.md`

## Concurrency and Lease Rules

To prevent overlapping runs from working on the same task:

1. Use a run mutex file at `.local/autopilot-lock.json`.
2. At run start:
   - if lock is present and fresh, exit immediately with `busy` status (no task changes)
   - if lock is stale, mark takeover in report and continue
3. Mark active task as `[IN_PROGRESS]` with run timestamp metadata before edits.
4. While running, refresh lock heartbeat periodically.
5. On successful completion, set task `[DONE]` and release lock.
6. On failure/block, set task `[BLOCKED]` and release lock.
7. Never process a second task in a different concurrent run while `[IN_PROGRESS]` exists with a fresh lock.

## Anti-Stall Rules

- If a task fails validation twice consecutively, mark `[BLOCKED]` with root cause and continue with next `[TODO]` in next run.
- If three consecutive runs produce no merged progress, force `Backlog Synthesis` refresh and regenerate top tasks.

## Quality Bar for “Aggressive” Improvement

Autopilot should prioritize meaningful capability movement over cosmetic churn.
Prefer deeper support in:

- formula read/write correctness
- pivot read/write safety
- end-to-end roundtrip reliability

Avoid low-value doc-only churn unless it unblocks user-facing correctness, release clarity, or API safety.
