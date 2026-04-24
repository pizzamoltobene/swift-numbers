# SwiftNumbers

![SwiftNumbers Logo](docs/assets/swiftnumbers-logo.png)

`SwiftNumbers` is a native Swift library and CLI for reading and editing Apple `.numbers` documents.

## Why SwiftNumbers

- Swift-native stack (`SwiftPM`, macOS 13+)
- Read real `.numbers` files (package + single-file archive)
- Edit tabular data and save valid `.numbers` output
- CLI for inspection and automation (`dump`, `list-sheets`)
- Structured diagnostics for safer debugging

## Install (SwiftPM)

```swift
.package(url: "https://github.com/pizzamoltobene/swift-numbers.git", from: "0.3.1.1")
```

```swift
.product(name: "SwiftNumbers", package: "swift-numbers")
```

## Quick Start

```bash
swift build
swift test
swift run swiftnumbers list-sheets Tests/Fixtures/multi-sheet.numbers
swift run swiftnumbers dump Tests/Fixtures/simple-table.numbers --format json
```

## Minimal Example

```swift
import SwiftNumbersCore

let editable = try EditableNumbersDocument.open(at: inputURL)
let sheet = try editable.sheet(named: "Sales")
let table = try sheet.table(named: "Q1")

try table.setValue(.number(1499.99), at: "D4")
try editable.save(to: outputURL)
```

## Documentation

Start here: [Docs Hub](docs/index.md)

- Setup: [Quickstart](docs/quickstart.md)
- Full behavior/operations: [Capabilities](docs/capabilities.md)
- Exact signatures/types: [API Reference](docs/api-reference.md)
- Practical workflows: [Cookbook](docs/cookbook.md)
- CLI usage: [CLI Reference](docs/cli-reference.md)
- Failure handling: [Troubleshooting](docs/troubleshooting.md)
- Internal design: [Architecture](docs/architecture.md)

## Scope Snapshot

- Supported in `v0.3.1.1`: core read/edit/save workflows for tabular data.
- Out of scope: formula write engine, pivots, charts, comments, full layout/styling parity, encrypted files.

For the exact matrix, use [Capabilities](docs/capabilities.md).

## License

Dual-license model:

- Open source: `AGPL-3.0` ([LICENSE-AGPL-3.0](LICENSE-AGPL-3.0))
- Commercial: [LICENSE-COMMERCIAL.md](LICENSE-COMMERCIAL.md)
