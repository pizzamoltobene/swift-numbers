# Troubleshooting

Common issues and resolution steps for `SwiftNumbers v0.3.0`.

## 1) Open fails for a `.numbers` file

### Symptoms

- `NumbersDocument.open(at:)` throws.
- CLI command exits non-zero.

### Checks

1. Verify path points to an existing `.numbers` item.
2. Confirm you can open the same file in Apple Numbers.
3. Run:

```bash
swift run swiftnumbers dump /absolute/path/file.numbers --format text
```

### Typical causes

- invalid/corrupted archive
- truncated package contents
- unsupported layout variant

## 2) `sheetNotFound` or `tableNotFound`

### Symptoms

- `EditableNumbersError.sheetNotFound`
- `EditableNumbersError.tableNotFound`

### Resolution

- Enumerate available names before lookup:

```swift
for s in doc.sheets {
  print(s.name)
  for t in s.tables {
    print("  \(t.name)")
  }
}
```

- Ensure exact casing and spacing match.
- If adding a table, note that duplicate table names in the same sheet now throw `duplicateTableName`.

## 3) `invalidCellReference`

### Symptoms

- A1 parsing fails for values like `A0`, `1A`, `A-1`, empty string.

### Valid A1 examples

- `A1`
- `B3`
- `AA10`

### Recommendation

- Use `CellAddress(row:column:)` when indices are already numeric.
- Use `CellReference` once and reuse it in loops.

## 4) Save succeeds but values are not as expected

### Checks

1. Reopen saved output via read API and assert values.
2. Compare `dump --format json` before/after.
3. Validate you updated the expected table/sheet names.

### Safe verification pattern

```swift
let reopened = try NumbersDocument.open(at: outputURL)
let sheet = reopened.sheets.first { $0.name == "Sales" }
let table = sheet?.tables.first { $0.name == "Q1" }
let value = table?.cell(at: CellAddress(row: 3, column: 2))
print(value as Any)
```

## 5) Diagnostic lines appear in `dump`

### What this means

Diagnostics indicate important parse/resolve events:

- informational decisions
- warnings about fallback or unsupported versions
- error-level decode problems

### First step

Inspect:

- `readPath`
- `fallbackReason`
- `diagnostics[]`

with:

```bash
swift run swiftnumbers dump /abs/file.numbers --format json
```

## 6) `saveInPlace()` concerns

### Behavior

`saveInPlace()` performs temp-write + atomic replace.
- It targets the current working document path (the latest successful `save(to:)` destination).

### Recommendation

- For safer workflows, first use `save(to:)` with a new destination.
- Validate output.
- Then replace source if needed.

## 7) Performance appears unexpectedly slow

### Checks

1. Build in release:

```bash
swift build -c release
swift run -c release swiftnumbers dump /abs/file.numbers
```

2. Avoid first-run cold-start noise.
3. Run multiple iterations and use median.

## 8) Tests pass locally but CI fails

### Baseline local command

```bash
./scripts/ci-check.sh
```

### Confirm

- Swift toolchain version matches CI expectation.
- No unstaged local generated artifacts are required by tests.

## Error quick reference

| Error | Meaning | Typical fix |
|---|---|---|
| `sheetNotFound(name)` | Sheet name not present | List names, fix input |
| `tableNotFound(sheet, table)` | Table missing in selected sheet | Verify table name/sheet pair |
| `duplicateTableName(sheet, table)` | Duplicate table name in one sheet | Choose a unique name before `addTable` |
| `invalidCellReference(raw)` | A1 format invalid | Use valid A1 or `CellAddress` |
| `invalidRowIndex(i)` | Row index outside allowed range | Validate bounds before insert |
| `invalidColumnIndex(i)` | Column index invalid | Validate column sizes |
| `nativeWriteFailed(details)` | Writer backend failed | Reproduce with `dump`, isolate file |

## Recommended debug routine

1. Run `dump --format json` on source.
2. Perform one minimal mutation.
3. Save to new path.
4. Reopen and assert target cell.
5. Inspect dump for diagnostics.

## Related docs

- [Capabilities](capabilities.md)
- [Cookbook](cookbook.md)
- [CLI Reference](cli-reference.md)
