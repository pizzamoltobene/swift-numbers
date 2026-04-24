# Operation 5.17

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.17 `saveInPlace()`

**Purpose**

Explicit in-place persist with atomic replace semantics.

**Signature**

```swift
func saveInPlace() throws
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| n/a | n/a | n/a | Operates on current working path |

**Behavior**

- writes to temp path
- atomically replaces current working file
- no-op if there are no pending changes

**Visual**

```mermaid
flowchart LR
  A["working.numbers"] --> B["write temp .numbers"]
  B --> C["atomic replace working file"]
  C --> D["working.numbers updated"]
```

**Example**

```swift
table.setValue(.number(99), at: .init(row: 1, column: 1))
try doc.saveInPlace()
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
