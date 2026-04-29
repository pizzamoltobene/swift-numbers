# SwiftNumbers Autopilot Policy

Last updated: 2026-04-29

## Purpose

Define infinite, self-renewing improvement rules for the `swift-numbers` autonomous development loop.

This policy is stable and long-lived. The roadmap is finite and consumable.
When roadmap tasks run out, the automation must generate new roadmap tasks from this policy.

## Perpetual Focus Areas (Priority Order)

1. Read reliability and compatibility
2. Write reliability and data safety
3. Apple Numbers parity through AppleScript/OSAScript:
   - use AppleScript dictionaries and probes as the Apple-native behavior oracle
   - keep `SwiftNumbers` implementation Swift-first with no runtime dependency on Numbers.app
4. Formula support:
   - read fidelity
   - write capability
5. Pivot support:
   - pivot detection and read diagnostics
   - safe write behavior and incremental pivot support
6. CLI usability and deterministic output contracts
7. Performance and memory efficiency on large documents
8. Documentation quality and release clarity

## Cadence and Delivery Model

- Execution cadence: hourly loop.
- Delivery focus: bugfix-first (reliability/correctness hardening before feature expansion).
- Team model: five-role rotation defined in [Autopilot Team Process](autopilot-team-process.md).
- Release model: monthly release train plus threshold releases when enough validated work accumulates.
- Normal release threshold: `5` changelog summary bullets.
- Month-end release rule: publish with fewer than `5` bullets only when there is validated unreleased work and all gates pass.

## Five-Role Operating Model

Every run must interpret the selected roadmap task through this role sequence:

1. Product / Roadmap Owner:
   - selects the first `[TODO]` task
   - confirms task type, area, and definition of done
2. Apple Numbers Oracle Analyst:
   - refreshes or reads AppleScript/OSAScript parity evidence when relevant
   - records deterministic skipped status when Numbers.app or permissions are unavailable
3. Swift Core Developer:
   - implements the smallest Swift-first diff for the selected task
   - avoids unrelated refactors
4. QA / Compatibility Engineer:
   - adds or updates focused tests when behavior changes
   - runs `swift build` and `swift test`
5. Docs / Release Engineer:
   - updates README/docs/changelog when user-visible behavior changes
   - computes release readiness and publishes only when release gates allow

New synthesized tasks should include role/type/area metadata where practical.
Allowed task types: `bugfix`, `feature`, `parity`, `docs`, `release`, `test`.

## Continuous Input Signals

Autopilot must collect and score signals from:

- failing/unstable tests
- build warnings/errors
- coverage hotspots in first-party code
- parser diagnostics and unsupported node summaries
- Apple Numbers AppleScript/OSAScript dictionary and probe drift when Numbers.app is available locally
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
   - at least 1 task from AppleScript/OSAScript parity signals when such signals exist
   - target monthly mix: 40% bugfix/reliability, 30% Apple Numbers parity features, 20% formula/write support, 10% docs/CLI/release
6. Append selected tasks to `docs/autopilot-roadmap.md` as a new milestone.
7. Assign deterministic task IDs:
   - `SN-AUTO-YYYYMMDD-01`, `SN-AUTO-YYYYMMDD-02`, ...
8. Start implementation from the first newly added `[TODO]`.

## Apple-Native Parity Refresh Rule

- Treat Apple Numbers AppleScript/OSAScript as the primary user-visible behavior oracle.
- Refresh `docs/apple-numbers-applescript-capability-map.md` before parity-gap planning when Numbers.app is installed and automation permissions are available:
  - `swift run swiftnumbers refresh-apple-numbers-map`
  - `swift run swiftnumbers refresh-apple-numbers-map --skip-oracle --dry-run` for deterministic unavailable-oracle validation
- Discover Numbers through LaunchServices/AppleScript (`path to application "Numbers"` or bundle identifier `com.apple.Numbers`), not by assuming `/Applications/Numbers.app`.
- AppleScript/OSAScript probes are development and planning inputs only:
  - production library code must remain Swift-first and must not depend on Numbers.app
  - CI must skip AppleScript probes deterministically when Numbers.app is unavailable
  - probe output must be normalized into stable capability rows before it can create roadmap tasks
- The AppleScript capability map should cover, at minimum:
  - document open/save/export behavior
  - sheet/table/cell read surfaces
  - row/column/table mutations exposed by Numbers
  - formula read/write behavior visible through Numbers
  - formatting, style, chart, pivot, and advanced object surfaces exposed by the scripting dictionary

## Historical Code-Parity Refresh Rule

- Keep `docs/numbers-parser-code-capability-map.md` regenerated from symbols before parity-gap planning:
  - `./scripts/refresh_numbers_parser_code_map.sh`
- The map must include snapshot metadata (commit/date) and deterministic section ordering.
- Compute deterministic parity queue candidates from roadmap + code map before renewal planning:
  - `./scripts/parity_task_queue.sh --roadmap ./docs/autopilot-roadmap.md --apple-map ./docs/apple-numbers-applescript-capability-map.md --code-map ./docs/numbers-parser-code-capability-map.md`
- Use the historical code map as a secondary signal after AppleScript/OSAScript parity signals.

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
- Monthly release train rule:
  - if validated unreleased work exists near month end, prepare a GitHub release even if the batch count is below `5`
  - do not publish an empty release
  - do not publish while build/test gates are failing

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
