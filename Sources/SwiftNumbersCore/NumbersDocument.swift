import Dispatch
import Foundation
import SwiftNumbersContainer
import SwiftNumbersIWA

public enum NumbersDocumentError: LocalizedError {
  case realReadFailed(String)
  case encryptedDocumentUnsupported

  public var errorDescription: String? {
    switch self {
    case .realReadFailed(let details):
      return "Swift-native read failed: \(details)"
    case .encryptedDocumentUnsupported:
      return
        "Encrypted .numbers documents are currently unsupported. Re-save without password protection and retry."
    }
  }
}

private struct ReadStyleRegistryOverlay: Decodable {
  let version: Int
  let nextStyleOrdinal: Int
  let styles: [ReadStyleRegistryStyleRecord]
  let assignments: [ReadStyleRegistryAssignmentRecord]
}

private struct ReadStyleRegistryStyleRecord: Decodable {
  let id: String
  let name: String
  let style: ReadStyleRegistryStylePayload
}

private struct ReadStyleRegistryAssignmentRecord: Decodable {
  let sheetName: String
  let tableName: String
  let row: Int
  let column: Int
  let styleID: String
}

private struct ReadStyleRegistryStylePayload: Decodable {
  let horizontalAlignment: String?
  let verticalAlignment: String?
  let backgroundColorHex: String?
  let fontName: String?
  let fontSize: Double?
  let isBold: Bool?
  let isItalic: Bool?
  let textColorHex: String?
  let hasTopBorder: Bool
  let hasRightBorder: Bool
  let hasBottomBorder: Bool
  let hasLeftBorder: Bool
  let numberFormatKind: String?
  let numberFormatID: Int32?

  func toReadCellStyle() -> ReadCellStyle {
    let mappedNumberFormat: ReadNumberFormat?
    if let numberFormatKind, let kind = ReadNumberFormatKind(rawValue: numberFormatKind) {
      mappedNumberFormat = ReadNumberFormat(kind: kind, formatID: numberFormatID ?? 0)
    } else {
      mappedNumberFormat = nil
    }

    return ReadCellStyle(
      horizontalAlignment: Self.decodeHorizontalAlignment(horizontalAlignment),
      verticalAlignment: Self.decodeVerticalAlignment(verticalAlignment),
      backgroundColorHex: backgroundColorHex,
      fontName: fontName,
      fontSize: fontSize,
      isBold: isBold,
      isItalic: isItalic,
      textColorHex: textColorHex,
      hasTopBorder: hasTopBorder,
      hasRightBorder: hasRightBorder,
      hasBottomBorder: hasBottomBorder,
      hasLeftBorder: hasLeftBorder,
      numberFormat: mappedNumberFormat
    )
  }

  private static func decodeHorizontalAlignment(_ value: String?) -> ReadHorizontalAlignment? {
    guard let value else {
      return nil
    }
    switch value {
    case "left":
      return .left
    case "center":
      return .center
    case "right":
      return .right
    case "justified":
      return .justified
    case "natural":
      return .natural
    default:
      if value.hasPrefix("unknown:"), let raw = Int32(value.dropFirst("unknown:".count)) {
        return .unknown(raw)
      }
      return nil
    }
  }

  private static func decodeVerticalAlignment(_ value: String?) -> ReadVerticalAlignment? {
    guard let value else {
      return nil
    }
    switch value {
    case "top":
      return .top
    case "middle":
      return .middle
    case "bottom":
      return .bottom
    default:
      if value.hasPrefix("unknown:"), let raw = Int32(value.dropFirst("unknown:".count)) {
        return .unknown(raw)
      }
      return nil
    }
  }
}

private struct NumbersReadTrace {
  private let enabled: Bool
  private let operation: String
  private let startedAt: DispatchTime
  private var lastMark: DispatchTime
  private var events: [(name: String, milliseconds: Double)] = []

  init(operation: String) {
    self.enabled = ProcessInfo.processInfo.environment["SWIFTNUMBERS_PERF_TRACE"] == "1"
    self.operation = operation
    self.startedAt = DispatchTime.now()
    self.lastMark = startedAt
  }

  mutating func mark(_ name: String) {
    guard enabled else { return }
    let now = DispatchTime.now()
    events.append((name: name, milliseconds: Self.milliseconds(from: lastMark, to: now)))
    lastMark = now
  }

  func finish(sourcePath: String) {
    guard enabled else { return }
    let total = Self.milliseconds(from: startedAt, to: DispatchTime.now())
    let eventObjects = events.map { event -> [String: Any] in
      ["name": event.name, "milliseconds": event.milliseconds]
    }
    let payload: [String: Any] = [
      "operation": operation,
      "sourcePath": sourcePath,
      "totalMilliseconds": total,
      "events": eventObjects,
    ]
    guard
      JSONSerialization.isValidJSONObject(payload),
      let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
      let line = String(data: data, encoding: .utf8)
    else {
      return
    }
    FileHandle.standardError.write(Data((line + "\n").utf8))
  }

  private static func milliseconds(from start: DispatchTime, to end: DispatchTime) -> Double {
    Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000.0
  }
}

public struct NumbersDocument: Sendable {
  public struct SheetSummary: Hashable, Sendable {
    public let id: String
    public let name: String
    public let tableCount: Int

    public init(id: String, name: String, tableCount: Int) {
      self.id = id
      self.name = name
      self.tableCount = tableCount
    }
  }

  public struct TableSummary: Hashable, Sendable {
    public let sheetID: String
    public let sheetName: String
    public let sheetIndex: Int
    public let tableID: String
    public let tableName: String
    public let tableIndex: Int
    public let tableInfoObjectID: UInt64
    public let tableModelObjectID: UInt64
    public let rowCount: Int
    public let columnCount: Int
    public let headerRowCount: Int
    public let headerColumnCount: Int
    public let tableNameVisible: Bool?
    public let captionVisible: Bool?
    public let captionText: String?
    public let captionTextSupported: Bool

    public init(
      sheetID: String,
      sheetName: String,
      sheetIndex: Int,
      tableID: String,
      tableName: String,
      tableIndex: Int,
      tableInfoObjectID: UInt64,
      tableModelObjectID: UInt64,
      rowCount: Int,
      columnCount: Int,
      headerRowCount: Int,
      headerColumnCount: Int,
      tableNameVisible: Bool?,
      captionVisible: Bool?,
      captionText: String?,
      captionTextSupported: Bool
    ) {
      self.sheetID = sheetID
      self.sheetName = sheetName
      self.sheetIndex = sheetIndex
      self.tableID = tableID
      self.tableName = tableName
      self.tableIndex = tableIndex
      self.tableInfoObjectID = tableInfoObjectID
      self.tableModelObjectID = tableModelObjectID
      self.rowCount = rowCount
      self.columnCount = columnCount
      self.headerRowCount = headerRowCount
      self.headerColumnCount = headerColumnCount
      self.tableNameVisible = tableNameVisible
      self.captionVisible = captionVisible
      self.captionText = captionText
      self.captionTextSupported = captionTextSupported
    }
  }

  public struct TableSelector: Hashable, Sendable {
    public let sheetName: String?
    public let sheetIndex: Int?
    public let tableName: String?
    public let tableIndex: Int?

    public init(
      sheetName: String? = nil,
      sheetIndex: Int? = nil,
      tableName: String? = nil,
      tableIndex: Int? = nil
    ) {
      self.sheetName = sheetName
      self.sheetIndex = sheetIndex
      self.tableName = tableName
      self.tableIndex = tableIndex
    }
  }

  public struct CellWindow: Hashable, Sendable {
    public let startRow: Int
    public let endRow: Int
    public let startColumn: Int
    public let endColumn: Int

    public init(startRow: Int, endRow: Int, startColumn: Int, endColumn: Int) {
      self.startRow = min(startRow, endRow)
      self.endRow = max(startRow, endRow)
      self.startColumn = min(startColumn, endColumn)
      self.endColumn = max(startColumn, endColumn)
    }
  }

  public struct TargetedTableRead: Sendable {
    public let sourceURL: URL
    public let sheet: Sheet
    public let table: Table

    public init(sourceURL: URL, sheet: Sheet, table: Table) {
      self.sourceURL = sourceURL
      self.sheet = sheet
      self.table = table
    }
  }

  public enum CSVExportMode: Hashable, Sendable {
    case value
    case formatted
    case formula
  }

  public let sourceURL: URL
  public let sheets: [Sheet]

  private let dumpInfo: DocumentDump
  private static let editableStringEscapePrefix = "__SWIFTNUMBERS_STRING__:"
  private static let editableDateMarkerPrefix = "__SWIFTNUMBERS_DATE__:"
  private static let editableFormulaMarkerPrefix = "__SWIFTNUMBERS_FORMULA__:"
  private static let styleRegistryMetadataFilename = "SwiftNumbersStyleRegistry.json"

  public static func sheetSummaries(at url: URL) throws -> [SheetSummary] {
    var trace = NumbersReadTrace(operation: "sheetSummaries")
    defer { trace.finish(sourcePath: url.path) }
    let container = try NumbersContainer.open(at: url)
    trace.mark("container")
    if try container.isLikelyEncryptedDocument() {
      throw NumbersDocumentError.encryptedDocumentUnsupported
    }

    let documentVersion = NumbersDocumentVersion.read(from: container)
    let blobs = try container.loadIndexBlobs()
    trace.mark("loadIndexBlobs")
    let inventory = try IWAInventoryBuilder.buildSheetSummaryInventory(from: blobs)
    trace.mark("inventory")
    let summaryResult = IWARealDocumentReader.readSheetSummaries(
      from: inventory,
      documentVersion: documentVersion
    )
    trace.mark("resolve")

    guard !summaryResult.sheets.isEmpty else {
      let reason =
        summaryResult.structuredDiagnostics
        .first(where: { $0.severity == .error || $0.severity == .warning })?
        .rendered
        ?? summaryResult.diagnostics.first
        ?? "Real-read summary path returned no sheets."
      throw NumbersDocumentError.realReadFailed(reason)
    }

    return summaryResult.sheets.map {
      SheetSummary(id: $0.id, name: $0.name, tableCount: $0.tableCount)
    }
  }

  public static func tableSummaries(at url: URL) throws -> [TableSummary] {
    var trace = NumbersReadTrace(operation: "tableSummaries")
    defer { trace.finish(sourcePath: url.path) }
    let container = try NumbersContainer.open(at: url)
    trace.mark("container")
    if try container.isLikelyEncryptedDocument() {
      throw NumbersDocumentError.encryptedDocumentUnsupported
    }

    let documentVersion = NumbersDocumentVersion.read(from: container)
    let blobs = try container.loadIndexBlobs()
    trace.mark("loadIndexBlobs")
    let inventory = try IWAInventoryBuilder.buildTableSummaryInventory(from: blobs)
    trace.mark("inventory")
    let summaryResult = IWARealDocumentReader.readTableSummaries(
      from: inventory,
      documentVersion: documentVersion
    )
    trace.mark("resolve")

    guard !summaryResult.tables.isEmpty else {
      let reason =
        summaryResult.structuredDiagnostics
        .first(where: { $0.severity == .error || $0.severity == .warning })?
        .rendered
        ?? "Real-read table summary path returned no tables."
      throw NumbersDocumentError.realReadFailed(reason)
    }

    return summaryResult.tables.map(mapResolvedTableSummary)
  }

  public static func readCell(
    at url: URL,
    selector: TableSelector = TableSelector(),
    cell reference: String,
    includeFormulas: Bool = true,
    includeFormatting: Bool = true
  ) throws -> TargetedTableRead {
    let parsed = try CellReference(reference)
    let window = CellWindow(
      startRow: parsed.address.row,
      endRow: parsed.address.row,
      startColumn: parsed.address.column,
      endColumn: parsed.address.column
    )
    return try readTable(
      at: url,
      selector: selector,
      window: window,
      includeFormulas: includeFormulas,
      includeFormatting: includeFormatting,
      includeRichText: true,
      includeStyles: true,
      includeMerges: true,
      includeCaptions: true
    )
  }

  public static func readColumn(
    at url: URL,
    selector: TableSelector = TableSelector(),
    column: Int,
    fromRow: Int = 0,
    includeFormulas: Bool = false,
    includeFormatting: Bool = false
  ) throws -> TargetedTableRead {
    let safeFromRow = max(0, fromRow)
    let window = CellWindow(
      startRow: safeFromRow,
      endRow: Int.max / 4,
      startColumn: column,
      endColumn: column
    )
    return try readTable(
      at: url,
      selector: selector,
      window: window,
      includeFormulas: includeFormulas,
      includeFormatting: includeFormatting
    )
  }

  public static func readRange(
    at url: URL,
    selector: TableSelector = TableSelector(),
    range: CellRange,
    includeFormulas: Bool = false,
    includeFormatting: Bool = false
  ) throws -> TargetedTableRead {
    try readTable(
      at: url,
      selector: selector,
      window: CellWindow(
        startRow: range.start.row,
        endRow: range.end.row,
        startColumn: range.start.column,
        endColumn: range.end.column
      ),
      includeFormulas: includeFormulas,
      includeFormatting: includeFormatting
    )
  }

  public static func readTable(
    at url: URL,
    selector: TableSelector = TableSelector(),
    window: CellWindow? = nil,
    includeFormulas: Bool = false,
    includeFormatting: Bool = false,
    includeRichText: Bool = false,
    includeStyles: Bool = false,
    includeMerges: Bool = true,
    includeCaptions: Bool = true
  ) throws -> TargetedTableRead {
    var trace = NumbersReadTrace(operation: "readTableTargeted")
    defer { trace.finish(sourcePath: url.path) }
    let container = try NumbersContainer.open(at: url)
    trace.mark("container")
    if try container.isLikelyEncryptedDocument() {
      throw NumbersDocumentError.encryptedDocumentUnsupported
    }

    let documentVersion = NumbersDocumentVersion.read(from: container)
    let blobs = try container.loadIndexBlobs()
    trace.mark("loadIndexBlobs")
    let features = iwaFeatures(
      includeFormulas: includeFormulas,
      includeFormatting: includeFormatting,
      includeRichText: includeRichText,
      includeStyles: includeStyles,
      includeMerges: includeMerges,
      includeCaptions: includeCaptions
    )
    let inventory = try IWAInventoryBuilder.buildSelectedReadInventory(
      from: blobs,
      features: features
    )
    trace.mark("inventory")
    let result = IWARealDocumentReader.readSelectedTable(
      from: inventory,
      documentVersion: documentVersion,
      selector: IWATableSelector(
        sheetName: selector.sheetName,
        sheetIndex: selector.sheetIndex,
        tableName: selector.tableName,
        tableIndex: selector.tableIndex
      ),
      cellWindow: window.map {
        IWACellWindow(
          startRow: $0.startRow,
          endRow: $0.endRow,
          startColumn: $0.startColumn,
          endColumn: $0.endColumn
        )
      },
      features: features
    )
    trace.mark("resolve")

    guard let resolvedSheet = result.sheets.first, let resolvedTable = resolvedSheet.tables.first
    else {
      let reason =
        result.structuredDiagnostics
        .first(where: { $0.severity == .error || $0.severity == .warning })?
        .rendered
        ?? "Real-read selected table path returned no table."
      throw NumbersDocumentError.realReadFailed(reason)
    }

    let mappedSheets = mapResolvedSheets([
      IWAResolvedSheet(id: resolvedSheet.id, name: resolvedSheet.name, tables: [resolvedTable])
    ])
    trace.mark("map")
    guard let sheet = mappedSheets.first, let table = sheet.tables.first else {
      throw NumbersDocumentError.realReadFailed("Selected table mapping returned no table.")
    }
    return TargetedTableRead(sourceURL: url, sheet: sheet, table: table)
  }

  public static func formulas(
    at url: URL,
    selector: TableSelector = TableSelector()
  ) throws -> TargetedTableRead {
    try readTable(
      at: url,
      selector: selector,
      window: nil,
      includeFormulas: true,
      includeFormatting: true,
      includeRichText: false,
      includeStyles: false,
      includeMerges: true,
      includeCaptions: true
    )
  }

  public static func exportCSV(
    at url: URL,
    selector: TableSelector = TableSelector(),
    mode: CSVExportMode = .value,
    to outputURL: URL? = nil
  ) throws -> String {
    let targeted = try readTable(
      at: url,
      selector: selector,
      window: nil,
      includeFormulas: mode == .formula,
      includeFormatting: mode == .formatted,
      includeRichText: false,
      includeStyles: false,
      includeMerges: false,
      includeCaptions: false
    )
    let csv = renderCSV(table: targeted.table, mode: mode)
    if let outputURL {
      try Data(csv.utf8).write(to: outputURL, options: .atomic)
    }
    return csv
  }

  public static func open(at url: URL) throws -> NumbersDocument {
    var trace = NumbersReadTrace(operation: "open")
    defer { trace.finish(sourcePath: url.path) }
    let container = try NumbersContainer.open(at: url)
    trace.mark("container")
    if try container.isLikelyEncryptedDocument() {
      throw NumbersDocumentError.encryptedDocumentUnsupported
    }
    let documentVersion = NumbersDocumentVersion.read(from: container)
    let blobs = try container.loadIndexBlobs()
    trace.mark("loadIndexBlobs")
    let inventory = try IWAInventoryBuilder.build(from: blobs)
    trace.mark("inventory")

    let realRead = IWARealDocumentReader.read(from: inventory, documentVersion: documentVersion)
    trace.mark("resolve")
    guard !realRead.sheets.isEmpty else {
      let reason =
        realRead.structuredDiagnostics
        .first(where: { $0.severity == .error || $0.severity == .warning })?
        .rendered
        ?? realRead.diagnostics.first
        ?? "Real-read path returned no sheets."
      throw NumbersDocumentError.realReadFailed(reason)
    }
    let mappedSheets = mapResolvedSheets(realRead.sheets)
    trace.mark("map")
    let sheets = try applyStyleRegistryOverlayIfPresent(to: mappedSheets, from: container)
    trace.mark("overlay")
    let diagnostics = realRead.diagnostics
    let structuredDiagnostics = realRead.structuredDiagnostics.map(mapReadDiagnostic)

    let resolvedCellCount =
      sheets
      .flatMap(\.tables)
      .reduce(0) { $0 + $1.populatedCellCount }

    let dump = DocumentDump(
      readPath: .real,
      sourcePath: url.path,
      documentVersion: documentVersion,
      blobCount: blobs.count,
      objectCount: inventory.records.count,
      objectReferenceEdgeCount: inventory.objectReferenceEdgeCount,
      rootObjectCount: inventory.rootObjectIDs.count,
      resolvedCellCount: resolvedCellCount,
      fallbackReason: nil,
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

  private static func mapResolvedTableSummary(_ summary: IWAResolvedTableSummary) -> TableSummary {
    TableSummary(
      sheetID: summary.sheetID,
      sheetName: summary.sheetName,
      sheetIndex: summary.sheetIndex,
      tableID: summary.tableID,
      tableName: summary.tableName,
      tableIndex: summary.tableIndex,
      tableInfoObjectID: summary.tableInfoObjectID,
      tableModelObjectID: summary.tableModelObjectID,
      rowCount: summary.rowCount,
      columnCount: summary.columnCount,
      headerRowCount: summary.headerRowCount,
      headerColumnCount: summary.headerColumnCount,
      tableNameVisible: summary.tableNameVisible,
      captionVisible: summary.captionVisible,
      captionText: summary.captionText,
      captionTextSupported: summary.captionTextSupported
    )
  }

  private static func iwaFeatures(
    includeFormulas: Bool,
    includeFormatting: Bool,
    includeRichText: Bool,
    includeStyles: Bool,
    includeMerges: Bool,
    includeCaptions: Bool
  ) -> IWAReadFeatures {
    var features: IWAReadFeatures = [.values]
    if includeFormatting {
      features.insert(.formatted)
    }
    if includeStyles {
      features.insert(.styles)
    }
    if includeFormulas {
      features.insert(.formulas)
    }
    if includeRichText {
      features.insert(.richText)
    }
    if includeMerges {
      features.insert(.merges)
    }
    if includeCaptions {
      features.insert(.captions)
    }
    return features
  }

  private static func renderCSV(table: Table, mode: CSVExportMode) -> String {
    var lines: [String] = []
    lines.reserveCapacity(table.rowCount)
    for row in 0..<table.rowCount {
      var fields: [String] = []
      fields.reserveCapacity(table.columnCount)
      for column in 0..<table.columnCount {
        let address = CellAddress(row: row, column: column)
        let readCell =
          table.readCell(at: address)
          ?? ReadCell(address: address, value: .empty, kind: .empty, formatted: "")
        fields.append(csvEscape(csvCellString(readCell: readCell, table: table, mode: mode)))
      }
      lines.append(fields.joined(separator: ","))
    }
    return lines.joined(separator: "\n") + "\n"
  }

  private static func csvCellString(readCell: ReadCell, table: Table, mode: CSVExportMode) -> String {
    switch mode {
    case .value:
      return csvCellString(from: readCell.readValue)
    case .formatted:
      return readCell.formatted
    case .formula:
      if let formula = table.formula(at: readCell.address)?.rawFormula {
        return formula
      }
      return csvCellString(from: readCell.readValue)
    }
  }

  private static func csvCellString(from value: ReadCellValue) -> String {
    switch value {
    case .empty:
      return ""
    case .string(let string):
      return string
    case .number(let number):
      return csvNumberString(number)
    case .bool(let bool):
      return bool ? "TRUE" : "FALSE"
    case .date(let date):
      return ISO8601DateFormatter().string(from: date)
    case .duration(let seconds):
      return csvNumberString(seconds)
    case .error(let message):
      return message
    case .richText(let richText):
      return richText.text
    case .formulaResult(let result):
      return csvCellString(from: result.computedValue)
    }
  }

  private static func csvCellString(from value: CellValue) -> String {
    switch value {
    case .empty:
      return ""
    case .string(let string), .formula(let string):
      return string
    case .number(let number):
      return csvNumberString(number)
    case .bool(let bool):
      return bool ? "TRUE" : "FALSE"
    case .date(let date):
      return ISO8601DateFormatter().string(from: date)
    }
  }

  private static func csvEscape(_ field: String) -> String {
    guard
      field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r")
    else {
      return field
    }
    return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
  }

  private static func csvNumberString(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.numberStyle = .decimal
    formatter.usesGroupingSeparator = false
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 15
    return formatter.string(from: NSNumber(value: value)) ?? String(value)
  }

  private static func applyStyleRegistryOverlayIfPresent(
    to sheets: [Sheet],
    from container: NumbersContainer
  ) throws -> [Sheet] {
    guard
      let data = try container.readMetadataFile(named: styleRegistryMetadataFilename),
      !data.isEmpty
    else {
      return sheets
    }

    let decoder = JSONDecoder()
    let overlay = try decoder.decode(ReadStyleRegistryOverlay.self, from: data)

    var stylesByID: [String: ReadCellStyle] = [:]
    stylesByID.reserveCapacity(overlay.styles.count)
    for styleRecord in overlay.styles {
      stylesByID[styleRecord.id] = styleRecord.style.toReadCellStyle()
    }

    struct TableKey: Hashable {
      let sheetName: String
      let tableName: String
    }

    var styleAssignmentsByTable: [TableKey: [CellAddress: ReadCellStyle]] = [:]
    styleAssignmentsByTable.reserveCapacity(overlay.assignments.count)

    for assignment in overlay.assignments {
      guard let style = stylesByID[assignment.styleID] else {
        continue
      }
      let tableKey = TableKey(sheetName: assignment.sheetName, tableName: assignment.tableName)
      let address = CellAddress(row: assignment.row, column: assignment.column)
      var assignmentMap = styleAssignmentsByTable[tableKey] ?? [:]
      assignmentMap[address] = style
      styleAssignmentsByTable[tableKey] = assignmentMap
    }

    guard !styleAssignmentsByTable.isEmpty else {
      return sheets
    }

    return sheets.map { sheet in
      let remappedTables = sheet.tables.map { table in
        let tableKey = TableKey(sheetName: sheet.name, tableName: table.name)
        guard let assignments = styleAssignmentsByTable[tableKey] else {
          return table
        }
        return applyingOverlayStyles(assignments, to: table)
      }

      return Sheet(id: sheet.id, name: sheet.name, tables: remappedTables)
    }
  }

  private static func applyingOverlayStyles(
    _ styleAssignments: [CellAddress: ReadCellStyle],
    to table: Table
  ) -> Table {
    guard !styleAssignments.isEmpty else {
      return table
    }

    let populatedReadCells = table.populatedCells(sorted: false)
    var readCellsByAddress = Dictionary(
      uniqueKeysWithValues: populatedReadCells.map { ($0.address, $0) })
    var didMutate = false

    for (address, style) in styleAssignments {
      guard address.row >= 0, address.column >= 0 else {
        continue
      }
      guard address.row < table.rowCount, address.column < table.columnCount else {
        continue
      }

      if let existing = readCellsByAddress[address] {
        guard existing.style != style else {
          continue
        }
        readCellsByAddress[address] = readCell(existing, replacingStyleWith: style)
        didMutate = true
      } else {
        readCellsByAddress[address] = ReadCell(
          address: address,
          value: .empty,
          kind: .empty,
          readValue: .empty,
          formatted: "",
          style: style,
          rawCellType: 0
        )
        didMutate = true
      }
    }

    guard didMutate else {
      return table
    }

    let cellsByAddress = Dictionary(
      uniqueKeysWithValues: populatedReadCells.map { ($0.address, $0.value) })

    return Table(
      id: table.id,
      name: table.name,
      metadata: table.metadata,
      cells: cellsByAddress,
      readCells: readCellsByAddress
    )
  }

  private static func readCell(
    _ existing: ReadCell,
    replacingStyleWith style: ReadCellStyle?
  ) -> ReadCell {
    ReadCell(
      address: existing.address,
      value: existing.value,
      kind: existing.kind,
      readValue: existing.readValue,
      formulaResult: existing.formulaResult,
      formatted: existing.formatted,
      richText: existing.richText,
      style: style,
      rawCellType: existing.rawCellType,
      stringID: existing.stringID,
      richTextID: existing.richTextID,
      formulaID: existing.formulaID,
      formulaErrorID: existing.formulaErrorID,
      mergeRange: existing.mergeRange,
      mergeRole: existing.mergeRole
    )
  }

  private static func mapResolvedSheets(_ sheets: [IWAResolvedSheet]) -> [Sheet] {
    let formatter = ReadValueFormatter()
    return sheets.map { sheet in
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
            } else if let formula = decodeEditableFormulaMarker(string) {
              value = .formula(formula)
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
            value = .string(cell.richText?.text ?? text)
          }

          let mappedKind: ReadCellKind
          if case .formula = value, cell.kind != .formula {
            mappedKind = .formula
          } else {
            mappedKind = mapResolvedCellKind(cell.kind)
          }
          let formattedValue = formatter.string(from: value)
          let mappedRichText = mapResolvedRichText(cell.richText)
          let mappedStyle = mapResolvedCellStyle(cell.style)
          let formulaResult: FormulaResultRead?
          if mappedKind == .formula {
            let rawFormula: String?
            if let cellFormula = cell.formulaRaw {
              rawFormula = cellFormula
            } else if case .formula(let syntheticFormula) = value {
              rawFormula = syntheticFormula
            } else {
              rawFormula = nil
            }
            let tokens =
              cell.formulaTokens.isEmpty
              ? (rawFormula.map(tokenizeFormulaForDump) ?? [])
              : cell.formulaTokens
            let astSummary =
              cell.formulaASTSummary
              ?? (tokens.isEmpty ? nil : "Tokenized formula (\(tokens.count) tokens)")

            formulaResult = FormulaResultRead(
              formulaID: cell.formulaID,
              rawFormula: rawFormula,
              parsedTokens: tokens,
              astSummary: astSummary,
              computedValue: value,
              computedFormatted: formattedValue
            )
          } else {
            formulaResult = nil
          }

          let readValue = mapResolvedReadValue(
            rawValue: cell.value,
            fallbackValue: value,
            richText: mappedRichText,
            formulaResult: formulaResult
          )

          cells[address] = value
          readCells[address] = ReadCell(
            address: address,
            value: value,
            kind: mappedKind,
            readValue: readValue,
            formulaResult: formulaResult,
            formatted: formattedValue,
            richText: mappedRichText,
            style: mappedStyle,
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
        let objectIdentifiers: TableObjectIdentifiers? = {
          let tableInfoObjectID = table.tableInfoObjectID > 0 ? table.tableInfoObjectID : nil
          let tableModelObjectID = table.tableModelObjectID > 0 ? table.tableModelObjectID : nil
          guard tableInfoObjectID != nil || tableModelObjectID != nil else {
            return nil
          }
          return TableObjectIdentifiers(
            tableInfoObjectID: tableInfoObjectID,
            tableModelObjectID: tableModelObjectID
          )
        }()
        let pivotLinks = table.pivotLinks.map { link in
          PivotLinkMetadata(
            drawableObjectID: link.drawableObjectID,
            drawableTypeIDs: link.drawableTypeIDs,
            linkedTableInfoObjectIDs: link.linkedTableInfoObjectIDs,
            linkedTableModelObjectIDs: link.linkedTableModelObjectIDs
          )
        }

        return Table(
          id: table.id,
          name: table.name,
          metadata: TableMetadata(
            rowCount: table.rowCount,
            columnCount: table.columnCount,
            headerRowCount: table.headerRowCount,
            headerColumnCount: table.headerColumnCount,
            rowHeights: table.rowHeights,
            columnWidths: table.columnWidths,
            mergeRanges: merges,
            tableNameVisible: table.tableNameVisible,
            captionVisible: table.captionVisible,
            captionText: table.captionText,
            captionTextSupported: table.captionTextSupported,
            objectIdentifiers: objectIdentifiers,
            pivotLinks: pivotLinks
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

  private static func decodeEscapedEditableString(_ raw: String) -> String? {
    guard raw.hasPrefix(editableStringEscapePrefix) else {
      return nil
    }
    return String(raw.dropFirst(editableStringEscapePrefix.count))
  }

  private static func decodeEditableDateMarker(_ raw: String) -> Date? {
    guard raw.hasPrefix(editableDateMarkerPrefix) else {
      return nil
    }

    let isoString = String(raw.dropFirst(editableDateMarkerPrefix.count))
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: isoString) {
      return date
    }

    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: isoString)
  }

  private static func decodeEditableFormulaMarker(_ raw: String) -> String? {
    guard raw.hasPrefix(editableFormulaMarkerPrefix) else {
      return nil
    }

    let encoded = String(raw.dropFirst(editableFormulaMarkerPrefix.count))
    let trimmed = encoded.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return nil
    }
    return trimmed.hasPrefix("=") ? trimmed : "=\(trimmed)"
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

  private static func mapResolvedReadValue(
    rawValue: IWAResolvedCellValue,
    fallbackValue: CellValue,
    richText: RichTextRead?,
    formulaResult: FormulaResultRead?
  ) -> ReadCellValue {
    if let formulaResult {
      return .formulaResult(formulaResult)
    }

    switch rawValue {
    case .empty:
      return .empty
    case .string(let string):
      if case .date(let date) = fallbackValue {
        return .date(date)
      }
      if case .formula(let formula) = fallbackValue {
        return .string(formula)
      }
      return .string(string)
    case .number(let number):
      return .number(number)
    case .bool(let bool):
      return .bool(bool)
    case .date(let date):
      return .date(date)
    case .duration(let seconds):
      return .duration(seconds)
    case .error(let message):
      return .error(message)
    case .richText(let text):
      if let richText {
        return .richText(richText)
      }
      return .richText(RichTextRead(text: text, runs: []))
    }
  }

  private static func mapResolvedRichText(_ richText: IWAResolvedRichText?) -> RichTextRead? {
    guard let richText else {
      return nil
    }

    let runs = richText.runs.compactMap { run -> RichTextRun? in
      guard run.start >= 0, run.end >= run.start else {
        return nil
      }
      return RichTextRun(
        range: run.start..<run.end,
        text: run.text,
        fontName: run.fontName,
        fontSize: run.fontSize,
        isBold: run.isBold,
        isItalic: run.isItalic,
        textColorHex: run.textColorHex,
        linkURL: run.linkURL
      )
    }
    return RichTextRead(text: richText.text, runs: runs)
  }

  private static func mapResolvedCellStyle(_ style: IWAResolvedCellStyle?) -> ReadCellStyle? {
    guard let style else {
      return nil
    }
    return ReadCellStyle(
      horizontalAlignment: style.horizontalAlignment.map(mapResolvedHorizontalAlignment),
      verticalAlignment: style.verticalAlignment.map(mapResolvedVerticalAlignment),
      backgroundColorHex: style.backgroundColorHex,
      fontName: style.fontName,
      fontSize: style.fontSize,
      isBold: style.isBold,
      isItalic: style.isItalic,
      textColorHex: style.textColorHex,
      hasTopBorder: style.hasTopBorder,
      hasRightBorder: style.hasRightBorder,
      hasBottomBorder: style.hasBottomBorder,
      hasLeftBorder: style.hasLeftBorder,
      numberFormat: style.numberFormat.map(mapResolvedNumberFormat)
    )
  }

  private static func mapResolvedHorizontalAlignment(
    _ value: IWAResolvedHorizontalAlignment
  ) -> ReadHorizontalAlignment {
    switch value {
    case .left:
      return .left
    case .center:
      return .center
    case .right:
      return .right
    case .justified:
      return .justified
    case .natural:
      return .natural
    case .unknown(let raw):
      return .unknown(raw)
    }
  }

  private static func mapResolvedVerticalAlignment(
    _ value: IWAResolvedVerticalAlignment
  ) -> ReadVerticalAlignment {
    switch value {
    case .top:
      return .top
    case .middle:
      return .middle
    case .bottom:
      return .bottom
    case .unknown(let raw):
      return .unknown(raw)
    }
  }

  private static func mapResolvedNumberFormat(
    _ value: IWAResolvedNumberFormat
  ) -> ReadNumberFormat {
    let kind: ReadNumberFormatKind
    switch value.kind {
    case .number:
      kind = .number
    case .currency:
      kind = .currency
    case .date:
      kind = .date
    case .duration:
      kind = .duration
    case .text:
      kind = .text
    case .bool:
      kind = .bool
    }

    return ReadNumberFormat(kind: kind, formatID: value.formatID)
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

  private static func formatReadValue(_ value: CellValue) -> String {
    let formatter = ReadValueFormatter()
    return formatter.string(from: value)
  }

  private struct ReadValueFormatter {
    private let numberFormatter: NumberFormatter
    private let dateFormatter: ISO8601DateFormatter

    init() {
      let numberFormatter = NumberFormatter()
      numberFormatter.locale = Locale(identifier: "en_US_POSIX")
      numberFormatter.numberStyle = .decimal
      numberFormatter.usesGroupingSeparator = false
      numberFormatter.maximumFractionDigits = 15
      numberFormatter.minimumFractionDigits = 0
      self.numberFormatter = numberFormatter

      let dateFormatter = ISO8601DateFormatter()
      dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      self.dateFormatter = dateFormatter
    }

    func string(from value: CellValue) -> String {
      switch value {
      case .empty:
        return ""
      case .string(let string):
        return string
      case .formula(let formula):
        return formula
      case .number(let number):
        return numberFormatter.string(from: NSNumber(value: number)) ?? String(number)
      case .bool(let bool):
        return bool ? "TRUE" : "FALSE"
      case .date(let date):
        return dateFormatter.string(from: date)
      }
    }
  }

  private static func tokenizeFormulaForDump(_ formula: String) -> [String] {
    if formula.isEmpty {
      return []
    }

    let punctuation = Set<Character>([
      "(", ")", ",", ":", "+", "-", "*", "/", "^", "&", "=", "<", ">",
    ])
    var tokens: [String] = []
    var current = ""
    var inString = false

    for character in formula {
      if inString {
        current.append(character)
        if character == "\"" {
          tokens.append(current)
          current = ""
          inString = false
        }
        continue
      }

      if character == "\"" {
        if !current.isEmpty {
          tokens.append(current)
          current = ""
        }
        current.append(character)
        inString = true
        continue
      }

      if character.isWhitespace {
        if !current.isEmpty {
          tokens.append(current)
          current = ""
        }
        continue
      }

      if punctuation.contains(character) {
        if !current.isEmpty {
          tokens.append(current)
          current = ""
        }
        tokens.append(String(character))
        continue
      }

      current.append(character)
    }

    if !current.isEmpty {
      tokens.append(current)
    }

    return tokens
  }
}
