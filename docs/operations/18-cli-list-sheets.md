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


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
