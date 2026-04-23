#!/bin/zsh
set -euo pipefail

# Regenerates docs/operations/*.md from section 5.x cards in docs/capabilities.md
# Usage:
#   ./scripts/generate_operation_docs.sh

cap="docs/capabilities.md"
ops_dir="docs/operations"

if [[ ! -f "$cap" ]]; then
  echo "Missing $cap" >&2
  exit 1
fi

mkdir -p "$ops_dir"

starts=("${(@f)$(rg -n '^### 5\.' "$cap" | cut -d: -f1)}")
heads=("${(@f)$(rg '^### 5\.' "$cap")}")
section6_start=$(rg -n '^## 6\)' "$cap" | cut -d: -f1)

if (( ${#starts[@]} == 0 )); then
  echo "No operation sections found in $cap" >&2
  exit 1
fi

slug_for_num() {
  local n="$1"
  case "$n" in
    1) print -r -- "numbersdocument-open" ;;
    2) print -r -- "numbersdocument-sheets" ;;
    3) print -r -- "sheet-tables" ;;
    4) print -r -- "table-metadata" ;;
    5) print -r -- "table-cell-at" ;;
    6) print -r -- "numbersdocument-dump-renderdump" ;;
    7) print -r -- "editable-open" ;;
    8) print -r -- "sheet-named-table-named" ;;
    9) print -r -- "cell-reference-editablecell-value" ;;
    10) print -r -- "setvalue" ;;
    11) print -r -- "appendrow" ;;
    12) print -r -- "insertrow" ;;
    13) print -r -- "appendcolumn" ;;
    14) print -r -- "addtable" ;;
    15) print -r -- "addsheet" ;;
    16) print -r -- "save-to" ;;
    17) print -r -- "saveinplace" ;;
    18) print -r -- "cli-list-sheets" ;;
    19) print -r -- "cli-dump" ;;
    20) print -r -- "can-save-editable-documents" ;;
    21) print -r -- "editable-state-properties" ;;
    22) print -r -- "editablesheet-tables-firsttable" ;;
    23) print -r -- "editabletable-metadata-populatedcount" ;;
    24) print -r -- "table-allcells-populatedcount" ;;
    25) print -r -- "cellreference-typed" ;;
    *) print -r -- "op-$n" ;;
  esac
}

for ((i=1; i<=${#starts[@]}; i++)); do
  start_line=${starts[$i]}
  if (( i < ${#starts[@]} )); then
    end_line=$(( starts[$((i+1))] - 1 ))
  else
    end_line=$(( section6_start - 1 ))
  fi

  heading=${heads[$i]}
  op_num=$(echo "$heading" | sed -E 's/^### 5\.([0-9]+).*/\1/')
  slug=$(slug_for_num "$op_num")
  file=$(printf "%s/%02d-%s.md" "$ops_dir" "$op_num" "$slug")

  {
    echo "# Operation 5.$op_num"
    echo
    echo "[Back to Docs Hub](../index.md) | [Back to Capabilities](../capabilities.md) | [Operations Index](README.md)"
    echo
    sed -n "${start_line},${end_line}p" "$cap"
    echo
    echo "---"
    echo
    echo "## Additional Notes"
    echo
    echo "- This page is generated from the canonical operation section in [Capabilities](../capabilities.md)."
    echo "- If API behavior changes, update the source operation card and regenerate operation pages."
  } > "$file"
done

cat > "$ops_dir/README.md" <<'OPS'
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
OPS

echo "Generated ${#starts[@]} operation pages in $ops_dir"
