# API Reference

Exact public API reference for `SwiftNumbersCore` in the current release line.

## Import

```swift
import SwiftNumbersCore
```

## Public Enums

### `NumbersDocumentError: LocalizedError`

| Case | Description |
|---|---|
| `realReadFailed` | `String` details from the Swift-native real-read path |
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
| `duplicateStyleName` | `String` |
| `styleNotFound` | `String` |
| `duplicateCustomFormatName` | `String` |
| `customFormatNotFound` | `String` |
| `invalidCellReference` | `String` |
| `invalidRangeReference` | `String` |
| `invalidRowIndex` | `Int` |
| `invalidColumnIndex` | `Int` |
| `invalidHeaderRowCount` | `Int` |
| `invalidHeaderColumnCount` | `Int` |
| `groupedTableMutationUnsupported` | `sheet: String, table: String, operation: String` |
| `pivotLinkedTableMutationUnsupported` | `sheet: String, table: String, operation: String, linkedObjectIDs: [UInt64]` |
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
  case formula(String)
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
public struct TableObjectIdentifiers: Hashable, Sendable {
  public let tableInfoObjectID: UInt64?
  public let tableModelObjectID: UInt64?
  public init(tableInfoObjectID: UInt64? = nil, tableModelObjectID: UInt64? = nil)
}

public struct PivotLinkMetadata: Hashable, Sendable {
  public let drawableObjectID: UInt64
  public let drawableTypeIDs: [UInt32]
  public let linkedTableInfoObjectIDs: [UInt64]
  public let linkedTableModelObjectIDs: [UInt64]
  public init(
    drawableObjectID: UInt64,
    drawableTypeIDs: [UInt32],
    linkedTableInfoObjectIDs: [UInt64],
    linkedTableModelObjectIDs: [UInt64]
  )
}

public struct TableCellGeometry: Hashable, Sendable {
  public let originX: Double
  public let originY: Double
  public let width: Double
  public let height: Double
  public init(originX: Double, originY: Double, width: Double, height: Double)
}

public struct TableMetadata: Hashable, Sendable {
  public let rowCount: Int
  public let columnCount: Int
  public let headerRowCount: Int
  public let headerColumnCount: Int
  public let rowHeights: [Double?]
  public let columnWidths: [Double?]
  public let mergeRanges: [MergeRange]
  public let tableNameVisible: Bool?
  public let captionVisible: Bool?
  public let captionText: String?
  public let captionTextSupported: Bool
  public let objectIdentifiers: TableObjectIdentifiers?
  public let pivotLinks: [PivotLinkMetadata]
  public init(
    rowCount: Int,
    columnCount: Int,
    headerRowCount: Int = 0,
    headerColumnCount: Int = 0,
    rowHeights: [Double?] = [],
    columnWidths: [Double?] = [],
    mergeRanges: [MergeRange],
    tableNameVisible: Bool? = nil,
    captionVisible: Bool? = nil,
    captionText: String? = nil,
    captionTextSupported: Bool = false,
    objectIdentifiers: TableObjectIdentifiers? = nil,
    pivotLinks: [PivotLinkMetadata] = []
  )
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
  public func richText(at address: CellAddress) -> RichTextRead?
  public func richText(_ reference: String) -> RichTextRead?
  public func style(at address: CellAddress) -> ReadCellStyle?
  public func style(_ reference: String) -> ReadCellStyle?
  public func formulas() -> [FormulaRead]
  public func formulaResult(at address: CellAddress) -> FormulaResultRead?
  public func formulaResult(_ reference: String) -> FormulaResultRead?
  public var rowCount: Int { get }
  public var columnCount: Int { get }
  public func rowHeight(at rowIndex: Int) -> Double?
  public func columnWidth(at columnIndex: Int) -> Double?
  public func cellGeometry(
    at address: CellAddress,
    defaultRowHeight: Double = 20,
    defaultColumnWidth: Double = 100
  ) -> TableCellGeometry?
  public func cellGeometry(
    _ reference: String,
    defaultRowHeight: Double = 20,
    defaultColumnWidth: Double = 100
  ) -> TableCellGeometry?
  public var usedRange: CellRange? { get }
  public func populatedCells(sorted: Bool = true) -> [ReadCell]
  public func rows() -> [[CellValue]]
  public func rows(valuesOnly: Bool = true) -> [[CellValue]]
  public func rows(lazy: Bool) -> AnySequence<[CellValue]>
  public func readRows() -> [[ReadCell]]
  public func readRows(lazy: Bool) -> AnySequence<[ReadCell]>
  public func readValues() -> [[ReadCellValue]]
  public func readValues(lazy: Bool) -> AnySequence<[ReadCellValue]>
  public func categorizedRows(
    by categoryColumns: [Int],
    headerRow: Int = 0,
    includeHeader: Bool = false
  ) throws -> [CategorizedReadRowGroup]
  public func categorizedValues(
    by categoryColumns: [Int],
    headerRow: Int = 0,
    includeHeader: Bool = false
  ) throws -> [CategorizedValueRowGroup]
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
  case fraction(maxDenominator: Int)
  case base(radix: Int, uppercase: Bool)
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

  @discardableResult
  public func registerStyle(named name: String, style: ReadCellStyle) throws -> String
  public func registeredStyles() -> [RegisteredDocumentStyle]
  public func registeredStyle(id styleID: String) -> RegisteredDocumentStyle?

  @discardableResult
  public func registerCustomFormat(named name: String, formatID: Int32) throws -> String
  public func registeredCustomFormats() -> [RegisteredDocumentCustomFormat]
  public func registeredCustomFormat(id customFormatID: String) -> RegisteredDocumentCustomFormat?

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

### `RegisteredDocumentStyle`

```swift
public struct RegisteredDocumentStyle: Hashable, Sendable {
  public let id: String
  public let name: String
  public let style: ReadCellStyle
}
```

### `RegisteredDocumentCustomFormat`

```swift
public struct RegisteredDocumentCustomFormat: Hashable, Sendable {
  public let id: String
  public let name: String
  public let formatID: Int32
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
  public func style(at address: CellAddress) -> ReadCellStyle?
  public func format(at address: CellAddress) -> EditableCellFormat?
  public func cell(_ reference: String) throws -> EditableCell
  public func cell(at reference: CellReference) -> EditableCell
  public var isTableNameVisible: Bool? { get }
  public var isCaptionVisible: Bool? { get }
  public var tableCaptionText: String? { get }
  public func rowHeight(at rowIndex: Int) -> Double?
  public func columnWidth(at columnIndex: Int) -> Double?
  public func setHeaderRowCount(_ count: Int) throws
  public func setHeaderColumnCount(_ count: Int) throws
  public func setRowHeight(_ height: Double, at rowIndex: Int) throws
  public func setColumnWidth(_ width: Double, at columnIndex: Int) throws

  public func setValue(_ value: CellValue, at address: CellAddress)
  public func setValue(_ value: CellValue, at reference: String) throws
  public func clearValue(at address: CellAddress)
  public func clearValue(at reference: String) throws
  public func clearValues(in range: MergeRange) throws
  public func clearValues(in rangeReference: String) throws
  public func setStyle(_ style: ReadCellStyle?, at address: CellAddress)
  public func setStyle(_ style: ReadCellStyle?, at reference: String) throws
  public func setBorder(_ isVisible: Bool, side: EditableBorderSide, at address: CellAddress)
  public func setBorder(_ isVisible: Bool, side: EditableBorderSide, at reference: String) throws
  public func applyStyle(id styleID: String, at address: CellAddress) throws
  public func applyStyle(id styleID: String, at reference: String) throws
  public func applyCustomFormat(id customFormatID: String, at address: CellAddress) throws
  public func applyCustomFormat(id customFormatID: String, at reference: String) throws
  public func setFormat(_ format: EditableCellFormat?, at address: CellAddress)
  public func setFormat(_ format: EditableCellFormat?, at reference: String) throws
  public func format(_ reference: String) -> EditableCellFormat?
  public func setTableNameVisible(_ isVisible: Bool) throws
  public func setCaptionVisible(_ isVisible: Bool) throws
  public func setCaptionText(_ text: String) throws

  public func appendRow(_ values: [CellValue])
  public func insertRow(_ values: [CellValue], at rowIndex: Int) throws
  public func appendColumn(_ values: [CellValue])
  public func deleteRow(at rowIndex: Int) throws
  public func deleteColumn(at columnIndex: Int) throws
  public func mergeCells(_ rangeReference: String) throws
  public func mergeCells(from start: CellAddress, to end: CellAddress) throws
  public func unmergeCells(_ rangeReference: String) throws
  public func unmergeCells(from start: CellAddress, to end: CellAddress)
}
```

### `EditableCell`

```swift
public final class EditableCell {
  public let address: CellAddress
  public var value: CellValue? { get set }
  public var style: ReadCellStyle? { get set }
  public var format: EditableCellFormat? { get set }
  public func setBorder(_ isVisible: Bool, side: EditableBorderSide)
}
```

### `EditableCellFormat`

```swift
public enum EditableCellFormat: Hashable, Sendable {
  case number(formatID: Int32 = 0)
  case date(formatID: Int32 = 0)
  case currency(formatID: Int32 = 0)
  case base(formatID: Int32 = 16)
  case fraction(formatID: Int32 = 16)
  case percentage(formatID: Int32 = 0)
  case scientific(formatID: Int32 = 0)
  case tickbox(formatID: Int32 = 0)
  case rating(formatID: Int32 = 0)
  case slider(formatID: Int32 = 0)
  case stepper(formatID: Int32 = 0)
  case popup(formatID: Int32 = 0)
  case custom(formatID: Int32)
}
```

### `EditableBorderSide`

```swift
public enum EditableBorderSide: String, CaseIterable, Hashable, Sendable {
  case top
  case right
  case bottom
  case left
}
```

## Behavior Notes

- `CellAddress` is zero-based.
- `CellReference` uses A1 notation.
- `setValue(..., at: CellAddress)` does not throw and ignores negative row/column indices.
- `setValue(..., at: String)` throws for invalid A1.
- `clearValue(at:)` is equivalent to writing `.empty` and uses the same validation rules as
  `setValue`.
- `clearValues(in:)` clears a validated rectangular range and throws `invalidRangeReference`
  when the range is malformed or outside the current table bounds.
- `setStyle(..., at: CellAddress)` does not throw and ignores negative row/column indices.
- `setStyle(..., at: String)` throws for invalid A1.
- `setBorder(..., at: CellAddress)` does not throw and ignores negative row/column indices.
- `setBorder(..., at: String)` throws for invalid A1.
- For merged ranges, `setBorder` deterministically applies the requested side to the full merged edge even when targeting a non-anchor/member cell.
- `registerStyle(named:style:)` throws `duplicateStyleName` when a style with the same normalized name already exists.
- `applyStyle(id:..., at: ...)` throws `styleNotFound` when the style identifier is unknown.
- `registerCustomFormat(named:formatID:)` throws `duplicateCustomFormatName` when a custom format with the same normalized name already exists.
- `applyCustomFormat(id:..., at: ...)` throws `customFormatNotFound` when the format identifier is unknown.
- `setFormat(..., at: CellAddress)` does not throw and ignores negative row/column indices.
- `setFormat(..., at: String)` throws for invalid A1.
- `setTableNameVisible(_:)` and `setCaptionVisible(_:)` throw when source metadata is unavailable for the current table.
- `setCaptionText(_:)` throws when caption storage is unavailable for the current table.
- `setHeaderRowCount(_:)` throws `invalidHeaderRowCount` when count is negative or exceeds current row count.
- `setHeaderColumnCount(_:)` throws `invalidHeaderColumnCount` when count is negative or exceeds current column count.
- Structural mutations on grouped tables throw `groupedTableMutationUnsupported`.
- Structural/data mutations on pivot-linked tables throw `pivotLinkedTableMutationUnsupported`
  with target-scoped linked object identifiers.
- `setRowHeight(_:at:)` throws `invalidRowIndex` for out-of-bounds row and `nativeWriteFailed` for negative/non-finite sizes.
- `setColumnWidth(_:at:)` throws `invalidColumnIndex` for out-of-bounds column and `nativeWriteFailed` for negative/non-finite sizes.
- `deleteRow(at:)` throws `invalidRowIndex` when index is out of bounds and shifts remaining rows deterministically.
- `deleteColumn(at:)` throws `invalidColumnIndex` when index is out of bounds and shifts remaining columns deterministically.
- `mergeCells(...)` / `unmergeCells(...)` throw for invalid range references and preserve deterministic sorted merge metadata.
- `unmergeCells(...)` removes only exact merged-range matches; partially overlapping ranges are left unchanged.
- `addSheet(named:)` auto-suffixes duplicate names (`Name`, `Name (2)`, ...).
- `EditableSheet.addTable(named:...)` throws `duplicateTableName` for duplicates in the same sheet.
- `save(to:)` writes to the given destination and updates the document working path to that destination.
- `saveInPlace()` performs atomic in-place replace on the current working path.

## Related docs

- [Capabilities](capabilities.md)
- [Cookbook](cookbook.md)
- [Troubleshooting](troubleshooting.md)
