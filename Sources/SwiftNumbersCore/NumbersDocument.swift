import Foundation
import SwiftNumbersContainer
import SwiftNumbersIWA
import SwiftNumbersProto

public enum NumbersDocumentError: LocalizedError {
  case metadataMissing
  case encryptedDocumentUnsupported

  public var errorDescription: String? {
    switch self {
    case .metadataMissing:
      return "Document metadata is missing (expected Metadata/DocumentMetadata.pb or .json)."
    case .encryptedDocumentUnsupported:
      return
        "Encrypted .numbers documents are currently unsupported. Re-save without password protection and retry."
    }
  }
}

public struct NumbersDocument: Sendable {
  public let sourceURL: URL
  public let sheets: [Sheet]

  private let dumpInfo: DocumentDump

  public static func open(at url: URL) throws -> NumbersDocument {
    let container = try NumbersContainer.open(at: url)
    if try container.isLikelyEncryptedDocument() {
      throw NumbersDocumentError.encryptedDocumentUnsupported
    }
    let documentVersion = NumbersDocumentVersion.read(from: container)
    let metadata = try MetadataLoader.loadDocumentMetadata(from: container)
    let blobs = try container.loadIndexBlobs()
    let inventory = try IWAInventoryBuilder.build(from: blobs)

    let realRead = IWARealDocumentReader.read(from: inventory, documentVersion: documentVersion)

    let sheets: [Sheet]
    let readPath: DocumentReadPath
    var fallbackReason: String?
    var diagnostics = realRead.diagnostics
    var structuredDiagnostics = realRead.structuredDiagnostics.map(mapReadDiagnostic)

    if let metadata, shouldPreferEditableMetadataOverlay(metadata) {
      sheets = mapMetadataSheets(metadata)
      readPath = .metadataFallback
      fallbackReason = "Using SwiftNumbers editable metadata overlay."
      let marker = ReadDiagnostic(
        code: "read-path.editable-overlay",
        severity: .info,
        message: "Prioritizing metadata overlay produced by SwiftNumbers writer."
      )
      diagnostics.append(marker.rendered)
      structuredDiagnostics.append(marker)
    } else if !realRead.sheets.isEmpty {
      sheets = mapResolvedSheets(realRead.sheets)
      readPath = .real
    } else if let metadata {
      sheets = mapMetadataSheets(metadata)
      readPath = .metadataFallback
      fallbackReason =
        realRead.structuredDiagnostics
        .first(where: { $0.severity == .error || $0.severity == .warning })?
        .rendered
        ?? "Real-read path returned no sheets."
      let marker = ReadDiagnostic(
        code: "read-path.fallback",
        severity: .warning,
        message: "Falling back to metadata decode path. (\(fallbackReason!))"
      )
      diagnostics.append(marker.rendered)
      structuredDiagnostics.append(marker)
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
      diagnostics: diagnostics,
      structuredDiagnostics: structuredDiagnostics
    )

    return NumbersDocument(sourceURL: url, sheets: sheets, dumpInfo: dump)
  }

  public func dump() -> DocumentDump {
    dumpInfo
  }

  public var firstSheet: Sheet? {
    sheets.first
  }

  public var sheetNames: [String] {
    sheets.map(\.name)
  }

  public var tableCount: Int {
    sheets.reduce(0) { $0 + $1.tables.count }
  }

  public var tableNames: [String] {
    sheets.flatMap { sheet in
      sheet.tables.map { "\(sheet.name)/\($0.name)" }
    }
  }

  public subscript(_ index: Int) -> Sheet? {
    sheet(at: index)
  }

  public subscript(_ name: String) -> Sheet? {
    sheet(named: name)
  }

  public func sheet(named name: String) -> Sheet? {
    sheets.first(where: { $0.name == name })
  }

  public func sheet(at index: Int) -> Sheet? {
    guard index >= 0, index < sheets.count else {
      return nil
    }
    return sheets[index]
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
        var readCells: [CellAddress: ReadCell] = [:]
        cells.reserveCapacity(table.cells.count)
        readCells.reserveCapacity(table.cells.count)

        for cell in table.cells {
          let address = CellAddress(row: cell.row, column: cell.column)
          let value: CellValue
          switch cell.value {
          case .empty:
            value = .empty
          case .string(let string):
            if let escaped = decodeEscapedEditableString(string) {
              value = .string(escaped)
            } else if let date = decodeEditableDateMarker(string) {
              value = .date(date)
            } else {
              value = .string(string)
            }
          case .number(let number):
            value = .number(number)
          case .bool(let bool):
            value = .bool(bool)
          case .date(let date):
            value = .date(date)
          case .duration(let seconds):
            value = .number(seconds)
          case .error(let message):
            value = .string(message)
          case .richText(let text):
            value = .string(text)
          }
          cells[address] = value
          readCells[address] = ReadCell(
            address: address,
            value: value,
            kind: mapResolvedCellKind(cell.kind),
            formatted: formatReadValue(value),
            rawCellType: cell.rawCellType,
            stringID: cell.stringID,
            richTextID: cell.richTextID,
            formulaID: cell.formulaID,
            formulaErrorID: cell.formulaErrorID
          )
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
          cells: cells,
          readCells: readCells
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
        var readCells: [CellAddress: ReadCell] = [:]
        cells.reserveCapacity(table.cells.count)
        readCells.reserveCapacity(table.cells.count)
        for cell in table.cells {
          let address = CellAddress(row: Int(cell.row), column: Int(cell.column))
          let value: CellValue

          switch cell.value {
          case .stringValue(let string):
            if let escaped = decodeEscapedEditableString(string) {
              value = .string(escaped)
            } else if let date = decodeEditableDateMarker(string) {
              value = .date(date)
            } else {
              value = .string(string)
            }
          case .numberValue(let number):
            value = .number(number)
          case .boolValue(let bool):
            value = .bool(bool)
          case nil:
            value = .empty
          }

          cells[address] = value
          readCells[address] = ReadCell(
            address: address,
            value: value,
            kind: mapCellKindFromValue(value),
            formatted: formatReadValue(value)
          )
        }

        return Table(
          id: table.tableID,
          name: table.name,
          metadata: TableMetadata(
            rowCount: Int(table.rowCount),
            columnCount: Int(table.columnCount),
            mergeRanges: ranges
          ),
          cells: cells,
          readCells: readCells
        )
      }

      return Sheet(
        id: sheet.sheetID,
        name: sheet.name,
        tables: tables
      )
    }
  }

  private static func shouldPreferEditableMetadataOverlay(
    _ metadata: Swiftnumbers_DocumentMetadata
  ) -> Bool {
    metadata.documentID.hasPrefix("swiftnumbers-editable-v1:")
  }

  private static func decodeEscapedEditableString(_ raw: String) -> String? {
    let prefix = "__SWIFTNUMBERS_STRING__:"
    guard raw.hasPrefix(prefix) else {
      return nil
    }
    return String(raw.dropFirst(prefix.count))
  }

  private static func decodeEditableDateMarker(_ raw: String) -> Date? {
    let prefix = "__SWIFTNUMBERS_DATE__:"
    guard raw.hasPrefix(prefix) else {
      return nil
    }

    let isoString = String(raw.dropFirst(prefix.count))
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: isoString) {
      return date
    }

    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: isoString)
  }

  private static func mapResolvedCellKind(_ kind: IWAResolvedCellKind) -> ReadCellKind {
    switch kind {
    case .empty:
      return .empty
    case .number:
      return .number
    case .text:
      return .text
    case .formula:
      return .formula
    case .date:
      return .date
    case .bool:
      return .bool
    case .duration:
      return .duration
    case .formulaError:
      return .formulaError
    case .richText:
      return .richText
    case .unknown(let raw):
      return .unknown(raw)
    }
  }

  private static func mapReadDiagnostic(_ diagnostic: IWAReadDiagnostic) -> ReadDiagnostic {
    ReadDiagnostic(
      code: diagnostic.code,
      severity: mapReadDiagnosticSeverity(diagnostic.severity),
      message: diagnostic.message,
      objectPath: diagnostic.objectPath,
      suggestion: diagnostic.suggestion,
      context: diagnostic.context
    )
  }

  private static func mapReadDiagnosticSeverity(
    _ severity: IWAReadDiagnosticSeverity
  ) -> ReadDiagnosticSeverity {
    switch severity {
    case .info:
      return .info
    case .warning:
      return .warning
    case .error:
      return .error
    }
  }

  private static func mapCellKindFromValue(_ value: CellValue) -> ReadCellKind {
    switch value {
    case .empty:
      return .empty
    case .string:
      return .text
    case .number:
      return .number
    case .bool:
      return .bool
    case .date:
      return .date
    }
  }

  private static func formatReadValue(_ value: CellValue) -> String {
    switch value {
    case .empty:
      return ""
    case .string(let string):
      return string
    case .number(let number):
      let formatter = NumberFormatter()
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.numberStyle = .decimal
      formatter.usesGroupingSeparator = false
      formatter.maximumFractionDigits = 15
      formatter.minimumFractionDigits = 0
      return formatter.string(from: NSNumber(value: number)) ?? String(number)
    case .bool(let bool):
      return bool ? "TRUE" : "FALSE"
    case .date(let date):
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      return formatter.string(from: date)
    }
  }
}
