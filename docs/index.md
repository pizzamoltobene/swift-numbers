# SwiftNumbers Docs

Documentation hub for the current `SwiftNumbers` release line.

## Start Here

1. [Quickstart](quickstart.md)
2. [Capabilities](capabilities.md)
3. [API Reference](api-reference.md)
4. [CLI Reference](cli-reference.md)
5. [Cookbook](cookbook.md)

## Public Docs Map

| If you need... | Open |
|---|---|
| Fast local setup | [Quickstart](quickstart.md) |
| Practical code snippets and workflows | [Cookbook](cookbook.md) |
| Full feature and behavior matrix | [Capabilities](capabilities.md) |
| Exact library API signatures/types | [API Reference](api-reference.md) |
| CLI command usage and JSON contracts | [CLI Reference](cli-reference.md) |
| Failure triage | [Troubleshooting](troubleshooting.md) |
| Internal architecture | [Architecture](architecture.md) |
| One page per operation | [Operations Index](operations/README.md) |

## Automation and Release Docs

| If you need... | Open |
|---|---|
| Infinite improvement rules for Autopilot | [Autopilot Policy](autopilot-policy.md) |
| Roadmap-driven autonomous loop | [Autopilot Roadmap](autopilot-roadmap.md) |
| Pause/resume + unblock runbook for Autopilot | [Autopilot Operations](autopilot-operations.md) |
| Test-only autonomous growth policy | [Testing Autopilot Policy](testing-autopilot-policy.md) |
| Test-only autonomous queue and milestones | [Testing Autopilot Roadmap](testing-autopilot-roadmap.md) |
| Test-only autonomous runbook | [Testing Autopilot Operations](testing-autopilot-operations.md) |
| Official release gate and publish checklist | [Release Checklist](release-checklist.md) |
| Autonomous release cadence, gates, and pause rules | [Autonomous Release Policy](autonomous-release-policy.md) |
| Consecutive autonomous release cycle log | [Release Cycles](release-cycles.md) |
| Public autonomous delivery model | [Autonomous Development](autonomous-development.md) |

## Internal Planning Docs

| If you need... | Open |
|---|---|
| Capability-gap baseline and priorities | [Capability Gap Baseline](capability-gap-baseline.md) |
| Growth and distribution campaign plan | [Growth Campaign Playbook](growth-campaign-playbook-2026Q2.md) |
| Full generated test inventory/report | [Detailed Test Report](testing-detailed-report.md) |

## Scope

Supported:
- Real `.numbers` read path (with diagnostics and fallback safety path)
- Read sheets/tables/cells/formulas/rich read model
- Editable tabular mutations + save (`save(to:)`, `saveInPlace()`)
- CLI: `list-sheets`, `list-tables`, `list-formulas`, `read-column`, `read-table`, `read-cell`, `read-range`, `export-csv`, `import-csv`, `dump`, `inspect`
- CLI outputs and switches: `--format text|json`, `--jsonl` (column/table/range), parity switches `--formulas`/`--formatting` (column/table/range), `dump --cells --formatting`, `inspect --redact --compact`
- CSV import pipeline stages: `--rename`, `--delete-column`, `--transform`, `--parse-dates`, `--date-column`, `--day-first`, `--date-format`
- Scoped commands use explicit selectors: one of `--sheet`/`--sheet-index` and one of `--table`/`--table-index`

Out of scope:
- Full formula-engine parity (beyond deterministic formula literal persistence)
- Pivot-linked table mutation support, charts, comments
- Full layout/styling fidelity
- Encrypted `.numbers` files

## Related

- [Repository README](../README.md)
- [Changelog](../CHANGELOG.md)
- [Contributing](../CONTRIBUTING.md)
- [Security](../SECURITY.md)
