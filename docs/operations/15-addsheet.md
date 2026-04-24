# Operation 5.15

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.15 `addSheet(named:)`

**Purpose**

Create a new sheet with default `Table 1`.

**Signature**

```swift
@discardableResult
func addSheet(named: String) -> EditableSheet
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `name` | `String` | Yes | New sheet name |

**Side Effects**

- adds a sheet
- creates default `Table 1` with `1x1`
- if name already exists, auto-suffixes (`Name`, `Name (2)`, ...)

**Visual**

Before:

```text
Sheets: [Sales, Marketing]
```

Operation:

```swift
let newSheet = doc.addSheet(named: "Archive")
try newSheet.table(named: "Table 1").setValue(.string("Seed"), at: "A1")
```

After:

```text
Sheets: [Sales, Marketing, Archive]
Archive contains: Table 1 (1x1)
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
