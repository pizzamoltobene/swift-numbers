| Probe | AppleScript status | Evidence | SwiftNumbers parity target |
|---|---|---|---|
| document-export-operation | skipped | <not-probed> | safe export is CLI-level (`export-csv`); native document export remains a roadmap gap |
| sheet-create-delete-operation | skipped | <not-probed> | `EditableNumbersDocument.addSheet`; sheet delete/rename parity remains a backlog gap |
| table-create-delete-operation | skipped | <not-probed> | `EditableSheet.addTable`; table delete/duplicate parity remains a backlog gap |
| row-mutation-operation | skipped | <not-probed> | `appendRow`, `insertRow`, `deleteRow` with grouped/pivot-linked safety guards |
| column-mutation-operation | skipped | <not-probed> | `appendColumn`, `deleteColumn`; insert-column parity remains a backlog gap |
| cell-range-clear-set-operation | skipped | <not-probed> | `setValue`, `clearValue`, `clearValues`; range fill parity remains a safe-write backlog gap |
| table-structure-transform-operation | skipped | <not-probed> | `mergeCells`, `unmergeCells`; sort/transpose parity remains a backlog gap |
