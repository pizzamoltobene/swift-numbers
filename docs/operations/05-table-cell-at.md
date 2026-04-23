# Operation 5.5

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.5 `Table.cell(at:)`

**Purpose**

Read the value at a zero-based address.

**Signature**

```swift
func cell(at address: CellAddress) -> CellValue?
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `address.row` | `Int` | Yes | Zero-based row |
| `address.column` | `Int` | Yes | Zero-based column |

**Returns**

- `CellValue?` (`nil` when absent)

**Visual**

|   | A | B | C |
|---|---|---|---|
| 1 | Item | Qty | Done |
| 2 | Pen | 5 | false |

`cell(at: .init(row: 1, column: 1)) -> .number(5)`

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
