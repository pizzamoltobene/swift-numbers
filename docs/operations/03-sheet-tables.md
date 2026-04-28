# Operation 5.3

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.3 `Sheet.tables`

**Purpose**

Access all tables on one sheet in deterministic read-model order.

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `tables` | `[Table]` | n/a | Immutable snapshot collection for that sheet |

**Related helpers**

- `firstTable` returns `tables.first`
- `tableNames` returns `tables.map(\.name)`
- `table(named:)` / `table(at:)` and subscripts (`sheet["Name"]`, `sheet[index]`) provide non-throwing lookup helpers

**Visual**

Before:

|   | A | B |
|---|---|---|
| 1 | Item | Qty |
| 2 | Pen | 5 |

After calling `sheet.tables`: no mutation, same data.

**Example**

```swift
for table in sheet.tables {
  print(table.name)
}
print(sheet.firstTable?.name ?? "<none>")
print(sheet.tableNames)
print(sheet.table(named: "Table 1") as Any)
print(sheet[0] as Any)
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
