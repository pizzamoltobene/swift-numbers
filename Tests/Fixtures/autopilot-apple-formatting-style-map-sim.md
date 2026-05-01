# Apple Numbers AppleScript Formatting Style Map Simulation

## Advanced Object Discovery Probe Rows

| Probe | AppleScript status | Evidence | SwiftNumbers classification | SwiftNumbers parity target |
|---|---|---|---|---|
| range-formatting-style-discovery | available | `range.format`, `range.font name`, `range.font size`, `range.background color`, `range.text color`, `range.alignment`, `range.vertical alignment` | safe-read-only | `ReadCell.style`, `ReadCell.formatted`, `formattedValue(...)`, CLI `--formatting`; richer write parity remains guarded |
| rich-text-style-discovery | available | `rich text.color`, `rich text.font`, `rich text.size` | safe-read-only | `ReadCell.richText`, `ReadCell.style`, `formattedValue(...)`; richer rich-text writes remain a backlog gap |
| media-object-discovery | available | `image`, `movie`, `audio clip` | safe-read-only | `swiftnumbers inspect` media object inventory diagnostics; native media writes remain unsupported |
