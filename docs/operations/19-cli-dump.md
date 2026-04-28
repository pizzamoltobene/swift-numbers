# Operation 5.19

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.19 `swiftnumbers dump`

**Purpose**

Inspect read path, inventory, diagnostics, and table summaries.

**Command**

```bash
swiftnumbers dump <file.numbers> [--format text|json] [--formulas] [--cells] [--formatting]
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `<file.numbers>` | path | Yes | Input `.numbers` |
| `--format` | `text`/`json` | No | Default `text` |
| `--formulas` | flag | No | Include formula-read details |
| `--cells` | flag | No | Include populated-cell read snapshots |
| `--formatting` | flag | No | Include deterministic per-cell formatting profiles |

**Behavior**

- default format is `text` (`--format json` emits structured payload).
- `--formulas`, `--cells`, and `--formatting` are additive; each section is included independently.

**Visual output (text, abbreviated)**

```text
Read path: real
Sheets: 2
Tables: 3
Resolved cells: 420
Diagnostics: 0
```

**Visual output (json, abbreviated)**

```json
{
  "readPath": "real",
  "sheetCount": 2,
  "tableCount": 3,
  "sheets": [
    {
      "name": "Sheet 1",
      "tables": [
        {
          "name": "Table 1",
          "tableNameVisible": true,
          "captionVisible": false,
          "captionText": "",
          "captionTextSupported": true
        }
      ]
    }
  ],
  "resolvedCellCount": 420,
  "diagnostics": []
}
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
