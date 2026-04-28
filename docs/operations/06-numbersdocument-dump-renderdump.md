# Operation 5.6

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.6 `NumbersDocument.dump()` and `renderDump()`

**Purpose**

Get operational introspection data (metrics + diagnostics).

**Signatures**

```swift
func dump() -> DocumentDump
func renderDump() -> String
```

**Attributes (selected `DocumentDump`)**

| Field | Type | Meaning |
|---|---|---|
| `sourcePath` | `String` | Absolute/relative source path used for open |
| `documentVersion` | `String?` | Version from document metadata when available |
| `readPath` | `DocumentReadPath` | `real` or `metadataFallback` |
| `fallbackReason` | `String?` | Why fallback happened |
| `blobCount` | `Int` | Index blob count |
| `objectCount` | `Int` | IWA object count |
| `objectReferenceEdgeCount` | `Int` | Object reference graph edge count |
| `rootObjectCount` | `Int` | Root object count |
| `resolvedCellCount` | `Int` | Parsed populated cells |
| `typeHistogram` | `[UInt32:Int]` | Distribution by object type ID |
| `unparsedBlobPaths` | `[String]` | Blob paths that could not be parsed |
| `diagnostics` | `[String]` | Human-readable diagnostics |
| `structuredDiagnostics` | `[ReadDiagnostic]` | Structured diagnostics (`code`, `severity`, `message`, `objectPath`, `suggestion`, `context`) |

`renderDump()` produces a human-readable text report and includes inventory counts, type histogram, unparsed blob paths, and `diagnostics`. For machine workflows and structured diagnostics, use `dump()`.

**Visual**

```text
Source: /path/file.numbers
Document version: 14.5
Read path: real
Sheets: 3
Tables: 5
Resolved cells: 1200
Index blobs: 42
IWA objects: 915
Object reference edges: 1820
Root objects: 6
Type histogram:
  6000: 120
  6001: 34
Unparsed blobs: 0
Diagnostics: 1
```

**Example**

```swift
let report = doc.dump()
print(report.readPath, report.resolvedCellCount, report.structuredDiagnostics.count)
print(doc.renderDump())
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
