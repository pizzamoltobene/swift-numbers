# SwiftNumbers Docs

Welcome to the documentation hub for `SwiftNumbers v0.2.0`.

If you are new to the project, start with the 5-minute path below. If you need exact API behavior, jump directly to Capabilities.

## 5-Minute Path

1. [Quickstart](quickstart.md)
2. [Capabilities (full API + operation reference)](capabilities.md)
3. [Operations Index (one page per operation)](operations/README.md)
4. [Cookbook (real workflows)](cookbook.md)
5. [CLI Reference](cli-reference.md)
6. [Troubleshooting](troubleshooting.md)

## Choose Your Path

| I need to... | Go to |
|---|---|
| Build and run quickly | [Quickstart](quickstart.md) |
| Understand exactly what API operations exist | [Capabilities](capabilities.md) |
| Read each operation as a separate page | [Operations Index](operations/README.md) |
| See exact public signatures and types | [API Reference](api-reference.md) |
| Copy/paste practical examples | [Cookbook](cookbook.md) |
| Use CLI in scripts and CI | [CLI Reference](cli-reference.md) |
| Understand internals and module boundaries | [Architecture](architecture.md) |
| Diagnose read/write failures | [Troubleshooting](troubleshooting.md) |

## Product Scope (v0.2.0)

### Supported

- Read real `.numbers` containers (package and single-file archive)
- Read sheets/tables/metadata/cells/merges
- Edit tabular data:
  - `setValue`
  - `appendRow`
  - `insertRow`
  - `appendColumn`
  - `addTable`
  - `addSheet`
- Save:
  - `save(to:)` to new destination
  - atomic same-path replace via `save(to: sourceURL)` or `saveInPlace()`
- CLI:
  - `swiftnumbers list-sheets`
  - `swiftnumbers dump`
  - `--format text|json`

### Not In Scope

- formulas
- pivot/grouped tables
- charts
- comments
- filters/sorts/conditions
- full style/layout fidelity parity
- encrypted documents

## API Surfaces

| Surface | Use for | Main entry points |
|---|---|---|
| Read-only API | inspection/extraction/reporting | `NumbersDocument.open(at:)`, `sheets`, `tables`, `cell(at:)`, `dump()` |
| Editable API | update tabular data and save | `EditableNumbersDocument.open(at:)`, mutation operations, `save(to:)`, `saveInPlace()` |
| CLI | terminal automation and quick checks | `swiftnumbers list-sheets`, `swiftnumbers dump` |

## Suggested Reading Order by Role

| Role | Reading order |
|---|---|
| App/backend engineer | [Quickstart](quickstart.md) → [Operations Index](operations/README.md) → [Cookbook](cookbook.md) |
| Tooling/CI engineer | [CLI Reference](cli-reference.md) → [Troubleshooting](troubleshooting.md) |
| Contributor | [Architecture](architecture.md) → [Capabilities](capabilities.md) → [Operations Index](operations/README.md) |

## Links

- Repository root: [README](../README.md)
- Changelog: [CHANGELOG](../CHANGELOG.md)
- Security policy: [SECURITY](../SECURITY.md)
- Contribution guide: [CONTRIBUTING](../CONTRIBUTING.md)
