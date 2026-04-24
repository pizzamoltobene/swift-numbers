# API Reference

Exact public API reference for `SwiftNumbersCore` in `v0.3.1`.

## Import

```swift
import SwiftNumbersCore
```

## Public Enums

### `NumbersDocumentError: LocalizedError`

| Case | Description |
|---|---|
| `metadataMissing` | Document metadata missing (`Metadata/DocumentMetadata.pb` or `.json`) |
| `encryptedDocumentUnsupported` | Input document appears encrypted (`.iwpv2` / `.iwph`) |

### `DocumentReadPath: String, Sendable`

| Case | Description |
|---|---|
| `real` | Real IWA read pipeline |
| `metadataFallback` | Metadata fallback path |

### `EditableNumbersError: LocalizedError`

| Case | Payload |
|---|---|
| `sheetNotFound` | `String` |
| `tableNotFound` | `sheet: String, table: String` |
| `duplicateTableName` | `sheet: String, table: String` |
| `invalidCellReference` | `String` |
| `invalidRowIndex` | `Int` |
| `invalidColumnIndex` | `Int` |
| `nativeWriteFailed` | `String` |

### `DocumentDirtyState: String, Sendable`

| Case | Meaning |
|---|---|
| `clean` | No pending changes |
| `dataDirty` | Value-level changes |
| `structureDirty` | Structural table/sheet changes |

## Public Structs

### `CellAddress`

```swift
public struct CellAddress: Hashable, Sendable {
  public let row: Int
  public let column: Int
  public init(row: Int, column: Int)
}
```

### `CellValue`

```swift
public enum CellValue: Sendable, Hashable {
  case empty
  case string(String)
  case number(Double)
  case bool(Bool)
  case date(Date)
}
```

### `MergeRange`

```swift
public struct MergeRange: Hashable, Sendable {
  public let startRow: Int
  public let endRow: Int
  public let startColumn: Int
  public let endColumn: Int
  public init(startRow: Int, endRow: Int, startColumn: Int, endColumn: Int)
}
```

### `TableMetadata`

```swift
public struct TableMetadata: Hashable, Sendable {
  public let rowCount: Int
  public let columnCount: Int
  public let mergeRanges: [MergeRange]
  public init(rowCount: Int, columnCount: Int, mergeRanges: [MergeRange])
}
```

### `Table`

```swift
public struct Table: Hashable, Sendable {
  public let id: String
  public let name: String
  public let metadata: TableMetadata
  public init(id: String, name: String, metadata: TableMetadata, cells: [CellAddress: CellValue] = [:])
  public func cell(at address: CellAddress) -> CellValue?
  public func cell(row: Int, column: Int) -> CellValue?
  public func cell(_ reference: String) -> CellValue?
  public func readCell(at address: CellAddress) -> ReadCell?
  public func readCell(_ reference: String) -> ReadCell?
  public func readValue(at address: CellAddress) -> ReadCellValue?
  public func readValue(_ reference: String) -> ReadCellValue?
  public func formula(at address: CellAddress) -> FormulaRead?
  public func formula(_ reference: String) -> FormulaRead?
  public func formulas() -> [FormulaRead]
  public func formulaResult(at address: CellAddress) -> FormulaResultRead?
  public func formulaResult(_ reference: String) -> FormulaResultRead?
  public var rowCount: Int { get }
  public var columnCount: Int { get }
  public var usedRange: CellRange? { get }
  public func populatedCells(sorted: Bool = true) -> [ReadCell]
  public func rows() -> [[CellValue]]
  public func rows(valuesOnly: Bool = true) -> [[CellValue]]
  public func rows(lazy: Bool) -> AnySequence<[CellValue]>
  public func readRows() -> [[ReadCell]]
  public func readRows(lazy: Bool) -> AnySequence<[ReadCell]>
  public func readValues() -> [[ReadCellValue]]
  public func readValues(lazy: Bool) -> AnySequence<[ReadCellValue]>
  public func column(named name: String, headerRow: Int = 0, includeHeader: Bool = false) throws -> [CellValue]
  public func column(at index: Int, from startRow: Int = 0) throws -> [CellValue]
  public func readColumn(at index: Int, from startRow: Int = 0) throws -> [ReadCell]
  public func values(in rangeReference: String) throws -> [[CellValue]]
  public func readCells(in rangeReference: String) throws -> [[ReadCell]]
  public func value<T>(_ type: T.Type, at address: CellAddress) throws -> T
  public func value<T>(_ type: T.Type, at reference: String) throws -> T
  public func optionalValue<T>(_ type: T.Type, at address: CellAddress) throws -> T?
  public func optionalValue<T>(_ type: T.Type, at reference: String) throws -> T?
  public func decodeRows<Row: Decodable>(as type: Row.Type, headerRow: Int = 0, decoder: JSONDecoder = JSONDecoder()) throws -> [Row]
  public func formattedValue(at address: CellAddress) -> String?
  public func formattedValue(at address: CellAddress, options: ReadFormattingOptions = .default) -> String?
  public func formattedValue(_ reference: String) -> String?
  public func formattedValue(_ reference: String, options: ReadFormattingOptions = .default) -> String?
  public func mergeRange(containing address: CellAddress) -> MergeRange?
  public func mergeRange(containing reference: String) -> MergeRange?
  public func isMergedCell(at address: CellAddress) -> Bool
  public func isMergedCell(_ reference: String) -> Bool
  public var allCells: [CellAddress: CellValue] { get }
  public var populatedCellCount: Int { get }
}
```

### `Sheet`

```swift
public struct Sheet: Hashable, Sendable {
  public let id: String
  public let name: String
  public let tables: [Table]
  public init(id: String, name: String, tables: [Table])
  public var firstTable: Table? { get }
  public var tableNames: [String] { get }
  public subscript(_ index: Int) -> Table? { get }
  public subscript(_ name: String) -> Table? { get }
  public func table(named name: String) -> Table?
  public func table(at index: Int) -> Table?
}
```

### `DocumentDump`

```swift
public struct DocumentDump: Sendable {
  public let readPath: DocumentReadPath
  public let sourcePath: String
  public let documentVersion: String?
  public let blobCount: Int
  public let objectCount: Int
  public let objectReferenceEdgeCount: Int
  public let rootObjectCount: Int
  public let resolvedCellCount: Int
  public let fallbackReason: String?
  public let typeHistogram: [UInt32: Int]
  public let unparsedBlobPaths: [String]
  public let diagnostics: [String]
  public let structuredDiagnostics: [ReadDiagnostic]
}
```

### `CellRange`

```swift
public struct CellRange: Hashable, Sendable {
  public let start: CellAddress
  public let end: CellAddress
  public init(start: CellAddress, end: CellAddress)
  public var rowCount: Int { get }
  public var columnCount: Int { get }
  public var a1: String { get }
  public func contains(_ address: CellAddress) -> Bool
}
```

### `CellReference`

```swift
public struct CellReference: Hashable, Sendable, CustomStringConvertible {
  public let address: CellAddress
  public let a1: String
  public var description: String { get }
  public init(_ rawValue: String) throws
  public init(address: CellAddress)
}
```

### `ReadCell`

```swift
public struct ReadCell: Hashable, Sendable {
  public let address: CellAddress
  public let value: CellValue
  public let kind: ReadCellKind
  public let readValue: ReadCellValue
  public let formulaResult: FormulaResultRead?
  public let formatted: String
  public let richText: RichTextRead?
  public let style: ReadCellStyle?
  public let rawCellType: UInt8?
  public let stringID: Int32?
  public let richTextID: Int32?
  public let formulaID: Int32?
  public let formulaErrorID: Int32?
  public let mergeRange: MergeRange?
  public let mergeRole: MergeRole
  public var isMerged: Bool { get }
}
```

### `ReadDiagnosticSeverity`

```swift
public enum ReadDiagnosticSeverity: String, Sendable {
  case info
  case warning
  case error
}
```

### `ReadDiagnostic`

```swift
public struct ReadDiagnostic: Hashable, Sendable {
  public let code: String
  public let severity: ReadDiagnosticSeverity
  public let message: String
  public let objectPath: String?
  public let suggestion: String?
  public let context: [String: String]
  public var rendered: String { get }
}
```

### `FormulaRead`

```swift
public struct FormulaRead: Hashable, Sendable {
  public let address: CellAddress
  public let reference: String
  public let formulaID: Int32?
  public let rawFormula: String?
  public let parsedTokens: [String]
  public let astSummary: String?
  public let result: CellValue
  public let resultFormatted: String
}
```

### `FormulaResultRead`

```swift
public struct FormulaResultRead: Hashable, Sendable {
  public let formulaID: Int32?
  public let rawFormula: String?
  public let parsedTokens: [String]
  public let astSummary: String?
  public let computedValue: CellValue
  public let computedFormatted: String
}
```

### `ReadCellValue`

```swift
public enum ReadCellValue: Hashable, Sendable {
  case empty
  case string(String)
  case number(Double)
  case bool(Bool)
  case date(Date)
  case duration(TimeInterval)
  case error(String)
  case richText(RichTextRead)
  case formulaResult(FormulaResultRead)
}
```

### `ReadCellKind`

```swift
public enum ReadCellKind: Hashable, Sendable {
  case empty
  case text
  case number
  case bool
  case date
  case duration
  case formula
  case formulaError
  case richText
  case unknown(UInt8)
}
```

### `ReadFormattingOptions`

```swift
public struct ReadFormattingOptions: Hashable, Sendable {
  public init(
    localeIdentifier: String = "en_US_POSIX",
    timeZoneIdentifier: String? = nil,
    usesGroupingSeparator: Bool = false,
    minimumFractionDigits: Int = 0,
    maximumFractionDigits: Int = 15,
    includeFractionalSeconds: Bool = true,
    numberFormatMode: ReadNumberFormatMode = .decimal,
    dateFormatMode: ReadDateFormatMode = .iso8601,
    durationFormatMode: ReadDurationFormatMode = .seconds,
    preferCellNumberFormatHints: Bool = true
  )
  public static let `default`: ReadFormattingOptions
}
```

### `ReadNumberFormatMode`

```swift
public enum ReadNumberFormatMode: Hashable, Sendable {
  case decimal
  case currency(code: String?)
  case percent
  case scientific
  case pattern(String)
}
```

### `ReadDateTimeStyle`

```swift
public enum ReadDateTimeStyle: String, Hashable, Sendable {
  case none
  case short
  case medium
  case long
  case full
}
```

### `ReadDateFormatMode`

```swift
public enum ReadDateFormatMode: Hashable, Sendable {
  case iso8601
  case styled(date: ReadDateTimeStyle, time: ReadDateTimeStyle)
  case pattern(String)
}
```

### `ReadDurationFormatMode`

```swift
public enum ReadDurationFormatMode: String, Hashable, Sendable {
  case seconds
  case hhmmss
  case abbreviated
}
```

### `TableReadError: LocalizedError`

```swift
public enum TableReadError: LocalizedError {
  case invalidCellReference(String)
  case invalidRangeReference(String)
  case outOfBounds(CellAddress)
  case missingValue(CellAddress)
  case typeMismatch(expected: String, actual: CellValue)
  case headerNotFound(String)
  case decodingFailed(String)
}
```

## Public Read API

### `NumbersDocument`

```swift
public struct NumbersDocument: Sendable {
  public let sourceURL: URL
  public let sheets: [Sheet]

  public static func open(at url: URL) throws -> NumbersDocument
  public var firstSheet: Sheet? { get }
  public var sheetNames: [String] { get }
  public var tableCount: Int { get }
  public var tableNames: [String] { get }
  public subscript(_ index: Int) -> Sheet? { get }
  public subscript(_ name: String) -> Sheet? { get }
  public func sheet(named name: String) -> Sheet?
  public func sheet(at index: Int) -> Sheet?
  public func dump() -> DocumentDump
  public func renderDump() -> String
}
```

## Public Editable API

### `EditableNumbersDocument`

```swift
public final class EditableNumbersDocument {
  public let sourceURL: URL
  public private(set) var sheets: [EditableSheet]
  public private(set) var dirtyState: DocumentDirtyState

  public var hasChanges: Bool { get }
  public var firstSheet: EditableSheet? { get }

  public static func open(at url: URL) throws -> EditableNumbersDocument
  public static func canSaveEditableDocuments() -> Bool

  public func sheet(named name: String) throws -> EditableSheet
  @discardableResult
  public func addSheet(named name: String) -> EditableSheet

  @discardableResult
  public func addTable(
    named name: String,
    rows: Int,
    columns: Int,
    onSheetNamed sheetName: String
  ) throws -> EditableTable

  public func save(to outputURL: URL) throws
  public func saveInPlace() throws
}
```

### `EditableSheet`

```swift
public final class EditableSheet {
  public let id: String
  public let name: String
  public private(set) var tables: [EditableTable]
  public private(set) var isDirty: Bool

  public var firstTable: EditableTable? { get }

  public func table(named name: String) throws -> EditableTable

  @discardableResult
  public func addTable(named name: String, rows: Int, columns: Int) throws -> EditableTable
}
```

### `EditableTable`

```swift
public final class EditableTable {
  public let id: String
  public let name: String
  public private(set) var isDirty: Bool
  public private(set) var isStructureDirty: Bool

  public var metadata: TableMetadata { get }
  public var populatedCellCount: Int { get }

  public func cell(at address: CellAddress) -> CellValue?
  public func cell(_ reference: String) throws -> EditableCell
  public func cell(at reference: CellReference) -> EditableCell

  public func setValue(_ value: CellValue, at address: CellAddress)
  public func setValue(_ value: CellValue, at reference: String) throws

  public func appendRow(_ values: [CellValue])
  public func insertRow(_ values: [CellValue], at rowIndex: Int) throws
  public func appendColumn(_ values: [CellValue])
}
```

### `EditableCell`

```swift
public final class EditableCell {
  public let address: CellAddress
  public var value: CellValue? { get set }
}
```

## Behavior Notes

- `CellAddress` is zero-based.
- `CellReference` uses A1 notation.
- `setValue(..., at: CellAddress)` does not throw and ignores negative row/column indices.
- `setValue(..., at: String)` throws for invalid A1.
- `addSheet(named:)` auto-suffixes duplicate names (`Name`, `Name (2)`, ...).
- `EditableSheet.addTable(named:...)` throws `duplicateTableName` for duplicates in the same sheet.
- `save(to:)` writes to the given destination and updates the document working path to that destination.
- `saveInPlace()` performs atomic in-place replace on the current working path.

## Related docs

- [Capabilities](capabilities.md)
- [Cookbook](cookbook.md)
- [Troubleshooting](troubleshooting.md)
