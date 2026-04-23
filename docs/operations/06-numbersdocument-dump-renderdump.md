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
| `readPath` | `DocumentReadPath` | `real` or `metadataFallback` |
| `fallbackReason` | `String?` | Why fallback happened |
| `resolvedCellCount` | `Int` | Parsed populated cells |
| `diagnostics` | `[String]` | Human-readable diagnostics |

**Visual**

```text
Source: /path/file.numbers
Read path: real
Sheets: 3
Tables: 5
Resolved cells: 1200
Diagnostics: 1
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
