# Operation 5.8

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.8 `sheet(named:)` / `table(named:)`

**Purpose**

Resolve mutable sheet/table by name.

**Signatures**

```swift
func sheet(named: String) throws -> EditableSheet
func table(named: String) throws -> EditableTable
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `name` | `String` | Yes | Exact match in current model |

**Throws**

- `sheetNotFound`
- `tableNotFound`

**Visual**

```text
Document
  ├─ Sheet "Sales"
  │   ├─ Table "Q1"
  │   └─ Table "Forecast"
  └─ Sheet "Archive"

sheet(named: "Sales") -> EditableSheet("Sales")
table(named: "Q1")    -> EditableTable("Q1")
```

**Example**

```swift
let sales = try doc.sheet(named: "Sales")
let q1 = try sales.table(named: "Q1")
print(q1.name)
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
