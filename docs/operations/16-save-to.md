# Operation 5.16

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.16 `save(to:)`

**Purpose**

Persist all mutations to disk.

**Signature**

```swift
func save(to outputURL: URL) throws
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `outputURL` | `URL` | Yes | New destination or same-path in-place |

**Behavior**

- if `outputURL` equals current working path and there are no pending changes: no-op
- if `outputURL` equals current working path and there are pending changes: performs atomic in-place replace
- if `outputURL` is a different path: writes a new document and sets that path as the new working path
- if no changes and `outputURL` is a different path: copies current working container
- repeated saves continue from the latest successful working path
- successful save resets pending operations/style registries and sets `dirtyState` to `clean`

**Visual**

```mermaid
flowchart LR
  A["Editable document in memory"] --> B{"save(to:) target"}
  B -->|"new path"| C["write new .numbers"]
  B -->|"same path"| D["temp file + atomic replace"]
```

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
