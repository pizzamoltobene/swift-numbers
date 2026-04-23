# Operation 5.19

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.19 `swiftnumbers dump`

**Purpose**

Inspect read path, inventory, diagnostics, and table summaries.

**Command**

```bash
swiftnumbers dump <file.numbers> [--format text|json]
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `<file.numbers>` | path | Yes | Input `.numbers` |
| `--format` | `text`/`json` | No | Default `text` |

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
  "resolvedCellCount": 420,
  "diagnostics": []
}
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
