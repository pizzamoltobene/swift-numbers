| Probe | AppleScript status | Evidence | SwiftNumbers public surface |
|---|---|---|---|
| sheet-list-read | skipped | <not-probed> | `NumbersDocument.sheetSummaries(at:)`, `swiftnumbers list-sheets` |
| table-list-read | skipped | <not-probed> | `NumbersDocument.tableSummaries(at:)`, `swiftnumbers list-tables` |
| range-read | skipped | <not-probed> | `NumbersDocument.readRange(...)`, `swiftnumbers read-range` |
| row-read | skipped | <not-probed> | `TableModel.readCells(in:)`, `swiftnumbers read-range` row slices |
| column-read | skipped | <not-probed> | `TableModel.readCells(in:)`, `swiftnumbers read-column` |
| cell-value-read | skipped | <not-probed> | `NumbersDocument.readCell(...)`, `swiftnumbers read-cell` |
| table-selection-range-read | skipped | <not-probed> | `TableModel.usedRange`, table/range diagnostics |
