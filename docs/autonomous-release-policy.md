# Autonomous Release Policy

This document defines when autonomous runs may publish an official release.

## Cadence

- The autonomous loop runs on an hourly heartbeat.
- Each run processes exactly one roadmap task: the first `[TODO]` in `docs/autopilot-roadmap.md`.
- Runs are serialized with `.local/autopilot-lock.json` to prevent concurrent overlapping edits.

## Quality Gates

An official release is allowed only when all gates pass in the same run:

- `swift build`
- `swift test`
- `./scripts/runtime-critical-check.sh`
- release metadata/gate checks from `./scripts/release_check.sh`

For user-visible behavior changes, the run must also update:

- `README.md`
- relevant files under `docs/`
- `CHANGELOG.md`

## Release Trigger

- Compute batch count from changelog summary bullets:
  - `./scripts/release_batch_count.sh --changelog ./CHANGELOG.md`
- Publish only when batch count is `>= 15` and quality gates pass.
- Standard automation entrypoint:
  - `SWIFT_NUMBERS_TASK_ID=<task-id> ./scripts/release_autofix.sh`

## Release Pause Conditions

Release is paused (skipped) when any of the following is true:

- lock is already held by another fresh run
- `swift build` fails
- `swift test` fails
- runtime critical-path audit fails
- release gate/metadata validation fails
- changelog batch count is below `15`
- current roadmap task is marked `[BLOCKED]`

## Resume Conditions

Release resumes automatically on the next run once pause conditions are cleared and the trigger is met.
