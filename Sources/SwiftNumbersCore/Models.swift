import Foundation

public struct CellAddress: Hashable, Sendable {
  public let row: Int
  public let column: Int

  public init(row: Int, column: Int) {
    self.row = row
    self.column = column
  }
}

public enum CellValue: Sendable, Hashable {
  case empty
  case string(String)
  case number(Double)
  case bool(Bool)
}

public struct MergeRange: Hashable, Sendable {
  public let startRow: Int
  public let endRow: Int
  public let startColumn: Int
  public let endColumn: Int

  public init(startRow: Int, endRow: Int, startColumn: Int, endColumn: Int) {
    self.startRow = startRow
    self.endRow = endRow
    self.startColumn = startColumn
    self.endColumn = endColumn
  }
}

public struct TableMetadata: Hashable, Sendable {
  public let rowCount: Int
  public let columnCount: Int
  public let mergeRanges: [MergeRange]

  public init(rowCount: Int, columnCount: Int, mergeRanges: [MergeRange]) {
    self.rowCount = rowCount
    self.columnCount = columnCount
    self.mergeRanges = mergeRanges
  }
}

public struct Table: Hashable, Sendable {
  public let id: String
  public let name: String
  public let metadata: TableMetadata
  private let cells: [CellAddress: CellValue]

  public init(
    id: String, name: String, metadata: TableMetadata, cells: [CellAddress: CellValue] = [:]
  ) {
    self.id = id
    self.name = name
    self.metadata = metadata
    self.cells = cells
  }

  public func cell(at address: CellAddress) -> CellValue? {
    cells[address]
  }

  public var populatedCellCount: Int {
    cells.count
  }
}

public struct Sheet: Hashable, Sendable {
  public let id: String
  public let name: String
  public let tables: [Table]

  public init(id: String, name: String, tables: [Table]) {
    self.id = id
    self.name = name
    self.tables = tables
  }
}

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

  public init(
    readPath: DocumentReadPath = .real,
    sourcePath: String,
    documentVersion: String? = nil,
    blobCount: Int,
    objectCount: Int,
    objectReferenceEdgeCount: Int,
    rootObjectCount: Int,
    resolvedCellCount: Int = 0,
    fallbackReason: String? = nil,
    typeHistogram: [UInt32: Int],
    unparsedBlobPaths: [String],
    diagnostics: [String] = []
  ) {
    self.readPath = readPath
    self.sourcePath = sourcePath
    self.documentVersion = documentVersion
    self.blobCount = blobCount
    self.objectCount = objectCount
    self.objectReferenceEdgeCount = objectReferenceEdgeCount
    self.rootObjectCount = rootObjectCount
    self.resolvedCellCount = resolvedCellCount
    self.fallbackReason = fallbackReason
    self.typeHistogram = typeHistogram
    self.unparsedBlobPaths = unparsedBlobPaths
    self.diagnostics = diagnostics
  }
}

public enum DocumentReadPath: String, Sendable {
  case real
  case metadataFallback
}
