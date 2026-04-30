# Apple Numbers AppleScript Read Probe Map Simulation

## Read Semantics Probe Rows

| Probe | AppleScript status | Evidence | SwiftNumbers public surface |
|---|---|---|---|
| cell-read-surface | missing | missing `cell.formatted value` parity fixture | `read-cell --format json` formatted value parity |
| sheet-read-surface | available | `sheet.name`, `sheet.tables` | `list-sheets --format json` and `list-tables --format json` |
| table-read-surface | available | `table.name`, `table.row count`, `table.column count` | `read-table --format json` metadata parity |
