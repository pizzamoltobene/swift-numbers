# Operation 5.9

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.9 `cell(_ reference:)` / `EditableCell.value`

**Purpose**

Convenient A1-based editable accessor.

**Signatures**

```swift
func cell(_ reference: String) throws -> EditableCell
var value: CellValue? { get set }
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `reference` | `String` | Yes | A1 format (`C4`, `AA12`) |

**Throws**

- `invalidCellReference`

**Visual**

Before:

|   | A | B | C |
|---|---|---|---|
| 1 | Item | Qty | Done |
| 2 | Pen | 5 | false |

Operation:

```swift
let c2 = try table.cell("C2")
c2.value = .bool(true)
```

After:

|   | A | B | C |
|---|---|---|---|
| 1 | Item | Qty | Done |
| 2 | Pen | 5 | true |

**Example**

```swift
let c4 = try table.cell("C4")
c4.value = .string("Done")
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
