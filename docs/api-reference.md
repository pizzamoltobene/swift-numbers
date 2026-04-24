# API Reference

Exact public API reference for `SwiftNumbersCore` in `v0.2.2.1`.

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

## Public Read API

### `NumbersDocument`

```swift
public struct NumbersDocument: Sendable {
  public let sourceURL: URL
  public let sheets: [Sheet]

  public static func open(at url: URL) throws -> NumbersDocument
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
