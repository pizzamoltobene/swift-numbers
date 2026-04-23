# Operations Index

One operation per page for fast, focused reading.

[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md)

## Read Operations

- [5.1 `NumbersDocument.open(at:)`](01-numbersdocument-open.md)
- [5.2 `NumbersDocument.sheets`](02-numbersdocument-sheets.md)
- [5.3 `Sheet.tables`](03-sheet-tables.md)
- [5.4 `Table.metadata`](04-table-metadata.md)
- [5.5 `Table.cell(at:)`](05-table-cell-at.md)
- [5.6 `NumbersDocument.dump()` and `renderDump()`](06-numbersdocument-dump-renderdump.md)

## Editable Open/Navigation

- [5.7 `EditableNumbersDocument.open(at:)`](07-editable-open.md)
- [5.8 `sheet(named:)` / `table(named:)`](08-sheet-named-table-named.md)
- [5.9 `cell(_ reference:)` / `EditableCell.value`](09-cell-reference-editablecell-value.md)

## Editable Mutations

- [5.10 `setValue(_:at:)`](10-setvalue.md)
- [5.11 `appendRow(_:)`](11-appendrow.md)
- [5.12 `insertRow(_:at:)`](12-insertrow.md)
- [5.13 `appendColumn(_:)`](13-appendcolumn.md)
- [5.14 `addTable(named:rows:columns:onSheetNamed:)`](14-addtable.md)
- [5.15 `addSheet(named:)`](15-addsheet.md)

## Save Operations

- [5.16 `save(to:)`](16-save-to.md)
- [5.17 `saveInPlace()`](17-saveinplace.md)

## CLI Operations

- [5.18 `swiftnumbers list-sheets`](18-cli-list-sheets.md)
- [5.19 `swiftnumbers dump`](19-cli-dump.md)

## Runtime State & Helpers

- [5.20 `EditableNumbersDocument.canSaveEditableDocuments()`](20-can-save-editable-documents.md)
- [5.21 `EditableNumbersDocument` state properties](21-editable-state-properties.md)
- [5.22 `EditableSheet.tables` and `EditableSheet.firstTable`](22-editablesheet-tables-firsttable.md)
- [5.23 `EditableTable.metadata` and `EditableTable.populatedCellCount`](23-editabletable-metadata-populatedcount.md)
- [5.24 `Table.allCells` and `Table.populatedCellCount` (read model)](24-table-allcells-populatedcount.md)
- [5.25 `CellReference` + `cell(at reference: CellReference)`](25-cellreference-typed.md)
