# Operation 5.4

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.4 `Table.metadata`

**Purpose**

Get structural metadata for a table.

**Attributes**

| Field | Type | Notes |
|---|---|---|
| `rowCount` | `Int` | Logical row count |
| `columnCount` | `Int` | Logical column count |
| `mergeRanges` | `[MergeRange]` | Merge areas if present |

**Visual**

```text
Table: Q1
rows=4, cols=3
mergeRanges:
  [row:0...0, col:0...1]   // A1:B1 merged
```

**Example**

```swift
let m = table.metadata
print(m.rowCount, m.columnCount, m.mergeRanges.count)
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
