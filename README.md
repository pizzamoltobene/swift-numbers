<p align="center">
  <img src="docs/assets/swiftnumbers-logo.svg" alt="SwiftNumbers logo" width="960" />
</p>

<h1 align="center">SwiftNumbers</h1>

<p align="center">
  Fast, native <code>.numbers</code> reading in Swift.
</p>

<p align="center">
  <a href="https://github.com/pizzamoltobene/swift-numbers/actions/workflows/ci.yml">
    <img alt="CI" src="https://github.com/pizzamoltobene/swift-numbers/actions/workflows/ci.yml/badge.svg" />
  </a>
  <img alt="Swift 6.0+" src="https://img.shields.io/badge/Swift-6.0%2B-F05138?logo=swift&logoColor=white" />
  <img alt="macOS 13+" src="https://img.shields.io/badge/macOS-13%2B-1F2937?logo=apple&logoColor=white" />
  <img alt="Release v0.1.0" src="https://img.shields.io/badge/Release-v0.1.0-16A34A" />
</p>

`SwiftNumbers` is a macOS-first Swift package for deterministic, read-only extraction of sheets, tables, and cell values from `.numbers` documents.

## What You Get

- Native Swift implementation (`Swift 6.0+`, `macOS 13+`)
- Stable public API:
  - `NumbersDocument.open(at:)`
  - `NumbersDocument.sheets`
  - `Sheet.tables`
  - `Table.metadata`
  - `Table.cell(at:) -> CellValue?`
- CLI with text and JSON output:
  - `swiftnumbers dump <file.numbers> [--format text|json]`
  - `swiftnumbers list-sheets <file.numbers> [--format text|json]`
- Real-read pipeline with diagnostics and safe metadata fallback
- CI quality gates: format, warnings-as-errors build, tests, coverage threshold

## Install (SwiftPM)

Use the `v0.1.0` tag:

```swift
.package(url: "https://github.com/pizzamoltobene/swift-numbers.git", from: "0.1.0")
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

swift run swiftnumbers list-sheets Fixtures/multi-sheet.numbers
swift run swiftnumbers dump Fixtures/simple-table.numbers --format json
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

Run performance guardrails (debug + release):

```bash
./scripts/bench_private_corpus.py --update-baseline
./scripts/bench_private_corpus.py
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

- [Quickstart](docs/quickstart.md)
- [Preview](docs/assets/preview.md)
- [Changelog](CHANGELOG.md)

## License

Dual-license model:

- Open source: `AGPL-3.0` ([LICENSE-AGPL-3.0](LICENSE-AGPL-3.0))
- Commercial: [LICENSE-COMMERCIAL.md](LICENSE-COMMERCIAL.md)
