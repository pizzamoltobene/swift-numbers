# Operation 5.25

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.25 `CellReference` + `cell(at reference: CellReference)`

**Purpose**

Use typed A1 references and avoid raw string parsing in hot paths.

**Signatures**

```swift
init(_ rawValue: String) throws
init(address: CellAddress)
func cell(at reference: CellReference) -> EditableCell
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `rawValue` | `String` | Yes | A1 coordinate like `B3`, `AA12` |
| `address` | `CellAddress` | Yes | Zero-based coordinate |
| `reference.address` | `CellAddress` | n/a | Parsed row/column |
| `reference.a1` | `String` | n/a | Normalized uppercase A1 text |

**Visual**

| A1 | row | column |
|---|---:|---:|
| `A1` | 0 | 0 |
| `B3` | 2 | 1 |
| `AA10` | 9 | 26 |

**Example**

```swift
let ref = try CellReference("D5")
let editableCell = table.cell(at: ref)
editableCell.value = .string("Ready")
```


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
