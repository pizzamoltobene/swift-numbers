# Release Checklist

Use this checklist for every official release of `swift-numbers`.

## Active Release Scripts

- `./scripts/release_batch_count.sh`
- `./scripts/release_check.sh`
- `./scripts/release_publish.sh`
- `./scripts/release_autofix.sh`
- `./scripts/release-notes-template.md` (metadata template)

## Preconditions

1. Local quality gates pass:
   - `swift build`
   - `swift test`
2. Changelog has release metadata in the target section:
   - `### Summary`
   - `### Breaking Changes`
   - `### Rollback Hint`
3. `gh` CLI is authenticated for `github.com`.

## Batch Gate

1. Compute unreleased batch size:

```bash
./scripts/release_batch_count.sh --changelog ./CHANGELOG.md
```

2. Verify threshold (current policy: `15`):

```bash
./scripts/release_batch_count.sh --check --threshold 15 --changelog ./CHANGELOG.md
```

Release should proceed only when threshold check exits `0`.

## Release Quality Gate

Run release checks and generate report artifact:

```bash
./scripts/release_check.sh
```

Optional manual Numbers.app confirmation:

```bash
SWIFT_NUMBERS_NUMBERS_APP_OK=1 ./scripts/release_check.sh
```

Expected artifact:
- `.local/release-check.json`

## Publish Paths

### Path A: Manual publish

1. Dry run:

```bash
SWIFT_NUMBERS_NUMBERS_APP_OK=1 ./scripts/release_publish.sh --tag vX.Y.Z --dry-run
```

2. Publish:

```bash
SWIFT_NUMBERS_NUMBERS_APP_OK=1 ./scripts/release_publish.sh --tag vX.Y.Z
```

### Path B: Autopilot one-task release

```bash
SWIFT_NUMBERS_TASK_ID=SN-RXX ./scripts/release_autofix.sh
```

This path promotes `Unreleased` changelog content, creates the release commit, then publishes tag and GitHub release.

## Expected Release Artifacts

- Updated `CHANGELOG.md` with:
  - refreshed `## [Unreleased]` template
  - new released section `## [X.Y.Z] - YYYY-MM-DD`
- Release commit (pattern: `chore(release): vX.Y.Z (...)`)
- Git tag: `vX.Y.Z`
- GitHub release for `vX.Y.Z` using changelog-derived notes
- `.local/release-check.json` from latest gate run
