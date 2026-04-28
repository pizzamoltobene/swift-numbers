# Operation 5.1

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.1 `NumbersDocument.open(at:)`

**Purpose**

Open a `.numbers` file and build the Swift-native read model (`NumbersDocument`).

**Signature**

```swift
static func open(at url: URL) throws -> NumbersDocument
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `url` | `URL` | Yes | Path to package or single-file archive `.numbers` |

**Returns**

- `NumbersDocument`

**Throws**

- container/path/archive parse errors
- `NumbersDocumentError.encryptedDocumentUnsupported` for password-protected documents
- `NumbersDocumentError.realReadFailed(String)` when real-read returns no sheet model (with best available diagnostic reason)

**Side Effects**

- none on disk

**Visual**

```mermaid
graph TD
  A["Input: file.numbers"] --> B["Container load"]
  B --> C["Encryption guard"]
  C --> D["IWA inventory"]
  D --> E["Real-read decode"]
  E --> F["Optional style overlay metadata"]
  F --> G["NumbersDocument(sheets/tables/cells)"]
```

**Example**

```swift
let doc = try NumbersDocument.open(at: inputURL)
print(doc.sheets.count)
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
