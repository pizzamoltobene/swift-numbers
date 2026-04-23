# Operation 5.3

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.3 `Sheet.tables`

**Purpose**

Read tables available on a sheet.

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `tables` | `[Table]` | n/a | Read-only |

**Visual**

Before:

|   | A | B |
|---|---|---|
| 1 | Item | Qty |
| 2 | Pen | 5 |

After calling `sheet.tables`: no mutation, same data.

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
