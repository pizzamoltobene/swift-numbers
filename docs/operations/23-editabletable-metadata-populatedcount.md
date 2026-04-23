# Operation 5.23

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.23 `EditableTable.metadata` and `EditableTable.populatedCellCount`

**Purpose**

Inspect live structural stats for mutable tables.

**Properties**

```swift
var metadata: TableMetadata { get }
var populatedCellCount: Int { get }
```

**Attributes**

| Property | Type | Meaning |
|---|---|---|
| `metadata.rowCount` | `Int` | Current logical row count |
| `metadata.columnCount` | `Int` | Current logical column count |
| `metadata.mergeRanges` | `[MergeRange]` | Current merge map |
| `populatedCellCount` | `Int` | Non-empty cells currently stored |

**Visual (before/after `appendRow`)**

```text
Before: rows=3 cols=2 populated=6
After : rows=4 cols=2 populated=8
```

**Example**

```swift
let t = try doc.sheet(named: "Sales").table(named: "Q1")
print(t.metadata.rowCount, t.metadata.columnCount, t.populatedCellCount)
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
