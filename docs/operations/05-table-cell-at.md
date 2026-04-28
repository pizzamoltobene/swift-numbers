# Operation 5.5

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.5 `Table.cell(at:)`

**Purpose**

Read the stored `CellValue` at a zero-based address.

**Signature**

```swift
func cell(at address: CellAddress) -> CellValue?
```

**Related overloads**

```swift
func cell(row: Int, column: Int) -> CellValue?
func cell(_ reference: String) -> CellValue?
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `address.row` | `Int` | Yes | Zero-based row |
| `address.column` | `Int` | Yes | Zero-based column |

**Returns**

- `CellValue?`:
  - populated cell -> concrete value (`.string`, `.number`, `.bool`, `.date`, `.formula`, `.empty`)
  - missing/unpopulated cell -> `nil`
  - invalid A1 in `cell(_ reference:)` -> `nil`
  - negative index in `cell(row:column:)` -> `nil`

Use `readCell(at:)` when you need an explicit read snapshot for empty in-bounds cells.

**Visual**

|   | A | B | C |
|---|---|---|---|
| 1 | Item | Qty | Done |
| 2 | Pen | 5 | false |

`cell(at: .init(row: 1, column: 1)) -> .number(5)`
`cell(at: .init(row: 99, column: 99)) -> nil`

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
