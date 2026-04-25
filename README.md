# SwiftNumbers

![SwiftNumbers Logo](docs/assets/swiftnumbers-logo.png)

`SwiftNumbers` is a native Swift library and CLI for reading and editing Apple `.numbers` documents.
It is also an open experiment in automated library development with a recurring delivery loop.

## Why SwiftNumbers

- Swift-native stack (`SwiftPM`, macOS 13+)
- Read real `.numbers` files (package + single-file archive)
- Edit tabular data and save valid `.numbers` output
- CLI for inspection and automation (`list-sheets`, `list-tables`, `read-cell`, `read-range`, `dump`)
- Structured diagnostics for safer debugging

## Autonomous Release Experiment

This project runs an automated development loop with a one-minute watchdog cadence and continuous queue execution.
Each cycle is intended to:

- pick the next roadmap task
- implement one small reviewable change
- run validation (`swift build`, `swift test`)
- update docs/changelog when behavior changes
- publish a release when all gates pass

The goal is transparent, high-frequency, high-quality iteration with readable release notes and docs.

Primary long-horizon areas:

- read compatibility and diagnostics
- write safety and roundtrip correctness
- formula support (read + write)
- pivot-table support (safe read/write behavior)

## Install (SwiftPM)

```swift
.package(url: "https://github.com/pizzamoltobene/swift-numbers.git", from: "0.3.2")
```

```swift
.product(name: "SwiftNumbers", package: "swift-numbers")
```

## Quick Start

```bash
swift build
swift test
swift run swiftnumbers list-sheets Tests/Fixtures/multi-sheet.numbers
swift run swiftnumbers list-tables Tests/Fixtures/multi-sheet.numbers --format json
swift run swiftnumbers list-formulas Tests/Fixtures/simple-table.numbers --format json
swift run swiftnumbers read-column Tests/Fixtures/simple-table.numbers 0 --sheet "Sheet 1" --table "Table 1" --from-row 1 --format json
swift run swiftnumbers read-column Tests/Fixtures/simple-table.numbers --header "Name" --sheet "Sheet 1" --table "Table 1" --format json
swift run swiftnumbers read-column Tests/Fixtures/simple-table.numbers --header "Name" --sheet "Sheet 1" --table "Table 1" --jsonl
swift run swiftnumbers read-table Tests/Fixtures/simple-table.numbers --sheet "Sheet 1" --table "Table 1" --from-row 1 --from-column 0 --max-rows 2 --max-columns 2 --format json
swift run swiftnumbers read-table Tests/Fixtures/simple-table.numbers --sheet "Sheet 1" --table "Table 1" --from-row 1 --from-column 0 --max-rows 2 --max-columns 2 --jsonl
swift run swiftnumbers read-cell Tests/Fixtures/simple-table.numbers A1 --sheet "Sheet 1" --table "Table 1" --format json
swift run swiftnumbers read-cell Tests/Fixtures/multi-sheet.numbers A1 --sheet-index 1 --table-index 1 --format json
swift run swiftnumbers read-range Tests/Fixtures/simple-table.numbers A2:B3 --sheet "Sheet 1" --table "Table 1" --format json
swift run swiftnumbers read-range Tests/Fixtures/simple-table.numbers A2:B3 --sheet "Sheet 1" --table "Table 1" --jsonl
swift run swiftnumbers dump Tests/Fixtures/simple-table.numbers --format json --cells --formatting
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

- Supported in `v0.3.2`: core read/edit/save workflows for tabular data.
- Out of scope: formula write engine, pivots, charts, comments, full layout/styling parity, encrypted files.

For the exact matrix, use [Capabilities](docs/capabilities.md).

## License

Dual-license model:

- Open source: `AGPL-3.0` ([LICENSE-AGPL-3.0](LICENSE-AGPL-3.0))
- Commercial: [LICENSE-COMMERCIAL.md](LICENSE-COMMERCIAL.md)
