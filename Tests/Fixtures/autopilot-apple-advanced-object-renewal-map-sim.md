# Apple Numbers AppleScript Advanced Object Renewal Map Simulation

## Advanced Object Discovery Probe Rows

| Probe | AppleScript status | Evidence | SwiftNumbers classification | SwiftNumbers parity target |
|---|---|---|---|---|
| chart-object-discovery | available | `chart` | safe-read-only | chart inventory and read-only diagnostics; native chart writes remain unsupported |
| pivot-object-discovery | missing | missing `pivot` | safe-write-blocked | pivot-like object diagnostics and write blocking for linked analytical drawables |
| range-formatting-style-discovery | available | `range.format`, `range.font name`, `range.background color` | safe-read-only | `ReadCell.style`, `ReadCell.formatted`, `formattedValue(...)`, CLI `--formatting`; richer write parity remains guarded |
| media-object-discovery | available | `image`, `movie`, `audio clip` | safe-read-only | media object inventory with unsupported-object diagnostics |
| shape-line-text-object-discovery | available | `shape`, `line`, `text item` | safe-read-only | shape/line/text object inventory and no unsafe native mutation support |
