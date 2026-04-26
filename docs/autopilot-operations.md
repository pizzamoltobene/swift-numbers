# Autopilot Operations

Operational runbook for the roadmap-driven autonomous loop.

## Scope

Use this document to operate Autopilot safely when tasks are in progress, blocked, or waiting for release threshold.

## Execution Model

- The loop is roadmap-driven: always pick the first applicable `[TODO]` task.
- The delivery focus is bugfix-first (reliability/correctness before expansion).
- One task is advanced per run.
- Required validation gates per run:
  - `swift build`
  - `swift test`
- Release is gated by changelog batch size:
  - `./scripts/release_batch_count.sh --changelog ./CHANGELOG.md`
  - release when batch count is `>= 15`

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
4. Release decision is explicit (`published` or `deferred-threshold-not-met`).
