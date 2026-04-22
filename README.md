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

## Requirements

- macOS 13+
- Swift 6.3+

## Build and Run

```bash
swift build
swift test
swift run swiftnumbers dump Fixtures/simple-table.numbers
swift run swiftnumbers list-sheets Fixtures/multi-sheet.numbers
```

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
