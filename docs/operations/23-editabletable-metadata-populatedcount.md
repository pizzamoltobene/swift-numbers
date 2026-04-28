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
| `metadata.headerRowCount` | `Int` | Current header-row count persisted in table metadata |
| `metadata.headerColumnCount` | `Int` | Current header-column count persisted in table metadata |
| `metadata.rowHeights` | `[Double?]` | Optional per-row height values when present in source |
| `metadata.columnWidths` | `[Double?]` | Optional per-column width values when present in source |
| `metadata.mergeRanges` | `[MergeRange]` | Current merge map |
| `metadata.tableNameVisible` | `Bool?` | Table name visibility flag when available |
| `metadata.captionVisible` | `Bool?` | Caption visibility flag when available |
| `metadata.captionText` | `String?` | Caption text when available |
| `metadata.captionTextSupported` | `Bool` | Whether caption text storage is available |
| `metadata.objectIdentifiers` | `TableObjectIdentifiers?` | Stable table object IDs when available |
| `metadata.pivotLinks` | `[PivotLinkMetadata]` | Resolver-discovered pivot-like links |
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
