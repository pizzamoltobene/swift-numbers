# Operation 5.10

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.10 `setValue(_:at:)`

**Purpose**

Set a cell value at coordinate or A1 reference.

**Signatures**

```swift
func setValue(_ value: CellValue, at address: CellAddress)
func setValue(_ value: CellValue, at reference: String) throws
func clearValue(at address: CellAddress)
func clearValue(at reference: String) throws
func clearValues(in range: MergeRange) throws
func clearValues(in rangeReference: String) throws
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `value` | `CellValue` | Yes | Any supported value type |
| `address` | `CellAddress` | Yes | Zero-based coordinate |
| `reference` | `String` | Yes | A1 coordinate (alt overload) |
| `range` | `MergeRange` | Yes | Zero-based rectangular range for `clearValues` |
| `rangeReference` | `String` | Yes | A1 range such as `A2:C4` for `clearValues` |

**Throws**

- `CellReferenceError.invalidFormat(String)` when `reference` is not valid A1 syntax
- `EditableNumbersError.invalidRangeReference(String)` when `rangeReference` is malformed or
  outside the current table bounds

**Behavior**

- `value == .empty` and `clearValue(at:)` remove the stored value entry for that address.
- `clearValues(in:)` removes stored values across an in-bounds rectangular range.
- negative `row`/`column` addresses are ignored (no mutation, no dirty mark).

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
try table.clearValue(at: "A2")
try table.clearValues(in: "B2:C2")
```

After:

|   | A | B | C |
|---|---|---|---|
| 1 | Item | Qty | Done |
| 2 |  |  |  |
| 3 | Pencil | 10 | true |

---

### 5.10a `setStyle(_:at:)`

**Purpose**

Apply or clear a style bundle at coordinate or A1 reference.

**Signatures**

```swift
func setStyle(_ style: ReadCellStyle?, at address: CellAddress)
func setStyle(_ style: ReadCellStyle?, at reference: String) throws
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `style` | `ReadCellStyle?` | Yes | `nil` clears stored style for the target cell |
| `address` | `CellAddress` | Yes | Zero-based coordinate |
| `reference` | `String` | Yes | A1 coordinate (alt overload) |

**Side Effects**

- marks document dirty
- can grow table bounds if target is outside current size
- style mutations currently use metadata-overlay persistence when saving

---

### 5.10a.1 Document style registry (`registerStyle`, `registeredStyles`, `applyStyle`)

**Purpose**

Create reusable named style definitions at document scope and apply them by stable identifier.

**Signatures**

```swift
@discardableResult
func registerStyle(named name: String, style: ReadCellStyle) throws -> String
func registeredStyles() -> [RegisteredDocumentStyle]
func registeredStyle(id styleID: String) -> RegisteredDocumentStyle?
func applyStyle(id styleID: String, at address: CellAddress) throws
func applyStyle(id styleID: String, at reference: String) throws
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `name` | `String` | Yes | Empty/whitespace names are normalized to `Style N` |
| `style` | `ReadCellStyle` | Yes | Style payload stored in document registry |
| `styleID` | `String` | Yes | Stable identifier returned from `registerStyle` |
| `address` | `CellAddress` | Yes | Zero-based coordinate |
| `reference` | `String` | Yes | A1 coordinate (alt overload) |

**Side Effects**

- creating/applying a registered style marks the document dirty
- style registry entries persist across save/reopen via metadata overlay
- duplicate style names fail fast with `duplicateStyleName`
- unknown style identifiers fail fast with `styleNotFound`

---

### 5.10a.2 Document custom-format registry (`registerCustomFormat`, `registeredCustomFormats`, `applyCustomFormat`)

**Purpose**

Create reusable named custom-number-format definitions at document scope and apply them by stable identifier.

**Signatures**

```swift
@discardableResult
func registerCustomFormat(named name: String, formatID: Int32) throws -> String
func registeredCustomFormats() -> [RegisteredDocumentCustomFormat]
func registeredCustomFormat(id customFormatID: String) -> RegisteredDocumentCustomFormat?
func applyCustomFormat(id customFormatID: String, at address: CellAddress) throws
func applyCustomFormat(id customFormatID: String, at reference: String) throws
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `name` | `String` | Yes | Empty/whitespace names are normalized to `Custom Format N` |
| `formatID` | `Int32` | Yes | Raw custom format identifier persisted in style number-format payload |
| `customFormatID` | `String` | Yes | Stable identifier returned from `registerCustomFormat` |
| `address` | `CellAddress` | Yes | Zero-based coordinate |
| `reference` | `String` | Yes | A1 coordinate (alt overload) |

**Side Effects**

- creating a registered custom format marks document dirty
- custom format registry entries persist across save/reopen via metadata overlay
- duplicate custom format names fail fast with `duplicateCustomFormatName`
- unknown custom format identifiers fail fast with `customFormatNotFound`

---

### 5.10b `setFormat(_:at:)`

**Purpose**

Apply or clear number/date/currency/custom format hints, including extended numeric families (`base`, `fraction`, `percentage`, `scientific`) and control families (`tickbox`, `rating`, `slider`, `stepper`, `popup`), at coordinate or A1 reference.

**Signatures**

```swift
func setFormat(_ format: EditableCellFormat?, at address: CellAddress)
func setFormat(_ format: EditableCellFormat?, at reference: String) throws
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `format` | `EditableCellFormat?` | Yes | `nil` clears only number-format hint while preserving other style fields |
| `address` | `CellAddress` | Yes | Zero-based coordinate |
| `reference` | `String` | Yes | A1 coordinate (alt overload) |

**Side Effects**

- marks document dirty
- can grow table bounds if target is outside current size
- format mutations currently persist through metadata-overlay style path

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
