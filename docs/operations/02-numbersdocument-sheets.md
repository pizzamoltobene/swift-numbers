# Operation 5.2

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.2 `NumbersDocument.sheets`

**Purpose**

Access all sheets in read model order.

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `sheets` | `[Sheet]` | n/a | Read-only collection |

**Visual**

```mermaid
graph TD
  D["NumbersDocument"] --> S1["Sheet 1"]
  D --> S2["Sheet 2"]
  S1 --> T1["Table A"]
  S1 --> T2["Table B"]
  S2 --> T3["Table C"]
```

**Example**

```swift
for sheet in doc.sheets {
  print(sheet.name)
}
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
