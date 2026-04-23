# SwiftNumbers


`SwiftNumbers` is a Swift library for reading/editing Apple `.numbers` documents.

## Documentation

Start here: [Docs Hub](docs/index.md)

| Goal | Where to read |
|---|---|
| Fast local setup | [Quickstart](docs/quickstart.md) |
| Full API and operation contract | [Capabilities](docs/capabilities.md) |
| One page per operation | [Operations Index](docs/operations/README.md) |
| Exact public signatures and types | [API Reference](docs/api-reference.md) |
| Copy/paste workflows | [Cookbook](docs/cookbook.md) |
| CLI usage and JSON fields | [CLI Reference](docs/cli-reference.md) |
| Failure analysis and fixes | [Troubleshooting](docs/troubleshooting.md) |
| Internal module and pipeline design | [Architecture](docs/architecture.md) |

## At a Glance

`SwiftNumbers` gives you a Swift-native way to work with Apple Numbers files in apps, tools, and backend workflows.

- Read real `.numbers` documents (package and single-file archive formats)
- Access sheets, tables, metadata, and cell values through a stable API
- Edit tabular data and save valid output `.numbers` files
- Inspect files from CLI (`dump`, `list-sheets`) in text or JSON
- Ship with a GitHub-ready baseline (format/lint/build/tests/coverage gates)

For full API/CLI behavior, use [Capabilities](docs/capabilities.md).  
For practical flows, use [Cookbook](docs/cookbook.md).

## Supported (v0.2.0)

- Open `.numbers` package documents and single-file archive documents
- Read sheets/tables/metadata and lookup cells by address
- CLI read operations:
  - `swiftnumbers list-sheets`
  - `swiftnumbers dump`
  - text and JSON output formats
- Editable operations:
  - update existing cell values
  - append/insert rows
  - append columns
  - add table on existing sheet
  - add sheet
  - save to a new output file (`save(to:)`)
  - in-place atomic replace save (`saveInPlace()`)
- Supported value types for editable workflows:
  - `string`
  - `number`
  - `bool`
  - `empty`
  - `date`

## Write Support (v0.2.0)

- Native Swift low-level IWA write path currently covers:
  - `setValue` for `string` / `number` / `bool` / `empty` / `date` (`date` uses a stable SwiftNumbers marker)
  - `appendRow(_:)`
  - `insertRow(_:at:)`
  - `appendColumn(_:)`
  - `addSheet(named:)`
  - `addTable(named:rows:columns:onSheetNamed:)`
- Metadata-overlay fallback is retained as a safety net when the low-level path cannot handle a specific source file/layout.
- `save(to:)` supports both:
  - writing to a new destination
  - same-path atomic in-place replace

## Out of Scope (v0.2.0)

- Advanced Numbers features are out of scope in `0.2.0`:
  - formulas
  - pivot/grouped tables
  - charts
  - comments
  - filters/sorts/conditions
  - advanced formatting and full layout fidelity
  - collaborative metadata
  - encrypted documents
- Platform scope is currently `macOS 13+`

## Install (SwiftPM)

Use the `v0.2.0` tag:

```swift
.package(url: "https://github.com/pizzamoltobene/swift-numbers.git", from: "0.2.0")
```

Then add the library target dependency:

```swift
.product(name: "SwiftNumbers", package: "swift-numbers")
```

## Quick Start

```bash
swift build
swift test
./scripts/ci-check.sh

swift run swiftnumbers list-sheets Tests/Fixtures/multi-sheet.numbers
swift run swiftnumbers dump Tests/Fixtures/simple-table.numbers --format json
```

## Editable Example

```swift
import SwiftNumbersCore

let document = try EditableNumbersDocument.open(at: inputURL)
let sheet = try document.sheet(named: "Sales")
let table = try sheet.table(named: "Q1")

try table.setValue(.string("Done"), at: "C4")
table.setValue(.number(1499.99), at: CellAddress(row: 3, column: 3))

try document.save(to: outputURL)
```

## Local Real-File Regression Workflow

Private files stay local only.

- Corpus path:
  - default: `./PrivateCorpus`
  - override: `SWIFT_NUMBERS_PRIVATE_CORPUS=/abs/path`
- Per-file expectation manifest:
  - default: `./.private-corpus/expectations.json`
  - override: `SWIFT_NUMBERS_PRIVATE_EXPECTATIONS=/abs/path/expectations.json`

Generate or refresh expectations:

```bash
./scripts/update_private_corpus_expectations.py --write
```

Run local release checks:

```bash
./scripts/release_check_020.sh
```

## Repository Layout

- `Sources/SwiftNumbersCore`: public models and document API
- `Sources/SwiftNumbersContainer`: package/container reading
- `Sources/SwiftNumbersIWA`: object inventory and traversal/decode pipeline
- `Sources/SwiftNumbersProto`: protobuf definitions and loading
- `Sources/swiftnumbers`: CLI
- `Tests/SwiftNumbersTests`: unit/integration/golden tests
- `docs/`: preview and quick docs

## Docs

- [Docs Hub](docs/index.md)
- [Quickstart](docs/quickstart.md)
- [Capabilities](docs/capabilities.md)
- [Operations Index](docs/operations/README.md)
- [API Reference](docs/api-reference.md)
- [Cookbook](docs/cookbook.md)
- [CLI Reference](docs/cli-reference.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Architecture](docs/architecture.md)
- [Preview](docs/assets/preview.md)
- [Changelog](CHANGELOG.md)

## License

Dual-license model:

- Open source: `AGPL-3.0` ([LICENSE-AGPL-3.0](LICENSE-AGPL-3.0))
- Commercial: [LICENSE-COMMERCIAL.md](LICENSE-COMMERCIAL.md)
