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
| `headerRowCount` | `Int` | Header rows count (zero-based data starts after this region) |
| `headerColumnCount` | `Int` | Header columns count |
| `rowHeights` | `[Double?]` | Optional per-row heights (`nil` when row uses default height) |
| `columnWidths` | `[Double?]` | Optional per-column widths (`nil` when column uses default width) |
| `mergeRanges` | `[MergeRange]` | Merge areas if present |
| `tableNameVisible` | `Bool?` | Presentation flag when available in source document |
| `captionVisible` | `Bool?` | Caption visibility flag when available |
| `captionText` | `String?` | Caption text when available |
| `captionTextSupported` | `Bool` | Whether caption text storage is available for this table |
| `objectIdentifiers` | `TableObjectIdentifiers?` | Stable object IDs (`tableInfoObjectID`, `tableModelObjectID`) when available on real-read path |
| `pivotLinks` | `[PivotLinkMetadata]` | Resolver-discovered pivot-like drawable links with stable IDs |

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
print(m.headerRowCount, m.headerColumnCount)
print(m.rowHeights.count, m.columnWidths.count)
print(m.tableNameVisible as Any, m.captionVisible as Any, m.captionText as Any, m.captionTextSupported)
print(m.objectIdentifiers?.tableInfoObjectID as Any, m.pivotLinks.count)
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
