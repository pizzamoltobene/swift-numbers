# SwiftNumbers Docs

Documentation hub for `SwiftNumbers v0.3.2`.

## Start Here

1. [Quickstart](quickstart.md)
2. [Capabilities](capabilities.md)
3. [API Reference](api-reference.md)

## Guide Map

| If you need... | Open |
|---|---|
| Fast local setup | [Quickstart](quickstart.md) |
| Full feature and behavior matrix | [Capabilities](capabilities.md) |
| One page per operation | [Operations Index](operations/README.md) |
| Copy/paste workflows | [Cookbook](cookbook.md) |
| CLI details and JSON output | [CLI Reference](cli-reference.md) |
| Failure triage | [Troubleshooting](troubleshooting.md) |
| Internal architecture | [Architecture](architecture.md) |
| Infinite improvement rules for Autopilot | [Autopilot Policy](autopilot-policy.md) |
| Roadmap-driven autonomous loop | [Autopilot Roadmap](autopilot-roadmap.md) |
| Public autonomous delivery model | [Autonomous Development](autonomous-development.md) |

## Scope (v0.3.2)

Supported:
- Real `.numbers` read path (with diagnostics and fallback safety path)
- Read sheets/tables/cells/formulas/rich read model
- Editable tabular mutations + save (`save(to:)`, `saveInPlace()`)
- CLI: `list-sheets`, `list-tables`, `list-formulas`, `read-column`, `read-table`, `read-cell`, `read-range`, `dump`, `--format text|json`, `--formulas`, `--cells`, `--formatting`

Out of scope:
- Formula write engine
- Pivots/grouped tables/charts/comments
- Full layout/styling fidelity
- Encrypted `.numbers` files

## Related

- [Repository README](../README.md)
- [Changelog](../CHANGELOG.md)
- [Contributing](../CONTRIBUTING.md)
- [Security](../SECURITY.md)
