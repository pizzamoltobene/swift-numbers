# Apple Numbers AppleScript Formula Renewal Map Simulation

## Formula Semantics Probe Rows

| Probe | AppleScript status | Evidence | SwiftNumbers parity target |
|---|---|---|---|
| formula-text-read | available | `cell.formula` | formula text extraction and stable JSON formula output |
| formula-result-read | available | `cell.value`, `cell.formatted value` | formula result and formatted-result parity |
| formula-write-operation | missing | missing guarded native formula write parity evidence | safe formula writes with reference validation and deterministic diagnostics |
