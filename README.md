# SwiftNumbers

Swift-native replacement for `numbers-parser` (macOS-first), focused on deterministic container reading, typed metadata access, and robust round-trip groundwork.

## Current MVP (Sprint 1)

- Open `.numbers` containers
- Read `Index.zip` blobs and build object inventory
- Read single-file `.numbers` ZIP containers (`Index/*.iwa`) and build object inventory
- Decode `document/sheet/table` metadata with SwiftProtobuf
- Build object-reference graph from IWA archive headers (`objectReferences`)
- Expose read-only basic cell values via `Table.cell(at:)`
- CLI command: `swiftnumbers dump <file.numbers>`
- CLI command: `swiftnumbers list-sheets <file.numbers>`
- Machine-readable CLI output: `--format json` for `dump` and `list-sheets`
- Real-file read path (typed Swift decode for `document/sheet/table/tile/string/merge`)
- Document version diagnostics from `Metadata/Properties.plist` (warning-only on unsupported versions)

## Requirements

- macOS 13+
- Swift 6.3+

## Build and Run

```bash
swift build
swift test
./scripts/ci-check.sh
swift run swiftnumbers dump Fixtures/simple-table.numbers
swift run swiftnumbers list-sheets Fixtures/multi-sheet.numbers
swift run swiftnumbers dump Fixtures/simple-table.numbers --format json
```

## CI / Quality Gates

GitHub workflow: `.github/workflows/ci.yml`

Required checks for `main`:

- build (`swift build -warnings-as-errors`)
- tests (`swift test --enable-code-coverage`)
- format check (`swift format lint --recursive`)
- first-party coverage summary (`./scripts/coverage-summary.sh --threshold 70`)

Local one-shot command:

```bash
./scripts/ci-check.sh
```

## Private Real-World Corpus (Local Only)

Real user `.numbers` files stay local and are never committed.

- Default local path: `./PrivateCorpus` (gitignored)
- Override via env var: `SWIFT_NUMBERS_PRIVATE_CORPUS=/abs/path/to/corpus`
- Local expectation manifest (gitignored): `./.private-corpus/expectations.json`
- Override manifest path via env var: `SWIFT_NUMBERS_PRIVATE_EXPECTATIONS=/abs/path/expectations.json`
- Integration tests auto-skip when corpus is missing

Supported corpus checks:

- `open + dump` on every file
- per-file expectations: `minSheets`, `minTables`, `minPopulatedCells`, `allowEmptyCells`

Generate/update manifest:

```bash
./scripts/update_private_corpus_expectations.py --write
```

## Performance Harness

Compare Python and Swift paths on private corpus:

```bash
./scripts/bench_private_corpus.py --update-baseline
./scripts/bench_private_corpus.py
```

What it measures:

- `python numbers-parser` open/read
- `swiftnumbers list-sheets`
- `swiftnumbers dump`

Guardrail:

- fail if Swift mean runtime regresses by more than `15%` vs baseline
- dual baselines are tracked separately:
  - debug: `.local/perf-baseline-debug.json`
  - release: `.local/perf-baseline-release.json`

## Repository Layout

- `Sources/SwiftNumbersContainer`: `.numbers` container access (`Index.zip`, metadata files)
- `Sources/SwiftNumbersIWA`: IWA inventory extraction + object reference traversal
- `Sources/SwiftNumbersProto`: protobuf schema + metadata loading (`document_metadata.proto` + vendored `TSP*.proto` from `numbers-parser`)
- `Sources/SwiftNumbersCore`: public API (`NumbersDocument`, `Sheet`, `Table`, `CellValue`)
- `Sources/swiftnumbers`: CLI
- `Fixtures/`: synthetic public fixtures + `reference-empty.numbers` (from `numbers-parser`)

## License Model

Dual-license:

- Open source: AGPL-3.0 (`LICENSE-AGPL-3.0`)
- Commercial: custom terms (`LICENSE-COMMERCIAL.md`)

## Upstream References

This project vendors selected format artifacts from [numbers-parser](https://github.com/masaccio/numbers-parser):

- `TSPMessages.proto`
- `TSPArchiveMessages.proto`
- `Fixtures/reference-empty.numbers`

To refresh these assets, run:

```bash
./scripts/import_numbers_parser_assets.sh
```

See [THIRD_PARTY_NOTICES.md](/Users/bondp/Documents/Personal/swift-numbers/THIRD_PARTY_NOTICES.md) for attribution details.
