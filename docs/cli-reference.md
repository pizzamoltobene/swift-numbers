# CLI Reference

Reference for `swiftnumbers` command-line tooling.

## Binary

Run via SwiftPM:

```bash
swift run swiftnumbers <subcommand> ...
```

## Global

```bash
swift run swiftnumbers --help
swift run swiftnumbers help <subcommand>
```

Selector rule used by read/export/import commands:

- For sheet selection, provide exactly one of: `--sheet` or `--sheet-index`.
- For table selection, provide exactly one of: `--table` or `--table-index`.
- If selector is missing (or both forms are provided), command exits with a validation error.

## Subcommands

- `list-sheets`
- `list-tables`
- `list-formulas`
- `read-column`
- `read-table`
- `read-cell`
- `read-range`
- `export-csv`
- `import-csv`
- `refresh-apple-numbers-map`
- `dump`
- `inspect`

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

## 2) `list-tables`

Print all tables (with read stats), optionally scoped to one sheet.

### Usage

```bash
swiftnumbers list-tables <file.numbers> [--sheet "<Sheet Name>"] [--format text|json]
```

### Arguments and options

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `<file.numbers>` | path | Yes | n/a | Input Numbers document |
| `--sheet` | `String` | No | n/a | Exact sheet name filter |
| `--format` | `text` or `json` | No | `text` | Output mode |

### Text output example

```text
1. Sheet A/Table A1 rows=3 cols=2 populated=6 formulas=0 merges=0 used=A1:B3
2. Sheet B/Table B1 rows=2 cols=2 populated=4 formulas=0 merges=0 used=A1:B2
```

### JSON output example

```json
{
  "sheetFilter": "Sheet B",
  "tableCount": 2,
  "tables": [
    {
      "index": 1,
      "sheetIndex": 2,
      "sheetID": "sheet-...",
      "sheetName": "Sheet B",
      "tableIndexInSheet": 1,
      "tableID": "table-...",
      "tableName": "Table B1",
      "rowCount": 2,
      "columnCount": 2,
      "mergeRangeCount": 0,
      "populatedCellCount": 4,
      "formulaCount": 0,
      "usedRange": "A1:B2",
      "tableNameVisible": true,
      "captionVisible": false,
      "captionText": "",
      "captionTextSupported": true
    }
  ]
}
```

## 3) `list-formulas`

Print formula cells across the document, optionally scoped to one sheet/table.

### Usage

```bash
swiftnumbers list-formulas <file.numbers> [--sheet "<Sheet Name>"] [--table "<Table Name>"] [--format text|json]
```

### Arguments and options

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `<file.numbers>` | path | Yes | n/a | Input Numbers document |
| `--sheet` | `String` | No | n/a | Exact sheet name filter |
| `--table` | `String` | No | n/a | Exact table name filter |
| `--format` | `text` or `json` | No | `text` | Output mode |

### JSON output example

```json
{
  "sheetFilter": "Sheet 1",
  "tableFilter": "Table 1",
  "formulaCount": 0,
  "formulas": []
}
```

## 4) `read-column`

Print typed column snapshots for one column selected by zero-based index or by header label. Each cell snapshot includes rich read metadata (`readValue`, merge role, and when available: `style`, `richText`, `formula` details).

### Usage

```bash
swiftnumbers read-column <file.numbers> [<column-index>] (--sheet "<Sheet Name>" | --sheet-index <n>) (--table "<Table Name>" | --table-index <n>) [--from-row <row>] [--header "<Header>"] [--header-row <row>] [--include-header] [--formulas] [--formatting] [--format text|json] [--jsonl]
```

### Arguments and options

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `<file.numbers>` | path | Yes | n/a | Input Numbers document |
| `<column-index>` | integer | No* | n/a | Zero-based column index (`0` = column A). Required unless `--header` is used |
| `--sheet` | `String` | Conditional | n/a | Exact sheet name (mutually exclusive with `--sheet-index`) |
| `--sheet-index` | integer | Conditional | n/a | Zero-based sheet index (mutually exclusive with `--sheet`) |
| `--table` | `String` | Conditional | n/a | Exact table name (mutually exclusive with `--table-index`) |
| `--table-index` | integer | Conditional | n/a | Zero-based table index in the selected sheet (mutually exclusive with `--table`) |
| `--from-row` | integer | No | `0` | Start row (zero-based). Index mode only |
| `--header` | string | No* | n/a | Header label to select column (case-insensitive). Required when `<column-index>` is omitted |
| `--header-row` | integer | No | `0` | Header row index used with `--header` |
| `--include-header` | flag | No | `false` | Includes header row in output when using `--header` |
| `--formulas` | flag | No | `false` | Parity switch (cat-numbers style): prefer formula literals when available |
| `--formatting` | flag | No | `false` | Parity switch (cat-numbers style): prefer formatted display values |
| `--format` | `text` or `json` | No | `text` | Output mode |
| `--jsonl` | flag | No | `false` | Emit NDJSON stream (one cell object per line) |

### JSON output example (abridged)

```json
{
  "selectionMode": "header",
  "requestedHeader": "Name",
  "headerRow": 0,
  "includeHeader": false,
  "parityMode": "formulas",
  "columnIndex": 0,
  "fromRow": 1,
  "cellCount": 3,
  "cells": [
    {
      "cellReference": "A2",
      "kind": "text",
      "formatted": "Answer",
      "output": "Answer",
      "readValue": { "kind": "string", "string": "Answer" }
    }
  ]
}
```

## 5) `read-table`

Print a table window as typed read snapshots. Cell snapshots include rich read metadata (`readValue`, merge role, and when available: `style`, `richText`, `formula` details).

### Usage

```bash
swiftnumbers read-table <file.numbers> (--sheet "<Sheet Name>" | --sheet-index <n>) (--table "<Table Name>" | --table-index <n>) [--from-row <row>] [--from-column <col>] [--max-rows <n>] [--max-columns <n>] [--formulas] [--formatting] [--format text|json] [--jsonl]
```

### Arguments and options

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `<file.numbers>` | path | Yes | n/a | Input Numbers document |
| `--sheet` | `String` | Conditional | n/a | Exact sheet name (mutually exclusive with `--sheet-index`) |
| `--sheet-index` | integer | Conditional | n/a | Zero-based sheet index (mutually exclusive with `--sheet`) |
| `--table` | `String` | Conditional | n/a | Exact table name (mutually exclusive with `--table-index`) |
| `--table-index` | integer | Conditional | n/a | Zero-based table index in the selected sheet (mutually exclusive with `--table`) |
| `--from-row` | integer | No | `0` | Start row (zero-based) |
| `--from-column` | integer | No | `0` | Start column (zero-based) |
| `--max-rows` | integer | No | `100` | Maximum rows in the output window |
| `--max-columns` | integer | No | `50` | Maximum columns in the output window |
| `--formulas` | flag | No | `false` | Parity switch (cat-numbers style): prefer formula literals when available |
| `--formatting` | flag | No | `false` | Parity switch (cat-numbers style): prefer formatted display values |
| `--format` | `text` or `json` | No | `text` | Output mode |
| `--jsonl` | flag | No | `false` | Emit NDJSON stream (one row object per line) |

### JSON output example (abridged)

```json
{
  "tableNameVisible": true,
  "captionVisible": false,
  "captionText": "",
  "captionTextSupported": true,
  "parityMode": "formatting",
  "fromRow": 1,
  "fromColumn": 0,
  "resolvedRowCount": 2,
  "resolvedColumnCount": 2,
  "truncatedRows": true,
  "truncatedColumns": true,
  "cells": [
    [
      {
        "cellReference": "A2",
        "kind": "text",
        "formatted": "Answer",
        "output": "Answer",
        "readValue": { "kind": "string", "string": "Answer" }
      }
    ]
  ]
}
```

For `--jsonl`, each emitted row object includes the same table presentation metadata fields:
`tableNameVisible`, `captionVisible`, `captionText`, and `captionTextSupported`.

## 6) `read-cell`

Print a full read snapshot for one cell (`value`, `readValue`, `formatted`, style, merge, formula metadata).

### Usage

```bash
swiftnumbers read-cell <file.numbers> <A1> (--sheet "<Sheet Name>" | --sheet-index <n>) (--table "<Table Name>" | --table-index <n>) [--format text|json]
```

### Arguments and options

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `<file.numbers>` | path | Yes | n/a | Input Numbers document |
| `<A1>` | string | Yes | n/a | Cell reference (for example `B2`) |
| `--sheet` | `String` | Conditional | n/a | Exact sheet name (mutually exclusive with `--sheet-index`) |
| `--sheet-index` | integer | Conditional | n/a | Zero-based sheet index (mutually exclusive with `--sheet`) |
| `--table` | `String` | Conditional | n/a | Exact table name (mutually exclusive with `--table-index`) |
| `--table-index` | integer | Conditional | n/a | Zero-based table index in the selected sheet (mutually exclusive with `--table`) |
| `--format` | `text` or `json` | No | `text` | Output mode |

### JSON output example (abridged)

```json
{
  "cellReference": "A1",
  "column": 0,
  "formatted": "Name",
  "kind": "text",
  "merge": {
    "isMerged": false,
    "range": null,
    "role": "none"
  },
  "readValue": {
    "kind": "string",
    "string": "Name"
  },
  "sheetName": "Sheet 1",
  "tableName": "Table 1",
  "value": {
    "kind": "string",
    "string": "Name"
  }
}
```

## 7) `read-range`

Print read snapshots for a range (`value`, `readValue`, `formatted`, merge metadata) with sheet/table scoping. Cell entries also include rich metadata fields when available (`style`, `richText`, `formula`).

### Usage

```bash
swiftnumbers read-range <file.numbers> <A1:D10> (--sheet "<Sheet Name>" | --sheet-index <n>) (--table "<Table Name>" | --table-index <n>) [--formulas] [--formatting] [--format text|json] [--jsonl]
```

### Arguments and options

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `<file.numbers>` | path | Yes | n/a | Input Numbers document |
| `<A1:D10>` | string | Yes | n/a | Range reference (for example `A2:B3`) |
| `--sheet` | `String` | Conditional | n/a | Exact sheet name (mutually exclusive with `--sheet-index`) |
| `--sheet-index` | integer | Conditional | n/a | Zero-based sheet index (mutually exclusive with `--sheet`) |
| `--table` | `String` | Conditional | n/a | Exact table name (mutually exclusive with `--table-index`) |
| `--table-index` | integer | Conditional | n/a | Zero-based table index in the selected sheet (mutually exclusive with `--table`) |
| `--formulas` | flag | No | `false` | Parity switch (cat-numbers style): prefer formula literals when available |
| `--formatting` | flag | No | `false` | Parity switch (cat-numbers style): prefer formatted display values |
| `--format` | `text` or `json` | No | `text` | Output mode |
| `--jsonl` | flag | No | `false` | Emit NDJSON stream (one range row object per line) |

### JSON output example (abridged)

```json
{
  "requestedRange": "A2:B3",
  "resolvedRange": "A2:B3",
  "rowCount": 2,
  "columnCount": 2,
  "cells": [
    [
      {
        "cellReference": "A2",
        "kind": "text",
        "formatted": "Answer",
        "formula": null,
        "richText": null,
        "style": null,
        "readValue": {
          "kind": "string",
          "string": "Answer"
        }
      }
    ]
  ]
}
```

## 8) `export-csv`

Export a selected table as CSV.

### Usage

```bash
swiftnumbers export-csv <file.numbers> (--sheet "<Sheet Name>" | --sheet-index <n>) (--table "<Table Name>" | --table-index <n>) [--mode value|formatted|formula] [--output <path.csv>]
```

### Arguments and options

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `<file.numbers>` | path | Yes | n/a | Input Numbers document |
| `--sheet` | `String` | Conditional | n/a | Exact sheet name (mutually exclusive with `--sheet-index`) |
| `--sheet-index` | integer | Conditional | n/a | Zero-based sheet index (mutually exclusive with `--sheet`) |
| `--table` | `String` | Conditional | n/a | Exact table name (mutually exclusive with `--table-index`) |
| `--table-index` | integer | Conditional | n/a | Zero-based table index in the selected sheet (mutually exclusive with `--table`) |
| `--mode` | `value`, `formatted`, `formula` | No | `value` | CSV cell mode: raw typed values, display-formatted values, or raw formulas with formatted fallback |
| `--output` | path | No | stdout | Writes CSV to file path instead of stdout |

### CSV output example

```csv
Name,Value,
Answer,42,
Enabled,TRUE,
,,
```

## 9) `import-csv`

Import CSV rows into a selected table and save updated `.numbers` output.

### Usage

```bash
swiftnumbers import-csv <file.numbers> <file.csv> (--sheet "<Sheet Name>" | --sheet-index <n>) (--table "<Table Name>" | --table-index <n>) [--header with-header|no-header] [--rename OLD:NEW] [--delete-column COLUMN] [--transform DEST=FUNC:SRC1;SRC2] [--parse-dates] [--date-column COLUMN] [--day-first] [--date-format PATTERN] [--output <path.numbers>]
```

### Arguments and options

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `<file.numbers>` | path | Yes | n/a | Input Numbers document |
| `<file.csv>` | path | Yes | n/a | CSV source file (UTF-8) |
| `--sheet` | `String` | Conditional | n/a | Exact sheet name (mutually exclusive with `--sheet-index`) |
| `--sheet-index` | integer | Conditional | n/a | Zero-based sheet index (mutually exclusive with `--sheet`) |
| `--table` | `String` | Conditional | n/a | Exact table name (mutually exclusive with `--table-index`) |
| `--table-index` | integer | Conditional | n/a | Zero-based table index in the selected sheet (mutually exclusive with `--table`) |
| `--header` | `with-header`, `no-header` | No | `with-header` | Header mode: keep CSV first row as header or generate `Column 1..N` |
| `--rename` | `OLD:NEW` | No | none | Rename stage mapping (repeatable). `OLD` supports exact column name or zero-based index |
| `--delete-column` | selector | No | none | Delete stage selector (repeatable). Supports exact name or zero-based index |
| `--transform` | `DEST=FUNC:SRC1;SRC2` | No | none | Transform stage rule (repeatable). `FUNC`: `merge`, `pos`, `neg`, `upper`, `lower`, `trim` |
| `--parse-dates` | flag | No | `false` | Parse date-like cells (`yyyy-MM-dd`, ISO8601) into typed date values |
| `--date-column` | selector | No | all columns | Restrict date parsing to selected columns (repeatable). Requires `--parse-dates` |
| `--day-first` | flag | No | `false` | Use day-first fallback patterns for ambiguous slash/hyphen dates (requires `--parse-dates`) |
| `--date-format` | pattern | No | none | Extra `DateFormatter` pattern tried before defaults (repeatable, requires `--parse-dates`) |
| `--output` | path | No | in-place save | Output path for updated `.numbers` document |

### Import behavior notes

- Numeric and boolean values are imported as typed Numbers cells when parseable.
- Import pipeline stage order is deterministic: `rename -> delete-column -> transform -> typed cell coercion`.
- With `--parse-dates`, recognized dates are imported as typed date cells.
- `--date-column` scopes date parsing to selected columns; without it, date parsing applies to all columns.
- `--date-format` patterns are evaluated before built-in date fallbacks.
- With `--header no-header`, a generated header row (`Column 1`, `Column 2`, ...) is inserted before CSV data.
- `--date-column`, `--date-format`, and `--day-first` are valid only together with `--parse-dates`.
- Built-in date fallbacks are:
  - default mode: `MM/dd/yyyy`, `MM-dd-yyyy`, `MM/dd/yyyy HH:mm:ss`, `MM/dd/yyyy HH:mm`, `yyyy-MM-dd`
  - with `--day-first`: `dd/MM/yyyy`, `dd-MM-yyyy`, `dd/MM/yyyy HH:mm:ss`, `dd/MM/yyyy HH:mm`, `yyyy-MM-dd`

## 10) `refresh-apple-numbers-map`

Refresh the checked-in Apple Numbers AppleScript capability map used by the parity roadmap.

This is a development/planning oracle command only. It discovers Numbers through
LaunchServices/AppleScript, reads the scripting dictionary with `sdef`, and writes a normalized
Markdown map with capability summary rows, read/mutation-semantics probe rows, and dictionary
inventory.
It does not add a Numbers.app dependency to the SwiftNumbers library.

### Usage

```bash
swiftnumbers refresh-apple-numbers-map [--output docs/apple-numbers-applescript-capability-map.md] [--dry-run] [--skip-oracle]
```

### Arguments and options

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `--output` | path | No | `docs/apple-numbers-applescript-capability-map.md` | Markdown map output path |
| `--dry-run` | flag | No | `false` | Print generated Markdown instead of writing it |
| `--skip-oracle` | flag | No | `false` | Emit deterministic skipped metadata without probing Numbers.app |

### Output behavior

- Available oracle: records LaunchServices discovery method, `sdef` parse status, capability rows, read/mutation probe rows, and stable dictionary inventory.
- Unavailable oracle: records deterministic skipped metadata so CI/offline validation can still pass.
- Timestamp metadata is intentionally omitted to avoid noisy diffs.

## 11) `dump`

Print structural summary and diagnostics.

### Usage

```bash
swiftnumbers dump <file.numbers> [--format text|json] [--formulas] [--cells] [--formatting]
```

### Arguments and options

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `<file.numbers>` | path | Yes | n/a | Input Numbers document |
| `--format` | `text` or `json` | No | `text` | Output mode |
| `--formulas` | flag | No | `false` | Include formula-read details (`formulaID`, raw formula when available, tokenized form, formatted result) |
| `--cells` | flag | No | `false` | Include populated-cell read snapshots (`kind`, typed value, formatted value, formula ID/raw) |
| `--formatting` | flag | No | `false` | Include deterministic formatting snapshots for populated cells across multiple format modes |

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
| `sheets[].tables[].tableNameVisible` | `Bool?` | Table-name visibility flag when available |
| `sheets[].tables[].captionVisible` | `Bool?` | Caption visibility flag when available |
| `sheets[].tables[].captionText` | `String?` | Caption text when available |
| `sheets[].tables[].captionTextSupported` | `Bool` | Whether native caption text storage is available for that table |
| `formulaCount` | `Int?` | Present only with `--formulas`; number of formula cells found |
| `formulas` | array? | Present only with `--formulas`; per-formula details |
| `cellCount` | `Int?` | Present only with `--cells`; number of populated cells emitted |
| `cells` | array? | Present only with `--cells`; per-cell read snapshots |
| `formattingCount` | `Int?` | Present only with `--formatting`; number of formatting snapshots emitted |
| `formatting` | array? | Present only with `--formatting`; per-cell formatted-value profile (`default`, `styleHinted`, `decimal`, `currencyUSD`, `percent`, `scientific`, date/duration variants) |
| `sheets` | array | Per-sheet/per-table details |

Pivot-related observability:

- `structuredDiagnostics[].code == "resolver.pivot.candidateDetected"` indicates a non-table drawable linked to table objects (potential pivot/analytic view), surfaced as read-only guidance.
- `structuredDiagnostics[].code == "resolver.pivot.candidateSummary"` provides aggregate stable cardinality/ID context across all detected pivot-like candidates (`candidateObjectIDs`, `candidateCount`, `linkedTableInfoObjectIDs`, `linkedTableInfoCount`, `linkedTableModelObjectIDs`, `linkedTableModelCount`).

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

## 12) `inspect`

Emit low-level object/container diagnostics in a stable machine-readable schema.

### Usage

```bash
swiftnumbers inspect <file.numbers> [--format text|json] [--redact] [--compact]
```

### Arguments and options

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `<file.numbers>` | path | Yes | n/a | Input Numbers document |
| `--format` | `text` or `json` | No | `json` | Output mode |
| `--redact` | flag | No | `false` | Redact path-like fields (`sourcePath`, object path metadata, unparsed blob paths) |
| `--compact` | flag | No | `false` | Emit compact output (single-line text or minified JSON) |

### JSON output fields

| Field | Type | Meaning |
|---|---|---|
| `sourcePath` | `String` | Source path (or `<redacted>`) |
| `documentVersion` | `String?` | Parsed version from metadata plist |
| `readPath` | `String` | `real` or `metadataFallback` |
| `fallbackReason` | `String?` | Why fallback happened |
| `redacted` | `Bool` | Whether redaction was applied |
| `container.blobCount` | `Int` | Index blob count |
| `container.objectCount` | `Int` | IWA object count |
| `container.objectReferenceEdgeCount` | `Int` | Reference graph edge count |
| `container.rootObjectCount` | `Int` | Root object count |
| `container.unparsedBlobCount` | `Int` | Number of unparsed blob entries |
| `container.unparsedBlobPaths` | `[String]` | Blob paths (or `<redacted>` values) |
| `document.sheetCount` | `Int` | Number of sheets |
| `document.tableCount` | `Int` | Number of tables |
| `document.resolvedCellCount` | `Int` | Number of populated cells parsed |
| `document.sheetNames` | `[String]` | Ordered sheet names |
| `document.tableNames` | `[String]` | Fully-qualified table names (`Sheet/Table`) |
| `typeHistogram` | `[String:Int]` | Type-ID distribution |
| `diagnosticCount` | `Int` | Count of string diagnostics |
| `diagnostics` | `[String]` | Human-readable diagnostics |
| `structuredDiagnosticCount` | `Int` | Count of structured diagnostics |
| `structuredDiagnostics` | array | Structured diagnostics (`code`, `severity`, `message`, `objectPath`, `suggestion`, `context`, `rendered`) |

### Compact redacted JSON example

```bash
swift run swiftnumbers inspect /abs/file.numbers --format json --redact --compact
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

## Exit Code Contract

`swiftnumbers` uses a stable binary exit contract for automation and scripts:

- `0`: command completed successfully.
- `non-zero`: command failed (argument parse/validation errors, file open/parse errors, or runtime execution errors).

For automation, treat any non-zero status as failure and do not rely on a specific non-zero code value.

## Related docs

- [Capabilities](capabilities.md)
- [Troubleshooting](troubleshooting.md)
- [Quickstart](quickstart.md)
