# Testing Autopilot Operations

Operational runbook for the testing-only autonomous loop.

## Scope

Use this runbook when operating the test-growth loop, including task execution, roadmap renewal, and blocker handling.

## Standard Run Sequence

1. Ensure no fresh lock exists at `.local/testing-autopilot-lock.json`.
2. Select the first `[TODO]` task from `docs/testing-autopilot-roadmap.md`.
3. Mark task `[IN_PROGRESS]`.
4. Implement exactly one small test-focused change set.
5. Run validation gates:
   - `swift build`
   - `swift test`
   - `./scripts/test-growth-report.sh --target 1000`
6. Update task status:
   - `[DONE]` on success
   - `[BLOCKED]` with root cause on failure
7. Release lock.

## Roadmap Renewal

When no `[TODO]` remains:

1. Run `./scripts/testing_backlog_synthesis.sh`.
2. Confirm new milestone appended with `SN-TEST-YYYYMMDD-XX` tasks.
3. Resume from first new `[TODO]`.

## Progress Reporting

Use report command for deterministic growth metrics:

- quick report:
  - `./scripts/test-growth-report.sh --target 1000`
- report with live execution stats:
  - `./scripts/test-growth-report.sh --run-tests --target 1000`
- enforce monotonic growth against a stored baseline:
  - `./scripts/test-growth-report.sh --baseline .local/test-count-baseline.txt --require-growth --write-baseline`

## `[BLOCKED]` Unblock Protocol

1. Record concrete root cause next to blocked task.
2. Classify blocker:
   - missing fixture or golden
   - nondeterministic assertion
   - environment/tooling issue
   - product-policy decision needed
3. Apply smallest unblock change.
4. Move status:
   - `[BLOCKED]` -> `[TODO]` when ready for retry
   - `[BLOCKED]` -> `[DONE]` only if definition of done is met
5. Re-run validation gates.

## Quality Guardrails

- Avoid flaky tests based on ambient time, locale, or randomized order.
- Prefer explicit deterministic fixtures and stable output normalization.
- Avoid broad production refactors in testing loop unless needed to unblock a regression contract.

## Operator Checklist

Before ending a run:

1. Task status is accurate (`[DONE]` or `[BLOCKED]`).
2. Lock file is released.
3. Growth report was generated.
4. Any user-visible docs/scripts changes are reflected in `README.md`, `docs/index.md`, and `CHANGELOG.md`.
