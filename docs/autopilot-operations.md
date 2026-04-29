# Autopilot Operations

Operational runbook for the roadmap-driven autonomous loop.

## Scope

Use this document to operate Autopilot safely when tasks are in progress, blocked, or waiting for release threshold.

## Execution Model

- The loop is roadmap-driven: always pick the first applicable `[TODO]` task.
- Each run uses the five-role process from [Autopilot Team Process](autopilot-team-process.md):
  Product / Roadmap Owner -> Apple Numbers Oracle Analyst -> Swift Core Developer -> QA / Compatibility Engineer -> Docs / Release Engineer.
- The delivery focus is bugfix-first (reliability/correctness before expansion).
- One task is advanced per run.
- If no `[TODO]` remains, regenerate backlog first:
  - `./scripts/autopilot_backlog_synthesis.sh`
- When Apple Numbers parity tasks are active, discover Numbers through AppleScript/LaunchServices:
  - `swift run swiftnumbers refresh-apple-numbers-map`
  - deterministic skipped validation: `swift run swiftnumbers refresh-apple-numbers-map --skip-oracle --dry-run`
  - do not assume `/Applications/Numbers.app`
- When AppleScript/OSAScript oracle probes cannot run, record a deterministic skipped oracle status and continue from checked-in roadmap signals.
- When M7 code-parity tasks are active, refresh parity baseline first:
  - `./scripts/refresh_numbers_parser_code_map.sh`
- Compute parity queue ordering from roadmap + capability map before selecting new parity work:
  - `./scripts/parity_task_queue.sh --roadmap ./docs/autopilot-roadmap.md --apple-map ./docs/apple-numbers-applescript-capability-map.md --code-map ./docs/numbers-parser-code-capability-map.md`
- Required validation gates per run:
  - `swift build`
  - `swift test`
- Release is gated by changelog batch size:
  - `./scripts/release_batch_count.sh --changelog ./CHANGELOG.md`
  - release when batch count is `>= 5`
- Monthly release train:
  - target at least one GitHub release per calendar month when validated unreleased work exists
  - month-end release may proceed below batch count `5` when build/test gates pass and the release is not empty

## Role Handoff Checklist

Before implementation:

1. Product / Roadmap Owner confirms first `[TODO]`, task type, and definition of done.
2. Apple Numbers Oracle Analyst checks whether AppleScript parity evidence is relevant.

During implementation:

1. Swift Core Developer makes the smallest scoped diff.
2. QA / Compatibility Engineer adds focused tests for changed behavior.

Before ending the run:

1. QA / Compatibility Engineer confirms `swift build` and `swift test`.
2. Docs / Release Engineer updates docs/changelog when required.
3. Docs / Release Engineer reports release decision and next task.

## Task State Contract

- `[TODO]`: queued and eligible for selection.
- `[IN_PROGRESS]`: currently owned by an active run.
- `[DONE]`: completed and validated for its definition of done.
- `[BLOCKED]`: cannot progress without explicit intervention.

## Pause and Resume

To pause automation safely:

1. Set automation status to `PAUSED`.
2. Wait for current run (if any) to release `.local/autopilot-lock.json`.
3. Confirm no stale `[IN_PROGRESS]` task remains in `docs/autopilot-roadmap.md`.

To resume:

1. Set automation status back to `ACTIVE`.
2. Ensure the next executable task in roadmap is `[TODO]`.
3. Next scheduled run continues from that first `[TODO]`.

## `[BLOCKED]` Unblock Protocol

When a run marks a task `[BLOCKED]`, use this exact flow:

1. Record root cause in roadmap next to the blocked task (specific and actionable).
2. Classify unblock type:
   - policy/product decision needed
   - missing fixture/test artifact
   - missing implementation precondition
   - external environment/tooling issue
3. Apply smallest fix to remove blocker.
4. Update task status:
   - `[BLOCKED]` -> `[TODO]` when ready for retry
   - or `[BLOCKED]` -> `[DONE]` only if definition of done is already met
5. If unblock introduced user-visible behavior, update `README.md`, relevant docs, and `CHANGELOG.md`.
6. Re-run validation gates (`swift build`, `swift test`).

## Lock and Concurrency

- Active lease file: `.local/autopilot-lock.json`
- Release artifact pattern: `.local/autopilot-lock.released-*.json`
- If a fresh lock exists from another run, current run must exit `busy`.
- Stale lock takeover is allowed only with explicit takeover reporting.

## Operator Checklist

Before ending a run:

1. Task status is correct (`[DONE]` or `[BLOCKED]` with root cause).
2. Lock is released.
3. Batch count is reported.
4. AppleScript oracle status is reported when parity work is relevant.
5. Release decision is explicit (`published`, `deferred-threshold-not-met`, `deferred-monthly-window`, or `blocked`).
