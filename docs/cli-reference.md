# CLI Reference

Reference for `swiftnumbers` command-line tooling.

## Binary

Run via SwiftPM:

```bash
swift run swiftnumbers <subcommand> ...
```

## Global

```bash
swiftnumbers --help
```

## Subcommands

- `list-sheets`
- `dump`

## 1) `list-sheets`

Print all sheet names from a `.numbers` file.

### Usage

```bash
swiftnumbers list-sheets <file.numbers> [--format text|json]
```

### Arguments and options

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `<file.numbers>` | path | Yes | n/a | Input Numbers document |
| `--format` | `text` or `json` | No | `text` | Output mode |

### Text output example

```text
1. Sales
2. Archive
```

### JSON output example

```json
{
  "sheets": [
    {
      "id": "sheet-...",
      "index": 1,
      "name": "Sales",
      "tableCount": 2
    },
    {
      "id": "sheet-...",
      "index": 2,
      "name": "Archive",
      "tableCount": 1
    }
  ]
}
```

## 2) `dump`

Print structural summary and diagnostics.

### Usage

```bash
swiftnumbers dump <file.numbers> [--format text|json] [--formulas]
```

### Arguments and options

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `<file.numbers>` | path | Yes | n/a | Input Numbers document |
| `--format` | `text` or `json` | No | `text` | Output mode |
| `--formulas` | flag | No | `false` | Include formula-read details (`formulaID`, raw formula when available, tokenized form, formatted result) |

### Text output (abridged)

```text
Source: /path/file.numbers
Document version: 14.4
Read path: real
Sheets: 2
Tables: 3
Resolved cells: 420
Diagnostics: 0
```

### JSON output fields

| Field | Type | Meaning |
|---|---|---|
| `sourcePath` | `String` | Input path |
| `documentVersion` | `String?` | Parsed version from metadata plist |
| `readPath` | `String` | `real` or `metadataFallback` |
| `fallbackReason` | `String?` | Why fallback happened |
| `sheetCount` | `Int` | Number of sheets |
| `sheetNames` | `[String]` | Ordered sheet names |
| `tableCount` | `Int` | Number of tables |
| `tableNames` | `[String]` | Fully-qualified table names (`Sheet/Table`) |
| `resolvedCellCount` | `Int` | Number of populated cells parsed |
| `blobCount` | `Int` | Index blob count |
| `objectCount` | `Int` | IWA object count |
| `objectReferenceEdgeCount` | `Int` | Reference graph edge count |
| `rootObjectCount` | `Int` | Root object count |
| `typeHistogram` | `[String:Int]` | Type-ID distribution |
| `unparsedBlobPaths` | `[String]` | Any skipped/failed blobs |
| `diagnostics` | `[String]` | Human-readable diagnostics |
| `structuredDiagnostics` | array | Structured diagnostics (`code`, `severity`, `message`, `objectPath`, `suggestion`, `context`, `rendered`) |
| `formulaCount` | `Int?` | Present only with `--formulas`; number of formula cells found |
| `formulas` | array? | Present only with `--formulas`; per-formula details |
| `sheets` | array | Per-sheet/per-table details |

### JSON output (abridged)

```json
{
  "blobCount": 112,
  "diagnostics": [],
  "documentVersion": "14.4",
  "fallbackReason": null,
  "objectCount": 743,
  "objectReferenceEdgeCount": 1384,
  "readPath": "real",
  "resolvedCellCount": 420,
  "rootObjectCount": 12,
  "sheetCount": 2,
  "sheetNames": ["Sales", "Archive"],
  "tableCount": 3,
  "tableNames": ["Sales/Table 1", "Sales/Table 2", "Archive/Table 1"],
  "structuredDiagnostics": [],
  "typeHistogram": {
    "6000": 45,
    "6001": 10
  },
  "unparsedBlobPaths": []
}
```

## Machine-friendly usage patterns

### CI check: ensure at least one sheet

```bash
swift run swiftnumbers list-sheets /abs/file.numbers --format json
```

Then parse `.sheets | length` in your pipeline.

### CI check: fail on diagnostics presence

```bash
swift run swiftnumbers dump /abs/file.numbers --format json
```

Then inspect `.diagnostics`.

## Exit behavior

- Returns non-zero on open/parse/runtime errors.
- Returns zero on successful command execution.

## Related docs

- [Capabilities](capabilities.md)
- [Troubleshooting](troubleshooting.md)
- [Quickstart](quickstart.md)
