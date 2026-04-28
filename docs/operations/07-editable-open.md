# Operation 5.7

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.7 `EditableNumbersDocument.open(at:)`

**Purpose**

Open a `.numbers` document in mutable mode by bootstrapping editable sheets/tables from read model data.

**Signature**

```swift
static func open(at url: URL) throws -> EditableNumbersDocument
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `url` | `URL` | Yes | Existing `.numbers` path |

**Returns**

- `EditableNumbersDocument` with:
  - editable `sheets` graph initialized from `NumbersDocument.open(at:)`
  - persisted style/custom-format registries restored from metadata overlays when present
  - clean initial state (`dirtyState == .clean`, `hasChanges == false`)

**Throws**

- read/open errors bubbled from `NumbersDocument.open(at:)`
- metadata overlay decode/open errors (style/custom-format registries)

**Side Effects**

- no mutation of source file on disk
- normalizes/stores `sourceURL` as standardized file URL

**Visual**

```mermaid
flowchart TD
  A["file.numbers"] --> B["EditableNumbersDocument.open(at:)"]
  B --> C["NumbersDocument.open(at:)"]
  C --> D["Bootstrap editable sheets/tables"]
  D --> E["Load style registry overlay (optional)"]
  E --> F["Load custom-format overlay (optional)"]
  F --> G["EditableNumbersDocument (clean state)"]
```

**Example**

```swift
let editable = try EditableNumbersDocument.open(at: inputURL)
print(editable.sheets.count)
print(editable.dirtyState, editable.hasChanges)
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
