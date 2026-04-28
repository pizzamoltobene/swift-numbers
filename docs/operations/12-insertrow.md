# Operation 5.12

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.12 `insertRow(_:at:)`

**Purpose**

Insert row at index and shift subsequent rows down.

**Signature**

```swift
func insertRow(_ values: [CellValue], at rowIndex: Int) throws
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `values` | `[CellValue]` | Yes | Row payload |
| `rowIndex` | `Int` | Yes | `0...rowCount` |

**Throws**

- `EditableNumbersError.invalidRowIndex(Int)`

**Behavior**

- `rowIndex == rowCount` is allowed (equivalent to append-at-end semantics).
- existing rows at and below `rowIndex` are shifted down by one.
- only non-`.empty` values are materialized into cell storage (sparse representation).

**Side Effects**

- `rowCount += 1`
- may increase `columnCount` if `values.count` is larger
- inserts one `rowHeights` slot (`nil`) at `rowIndex`
- when `columnCount` grows, appends matching `columnWidths` slots (`nil`)
- marks document/table dirty (structure changed)

**Visual (before/after)**

Before:

|   | A | B |
|---|---|---|
| 1 | Name | Score |
| 2 | Alice | 9 |
| 3 | Bob | 7 |

Operation:

```swift
try table.insertRow([.string("Header"), .string("Value")], at: 0)
```

After:

|   | A | B |
|---|---|---|
| 1 | Header | Value |
| 2 | Name | Score |
| 3 | Alice | 9 |
| 4 | Bob | 7 |

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
