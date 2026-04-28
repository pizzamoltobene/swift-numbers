# Operation 5.14

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.14 `addTable(named:rows:columns:onSheetNamed:)`

**Purpose**

Create a new table on an existing sheet.

**Signature**

```swift
func addTable(named: String, rows: Int, columns: Int, onSheetNamed: String) throws -> EditableTable
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `name` | `String` | Yes | Table display name |
| `rows` | `Int` | Yes | Initial row count (`>= 0`) |
| `columns` | `Int` | Yes | Initial column count (`>= 0`) |
| `sheetName` | `String` | Yes | Existing target sheet |

**Throws**

- `EditableNumbersError.sheetNotFound(String)`
- `EditableNumbersError.invalidRowIndex(Int)`
- `EditableNumbersError.invalidColumnIndex(Int)`
- `EditableNumbersError.duplicateTableName(sheet: String, table: String)`

**Behavior**

- `name` is trimmed; empty/whitespace table names normalize to `Table N`.
- duplicate names on the same sheet fail fast (no auto-suffix).
- `rows`/`columns` may be zero (`>= 0` is accepted).

**Side Effects**

- appends the new table to the target sheet table list (stable order)
- marks sheet/document state as structure-dirty

**Visual**

Before (`Sales` has one table):

```text
Sheet: Sales
  - Table: Q1
```

Operation:

```swift
let t = try doc.addTable(named: "Forecast", rows: 2, columns: 3, onSheetNamed: "Sales")
t.setValue(.string("Ready"), at: CellAddress(row: 0, column: 0))
```

After:

```text
Sheet: Sales
  - Table: Q1
  - Table: Forecast
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
