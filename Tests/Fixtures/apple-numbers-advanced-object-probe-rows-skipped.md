| Probe | AppleScript status | Evidence | SwiftNumbers classification | SwiftNumbers parity target |
|---|---|---|---|---|
| chart-object-discovery | skipped | <not-probed> | safe-read-only | chart inventory and read-only diagnostics; native chart writes remain unsupported |
| pivot-object-discovery | skipped | <not-probed> | safe-write-blocked | pivot-like object diagnostics and write blocking for linked analytical drawables |
| range-formatting-style-discovery | skipped | <not-probed> | safe-read-only | `ReadCell.style`, `ReadCell.formatted`, `formattedValue(...)`, CLI `--formatting`; richer write parity remains guarded |
| media-object-discovery | skipped | <not-probed> | safe-read-only | media object inventory with unsupported-object diagnostics |
| shape-line-text-object-discovery | skipped | <not-probed> | safe-read-only | shape/line/text object inventory and no unsafe native mutation support |
| rich-text-style-discovery | skipped | <not-probed> | safe-read-only | `ReadCell.richText`, `ReadCell.style`, `formattedValue(...)`; richer rich-text writes remain a backlog gap |
