import Foundation
import SwiftNumbersContainer
import SwiftNumbersIWA
import SwiftNumbersProto

public enum NumbersDocumentError: LocalizedError {
  case metadataMissing

  public var errorDescription: String? {
    switch self {
    case .metadataMissing:
      return "Document metadata is missing (expected Metadata/DocumentMetadata.pb or .json)."
    }
  }
}

public struct NumbersDocument: Sendable {
  public let sourceURL: URL
  public let sheets: [Sheet]

  private let dumpInfo: DocumentDump

  public static func open(at url: URL) throws -> NumbersDocument {
    let container = try NumbersContainer.open(at: url)
    let documentVersion = NumbersDocumentVersion.read(from: container)
    let blobs = try container.loadIndexBlobs()
    let inventory = try IWAInventoryBuilder.build(from: blobs)

    let realRead = IWARealDocumentReader.read(from: inventory, documentVersion: documentVersion)

    let sheets: [Sheet]
    let readPath: DocumentReadPath
    var fallbackReason: String?
    var diagnostics = realRead.diagnostics

    if !realRead.sheets.isEmpty {
      sheets = mapResolvedSheets(realRead.sheets)
      readPath = .real
    } else if let metadata = try MetadataLoader.loadDocumentMetadata(from: container) {
      sheets = mapMetadataSheets(metadata)
      readPath = .metadataFallback
      fallbackReason =
        realRead.structuredDiagnostics
        .first(where: { $0.severity == .error || $0.severity == .warning })?
        .rendered
        ?? "Real-read path returned no sheets."
      diagnostics.append(
        "[warning] read-path.fallback: Falling back to metadata decode path. (\(fallbackReason!))")
    } else {
      sheets = []
      readPath = .real
    }

    let resolvedCellCount =
      sheets
      .flatMap(\.tables)
      .reduce(0) { $0 + $1.populatedCellCount }

    let dump = DocumentDump(
      readPath: readPath,
      sourcePath: url.path,
      documentVersion: documentVersion,
      blobCount: blobs.count,
      objectCount: inventory.records.count,
      objectReferenceEdgeCount: inventory.objectReferenceEdgeCount,
      rootObjectCount: inventory.rootObjectIDs.count,
      resolvedCellCount: resolvedCellCount,
      fallbackReason: fallbackReason,
      typeHistogram: inventory.typeHistogram,
      unparsedBlobPaths: inventory.unparsedBlobPaths,
      diagnostics: diagnostics
    )

    return NumbersDocument(sourceURL: url, sheets: sheets, dumpInfo: dump)
  }

  public func dump() -> DocumentDump {
    dumpInfo
  }

  public func renderDump() -> String {
    var lines: [String] = []
    lines.append("Source: \(dumpInfo.sourcePath)")
    if let documentVersion = dumpInfo.documentVersion {
      lines.append("Document version: \(documentVersion)")
    } else {
      lines.append("Document version: <unknown>")
    }
    lines.append("Read path: \(dumpInfo.readPath.rawValue)")
    if let fallbackReason = dumpInfo.fallbackReason {
      lines.append("Fallback reason: \(fallbackReason)")
    }
    lines.append("Sheets: \(sheets.count)")
    lines.append("Tables: \(sheets.reduce(0) { $0 + $1.tables.count })")
    lines.append("Resolved cells: \(dumpInfo.resolvedCellCount)")
    lines.append("Index blobs: \(dumpInfo.blobCount)")
    lines.append("IWA objects: \(dumpInfo.objectCount)")
    lines.append("Object reference edges: \(dumpInfo.objectReferenceEdgeCount)")
    lines.append("Root objects: \(dumpInfo.rootObjectCount)")

    let sortedTypes = dumpInfo.typeHistogram.keys.sorted()
    if sortedTypes.isEmpty {
      lines.append("Type histogram: <empty>")
    } else {
      lines.append("Type histogram:")
      for typeID in sortedTypes {
        let count = dumpInfo.typeHistogram[typeID, default: 0]
        lines.append("  \(typeID): \(count)")
      }
    }

    if dumpInfo.unparsedBlobPaths.isEmpty {
      lines.append("Unparsed blobs: 0")
    } else {
      lines.append("Unparsed blobs: \(dumpInfo.unparsedBlobPaths.count)")
      for path in dumpInfo.unparsedBlobPaths {
        lines.append("  \(path)")
      }
    }

    if dumpInfo.diagnostics.isEmpty {
      lines.append("Diagnostics: 0")
    } else {
      lines.append("Diagnostics: \(dumpInfo.diagnostics.count)")
      for diagnostic in dumpInfo.diagnostics {
        lines.append("  \(diagnostic)")
      }
    }

    return lines.joined(separator: "\n")
  }

  private static func mapResolvedSheets(_ sheets: [IWAResolvedSheet]) -> [Sheet] {
    sheets.map { sheet in
      let tables = sheet.tables.map { table in
        var cells: [CellAddress: CellValue] = [:]
        cells.reserveCapacity(table.cells.count)

        for cell in table.cells {
          let address = CellAddress(row: cell.row, column: cell.column)
          let value: CellValue
          switch cell.value {
          case .empty:
            value = .empty
          case .string(let string):
            value = .string(string)
          case .number(let number):
            value = .number(number)
          case .bool(let bool):
            value = .bool(bool)
          }
          cells[address] = value
        }

        let merges = table.merges.map { merge in
          MergeRange(
            startRow: merge.startRow,
            endRow: merge.endRow,
            startColumn: merge.startColumn,
            endColumn: merge.endColumn
          )
        }

        return Table(
          id: table.id,
          name: table.name,
          metadata: TableMetadata(
            rowCount: table.rowCount,
            columnCount: table.columnCount,
            mergeRanges: merges
          ),
          cells: cells
        )
      }

      return Sheet(
        id: sheet.id,
        name: sheet.name,
        tables: tables
      )
    }
  }

  private static func mapMetadataSheets(_ metadata: Swiftnumbers_DocumentMetadata) -> [Sheet] {
    metadata.sheets.map { sheet in
      let tables = sheet.tables.map { table in
        let ranges = table.merges.map { merge in
          MergeRange(
            startRow: Int(merge.startRow),
            endRow: Int(merge.endRow),
            startColumn: Int(merge.startColumn),
            endColumn: Int(merge.endColumn)
          )
        }

        var cells: [CellAddress: CellValue] = [:]
        cells.reserveCapacity(table.cells.count)
        for cell in table.cells {
          let address = CellAddress(row: Int(cell.row), column: Int(cell.column))
          let value: CellValue

          switch cell.value {
          case .stringValue(let string):
            value = .string(string)
          case .numberValue(let number):
            value = .number(number)
          case .boolValue(let bool):
            value = .bool(bool)
          case nil:
            value = .empty
          }

          cells[address] = value
        }

        return Table(
          id: table.tableID,
          name: table.name,
          metadata: TableMetadata(
            rowCount: Int(table.rowCount),
            columnCount: Int(table.columnCount),
            mergeRanges: ranges
          ),
          cells: cells
        )
      }

      return Sheet(
        id: sheet.sheetID,
        name: sheet.name,
        tables: tables
      )
    }
  }
}
