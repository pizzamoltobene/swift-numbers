# Operation 5.18

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.18 `swiftnumbers list-sheets`

**Purpose**

Print sheet list quickly from CLI.

**Command**

```bash
swiftnumbers list-sheets <file.numbers> [--format text|json]
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `<file.numbers>` | path | Yes | Input `.numbers` |
| `--format` | `text`/`json` | No | Default `text` |

**Visual output (text)**

```text
1. Sales
2. Archive
```

**Visual output (json)**

```json
{
  "sheets": [
    { "index": 1, "id": "sheet-...", "name": "Sales", "tableCount": 2 },
    { "index": 2, "id": "sheet-...", "name": "Archive", "tableCount": 1 }
  ]
}
```

---

### 5.18.1 `swiftnumbers list-tables`

**Purpose**

Print table inventory across sheets with optional sheet filter and table stats.

**Command**

```bash
swiftnumbers list-tables <file.numbers> [--sheet "<Sheet Name>"] [--format text|json]
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `<file.numbers>` | path | Yes | Input `.numbers` |
| `--sheet` | string | No | Exact sheet name filter |
| `--format` | `text`/`json` | No | Default `text` |

**Visual output (text)**

```text
1. Sheet A/Table A1 rows=3 cols=2 populated=6 formulas=0 merges=0 used=A1:B3
2. Sheet B/Table B1 rows=2 cols=2 populated=4 formulas=0 merges=0 used=A1:B2
```

**Visual output (json, abbreviated)**

```json
{
  "sheetFilter": "Sheet B",
  "tableCount": 2,
  "tables": [
    {
      "index": 1,
      "sheetName": "Sheet B",
      "tableName": "Table B1",
      "rowCount": 2,
      "columnCount": 2,
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

---

### 5.18.2 `swiftnumbers list-formulas`

**Purpose**

List formula cells with raw/tokenized details and formatted results, optionally scoped to sheet/table.

**Command**

```bash
swiftnumbers list-formulas <file.numbers> [--sheet "<Sheet Name>"] [--table "<Table Name>"] [--format text|json]
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `<file.numbers>` | path | Yes | Input `.numbers` |
| `--sheet` | string | No | Exact sheet name filter |
| `--table` | string | No | Exact table name filter |
| `--format` | `text`/`json` | No | Default `text` |

**Visual output (json, abbreviated)**

```json
{
  "sheetFilter": "Sheet 1",
  "tableFilter": "Table 1",
  "formulaCount": 0,
  "formulas": []
}
```

---

### 5.18.3 `swiftnumbers read-column`

**Purpose**

Inspect one column with typed read snapshots, selected by zero-based index or by header. Each returned cell includes richer read metadata (`readValue`, merge role, and when available: `style`, `richText`, `formula`).

**Command**

```bash
swiftnumbers read-column <file.numbers> [<column-index>] (--sheet "<Sheet Name>" | --sheet-index <n>) (--table "<Table Name>" | --table-index <n>) [--from-row <row>] [--header "<Header>"] [--header-row <row>] [--include-header] [--formulas] [--formatting] [--format text|json] [--jsonl]
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `<file.numbers>` | path | Yes | Input `.numbers` |
| `<column-index>` | int | No* | Zero-based column index (`0` = A). Required unless `--header` is used |
| `--sheet` | string | Conditional | Exact sheet name (mutually exclusive with `--sheet-index`) |
| `--sheet-index` | int | Conditional | Zero-based sheet index (mutually exclusive with `--sheet`) |
| `--table` | string | Conditional | Exact table name (mutually exclusive with `--table-index`) |
| `--table-index` | int | Conditional | Zero-based table index in selected sheet (mutually exclusive with `--table`) |
| `--from-row` | int | No | Default `0`; index mode only |
| `--header` | string | No* | Header label selector (case-insensitive) |
| `--header-row` | int | No | Default `0`; used with `--header` |
| `--include-header` | flag | No | Include header row in output with `--header` |
| `--formulas` | flag | No | Parity mode: prefer formula literals when available |
| `--formatting` | flag | No | Parity mode: prefer formatted display values |
| `--format` | `text`/`json` | No | Default `text` |
| `--jsonl` | flag | No | Emit NDJSON stream (one cell per line) |

**Visual output (json, abbreviated)**

```json
{
  "selectionMode": "header",
  "requestedHeader": "Name",
  "headerRow": 0,
  "includeHeader": false,
  "columnIndex": 0,
  "fromRow": 1,
  "cellCount": 3,
  "cells": [
    {
      "cellReference": "A2",
      "kind": "text",
      "formatted": "Answer",
      "readValue": { "kind": "string", "string": "Answer" }
    }
  ]
}
```

---

### 5.18.4 `swiftnumbers read-table`

**Purpose**

Inspect a table window as typed read snapshots (`rows x columns`) with explicit truncation flags. Each cell carries richer read metadata (`readValue`, merge role, and when available: `style`, `richText`, `formula`).

**Command**

```bash
swiftnumbers read-table <file.numbers> (--sheet "<Sheet Name>" | --sheet-index <n>) (--table "<Table Name>" | --table-index <n>) [--from-row <row>] [--from-column <col>] [--max-rows <n>] [--max-columns <n>] [--formulas] [--formatting] [--format text|json] [--jsonl]
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `<file.numbers>` | path | Yes | Input `.numbers` |
| `--sheet` | string | Conditional | Exact sheet name (mutually exclusive with `--sheet-index`) |
| `--sheet-index` | int | Conditional | Zero-based sheet index (mutually exclusive with `--sheet`) |
| `--table` | string | Conditional | Exact table name (mutually exclusive with `--table-index`) |
| `--table-index` | int | Conditional | Zero-based table index in selected sheet (mutually exclusive with `--table`) |
| `--from-row` | int | No | Default `0` |
| `--from-column` | int | No | Default `0` |
| `--max-rows` | int | No | Default `100` |
| `--max-columns` | int | No | Default `50` |
| `--formulas` | flag | No | Parity mode: prefer formula literals when available |
| `--formatting` | flag | No | Parity mode: prefer formatted display values |
| `--format` | `text`/`json` | No | Default `text` |
| `--jsonl` | flag | No | Emit NDJSON stream (one row per line) |

**Visual output (json, abbreviated)**

```json
{
  "tableNameVisible": true,
  "captionVisible": false,
  "captionText": "",
  "captionTextSupported": true,
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
        "readValue": { "kind": "string", "string": "Answer" }
      }
    ]
  ]
}
```

For `--jsonl`, each emitted row object includes the same table presentation metadata fields:
`tableNameVisible`, `captionVisible`, `captionText`, and `captionTextSupported`.

---

### 5.18.5 `swiftnumbers read-cell`

**Purpose**

Inspect one cell with full read snapshot: typed value, read value, formatted output, style, merge role, and formula details.

**Command**

```bash
swiftnumbers read-cell <file.numbers> <A1> (--sheet "<Sheet Name>" | --sheet-index <n>) (--table "<Table Name>" | --table-index <n>) [--format text|json]
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `<file.numbers>` | path | Yes | Input `.numbers` |
| `<A1>` | string | Yes | Cell reference (for example `B2`) |
| `--sheet` | string | Conditional | Exact sheet name (mutually exclusive with `--sheet-index`) |
| `--sheet-index` | int | Conditional | Zero-based sheet index (mutually exclusive with `--sheet`) |
| `--table` | string | Conditional | Exact table name (mutually exclusive with `--table-index`) |
| `--table-index` | int | Conditional | Zero-based table index in selected sheet (mutually exclusive with `--table`) |
| `--format` | `text`/`json` | No | Default `text` |

**Visual output (json, abbreviated)**

```json
{
  "sheetName": "Sheet 1",
  "tableName": "Table 1",
  "cellReference": "A1",
  "kind": "text",
  "value": { "kind": "string", "string": "Name" },
  "readValue": { "kind": "string", "string": "Name" },
  "formatted": "Name",
  "merge": { "isMerged": false, "role": "none", "range": null }
}
```

---

### 5.18.6 `swiftnumbers read-range`

**Purpose**

Inspect a range with typed read snapshots (value/readValue/formatted + merge metadata) in one call, including richer per-cell metadata when available (`style`, `richText`, `formula`).

**Command**

```bash
swiftnumbers read-range <file.numbers> <A1:D10> (--sheet "<Sheet Name>" | --sheet-index <n>) (--table "<Table Name>" | --table-index <n>) [--formulas] [--formatting] [--format text|json] [--jsonl]
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `<file.numbers>` | path | Yes | Input `.numbers` |
| `<A1:D10>` | string | Yes | Range reference (for example `A2:B3`) |
| `--sheet` | string | Conditional | Exact sheet name (mutually exclusive with `--sheet-index`) |
| `--sheet-index` | int | Conditional | Zero-based sheet index (mutually exclusive with `--sheet`) |
| `--table` | string | Conditional | Exact table name (mutually exclusive with `--table-index`) |
| `--table-index` | int | Conditional | Zero-based table index in selected sheet (mutually exclusive with `--table`) |
| `--formulas` | flag | No | Parity mode: prefer formula literals when available |
| `--formatting` | flag | No | Parity mode: prefer formatted display values |
| `--format` | `text`/`json` | No | Default `text` |
| `--jsonl` | flag | No | Emit NDJSON stream (one range row per line) |

**Visual output (json, abbreviated)**

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
        "readValue": { "kind": "string", "string": "Answer" }
      }
    ]
  ]
}
```

---

### 5.18.7 `swiftnumbers export-csv`

**Purpose**

Export one selected table as CSV for downstream tools.

**Command**

```bash
swiftnumbers export-csv <file.numbers> (--sheet "<Sheet Name>" | --sheet-index <n>) (--table "<Table Name>" | --table-index <n>) [--mode value|formatted|formula] [--output <path.csv>]
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `<file.numbers>` | path | Yes | Input `.numbers` |
| `--sheet` | string | Conditional | Exact sheet name (mutually exclusive with `--sheet-index`) |
| `--sheet-index` | int | Conditional | Zero-based sheet index (mutually exclusive with `--sheet`) |
| `--table` | string | Conditional | Exact table name (mutually exclusive with `--table-index`) |
| `--table-index` | int | Conditional | Zero-based table index in selected sheet (mutually exclusive with `--table`) |
| `--mode` | enum | No | `value` (default), `formatted`, or `formula` |
| `--output` | path | No | Write CSV to file path instead of stdout |

**CSV mode behavior**

- `value`: deterministic typed values.
- `formatted`: display-formatted values.
- `formula`: raw formula text when available, with formatted fallback.

**Visual output (csv)**

```csv
Name,Value,
Answer,42,
Enabled,TRUE,
,,
```

---

### 5.18.8 `swiftnumbers import-csv`

**Purpose**

Import CSV content into one selected table and persist updated `.numbers` output.

**Command**

```bash
swiftnumbers import-csv <file.numbers> <file.csv> (--sheet "<Sheet Name>" | --sheet-index <n>) (--table "<Table Name>" | --table-index <n>) [--header with-header|no-header] [--rename OLD:NEW]... [--delete-column NAME_OR_INDEX]... [--transform DEST=FUNC:SRC1;SRC2]... [--parse-dates] [--date-column NAME_OR_INDEX]... [--day-first] [--date-format "<pattern>"]... [--output <path.numbers>]
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `<file.numbers>` | path | Yes | Input `.numbers` |
| `<file.csv>` | path | Yes | CSV source file (UTF-8) |
| `--sheet` | string | Conditional | Exact sheet name (mutually exclusive with `--sheet-index`) |
| `--sheet-index` | int | Conditional | Zero-based sheet index (mutually exclusive with `--sheet`) |
| `--table` | string | Conditional | Exact table name (mutually exclusive with `--table-index`) |
| `--table-index` | int | Conditional | Zero-based table index in selected sheet (mutually exclusive with `--table`) |
| `--header` | enum | No | `with-header` (default) or `no-header` |
| `--rename` | repeatable string | No | Rename stage `OLD:NEW` (`OLD` = exact header name or zero-based index) |
| `--delete-column` | repeatable string | No | Delete stage selector (exact header name or zero-based index) |
| `--transform` | repeatable string | No | Transform stage `DEST=FUNC:SRC1;SRC2`, `FUNC` in `merge`, `pos`, `neg`, `upper`, `lower`, `trim` |
| `--parse-dates` | flag | No | Parse date-like values into typed date cells |
| `--date-column` | repeatable string | No | Date-parse selector (exact header name or zero-based index); requires `--parse-dates` |
| `--day-first` | flag | No | With `--parse-dates`, treats ambiguous slash/hyphen dates as day-first |
| `--date-format` | repeatable string | No | Additional `DateFormatter` patterns (checked before defaults); requires `--parse-dates` |
| `--output` | path | No | Save to output path; default is in-place save |

**Import behavior**

- Header mode `with-header`: first CSV row is preserved as row 0.
- Header mode `no-header`: generated row `Column 1..N` is inserted before CSV data.
- Pipeline stage order is deterministic: `rename -> delete-column -> transform`.
- Typed import converts booleans/numbers, and dates when `--parse-dates` is enabled.
- `--date-column`, `--date-format`, and `--day-first` are valid only with `--parse-dates`.
- Built-in date fallbacks: default `MM/dd/yyyy`, `MM-dd-yyyy`, `MM/dd/yyyy HH:mm:ss`, `MM/dd/yyyy HH:mm`, `yyyy-MM-dd`; with `--day-first`: `dd/MM/yyyy`, `dd-MM-yyyy`, `dd/MM/yyyy HH:mm:ss`, `dd/MM/yyyy HH:mm`, `yyyy-MM-dd`.

---

### 5.18.9 `swiftnumbers inspect`

**Purpose**

Inspect low-level container/object diagnostics, read-path decisions, and structured diagnostic payloads.

**Command**

```bash
swiftnumbers inspect <file.numbers> [--format text|json] [--redact] [--compact]
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `<file.numbers>` | path | Yes | Input `.numbers` |
| `--format` | `text`/`json` | No | Default `json` |
| `--redact` | flag | No | Redacts path-like fields in output |
| `--compact` | flag | No | Minifies JSON or emits one-line text summary |

**Visual output (text, compact)**

```text
readPath=real version=14.5 sheets=2 tables=3 cells=420 blobs=8 objects=112 edges=154 roots=1 diagnostics=0 structuredDiagnostics=0 redacted=false
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
