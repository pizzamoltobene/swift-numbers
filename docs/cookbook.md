# Cookbook

Practical, copy-paste workflows for `SwiftNumbers v0.2.2.1`.

All examples use `SwiftNumbersCore`.

## 1) Open a document and print sheet names

```swift
import Foundation
import SwiftNumbersCore

let url = URL(fileURLWithPath: "/absolute/path/to/file.numbers")
let doc = try NumbersDocument.open(at: url)
for sheet in doc.sheets {
  print(sheet.name)
}
```

## 2) Print all tables with size and populated cell count

```swift
for sheet in doc.sheets {
  for table in sheet.tables {
    let meta = table.metadata
    print("\(sheet.name) / \(table.name): rows=\(meta.rowCount), cols=\(meta.columnCount), populated=\(table.populatedCellCount)")
  }
}
```

## 3) Read a value by zero-based address

```swift
if let firstSheet = doc.sheets.first,
   let firstTable = firstSheet.tables.first {
  let value = firstTable.cell(at: CellAddress(row: 1, column: 1))
  print(value as Any)
}
```

## 4) Read dump diagnostics for observability

```swift
let dump = doc.dump()
print("readPath=\(dump.readPath.rawValue)")
print("resolvedCellCount=\(dump.resolvedCellCount)")
for line in dump.diagnostics {
  print(line)
}
```

## 5) Open editable document and check state

```swift
let editable = try EditableNumbersDocument.open(at: url)
print(editable.hasChanges)          // false
print(editable.dirtyState.rawValue) // clean
```

## 6) Update a single cell by A1

```swift
let sheet = try editable.sheet(named: "Sales")
let table = try sheet.table(named: "Q1")
try table.setValue(.string("Done"), at: "C4")
```

## 7) Update a single cell by row/column

```swift
table.setValue(.number(1499.99), at: CellAddress(row: 3, column: 3))
```

## 8) Use typed A1 reference for repeated operations

```swift
let ref = try CellReference("B10")
let cell = table.cell(at: ref)
cell.value = .bool(true)
```

## 9) Append a row

```swift
table.appendRow([
  .string("Alice"),
  .number(42),
  .bool(true),
  .date(Date())
])
```

## 10) Insert a row at specific index

```swift
try table.insertRow([
  .string("Header"),
  .string("Value")
], at: 0)
```

## 11) Append a column

```swift
table.appendColumn([
  .string("Status"),
  .string("Pass"),
  .string("Pass")
])
```

## 12) Create a new sheet

```swift
let archive = editable.addSheet(named: "Archive")
let seed = try archive.table(named: "Table 1")
try seed.setValue(.string("Seed"), at: "A1")
```

## 13) Create a new table on an existing sheet

```swift
let forecast = try editable.addTable(
  named: "Forecast",
  rows: 10,
  columns: 5,
  onSheetNamed: "Sales"
)
forecast.setValue(.string("Q2"), at: CellAddress(row: 0, column: 0))
```

## 14) Save to a new destination

```swift
let output = URL(fileURLWithPath: "/absolute/path/to/output.numbers")
try editable.save(to: output)
```

## 15) Save in place (atomic replace)

```swift
try editable.saveInPlace()
```

## 16) Handle expected lookup errors

```swift
do {
  _ = try editable.sheet(named: "Missing")
} catch let error as EditableNumbersError {
  print(error.localizedDescription)
}
```

## 17) Bulk updates with explicit mapping

```swift
let updates: [(String, CellValue)] = [
  ("A2", .string("North")),
  ("B2", .number(1000)),
  ("C2", .bool(true)),
  ("D2", .date(Date()))
]

for (ref, value) in updates {
  try table.setValue(value, at: ref)
}
```

## 18) Read-only fallback-safe extraction

```swift
let readDoc = try NumbersDocument.open(at: url)
for sheet in readDoc.sheets {
  for table in sheet.tables {
    let all = table.allCells
    // safe sparse traversal
    for (address, value) in all {
      print(sheet.name, table.name, address.row, address.column, value)
    }
  }
}
```

## 19) CLI quick checks from shell

```bash
swift run swiftnumbers list-sheets /absolute/path/file.numbers
swift run swiftnumbers list-sheets /absolute/path/file.numbers --format json
swift run swiftnumbers dump /absolute/path/file.numbers
swift run swiftnumbers dump /absolute/path/file.numbers --format json
```

## 20) End-to-end flow (Open → Edit → Save)

```swift
import Foundation
import SwiftNumbersCore

let inputURL = URL(fileURLWithPath: "/absolute/path/in.numbers")
let outputURL = URL(fileURLWithPath: "/absolute/path/out.numbers")

let doc = try EditableNumbersDocument.open(at: inputURL)
let sales = try doc.sheet(named: "Sales")
let q1 = try sales.table(named: "Q1")

try q1.setValue(.string("Done"), at: "C4")
q1.appendRow([.string("Carol"), .number(10), .bool(true)])

try doc.save(to: outputURL)
```

## Notes

- `CellAddress` is zero-based.
- `CellReference` uses A1 notation.
- `save(to:)` to the same path uses atomic replace semantics.
- `saveInPlace()` operates on the current working document path.
- `addSheet(named:)` auto-suffixes duplicate names.
- `addTable(...)` rejects duplicate table names in the same sheet.
- `.date(Date)` is preserved using a stable SwiftNumbers marker in current write path.
