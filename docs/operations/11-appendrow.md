# Operation 5.11

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)

### 5.11 `appendRow(_:)`

**Purpose**

Append a row at end of table.

**Signature**

```swift
func appendRow(_ values: [CellValue])
```

**Attributes**

| Attribute | Type | Required | Notes |
|---|---|---|---|
| `values` | `[CellValue]` | Yes | New row values |

**Side Effects**

- `rowCount += 1`
- may increase `columnCount` if `values.count` is larger

**Visual (before/after)**

Before (`rowCount = 3`):

|   | A | B |
|---|---|---|
| 1 | Name | Score |
| 2 | Alice | 9 |
| 3 | Bob | 7 |

Operation:

```swift
table.appendRow([.string("Carol"), .number(10)])
```

After (`rowCount = 4`):

|   | A | B |
|---|---|---|
| 1 | Name | Score |
| 2 | Alice | 9 |
| 3 | Bob | 7 |
| 4 | Carol | 10 |

---


---

## Additional Notes

- This page is generated from the canonical operation section in [Capabilities](../capabilities.md).
- If API behavior changes, update the source operation card and regenerate operation pages.
