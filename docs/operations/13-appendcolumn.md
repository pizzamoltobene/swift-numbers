# Operation 5.13

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.13 `appendColumn(_:)`

**Purpose**

Append a new column at the end.

**Signature**

```swift
func appendColumn(_ values: [CellValue])
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `values` | `[CellValue]` | Yes | Values for each row |

**Side Effects**

- `columnCount += 1`
- may increase `rowCount` if `values.count` is larger

**Visual (before/after)**

Before:

|   | A | B |
|---|---|---|
| 1 | Name | Score |
| 2 | Alice | 9 |
| 3 | Bob | 7 |

Operation:

```swift
table.appendColumn([.string("Status"), .string("Pass"), .string("Pass")])
```

After:

|   | A | B | C |
|---|---|---|---|
| 1 | Name | Score | Status |
| 2 | Alice | 9 | Pass |
| 3 | Bob | 7 | Pass |

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
