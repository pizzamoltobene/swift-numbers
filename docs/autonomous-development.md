# Autonomous Development Model

`SwiftNumbers` is run as an open experiment in automated library delivery.

## Cadence

- An autonomous cycle uses hourly heartbeat ticks.
- Each run executes one roadmap task from [Autopilot Roadmap](autopilot-roadmap.md).
- If the roadmap is exhausted, Autopilot generates the next milestone from [Autopilot Policy](autopilot-policy.md).
- Overlap protection uses a lock/lease file (`.local/autopilot-lock.json`) so concurrent ticks do not execute the same task simultaneously.
- Delivery policy is bugfix-first: reliability/correctness fixes are prioritized over feature expansion.

## Expected Cycle Output

Each cycle is expected to:

1. implement one small, reviewable change
2. run quality gates (`swift build`, `swift test`)
3. update docs and changelog for user-visible changes
4. publish an official release only when release gates pass and the changelog batch threshold is met

## Release Gate Baseline

- Build must pass.
- Tests must pass.
- Critical-path runtime audit must pass (`./scripts/runtime-critical-check.sh`) to prevent Python/Node/Ruby drift in CI/release scripts.
- Changelog and release notes must be present for user-visible changes.
- `CHANGELOG.md` `Unreleased -> Summary` must contain at least 5 non-placeholder bullet items.
- Batch count should be computed by `./scripts/release_batch_count.sh --changelog ./CHANGELOG.md`.
- If any gate fails, release is skipped and the run is treated as blocked/fix-required.
- Release pipeline entry point: `./scripts/release_publish.sh`.
- End-to-end automation entry point for threshold-based batched release: `./scripts/release_autofix.sh`.

## Transparency

Roadmap status is tracked in-repo so users can see what the automation is doing and what is planned next.
Long-term direction and infinite improvement criteria are tracked in `autopilot-policy.md`.
