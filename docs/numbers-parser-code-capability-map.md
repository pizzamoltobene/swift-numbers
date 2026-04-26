# numbers-parser Code Capability Map

Last updated: 2026-04-26

This document is a code-derived map of `numbers-parser` capabilities used to drive roadmap work in `SwiftNumbers`.
No README/API docs claims were used for this baseline.

## Baseline Snapshot

- Repository: `https://github.com/masaccio/numbers-parser`
- Baseline commit: `65076c1`
- Commit date: `2026-02-10`
- Analyzed files:
  - `src/numbers_parser/document.py`
  - `src/numbers_parser/cell.py`
  - `src/numbers_parser/_cat_numbers.py`
  - `src/numbers_parser/_csv2numbers.py`
  - `src/numbers_parser/_unpack_numbers.py`
  - `pyproject.toml`

## Capability Map (Code-Only)

### 1) Document-Level API

Exposed in `Document`:

- `sheets`, `default_table`, `styles`, `custom_formats` getters
- `save(filename, package=False)`
  - pivot tables are explicitly skipped with warning during save
- `add_sheet(...)`
- `add_style(...)`
- `add_custom_format(...)`

Evidence:
- `document.py:105-120`
- `document.py:127-158`
- `document.py:160-344`

### 2) Sheet-Level API

Exposed in `Sheet`:

- `tables` getter
- sheet `name` getter/setter
- `add_table(...)`

Evidence:
- `document.py:353-368`
- `document.py:366-469`

### 3) Table-Level Read/Metadata API

Exposed in `Table`:

- Table presentation metadata:
  - `name` getter/setter
  - `table_name_enabled` getter/setter
  - `caption_enabled` getter/setter
  - `caption` getter/setter
- Header/layout metadata:
  - `num_header_rows`, `num_header_cols`
  - `height`, `width`, `row_height`, `col_width`, `coordinates`
- Cell/table reads:
  - `rows(values_only=...)`
  - `cell(...)` with row/col and A1 notation
  - `iter_rows(...)`, `iter_cols(...)`
  - `merge_ranges`
  - `categorized_data(values_only=...)`

Evidence:
- `document.py:497-658`
- `document.py:658-919`
- `document.py:1020-1074`

### 4) Table-Level Write/Mutation API

Exposed in `Table`:

- `write(...)` value write
- `set_cell_style(...)`
- Structural mutations:
  - `add_row(...)`
  - `add_column(...)`
  - `delete_row(...)`
  - `delete_column(...)`
- Merge operations:
  - `merge_cells(...)`
  - no `unmerge` method found in `document.py`

Evidence:
- `document.py:944-1019`
- `document.py:1075-1279`
- `document.py:1280-1321`

### 5) Border/Formatting API

Exposed in `Table`:

- `set_cell_border(...)` with side selection and stroke length
- `set_cell_formatting(...)` with data format families:
  - `base`, `currency`, `custom`, `datetime`, `fraction`
  - `percentage`, `number`, `scientific`
  - `tickbox`, `rating`, `slider`, `stepper`, `popup`

Document-level custom formats are also mutable via `add_custom_format(...)`.

Evidence:
- `document.py:1323-1423`
- `document.py:1424-1629`
- `document.py:269-344`

### 6) Formula Behavior

Cell read path exposes formula metadata:

- `Cell.is_formula`
- `Cell.formula`

Write typing path (`Cell._from_value`) supports string/number/bool/date/duration,
but does not include a dedicated formula value type.

Evidence:
- `cell.py:637-660`
- `cell.py:797-822`

### 7) CLI Surface

Registered executables:

- `cat-numbers`
- `unpack-numbers`
- `csv2numbers`

`cat-numbers` supports table/sheet listing, formula dump mode, formatted-value dump mode,
and sheet/table filtering.

`csv2numbers` supports CSV conversion with options for whitespace normalization,
reverse order, no-header mode, day-first date parsing, encoding override, date column parsing,
column rename/delete, and transform operators (`merge`, `neg`, `pos`, `lookup`).

`unpack-numbers` supports low-level unpacking options for UUID view, storage prettification,
compact JSON, redaction, and output directory selection.

Evidence:
- `pyproject.toml:31-34`
- `_cat_numbers.py:32-90`
- `_csv2numbers.py:249-374`
- `_unpack_numbers.py:119-133`

## SwiftNumbers Code Snapshot (for Gap Scoring)

Current `SwiftNumbers` code exposes:

- Editable write API: `setValue`, `setStyle`, `setFormat`, `appendRow`, `insertRow`, `appendColumn`
- `EditableCellFormat` currently: `number`, `date`, `currency`, `custom`
- Formula write support exists in persistence path (`CellValue.formula` case handling)
- Merge metadata read exists (`TableMetadata.mergeRanges`, `mergeRange(...)`, `isMergedCell(...)`)
- Pivot-linked and grouped-table unsafe mutations are explicitly blocked with deterministic errors
- CLI subcommands: `dump`, `list-sheets`, `list-tables`, `list-formulas`, `read-cell`, `read-column`, `read-table`, `read-range`, `export-csv`, `import-csv`

Evidence:
- `Sources/SwiftNumbersCore/EditableNumbers.swift:50-733`
- `Sources/SwiftNumbersCore/EditableNumbers.swift:1056-1067`
- `Sources/SwiftNumbersCore/Models.swift:565-583`
- `Sources/SwiftNumbersCore/Models.swift:1115-1137`
- `Sources/SwiftNumbersCore/IWASetCellWriter.swift:261-289`
- `Sources/swiftnumbers/main.swift:23-33`

## Conveyor Matrix (numbers-parser -> SwiftNumbers Roadmap)

| Capability Area | numbers-parser (65076c1) | SwiftNumbers (current code) | Conveyor Task |
|---|---|---|---|
| Merge create/remove API | `merge_cells` only (no unmerge symbol) | merge read; merge/unmerge write pending | `SN-R44`, `SN-R72` |
| Table caption + table-name visibility API | present | pending | `SN-R45` |
| Delete row/column API | present (`delete_row`, `delete_column`) | pending | `SN-R71` |
| Header rows/cols mutation | present (`num_header_rows`, `num_header_cols`) | pending | `SN-R73` |
| Row/column geometry mutation | present (`row_height`, `col_width`, `coordinates`) | pending | `SN-R74` |
| Style registry and apply | present (`add_style`, `set_cell_style`) | style apply exists; registry API pending | `SN-R75` |
| Border write API | present (`set_cell_border`) | pending | `SN-R77` |
| Extended format families | present (base/fraction/percentage/scientific/etc.) | core set only (`number/date/currency/custom`) | `SN-R78` |
| Interactive format controls | present (`tickbox`, `rating`, `slider`, `stepper`, `popup`) | pending | `SN-R79` |
| Document custom format registry | present (`add_custom_format`) | partial/custom apply path exists; registry API pending | `SN-R76` |
| Categorized/grouped read surface | present (`categorized_data`) | grouped safety guards exist; grouped read API pending | `SN-R80` |
| CLI listing/export details | present in `cat-numbers` | partial parity via `list-*`/`read-*` | `SN-R82` |
| CLI CSV transform pipeline | present in `csv2numbers` | baseline import/export only | `SN-R83` |
| CLI unpack/debug inspection | present in `unpack-numbers` | no equivalent command | `SN-R84` |
| Continuous code-parity scoring | not a built-in numbers-parser feature | needed for autonomous queueing | `SN-R70`, `SN-R85` |

## Notes for Planning

- This map is a capability inventory, not a quality verdict.
- `SwiftNumbers` should preserve existing reliability strengths while adding parity APIs:
  - deterministic formula writes
  - explicit grouped/pivot safety guards
- Each conveyor task must ship with save/reopen regression tests for package and single-file `.numbers` forms.
