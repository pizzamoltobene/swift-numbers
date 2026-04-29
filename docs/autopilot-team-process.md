# Autopilot Team Process

Operating model for the automated `SwiftNumbers` development loop.

The goal is to make automation behave like a small product team instead of a single endless coding pass.
Each run still advances one roadmap task, but the task is interpreted through a role and release process.

## Five Roles

| Role | Owns | Output |
|---|---|---|
| Product / Roadmap Owner | Scope, priority, release balance, roadmap order | A first eligible roadmap task with clear task type and definition of done |
| Apple Numbers Oracle Analyst | AppleScript/OSAScript capability discovery and behavior comparison | Stable parity gaps from Numbers.app dictionary/probes |
| Swift Core Developer | Swift implementation and CLI/API behavior | Small reviewable code diff for one task |
| QA / Compatibility Engineer | Regression coverage, fixtures, build/test gates, roundtrip safety | Passing `swift build` and `swift test`, or a precise blocker |
| Docs / Release Engineer | README/docs/changelog accuracy, release threshold, GitHub release | Current docs and release decision |

## Role Rotation Per Run

Every automation run follows the same internal handoff:

1. Product / Roadmap Owner selects the first `[TODO]` task in `docs/autopilot-roadmap.md`.
2. Apple Numbers Oracle Analyst refreshes or reads AppleScript parity signals when the task is parity-related or backlog synthesis is needed.
3. Swift Core Developer implements the smallest diff that advances the selected task.
4. QA / Compatibility Engineer runs validation and adds focused regression coverage when behavior changes.
5. Docs / Release Engineer updates user-facing docs when needed, computes release readiness, and publishes only when gates allow.

## Task Metadata

New generated tasks should include:

| Field | Allowed values |
|---|---|
| Role | `product`, `oracle`, `developer`, `qa`, `release` |
| Type | `bugfix`, `feature`, `parity`, `docs`, `release`, `test` |
| Area | `read`, `write`, `formula`, `pivot`, `cli`, `performance`, `docs`, `release` |

Existing tasks without explicit metadata are interpreted by title, definition of done, and validation text.

## Monthly Release Train

Automation may ship threshold releases during the month, but it must also maintain a monthly release train.

| Window | Focus | Release stance |
|---|---|---|
| Week 1 | Oracle refresh and roadmap shaping | No release unless urgent fix |
| Week 2 | Bugfix and reliability implementation | Release if batch threshold is reached |
| Week 3 | Feature and parity implementation | Release if batch threshold is reached |
| Week 4 | Hardening, docs, changelog, release notes | Release by month end if there is validated unreleased work |

Monthly release target:
- at least one GitHub release per calendar month when there is validated unreleased work
- normal release threshold remains `5` changelog summary bullets
- month-end release may publish with fewer than `5` bullets if all validation gates pass and the release is not empty

## Work Mix

For each monthly train, backlog synthesis should aim for:

| Work type | Target share |
|---|---:|
| Bugfix / reliability | 40% |
| Apple Numbers parity features | 30% |
| Formula and write support | 20% |
| Docs, CLI polish, release work | 10% |

This is a planning target, not a reason to skip the first `[TODO]` task in the roadmap.

## Release Definition

A release-ready batch must have:

- completed roadmap tasks marked `[DONE]`
- `swift build` passing
- `swift test` passing
- current README/docs for user-visible behavior
- current `CHANGELOG.md`
- explicit release notes
- no fresh `.local/autopilot-lock.json`

If any gate fails, the current task is `[BLOCKED]` with the root cause and the release is deferred.
