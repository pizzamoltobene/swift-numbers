# Operation 5.24

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.24 `Table.allCells` and `Table.populatedCellCount` (read model)

**Purpose**

Access full sparse-cell map from read-only model.

**Properties**

```swift
var allCells: [CellAddress: CellValue] { get }
var populatedCellCount: Int { get }
```

**Attributes**

| Property | Type | Meaning |
|---|---|---|
| `allCells` | `[CellAddress: CellValue]` | Sparse dictionary of populated cells |
| `populatedCellCount` | `Int` | Number of stored non-empty cells |

**Visual**

```text
allCells:
  (row:0,col:0) -> "Item"
  (row:0,col:1) -> "Qty"
  (row:1,col:0) -> "Pen"
  (row:1,col:1) -> 5
```

**Example**

```swift
let table = doc.sheets[0].tables[0]
for (address, value) in table.allCells {
  print(address.row, address.column, value)
}
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
