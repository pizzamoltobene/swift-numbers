# Operation 5.10

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.10 `setValue(_:at:)`

**Purpose**

Set a cell value at coordinate or A1 reference.

**Signatures**

```swift
func setValue(_ value: CellValue, at address: CellAddress)
func setValue(_ value: CellValue, at reference: String) throws
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `value` | `CellValue` | Yes | Any supported value type |
| `address` | `CellAddress` | Yes | Zero-based coordinate |
| `reference` | `String` | Yes | A1 coordinate (alt overload) |

**Side Effects**

- marks document dirty
- can grow table bounds if target is outside current size

**Visual (before/after)**

Before:

|   | A | B | C |
|---|---|---|---|
| 1 | Item | Qty | Done |
| 2 | Pen | 5 | false |
| 3 | Pencil | 10 | false |

Operation:

```swift
table.setValue(.bool(true), at: CellAddress(row: 2, column: 2))
```

After:

|   | A | B | C |
|---|---|---|---|
| 1 | Item | Qty | Done |
| 2 | Pen | 5 | false |
| 3 | Pencil | 10 | true |

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
