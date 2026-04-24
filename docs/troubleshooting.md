# Troubleshooting

Quick runbook for `SwiftNumbers v0.3.1.1`.

## Fast Triage

```bash
swift run swiftnumbers dump /absolute/path/file.numbers --format json
```

Check first:
- `readPath`
- `fallbackReason`
- `diagnostics`

## Common Issues

| Symptom | Likely cause | What to do |
|---|---|---|
| `NumbersDocument.open(at:)` throws | invalid/corrupted archive, unsupported shape, wrong path | verify file opens in Apple Numbers, run `dump --format json` |
| `sheetNotFound` | wrong sheet name | print available `doc.sheets.map(\.name)` |
| `tableNotFound` | wrong table name for selected sheet | list `sheet.tables.map(\.name)` |
| `invalidCellReference` | bad A1 (`A0`, `1A`, empty) | validate A1 or use `CellAddress` |
| Save completed but value is wrong | mutated different sheet/table/cell | reopen output and assert exact target cell |
| Diagnostics warnings in dump | fallback or decode anomaly | inspect `readPath`, `fallbackReason`, `structuredDiagnostics` |
| Slow CLI timings | debug build / cold-start noise | run release build and compare median |
| CI fails, local seems fine | environment mismatch | run `./scripts/ci-check.sh` and compare toolchain |

## Save Validation Routine

1. Open source file.
2. Apply one minimal mutation.
3. `save(to:)` to a new path.
4. Reopen saved file via read API.
5. Assert target cell value.
6. Run `dump --format json` if mismatch remains.

## In-place Save Note

`saveInPlace()` does atomic replace on the **current working document path**
(the latest successful destination if you already called `save(to:)`).

## When Reporting a Bug

Include:
- SwiftNumbers version/tag
- macOS + Swift version
- failing command or API call
- `dump --format json` output (or minimal excerpt)
- expected vs actual value/read path

## Related Docs

- [Capabilities](capabilities.md)
- [CLI Reference](cli-reference.md)
- [Cookbook](cookbook.md)
