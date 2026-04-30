| Probe | AppleScript status | Evidence | SwiftNumbers parity target |
|---|---|---|---|
| formula-text-read | skipped | <not-probed> | `TableModel.formula(...)`, `TableModel.formulas()`, `swiftnumbers list-formulas` |
| formula-result-read | skipped | <not-probed> | `TableModel.formulaResult(...)`, `NumbersDocument.readCell(...)` formula result payloads |
| formula-range-reference-read | skipped | <not-probed> | formula AST/range-reference rendering and `--formulas` parity output |
| formula-function-call-read | skipped | <not-probed> | formula AST function-call rendering with deterministic fallback summaries |
| formula-set-operation | skipped | <not-probed> | `EditableTable.setValue(.formula(...))` with strict unsafe-reference guards |
| formula-clear-operation | skipped | <not-probed> | formula clear/write parity; native range clear remains a safe-write backlog gap |
