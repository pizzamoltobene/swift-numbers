# Apple Numbers AppleScript Mutation Renewal Map Simulation

## Mutation Semantics Probe Rows

| Probe | AppleScript status | Evidence | SwiftNumbers parity target |
|---|---|---|---|
| document-lifecycle-mutation | available | `save`, `export`, `set password`, `remove password` | guarded document lifecycle write planning and release-safe export parity |
| table-mutation-operation | missing | missing native `make table` parity evidence | `addTable`, table rename, and duplicate-table safety guards |
| row-column-mutation-operation | missing | missing `add row below`, `add column after` parity evidence | `appendRow`, `insertRow`, `appendColumn`, `insertColumn`, `deleteRow`, `deleteColumn` safety guards |
