# SwiftNumbers

![SwiftNumbers Logo](docs/assets/swiftnumbers-logo.png)

`SwiftNumbers` is a native Swift library and CLI for reading and editing Apple `.numbers` documents.
It is also an open experiment in automated library development with a recurring delivery loop.

## Why SwiftNumbers

- Swift-native stack (`SwiftPM`, macOS 13+)
- Read real `.numbers` files (package + single-file archive)
- Edit tabular data and save valid `.numbers` output
- CLI for inspection and automation (`list-sheets`, `list-tables`, `read-cell`, `read-range`, `export-csv`, `import-csv`, `dump`)
- Structured diagnostics for safer debugging

## Autonomous Release Experiment

This project runs an automated development loop with an hourly cadence and a bugfix-first delivery model.
Each cycle is intended to:

- pick the next roadmap task
- implement one small reviewable change
- run validation (`swift build`, `swift test`)
- update docs/changelog when behavior changes
- publish a release only after quality gates pass and the changelog batch reaches release threshold

The goal is transparent, high-frequency, high-quality iteration with readable release notes and docs.
Release cadence, gates, and pause rules are defined in [Autonomous Release Policy](docs/autonomous-release-policy.md).

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
swift run swiftnumbers export-csv Tests/Fixtures/simple-table.numbers --sheet "Sheet 1" --table "Table 1" --mode value
swift run swiftnumbers import-csv Tests/Fixtures/simple-table.numbers /absolute/path/input.csv --sheet "Sheet 1" --table "Table 1" --header with-header --parse-dates --output /absolute/path/output.numbers
swift run swiftnumbers dump Tests/Fixtures/simple-table.numbers --format json --cells --formatting
```

## Minimal Example

```swift
import SwiftNumbersCore

let editable = try EditableNumbersDocument.open(at: inputURL)
let sheet = try editable.sheet(named: "Sales")
let table = try sheet.table(named: "Q1")

try table.setValue(.number(1499.99), at: "D4")
try table.setStyle(
  ReadCellStyle(fontName: "HelveticaNeue", fontSize: 13, isBold: true, textColorHex: "#112233"),
  at: "D4"
)
try table.setFormat(.currency(formatID: 202), at: "D4")
try table.mergeCells("D4:E4")
try table.unmergeCells("D4:E4")
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
- Autonomous release gates and pause/resume rules: [Autonomous Release Policy](docs/autonomous-release-policy.md)

## Scope Snapshot

- Supported in `v0.3.2`: core read/edit/save workflows for tabular data.
- Writable cell-style bundles are available in editable API (`setStyle`) with deterministic save/reopen roundtrip via metadata overlay.
- Writable cell-format API (`setFormat`) now supports number/date/currency/custom format hints with deterministic save/reopen roundtrip.
- Writable merge/unmerge API is available in editable workflows (`mergeCells` / `unmergeCells`) with low-level native persistence.
- Table presentation metadata API is now available for editable workflows: table-name visibility, caption visibility, and caption text roundtrip where caption storage is present.
- Grouped-table safety: structural mutations that are unsafe for grouped row headers fail fast with deterministic guidance.
- Pivot-candidate observability: `dump` structured diagnostics now surface non-table drawables linked to table objects (`resolver.pivot.candidateDetected`) for safer troubleshooting.
- Pivot-linked read surface: `Table.metadata.objectIdentifiers` and `Table.metadata.pivotLinks` now expose stable object IDs for resolver-linked pivot structures on real-read path.
- Pivot-linked write safety: native write operations on tables linked to pivot-like drawables now fail fast with deterministic guidance.
- Out of scope: advanced formula engine behavior, pivots, charts, comments, full layout/styling parity, encrypted files.

For the exact matrix, use [Capabilities](docs/capabilities.md).

## License

`AGPL-3.0` ([LICENSE-AGPL-3.0](LICENSE-AGPL-3.0))
