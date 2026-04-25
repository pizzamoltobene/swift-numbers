# Autonomous Development Model

`SwiftNumbers` is run as an open experiment in automated library delivery.

## Cadence

- An autonomous cycle uses ten-minute heartbeat ticks.
- Each run executes one roadmap task from [Autopilot Roadmap](autopilot-roadmap.md).
- If the roadmap is exhausted, Autopilot generates the next milestone from [Autopilot Policy](autopilot-policy.md).
- Overlap protection uses a lock/lease file (`.local/autopilot-lock.json`) so concurrent ticks do not execute the same task simultaneously.

## Expected Cycle Output

Each cycle is expected to:

1. implement one small, reviewable change
2. run quality gates (`swift build`, `swift test`)
3. update docs and changelog for user-visible changes
4. commit and publish an official release when release gates pass

## Release Gate Baseline

- Build must pass.
- Tests must pass.
- Changelog and release notes must be present for user-visible changes.
- If any gate fails, release is skipped and the run is treated as blocked/fix-required.
- Release pipeline entry point: `./scripts/release_publish.sh`.
- End-to-end automation entry point for "one fix -> one release": `./scripts/release_autofix.sh`.

## Transparency

Roadmap status is tracked in-repo so users can see what the automation is doing and what is planned next.
Long-term direction and infinite improvement criteria are tracked in `autopilot-policy.md`.
