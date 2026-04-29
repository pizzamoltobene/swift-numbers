import Foundation
import SwiftNumbersContainer
import SwiftNumbersProto
import SwiftProtobuf

public enum IWAResolvedCellValue: Hashable, Sendable {
  case empty
  case string(String)
  case number(Double)
  case bool(Bool)
  case date(Date)
  case duration(TimeInterval)
  case error(String)
  case richText(String)
}

public enum IWAResolvedCellKind: Hashable, Sendable {
  case empty
  case number
  case text
  case formula
  case date
  case bool
  case duration
  case formulaError
  case richText
  case unknown(UInt8)
}

public struct IWAResolvedRichTextRun: Hashable, Sendable {
  public let start: Int
  public let end: Int
  public let text: String
  public let fontName: String?
  public let fontSize: Double?
  public let isBold: Bool?
  public let isItalic: Bool?
  public let textColorHex: String?
  public let linkURL: String?

  public init(
    start: Int,
    end: Int,
    text: String,
    fontName: String? = nil,
    fontSize: Double? = nil,
    isBold: Bool? = nil,
    isItalic: Bool? = nil,
    textColorHex: String? = nil,
    linkURL: String? = nil
  ) {
    self.start = start
    self.end = end
    self.text = text
    self.fontName = fontName
    self.fontSize = fontSize
    self.isBold = isBold
    self.isItalic = isItalic
    self.textColorHex = textColorHex
    self.linkURL = linkURL
  }
}

public struct IWAResolvedRichText: Hashable, Sendable {
  public let text: String
  public let runs: [IWAResolvedRichTextRun]

  public init(text: String, runs: [IWAResolvedRichTextRun]) {
    self.text = text
    self.runs = runs
  }
}

public enum IWAResolvedHorizontalAlignment: Hashable, Sendable {
  case left
  case center
  case right
  case justified
  case natural
  case unknown(Int32)
}

public enum IWAResolvedVerticalAlignment: Hashable, Sendable {
  case top
  case middle
  case bottom
  case unknown(Int32)
}

public enum IWAResolvedNumberFormatKind: String, Hashable, Sendable {
  case number
  case currency
  case date
  case duration
  case text
  case bool
}

public struct IWAResolvedNumberFormat: Hashable, Sendable {
  public let kind: IWAResolvedNumberFormatKind
  public let formatID: Int32

  public init(kind: IWAResolvedNumberFormatKind, formatID: Int32) {
    self.kind = kind
    self.formatID = formatID
  }
}

public struct IWAResolvedCellStyle: Hashable, Sendable {
  public let horizontalAlignment: IWAResolvedHorizontalAlignment?
  public let verticalAlignment: IWAResolvedVerticalAlignment?
  public let backgroundColorHex: String?
  public let fontName: String?
  public let fontSize: Double?
  public let isBold: Bool?
  public let isItalic: Bool?
  public let textColorHex: String?
  public let hasTopBorder: Bool
  public let hasRightBorder: Bool
  public let hasBottomBorder: Bool
  public let hasLeftBorder: Bool
  public let numberFormat: IWAResolvedNumberFormat?

  public init(
    horizontalAlignment: IWAResolvedHorizontalAlignment? = nil,
    verticalAlignment: IWAResolvedVerticalAlignment? = nil,
    backgroundColorHex: String? = nil,
    fontName: String? = nil,
    fontSize: Double? = nil,
    isBold: Bool? = nil,
    isItalic: Bool? = nil,
    textColorHex: String? = nil,
    hasTopBorder: Bool = false,
    hasRightBorder: Bool = false,
    hasBottomBorder: Bool = false,
    hasLeftBorder: Bool = false,
    numberFormat: IWAResolvedNumberFormat? = nil
  ) {
    self.horizontalAlignment = horizontalAlignment
    self.verticalAlignment = verticalAlignment
    self.backgroundColorHex = backgroundColorHex
    self.fontName = fontName
    self.fontSize = fontSize
    self.isBold = isBold
    self.isItalic = isItalic
    self.textColorHex = textColorHex
    self.hasTopBorder = hasTopBorder
    self.hasRightBorder = hasRightBorder
    self.hasBottomBorder = hasBottomBorder
    self.hasLeftBorder = hasLeftBorder
    self.numberFormat = numberFormat
  }
}

public struct IWAResolvedCell: Hashable, Sendable {
  public let row: Int
  public let column: Int
  public let value: IWAResolvedCellValue
  public let kind: IWAResolvedCellKind
  public let richText: IWAResolvedRichText?
  public let style: IWAResolvedCellStyle?
  public let rawCellType: UInt8
  public let stringID: Int32?
  public let richTextID: Int32?
  public let formulaID: Int32?
  public let formulaErrorID: Int32?
  public let formulaRaw: String?
  public let formulaTokens: [String]
  public let formulaASTSummary: String?

  public init(
    row: Int,
    column: Int,
    value: IWAResolvedCellValue,
    kind: IWAResolvedCellKind,
    richText: IWAResolvedRichText? = nil,
    style: IWAResolvedCellStyle? = nil,
    rawCellType: UInt8,
    stringID: Int32? = nil,
    richTextID: Int32? = nil,
    formulaID: Int32? = nil,
    formulaErrorID: Int32? = nil,
    formulaRaw: String? = nil,
    formulaTokens: [String] = [],
    formulaASTSummary: String? = nil
  ) {
    self.row = row
    self.column = column
    self.value = value
    self.kind = kind
    self.richText = richText
    self.style = style
    self.rawCellType = rawCellType
    self.stringID = stringID
    self.richTextID = richTextID
    self.formulaID = formulaID
    self.formulaErrorID = formulaErrorID
    self.formulaRaw = formulaRaw
    self.formulaTokens = formulaTokens
    self.formulaASTSummary = formulaASTSummary
  }
}

public struct IWAResolvedMergeRange: Hashable, Sendable {
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

public struct IWAResolvedPivotLink: Hashable, Sendable {
  public let drawableObjectID: UInt64
  public let drawableTypeIDs: [UInt32]
  public let linkedTableInfoObjectIDs: [UInt64]
  public let linkedTableModelObjectIDs: [UInt64]
  public var drawableTypeCount: Int { drawableTypeIDs.count }
  public var linkedTableInfoCount: Int { linkedTableInfoObjectIDs.count }
  public var linkedTableModelCount: Int { linkedTableModelObjectIDs.count }

  public init(
    drawableObjectID: UInt64,
    drawableTypeIDs: [UInt32],
    linkedTableInfoObjectIDs: [UInt64],
    linkedTableModelObjectIDs: [UInt64]
  ) {
    self.drawableObjectID = drawableObjectID
    self.drawableTypeIDs = drawableTypeIDs
    self.linkedTableInfoObjectIDs = linkedTableInfoObjectIDs
    self.linkedTableModelObjectIDs = linkedTableModelObjectIDs
  }
}

public struct IWAResolvedTable: Hashable, Sendable {
  public let id: String
  public let name: String
  public let tableInfoObjectID: UInt64
  public let tableModelObjectID: UInt64
  public let rowCount: Int
  public let columnCount: Int
  public let headerRowCount: Int
  public let headerColumnCount: Int
  public let rowHeights: [Double?]
  public let columnWidths: [Double?]
  public let merges: [IWAResolvedMergeRange]
  public let tableNameVisible: Bool?
  public let captionVisible: Bool?
  public let captionText: String?
  public let captionTextSupported: Bool
  public let pivotLinks: [IWAResolvedPivotLink]
  public let cells: [IWAResolvedCell]

  public init(
    id: String,
    name: String,
    tableInfoObjectID: UInt64 = 0,
    tableModelObjectID: UInt64 = 0,
    rowCount: Int,
    columnCount: Int,
    headerRowCount: Int = 0,
    headerColumnCount: Int = 0,
    rowHeights: [Double?] = [],
    columnWidths: [Double?] = [],
    merges: [IWAResolvedMergeRange],
    tableNameVisible: Bool? = nil,
    captionVisible: Bool? = nil,
    captionText: String? = nil,
    captionTextSupported: Bool = false,
    pivotLinks: [IWAResolvedPivotLink] = [],
    cells: [IWAResolvedCell]
  ) {
    self.id = id
    self.name = name
    self.tableInfoObjectID = tableInfoObjectID
    self.tableModelObjectID = tableModelObjectID
    self.rowCount = rowCount
    self.columnCount = columnCount
    self.headerRowCount = headerRowCount
    self.headerColumnCount = headerColumnCount
    self.rowHeights = rowHeights
    self.columnWidths = columnWidths
    self.merges = merges
    self.tableNameVisible = tableNameVisible
    self.captionVisible = captionVisible
    self.captionText = captionText
    self.captionTextSupported = captionTextSupported
    self.pivotLinks = pivotLinks
    self.cells = cells
  }
}

public struct IWAResolvedSheet: Hashable, Sendable {
  public let id: String
  public let name: String
  public let tables: [IWAResolvedTable]

  public init(id: String, name: String, tables: [IWAResolvedTable]) {
    self.id = id
    self.name = name
    self.tables = tables
  }
}

public struct IWAResolvedSheetSummary: Hashable, Sendable {
  public let id: String
  public let name: String
  public let tableCount: Int

  public init(id: String, name: String, tableCount: Int) {
    self.id = id
    self.name = name
    self.tableCount = tableCount
  }
}

public enum IWAReadDiagnosticSeverity: String, Sendable {
  case info
  case warning
  case error
}

public struct IWAReadDiagnostic: Sendable {
  public let code: String
  public let severity: IWAReadDiagnosticSeverity
  public let message: String
  public let objectPath: String?
  public let suggestion: String?
  public let context: [String: String]

  public init(
    code: String,
    severity: IWAReadDiagnosticSeverity,
    message: String,
    objectPath: String? = nil,
    suggestion: String? = nil,
    context: [String: String] = [:]
  ) {
    self.code = code
    self.severity = severity
    self.message = message
    self.objectPath = objectPath
    self.suggestion = suggestion
    self.context = context
  }

  public var rendered: String {
    var components = ["[\(severity.rawValue)] \(code): \(message)"]
    if let objectPath, !objectPath.isEmpty {
      components.append("path=\(objectPath)")
    }
    if let suggestion, !suggestion.isEmpty {
      components.append("suggestion=\(suggestion)")
    }
    if !context.isEmpty {
      let details = context.keys.sorted().map { "\($0)=\(context[$0]!)" }.joined(separator: ", ")
      components.append(details)
    }
    return components.joined(separator: " | ")
  }
}

public struct IWARealReadResult: Sendable {
  public let sheets: [IWAResolvedSheet]
  public let structuredDiagnostics: [IWAReadDiagnostic]
  public var diagnostics: [String] {
    structuredDiagnostics.map(\.rendered)
  }

  public init(sheets: [IWAResolvedSheet], diagnostics: [String]) {
    self.init(
      sheets: sheets,
      structuredDiagnostics: diagnostics.map {
        IWAReadDiagnostic(code: "legacy", severity: .info, message: $0)
      })
  }

  public init(sheets: [IWAResolvedSheet], structuredDiagnostics: [IWAReadDiagnostic]) {
    self.sheets = sheets
    self.structuredDiagnostics = structuredDiagnostics
  }
}

public struct IWAResolvedTableSummary: Hashable, Sendable {
  public let sheetObjectID: UInt64
  public let sheetID: String
  public let sheetName: String
  public let sheetIndex: Int
  public let tableInfoObjectID: UInt64
  public let tableModelObjectID: UInt64
  public let tableID: String
  public let tableName: String
  public let tableIndex: Int
  public let rowCount: Int
  public let columnCount: Int
  public let headerRowCount: Int
  public let headerColumnCount: Int
  public let tableNameVisible: Bool?
  public let captionVisible: Bool?
  public let captionText: String?
  public let captionTextSupported: Bool

  public init(
    sheetObjectID: UInt64,
    sheetID: String,
    sheetName: String,
    sheetIndex: Int,
    tableInfoObjectID: UInt64,
    tableModelObjectID: UInt64,
    tableID: String,
    tableName: String,
    tableIndex: Int,
    rowCount: Int,
    columnCount: Int,
    headerRowCount: Int,
    headerColumnCount: Int,
    tableNameVisible: Bool?,
    captionVisible: Bool?,
    captionText: String?,
    captionTextSupported: Bool
  ) {
    self.sheetObjectID = sheetObjectID
    self.sheetID = sheetID
    self.sheetName = sheetName
    self.sheetIndex = sheetIndex
    self.tableInfoObjectID = tableInfoObjectID
    self.tableModelObjectID = tableModelObjectID
    self.tableID = tableID
    self.tableName = tableName
    self.tableIndex = tableIndex
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

public struct IWATableSelector: Hashable, Sendable {
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

public struct IWACellWindow: Hashable, Sendable {
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

  public func contains(row: Int, column: Int) -> Bool {
    row >= startRow && row <= endRow && column >= startColumn && column <= endColumn
  }
}

public struct IWAReadFeatures: OptionSet, Hashable, Sendable {
  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public static let values = IWAReadFeatures(rawValue: 1 << 0)
  public static let formatted = IWAReadFeatures(rawValue: 1 << 1)
  public static let styles = IWAReadFeatures(rawValue: 1 << 2)
  public static let formulas = IWAReadFeatures(rawValue: 1 << 3)
  public static let richText = IWAReadFeatures(rawValue: 1 << 4)
  public static let merges = IWAReadFeatures(rawValue: 1 << 5)
  public static let captions = IWAReadFeatures(rawValue: 1 << 6)

  public static let valueOnly: IWAReadFeatures = [.values]
  public static let full: IWAReadFeatures = [
    .values, .formatted, .styles, .formulas, .richText, .merges, .captions,
  ]
}

public struct IWARealSheetSummaryResult: Sendable {
  public let sheets: [IWAResolvedSheetSummary]
  public let structuredDiagnostics: [IWAReadDiagnostic]
  public var diagnostics: [String] {
    structuredDiagnostics.map(\.rendered)
  }

  public init(sheets: [IWAResolvedSheetSummary], diagnostics: [String]) {
    self.init(
      sheets: sheets,
      structuredDiagnostics: diagnostics.map {
        IWAReadDiagnostic(code: "legacy", severity: .info, message: $0)
      })
  }

  public init(sheets: [IWAResolvedSheetSummary], structuredDiagnostics: [IWAReadDiagnostic]) {
    self.sheets = sheets
    self.structuredDiagnostics = structuredDiagnostics
  }
}

public enum NumbersDocumentVersion {
  private static let supportedVersions: Set<String> = [
    "10.3", "11.0", "11.1", "11.2", "12.0", "12.1", "12.2", "13.0", "13.1",
    "13.2", "14.0", "14.1", "14.2", "14.3", "14.4", "14.5", "26.0", "26.1",
  ]

  public static func read(from container: NumbersContainer) -> String? {
    let maybePlistData: Data?
    do {
      maybePlistData = try container.readMetadataFile(named: "Properties.plist")
    } catch {
      return nil
    }

    guard let plistData = maybePlistData else {
      return nil
    }

    let payload: Any
    do {
      payload = try PropertyListSerialization.propertyList(from: plistData, format: nil)
    } catch {
      return nil
    }

    guard let dictionary = payload as? [String: Any] else {
      return nil
    }

    if let version = dictionary["fileFormatVersion"] as? String {
      let trimmed = version.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }

    if let version = dictionary["fileFormatVersion"] as? NSNumber {
      return version.stringValue
    }

    return nil
  }

  public static func unsupportedVersionDiagnostic(for version: String?) -> String? {
    guard let version else {
      return nil
    }

    guard let normalized = normalize(version: version) else {
      return
        "Could not normalize Numbers document version '\(version)'; decode will continue in best-effort mode."
    }

    guard !supportedVersions.contains(normalized) else {
      return nil
    }

    return
      "Numbers document version \(version) is not in the tested support set (\(normalized)); decode will continue in best-effort mode."
  }

  private static func normalize(version: String) -> String? {
    let components =
      version
      .split(separator: ".")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    guard !components.isEmpty else {
      return nil
    }

    if components.count == 1 {
      return components[0]
    }

    return "\(components[0]).\(components[1])"
  }
}

public struct IWARealTableSummaryResult: Sendable {
  public let tables: [IWAResolvedTableSummary]
  public let structuredDiagnostics: [IWAReadDiagnostic]

  public init(tables: [IWAResolvedTableSummary], structuredDiagnostics: [IWAReadDiagnostic]) {
    self.tables = tables
    self.structuredDiagnostics = structuredDiagnostics
  }
}

public enum IWARealDocumentReader {
  private enum TypeID {
    static let documentArchive: UInt32 = 1
    static let sheetArchive: UInt32 = 2
    static let captionInfoArchive: UInt32 = 633
    static let wpStorageArchive: UInt32 = 2001
    static let wpStorageArchiveAlt: UInt32 = 2005
    static let wpCharacterStyleArchive: UInt32 = 2021
    static let wpParagraphStyleArchive: UInt32 = 2022
    static let wpHyperlinkFieldArchive: UInt32 = 2032
    static let wpUnsupportedHyperlinkFieldArchive: UInt32 = 2039
    static let standinCaptionArchive: UInt32 = 3097
    static let tableInfoArchive: UInt32 = 6000
    static let tableModelArchive: UInt32 = 6001
    static let cellStyleArchive: UInt32 = 6004
    static let tileArchive: UInt32 = 6002
    static let tableDataList: UInt32 = 6005
    static let headerStorageBucket: UInt32 = 6006
    static let tableDataListSegment: UInt32 = 6011
    static let richTextPayloadArchive: UInt32 = 6218
    static let mergeRegionMapArchive: UInt32 = 6144
  }

  private enum DiagnosticCode: String {
    case unsupportedVersion = "version.unsupported"
    case documentRootMissing = "resolver.document.missing"
    case documentCandidateSelected = "resolver.document.selected"
    case documentCandidateSelectionFallback = "resolver.document.selectionFallback"
    case documentDecodeFailed = "resolver.document.decodeFailed"
    case noSheetsResolved = "resolver.sheet.empty"
    case invalidSheetReference = "resolver.sheet.invalidReference"
    case duplicateSheetReference = "resolver.sheet.duplicateReference"
    case sheetDecodeMissing = "resolver.sheet.decodeMissing"
    case tableResolveFailed = "resolver.table.resolveFailed"
    case pivotCandidateDetected = "resolver.pivot.candidateDetected"
    case pivotCandidateSummary = "resolver.pivot.candidateSummary"
    case rowStorageMapPatched = "decode.rowStorage.patched"
    case unsupportedCellTypeDropped = "decode.cell.unsupportedTypeDropped"
    case formulaDecodeFailed = "decode.formula.failed"
    case formulaUnsupportedAstNodes = "decode.formula.unsupportedAstNodes"
  }

  public static func read(from inventory: IWAInventory, documentVersion: String?)
    -> IWARealReadResult
  {
    var diagnostics: [IWAReadDiagnostic] = []
    if let warning = NumbersDocumentVersion.unsupportedVersionDiagnostic(for: documentVersion) {
      diagnostics.append(
        IWAReadDiagnostic(
          code: DiagnosticCode.unsupportedVersion.rawValue,
          severity: .warning,
          message: warning
        ))
    }

    var resolver = Resolver(inventory: inventory, diagnostics: diagnostics)
    let resolved = resolver.resolve()
    return IWARealReadResult(
      sheets: resolved.sheets,
      structuredDiagnostics: deduplicateUnsupportedDecodeDiagnostics(resolved.structuredDiagnostics)
    )
  }

  public static func readSheetSummaries(from inventory: IWAInventory, documentVersion: String?)
    -> IWARealSheetSummaryResult
  {
    var diagnostics: [IWAReadDiagnostic] = []
    if let warning = NumbersDocumentVersion.unsupportedVersionDiagnostic(for: documentVersion) {
      diagnostics.append(
        IWAReadDiagnostic(
          code: DiagnosticCode.unsupportedVersion.rawValue,
          severity: .warning,
          message: warning
        ))
    }

    var resolver = Resolver(inventory: inventory, diagnostics: diagnostics)
    let resolved = resolver.resolveSheetSummaries()
    return IWARealSheetSummaryResult(
      sheets: resolved.sheets,
      structuredDiagnostics: deduplicateUnsupportedDecodeDiagnostics(resolved.structuredDiagnostics)
    )
  }

  public static func readTableSummaries(from inventory: IWAInventory, documentVersion: String?)
    -> IWARealTableSummaryResult
  {
    var diagnostics: [IWAReadDiagnostic] = []
    if let warning = NumbersDocumentVersion.unsupportedVersionDiagnostic(for: documentVersion) {
      diagnostics.append(
        IWAReadDiagnostic(
          code: DiagnosticCode.unsupportedVersion.rawValue,
          severity: .warning,
          message: warning
        ))
    }

    var resolver = Resolver(inventory: inventory, diagnostics: diagnostics)
    let resolved = resolver.resolveTableSummaries()
    return IWARealTableSummaryResult(
      tables: resolved.tables,
      structuredDiagnostics: deduplicateUnsupportedDecodeDiagnostics(resolved.structuredDiagnostics)
    )
  }

  public static func readSelectedTable(
    from inventory: IWAInventory,
    documentVersion: String?,
    selector: IWATableSelector,
    cellWindow: IWACellWindow?,
    features: IWAReadFeatures
  ) -> IWARealReadResult {
    var diagnostics: [IWAReadDiagnostic] = []
    if let warning = NumbersDocumentVersion.unsupportedVersionDiagnostic(for: documentVersion) {
      diagnostics.append(
        IWAReadDiagnostic(
          code: DiagnosticCode.unsupportedVersion.rawValue,
          severity: .warning,
          message: warning
        ))
    }

    var resolver = Resolver(
      inventory: inventory,
      diagnostics: diagnostics,
      cellWindow: cellWindow,
      features: features
    )
    let resolved = resolver.resolveSelectedTable(selector: selector)
    return IWARealReadResult(
      sheets: resolved.sheets,
      structuredDiagnostics: deduplicateUnsupportedDecodeDiagnostics(resolved.structuredDiagnostics)
    )
  }

  static func deduplicateUnsupportedDecodeDiagnostics(_ diagnostics: [IWAReadDiagnostic])
    -> [IWAReadDiagnostic]
  {
    var deduplicated: [IWAReadDiagnostic] = []
    deduplicated.reserveCapacity(diagnostics.count)

    var seenUnsupportedKeys = Set<String>()
    for diagnostic in diagnostics {
      guard isUnsupportedDecodeDiagnosticCode(diagnostic.code) else {
        deduplicated.append(diagnostic)
        continue
      }

      guard let nodeType = unsupportedNodeType(for: diagnostic) else {
        deduplicated.append(diagnostic)
        continue
      }

      let objectKey = normalizedDiagnosticObjectKey(diagnostic)
      let key = "\(diagnostic.code)|\(objectKey)|\(nodeType)"
      if seenUnsupportedKeys.insert(key).inserted {
        deduplicated.append(diagnostic)
      }
    }

    return deduplicated
  }

  private static func isUnsupportedDecodeDiagnosticCode(_ code: String) -> Bool {
    code == DiagnosticCode.unsupportedCellTypeDropped.rawValue
      || code == DiagnosticCode.formulaUnsupportedAstNodes.rawValue
  }

  private static func unsupportedNodeType(for diagnostic: IWAReadDiagnostic) -> String? {
    let rawNodeType: String?
    let isNodeTypeList: Bool
    switch diagnostic.code {
    case DiagnosticCode.unsupportedCellTypeDropped.rawValue:
      rawNodeType = diagnostic.context["cellType"]
      isNodeTypeList = false
    case DiagnosticCode.formulaUnsupportedAstNodes.rawValue:
      if let list = diagnostic.context["unsupportedNodeTypes"] {
        rawNodeType = list
        isNodeTypeList = true
      } else {
        rawNodeType = diagnostic.context["unsupportedNodeType"]
        isNodeTypeList = false
      }
    default:
      return nil
    }

    guard let rawNodeType else { return nil }
    if isNodeTypeList {
      return normalizeUnsupportedNodeTypeList(rawNodeType)
    }
    return normalizeUnsupportedNodeTypeToken(rawNodeType)
  }

  private static func normalizedObjectPath(_ objectPath: String?) -> String {
    objectPath?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
  }

  private static func normalizedDiagnosticObjectKey(_ diagnostic: IWAReadDiagnostic) -> String {
    let objectPath = normalizedObjectPath(diagnostic.objectPath)
    if !objectPath.isEmpty {
      return "path:\(objectPath)"
    }

    for contextKey in ["tableID", "objectID", "tableInfoObjectID", "tableModelObjectID"] {
      if let value = normalizeDiagnosticContextValue(diagnostic.context[contextKey]) {
        return "\(contextKey):\(value)"
      }
    }

    return "path:"
  }

  private static func normalizeDiagnosticContextValue(_ value: String?) -> String? {
    guard let value else { return nil }
    let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return normalized.isEmpty ? nil : normalized
  }

  private static func normalizeUnsupportedNodeTypeToken(_ rawValue: String) -> String? {
    let collapsed =
      rawValue
      .split(whereSeparator: \.isWhitespace)
      .map(String.init)
      .joined(separator: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
    return collapsed.isEmpty ? nil : collapsed
  }

  private static func normalizeUnsupportedNodeTypeList(_ rawValue: String) -> String? {
    let normalizedTokens = rawValue.split(separator: ",")
      .compactMap { normalizeUnsupportedNodeTypeToken(String($0)) }
    guard !normalizedTokens.isEmpty else {
      return nil
    }
    return Array(Set(normalizedTokens)).sorted().joined(separator: ",")
  }

  private struct Resolver {
    let inventory: IWAInventory
    private var diagnostics: [IWAReadDiagnostic]
    private let cellWindow: IWACellWindow?
    private let features: IWAReadFeatures
    private let recordsByObjectID: [UInt64: [IWAObjectRecord]]
    private var resolvedTableCache: [UInt64: IWAResolvedTable]
    private var unresolvedTableObjectIDs: Set<UInt64>
    private var pivotDiagnosticDrawableObjectIDs: Set<UInt64>
    private var pivotLinksByTableInfoObjectID: [UInt64: [IWAResolvedPivotLink]]

    init(
      inventory: IWAInventory,
      diagnostics: [IWAReadDiagnostic],
      cellWindow: IWACellWindow? = nil,
      features: IWAReadFeatures = .full
    ) {
      self.inventory = inventory
      self.diagnostics = diagnostics
      self.cellWindow = cellWindow
      self.features = features
      self.resolvedTableCache = [:]
      self.unresolvedTableObjectIDs = []
      self.pivotDiagnosticDrawableObjectIDs = []
      self.pivotLinksByTableInfoObjectID = [:]

      var grouped: [UInt64: [IWAObjectRecord]] = [:]
      for record in inventory.records {
        grouped[record.objectID, default: []].append(record)
      }
      for (objectID, records) in grouped {
        grouped[objectID] = records.sorted(by: Self.preferredRecordOrder(_:_:))
      }
      self.recordsByObjectID = grouped
    }

    private static func preferredRecordOrder(_ lhs: IWAObjectRecord, _ rhs: IWAObjectRecord)
      -> Bool
    {
      if lhs.typeID != rhs.typeID {
        return lhs.typeID < rhs.typeID
      }
      if lhs.payloadSize != rhs.payloadSize {
        return lhs.payloadSize > rhs.payloadSize
      }
      if lhs.payloadData != rhs.payloadData {
        return lhs.payloadData.lexicographicallyPrecedes(rhs.payloadData)
      }
      if lhs.sourceBlobPath != rhs.sourceBlobPath {
        return lhs.sourceBlobPath < rhs.sourceBlobPath
      }
      if lhs.objectReferences != rhs.objectReferences {
        return lhs.objectReferences.lexicographicallyPrecedes(rhs.objectReferences)
      }
      if lhs.dataReferences != rhs.dataReferences {
        return lhs.dataReferences.lexicographicallyPrecedes(rhs.dataReferences)
      }
      return false
    }

    mutating func resolve() -> IWARealReadResult {
      guard let documentObjectID = selectDocumentObjectID() else {
        addDiagnostic(
          .documentRootMissing,
          severity: .error,
          message: "TN.DocumentArchive root not found in IWA inventory.")
        return IWARealReadResult(sheets: [], structuredDiagnostics: diagnostics)
      }

      guard
        let document: TN_DocumentArchive = decode(
          objectID: documentObjectID,
          typeID: TypeID.documentArchive,
          as: TN_DocumentArchive.self
        )
      else {
        addDiagnostic(
          .documentDecodeFailed,
          severity: .error,
          message: "Failed to decode TN.DocumentArchive.",
          context: ["objectID": String(documentObjectID)]
        )
        return IWARealReadResult(sheets: [], structuredDiagnostics: diagnostics)
      }

      var sheets: [IWAResolvedSheet] = []
      sheets.reserveCapacity(document.sheets.count)

      var seenSheetObjectIDs = Set<UInt64>()
      for (sheetIndex, sheetReference) in document.sheets.enumerated() {
        let sheetObjectID = sheetReference.identifier
        guard sheetObjectID > 0 else {
          addDiagnostic(
            .invalidSheetReference,
            severity: .warning,
            message: "Skipping sheet reference with invalid object identifier.",
            context: ["sheetIndex": String(sheetIndex)]
          )
          continue
        }
        if seenSheetObjectIDs.contains(sheetObjectID) {
          addDiagnostic(
            .duplicateSheetReference,
            severity: .info,
            message: "Skipping duplicate sheet reference.",
            context: ["objectID": String(sheetObjectID), "sheetIndex": String(sheetIndex)]
          )
          continue
        }
        seenSheetObjectIDs.insert(sheetObjectID)

        let decodedSheet: TN_SheetArchive? = decode(
          objectID: sheetObjectID,
          typeID: TypeID.sheetArchive,
          as: TN_SheetArchive.self
        )
        if decodedSheet == nil {
          addDiagnostic(
            .sheetDecodeMissing,
            severity: .warning,
            message: "Sheet metadata missing; using fallback name and parent traversal.",
            context: ["objectID": String(sheetObjectID), "sheetIndex": String(sheetIndex)]
          )
        }

        let sheetName =
          decodedSheet?.name.isEmpty == false ? decodedSheet!.name : "Sheet \(sheetIndex + 1)"
        let drawableRefs = decodedSheet?.drawableInfos ?? []

        let tables = resolveMergedTables(sheetObjectID: sheetObjectID, drawableRefs: drawableRefs)

        sheets.append(
          IWAResolvedSheet(
            id: "sheet-\(sheetObjectID)",
            name: sheetName,
            tables: tables
          )
        )
      }

      emitPivotCandidateSummaryDiagnosticIfNeeded()

      if sheets.isEmpty {
        addDiagnostic(
          .noSheetsResolved,
          severity: .warning,
          message: "No sheets were resolved from TN.DocumentArchive.",
          context: ["objectID": String(documentObjectID)]
        )
      }

      return IWARealReadResult(sheets: sheets, structuredDiagnostics: diagnostics)
    }

    mutating func resolveSheetSummaries() -> IWARealSheetSummaryResult {
      guard let documentObjectID = selectDocumentObjectID() else {
        addDiagnostic(
          .documentRootMissing,
          severity: .error,
          message: "TN.DocumentArchive root not found in IWA inventory.")
        return IWARealSheetSummaryResult(sheets: [], structuredDiagnostics: diagnostics)
      }

      guard
        let document: TN_DocumentArchive = decode(
          objectID: documentObjectID,
          typeID: TypeID.documentArchive,
          as: TN_DocumentArchive.self
        )
      else {
        addDiagnostic(
          .documentDecodeFailed,
          severity: .error,
          message: "Failed to decode TN.DocumentArchive.",
          context: ["objectID": String(documentObjectID)]
        )
        return IWARealSheetSummaryResult(sheets: [], structuredDiagnostics: diagnostics)
      }

      var summaries: [IWAResolvedSheetSummary] = []
      summaries.reserveCapacity(document.sheets.count)

      var seenSheetObjectIDs = Set<UInt64>()
      for (sheetIndex, sheetReference) in document.sheets.enumerated() {
        let sheetObjectID = sheetReference.identifier
        guard sheetObjectID > 0 else {
          addDiagnostic(
            .invalidSheetReference,
            severity: .warning,
            message: "Skipping sheet reference with invalid object identifier.",
            context: ["sheetIndex": String(sheetIndex)]
          )
          continue
        }
        if seenSheetObjectIDs.contains(sheetObjectID) {
          addDiagnostic(
            .duplicateSheetReference,
            severity: .info,
            message: "Skipping duplicate sheet reference.",
            context: ["objectID": String(sheetObjectID), "sheetIndex": String(sheetIndex)]
          )
          continue
        }
        seenSheetObjectIDs.insert(sheetObjectID)

        let decodedSheet: TN_SheetArchive? = decode(
          objectID: sheetObjectID,
          typeID: TypeID.sheetArchive,
          as: TN_SheetArchive.self
        )
        if decodedSheet == nil {
          addDiagnostic(
            .sheetDecodeMissing,
            severity: .warning,
            message: "Sheet metadata missing; using fallback name and parent traversal.",
            context: ["objectID": String(sheetObjectID), "sheetIndex": String(sheetIndex)]
          )
        }

        let sheetName =
          decodedSheet?.name.isEmpty == false ? decodedSheet!.name : "Sheet \(sheetIndex + 1)"
        let drawableRefs = decodedSheet?.drawableInfos ?? []
        let (tableInfoObjectIDs, _) = mergedTableInfoObjectIDs(
          sheetObjectID: sheetObjectID,
          drawableRefs: drawableRefs
        )

        summaries.append(
          IWAResolvedSheetSummary(
            id: "sheet-\(sheetObjectID)",
            name: sheetName,
            tableCount: tableInfoObjectIDs.count
          )
        )
      }

      emitPivotCandidateSummaryDiagnosticIfNeeded()

      if summaries.isEmpty {
        addDiagnostic(
          .noSheetsResolved,
          severity: .warning,
          message: "No sheets were resolved from TN.DocumentArchive.",
          context: ["objectID": String(documentObjectID)]
        )
      }

      return IWARealSheetSummaryResult(sheets: summaries, structuredDiagnostics: diagnostics)
    }

    mutating func resolveTableSummaries() -> IWARealTableSummaryResult {
      guard let documentObjectID = selectDocumentObjectID() else {
        addDiagnostic(
          .documentRootMissing,
          severity: .error,
          message: "TN.DocumentArchive root not found in IWA inventory.")
        return IWARealTableSummaryResult(tables: [], structuredDiagnostics: diagnostics)
      }

      guard
        let document: TN_DocumentArchive = decode(
          objectID: documentObjectID,
          typeID: TypeID.documentArchive,
          as: TN_DocumentArchive.self
        )
      else {
        addDiagnostic(
          .documentDecodeFailed,
          severity: .error,
          message: "Failed to decode TN.DocumentArchive.",
          context: ["objectID": String(documentObjectID)]
        )
        return IWARealTableSummaryResult(tables: [], structuredDiagnostics: diagnostics)
      }

      var summaries: [IWAResolvedTableSummary] = []

      var seenSheetObjectIDs = Set<UInt64>()
      for (sheetIndex, sheetReference) in document.sheets.enumerated() {
        let sheetObjectID = sheetReference.identifier
        guard sheetObjectID > 0 else {
          addDiagnostic(
            .invalidSheetReference,
            severity: .warning,
            message: "Skipping sheet reference with invalid object identifier.",
            context: ["sheetIndex": String(sheetIndex)]
          )
          continue
        }
        guard seenSheetObjectIDs.insert(sheetObjectID).inserted else {
          addDiagnostic(
            .duplicateSheetReference,
            severity: .info,
            message: "Skipping duplicate sheet reference.",
            context: ["objectID": String(sheetObjectID), "sheetIndex": String(sheetIndex)]
          )
          continue
        }

        let decodedSheet: TN_SheetArchive? = decode(
          objectID: sheetObjectID,
          typeID: TypeID.sheetArchive,
          as: TN_SheetArchive.self
        )
        if decodedSheet == nil {
          addDiagnostic(
            .sheetDecodeMissing,
            severity: .warning,
            message: "Sheet metadata missing; using fallback name and parent traversal.",
            context: ["objectID": String(sheetObjectID), "sheetIndex": String(sheetIndex)]
          )
        }

        let sheetName =
          decodedSheet?.name.isEmpty == false ? decodedSheet!.name : "Sheet \(sheetIndex + 1)"
        let drawableRefs = decodedSheet?.drawableInfos ?? []
        let (tableInfoObjectIDs, _) = mergedTableInfoObjectIDs(
          sheetObjectID: sheetObjectID,
          drawableRefs: drawableRefs
        )

        summaries.reserveCapacity(summaries.count + tableInfoObjectIDs.count)
        for (tableIndex, tableInfoObjectID) in tableInfoObjectIDs.enumerated() {
          if let summary = resolveTableSummary(
            sheetObjectID: sheetObjectID,
            sheetID: "sheet-\(sheetObjectID)",
            sheetName: sheetName,
            sheetIndex: sheetIndex,
            tableInfoObjectID: tableInfoObjectID,
            tableIndex: tableIndex
          ) {
            summaries.append(summary)
          }
        }
      }

      emitPivotCandidateSummaryDiagnosticIfNeeded()

      if summaries.isEmpty {
        addDiagnostic(
          .noSheetsResolved,
          severity: .warning,
          message: "No tables were resolved from TN.DocumentArchive.",
          context: ["objectID": String(documentObjectID)]
        )
      }

      return IWARealTableSummaryResult(tables: summaries, structuredDiagnostics: diagnostics)
    }

    mutating func resolveSelectedTable(selector: IWATableSelector) -> IWARealReadResult {
      guard let documentObjectID = selectDocumentObjectID() else {
        addDiagnostic(
          .documentRootMissing,
          severity: .error,
          message: "TN.DocumentArchive root not found in IWA inventory.")
        return IWARealReadResult(sheets: [], structuredDiagnostics: diagnostics)
      }

      guard
        let document: TN_DocumentArchive = decode(
          objectID: documentObjectID,
          typeID: TypeID.documentArchive,
          as: TN_DocumentArchive.self
        )
      else {
        addDiagnostic(
          .documentDecodeFailed,
          severity: .error,
          message: "Failed to decode TN.DocumentArchive.",
          context: ["objectID": String(documentObjectID)]
        )
        return IWARealReadResult(sheets: [], structuredDiagnostics: diagnostics)
      }

      if let requestedSheetIndex = selector.sheetIndex,
        requestedSheetIndex < 0 || requestedSheetIndex >= document.sheets.count
      {
        addDiagnostic(
          .noSheetsResolved,
          severity: .warning,
          message:
            "Sheet index \(requestedSheetIndex) is out of bounds (document has \(document.sheets.count) sheets)."
        )
        return IWARealReadResult(sheets: [], structuredDiagnostics: diagnostics)
      }

      var matchedSheet = false
      var seenSheetObjectIDs = Set<UInt64>()
      for (sheetIndex, sheetReference) in document.sheets.enumerated() {
        let sheetObjectID = sheetReference.identifier
        guard sheetObjectID > 0, seenSheetObjectIDs.insert(sheetObjectID).inserted else {
          continue
        }

        let decodedSheet: TN_SheetArchive? = decode(
          objectID: sheetObjectID,
          typeID: TypeID.sheetArchive,
          as: TN_SheetArchive.self
        )
        let sheetName =
          decodedSheet?.name.isEmpty == false ? decodedSheet!.name : "Sheet \(sheetIndex + 1)"

        guard matchesSheet(selector: selector, sheetName: sheetName, sheetIndex: sheetIndex) else {
          continue
        }
        matchedSheet = true

        let drawableRefs = decodedSheet?.drawableInfos ?? []
        let (tableInfoObjectIDs, _) = mergedTableInfoObjectIDs(
          sheetObjectID: sheetObjectID,
          drawableRefs: drawableRefs
        )

        if let requestedTableIndex = selector.tableIndex,
          requestedTableIndex < 0 || requestedTableIndex >= tableInfoObjectIDs.count
        {
          addDiagnostic(
            .noSheetsResolved,
            severity: .warning,
            message:
              "Table index \(requestedTableIndex) is out of bounds for sheet '\(sheetName)' (sheet has \(tableInfoObjectIDs.count) tables)."
          )
          return IWARealReadResult(sheets: [], structuredDiagnostics: diagnostics)
        }

        guard
          let tableInfoObjectID = selectedTableInfoObjectID(
            from: tableInfoObjectIDs,
            selector: selector
          )
        else {
          if let requestedTableName = selector.tableName {
            addDiagnostic(
              .noSheetsResolved,
              severity: .warning,
              message: "Table '\(requestedTableName)' not found in sheet '\(sheetName)'."
            )
          }
          return IWARealReadResult(sheets: [], structuredDiagnostics: diagnostics)
        }

        guard let table = resolveTable(tableInfoObjectID: tableInfoObjectID) else {
          addDiagnostic(
            .tableResolveFailed,
            severity: .warning,
            message: "Failed to resolve selected table.",
            context: ["objectID": String(tableInfoObjectID)]
          )
          break
        }

        emitPivotCandidateSummaryDiagnosticIfNeeded()
        return IWARealReadResult(
          sheets: [
            IWAResolvedSheet(id: "sheet-\(sheetObjectID)", name: sheetName, tables: [table])
          ],
          structuredDiagnostics: diagnostics
        )
      }

      if let requestedSheetName = selector.sheetName, !matchedSheet {
        addDiagnostic(
          .noSheetsResolved,
          severity: .warning,
          message: "Sheet '\(requestedSheetName)' not found."
        )
        return IWARealReadResult(sheets: [], structuredDiagnostics: diagnostics)
      }

      addDiagnostic(
        .noSheetsResolved,
        severity: .warning,
        message: "No table matched the selected sheet/table constraints."
      )
      return IWARealReadResult(sheets: [], structuredDiagnostics: diagnostics)
    }

    private func matchesSheet(
      selector: IWATableSelector,
      sheetName: String,
      sheetIndex: Int
    ) -> Bool {
      if let requestedIndex = selector.sheetIndex {
        return requestedIndex == sheetIndex
      }
      if let requestedName = selector.sheetName {
        return requestedName == sheetName
      }
      return sheetIndex == 0
    }

    private mutating func selectedTableInfoObjectID(
      from tableInfoObjectIDs: [UInt64],
      selector: IWATableSelector
    ) -> UInt64? {
      if let requestedIndex = selector.tableIndex {
        guard requestedIndex >= 0, requestedIndex < tableInfoObjectIDs.count else {
          return nil
        }
        return tableInfoObjectIDs[requestedIndex]
      }

      if let requestedName = selector.tableName {
        for tableInfoObjectID in tableInfoObjectIDs {
          guard
            let summary = resolveTableSummary(
              sheetObjectID: 0,
              sheetID: "",
              sheetName: "",
              sheetIndex: 0,
              tableInfoObjectID: tableInfoObjectID,
              tableIndex: 0
            )
          else {
            continue
          }
          if summary.tableName == requestedName {
            return tableInfoObjectID
          }
        }
        return nil
      }

      return tableInfoObjectIDs.first
    }

    private mutating func selectDocumentObjectID() -> UInt64? {
      let candidateIDs = Set(
        inventory.records.filter { $0.typeID == TypeID.documentArchive }.map(\.objectID))
      let sortedCandidates = candidateIDs.sorted()
      guard !sortedCandidates.isEmpty else {
        return nil
      }

      let rootCandidates = inventory.rootObjectIDs.filter { candidateIDs.contains($0) }.sorted()
      if let root = rootCandidates.first {
        if rootCandidates.count > 1 {
          addDiagnostic(
            .documentCandidateSelectionFallback,
            severity: .info,
            message:
              "Multiple root document candidates found; selecting smallest object identifier.",
            context: [
              "candidateCount": String(rootCandidates.count),
              "selectedObjectID": String(root),
            ]
          )
        }
        addDiagnostic(
          .documentCandidateSelected,
          severity: .info,
          message: "Selected TN.DocumentArchive candidate from root set.",
          context: ["objectID": String(root)]
        )
        return root
      }

      guard let selected = sortedCandidates.first else {
        return nil
      }
      addDiagnostic(
        .documentCandidateSelectionFallback,
        severity: .warning,
        message: "No root TN.DocumentArchive candidate found; selecting deterministic fallback.",
        context: [
          "candidateCount": String(sortedCandidates.count),
          "selectedObjectID": String(selected),
        ]
      )
      return selected
    }

    private mutating func resolveMergedTables(
      sheetObjectID: UInt64,
      drawableRefs refs: [TSP_Reference]
    ) -> [IWAResolvedTable] {
      let (orderedTableInfoObjectIDs, drawableTableInfoObjectIDs) = mergedTableInfoObjectIDs(
        sheetObjectID: sheetObjectID,
        drawableRefs: refs
      )

      var tables: [IWAResolvedTable] = []
      tables.reserveCapacity(orderedTableInfoObjectIDs.count)

      for tableInfoObjectID in orderedTableInfoObjectIDs {
        guard let table = resolveTable(tableInfoObjectID: tableInfoObjectID) else {
          if drawableTableInfoObjectIDs.contains(tableInfoObjectID) {
            addDiagnostic(
              .tableResolveFailed,
              severity: .warning,
              message: "Could not resolve table from sheet drawable reference.",
              context: ["tableInfoObjectID": String(tableInfoObjectID)]
            )
          } else {
            addDiagnostic(
              .tableResolveFailed,
              severity: .warning,
              message: "Could not resolve table during sheet-parent traversal.",
              context: [
                "sheetObjectID": String(sheetObjectID),
                "tableInfoObjectID": String(tableInfoObjectID),
              ]
            )
          }
          continue
        }

        tables.append(table)
      }

      return tables
    }

    private mutating func mergedTableInfoObjectIDs(
      sheetObjectID: UInt64,
      drawableRefs refs: [TSP_Reference]
    ) -> (ordered: [UInt64], drawable: Set<UInt64>) {
      let drawableTableInfoObjectIDs = tableInfoObjectIDsFromDrawableRefs(refs)
      let parentTableInfoObjectIDs = tableInfoObjectIDsByParent(sheetObjectID: sheetObjectID)

      var ordered: [UInt64] = []
      ordered.reserveCapacity(drawableTableInfoObjectIDs.count + parentTableInfoObjectIDs.count)

      var seenTableInfoObjectIDs = Set<UInt64>()
      for tableInfoObjectID in drawableTableInfoObjectIDs
      where seenTableInfoObjectIDs.insert(tableInfoObjectID).inserted {
        ordered.append(tableInfoObjectID)
      }

      for tableInfoObjectID in parentTableInfoObjectIDs
      where seenTableInfoObjectIDs.insert(tableInfoObjectID).inserted {
        ordered.append(tableInfoObjectID)
      }

      return (ordered, Set(drawableTableInfoObjectIDs))
    }

    private mutating func tableInfoObjectIDsFromDrawableRefs(_ refs: [TSP_Reference]) -> [UInt64] {
      let drawableObjectIDs = Set(refs.map(\.identifier).filter { $0 > 0 }).sorted()

      // Pre-scan non-table drawables so table resolution can include pivot linkage metadata
      // regardless of drawable ordering in sheet references.
      for drawableObjectID in drawableObjectIDs
      where !hasRecord(objectID: drawableObjectID, typeID: TypeID.tableInfoArchive) {
        emitPivotCandidateDiagnosticIfNeeded(drawableObjectID: drawableObjectID)
      }

      return drawableObjectIDs.filter {
        hasRecord(objectID: $0, typeID: TypeID.tableInfoArchive)
      }
    }

    private mutating func emitPivotCandidateDiagnosticIfNeeded(drawableObjectID: UInt64) {
      guard !pivotDiagnosticDrawableObjectIDs.contains(drawableObjectID) else {
        return
      }

      guard let drawableRecords = recordsByObjectID[drawableObjectID], !drawableRecords.isEmpty
      else {
        return
      }

      let referencedObjectIDs = Set(
        drawableRecords.flatMap(\.objectReferences).filter { $0 > 0 }
      )
      guard !referencedObjectIDs.isEmpty else {
        return
      }

      let linkedTableInfoObjectIDs =
        referencedObjectIDs
        .filter { hasRecord(objectID: $0, typeID: TypeID.tableInfoArchive) }
        .sorted()
      let linkedTableModelObjectIDs =
        referencedObjectIDs
        .filter { hasRecord(objectID: $0, typeID: TypeID.tableModelArchive) }
        .sorted()

      guard !linkedTableInfoObjectIDs.isEmpty || !linkedTableModelObjectIDs.isEmpty else {
        return
      }

      let drawableTypeIDs = Set(drawableRecords.map(\.typeID)).sorted()
      let context: [String: String] = [
        "drawableObjectID": String(drawableObjectID),
        "drawableTypeIDs": drawableTypeIDs.map(String.init).joined(separator: ","),
        "drawableTypeCount": String(drawableTypeIDs.count),
        "referencedObjectCount": String(referencedObjectIDs.count),
        "linkedTableInfoObjectIDs": linkedTableInfoObjectIDs.map(String.init).joined(
          separator: ","),
        "linkedTableInfoCount": String(linkedTableInfoObjectIDs.count),
        "linkedTableModelObjectIDs": linkedTableModelObjectIDs.map(String.init).joined(
          separator: ","),
        "linkedTableModelCount": String(linkedTableModelObjectIDs.count),
      ]

      addDiagnostic(
        .pivotCandidateDetected,
        severity: .info,
        message:
          "Detected a non-table drawable linked to table objects; this may represent a pivot/analytic view and is treated as read-only in current write paths.",
        objectPath: "sheet-drawable/\(drawableObjectID)",
        suggestion:
          "Inspect structured diagnostics before structural edits and keep linked tables read-only until pivot-preserving writes are enabled.",
        context: context
      )
      let linkage = IWAResolvedPivotLink(
        drawableObjectID: drawableObjectID,
        drawableTypeIDs: drawableTypeIDs,
        linkedTableInfoObjectIDs: linkedTableInfoObjectIDs,
        linkedTableModelObjectIDs: linkedTableModelObjectIDs
      )
      for tableInfoObjectID in linkedTableInfoObjectIDs {
        var linkages = pivotLinksByTableInfoObjectID[tableInfoObjectID] ?? []
        if !linkages.contains(where: { $0.drawableObjectID == linkage.drawableObjectID }) {
          linkages.append(linkage)
          linkages.sort { $0.drawableObjectID < $1.drawableObjectID }
          pivotLinksByTableInfoObjectID[tableInfoObjectID] = linkages
        }
      }
      pivotDiagnosticDrawableObjectIDs.insert(drawableObjectID)
    }

    private mutating func emitPivotCandidateSummaryDiagnosticIfNeeded() {
      let candidateDiagnostics = diagnostics.filter {
        $0.code == DiagnosticCode.pivotCandidateDetected.rawValue
      }
      guard !candidateDiagnostics.isEmpty else {
        return
      }

      var candidateObjectIDs = Set<UInt64>()
      var linkedTableInfoObjectIDs = Set<UInt64>()
      var linkedTableModelObjectIDs = Set<UInt64>()
      for diagnostic in candidateDiagnostics {
        if let rawObjectID = diagnostic.context["drawableObjectID"],
          let objectID = UInt64(rawObjectID)
        {
          candidateObjectIDs.insert(objectID)
        }
        linkedTableInfoObjectIDs.formUnion(
          parseObjectIDs(diagnostic.context["linkedTableInfoObjectIDs"]))
        linkedTableModelObjectIDs.formUnion(
          parseObjectIDs(diagnostic.context["linkedTableModelObjectIDs"]))
      }

      let sortedCandidateObjectIDs = candidateObjectIDs.sorted()
      let sortedLinkedTableInfoObjectIDs = linkedTableInfoObjectIDs.sorted()
      let sortedLinkedTableModelObjectIDs = linkedTableModelObjectIDs.sorted()

      addDiagnostic(
        .pivotCandidateSummary,
        severity: .info,
        message: "Summarized pivot-like drawable links detected during read resolution.",
        suggestion:
          "Use candidate and linked-table identifiers to inspect pivot-linked read-only regions before edits.",
        context: [
          "candidateObjectIDs": sortedCandidateObjectIDs.map(String.init).joined(separator: ","),
          "candidateCount": String(sortedCandidateObjectIDs.count),
          "linkedTableInfoObjectIDs": sortedLinkedTableInfoObjectIDs.map(String.init).joined(
            separator: ","),
          "linkedTableInfoCount": String(sortedLinkedTableInfoObjectIDs.count),
          "linkedTableModelObjectIDs": sortedLinkedTableModelObjectIDs.map(String.init).joined(
            separator: ","),
          "linkedTableModelCount": String(sortedLinkedTableModelObjectIDs.count),
        ]
      )
    }

    private func parseObjectIDs(_ rawValue: String?) -> Set<UInt64> {
      guard let rawValue else {
        return []
      }

      var objectIDs = Set<UInt64>()
      for token in rawValue.split(separator: ",") {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if let objectID = UInt64(trimmed), objectID > 0 {
          objectIDs.insert(objectID)
        }
      }
      return objectIDs
    }

    private func hasRecord(objectID: UInt64, typeID: UInt32) -> Bool {
      recordsByObjectID[objectID]?.contains(where: { $0.typeID == typeID }) == true
    }

    private mutating func tableInfoObjectIDsByParent(sheetObjectID: UInt64) -> [UInt64] {
      var tableInfoObjectIDs: [UInt64] = []

      let candidateTableInfoObjectIDs = Set(
        inventory.records.filter { $0.typeID == TypeID.tableInfoArchive }.map(\.objectID))
      for tableInfoObjectID in candidateTableInfoObjectIDs.sorted() {
        guard
          let tableInfo: TST_TableInfoArchive = decode(
            objectID: tableInfoObjectID,
            typeID: TypeID.tableInfoArchive,
            as: TST_TableInfoArchive.self
          )
        else {
          continue
        }

        guard tableInfo.hasSuper,
          tableInfo.super.hasParent,
          tableInfo.super.parent.identifier == sheetObjectID
        else {
          continue
        }

        tableInfoObjectIDs.append(tableInfoObjectID)
      }

      return tableInfoObjectIDs
    }

    private func resolveTableSummary(
      sheetObjectID: UInt64,
      sheetID: String,
      sheetName: String,
      sheetIndex: Int,
      tableInfoObjectID: UInt64,
      tableIndex: Int
    ) -> IWAResolvedTableSummary? {
      guard tableInfoObjectID > 0 else {
        return nil
      }

      guard
        let tableInfo: TST_TableInfoArchive = decode(
          objectID: tableInfoObjectID,
          typeID: TypeID.tableInfoArchive,
          as: TST_TableInfoArchive.self
        ),
        tableInfo.hasTableModel
      else {
        return nil
      }

      let tableModelObjectID = tableInfo.tableModel.identifier
      guard tableModelObjectID > 0 else {
        return nil
      }

      guard
        let tableModel: TST_TableModelArchive = decode(
          objectID: tableModelObjectID,
          typeID: TypeID.tableModelArchive,
          as: TST_TableModelArchive.self
        )
      else {
        return nil
      }

      let tableID = tableModel.tableID.isEmpty ? String(tableModelObjectID) : tableModel.tableID
      let tableName = tableModel.tableName.isEmpty ? "Table \(tableID)" : tableModel.tableName
      let caption = resolveCaptionMetadata(drawable: tableInfo.super)

      return IWAResolvedTableSummary(
        sheetObjectID: sheetObjectID,
        sheetID: sheetID,
        sheetName: sheetName,
        sheetIndex: sheetIndex,
        tableInfoObjectID: tableInfoObjectID,
        tableModelObjectID: tableModelObjectID,
        tableID: tableID,
        tableName: tableName,
        tableIndex: tableIndex,
        rowCount: Int(tableModel.numberOfRows),
        columnCount: Int(tableModel.numberOfColumns),
        headerRowCount: Int(tableModel.numberOfHeaderRows),
        headerColumnCount: Int(tableModel.numberOfHeaderColumns),
        tableNameVisible: tableModel.hasTableNameEnabled ? tableModel.tableNameEnabled : nil,
        captionVisible: tableInfo.super.hasCaptionHidden ? !tableInfo.super.captionHidden : nil,
        captionText: caption.text,
        captionTextSupported: caption.isSupported
      )
    }

    private mutating func resolveTable(tableInfoObjectID: UInt64) -> IWAResolvedTable? {
      guard tableInfoObjectID > 0 else {
        return nil
      }
      if let cached = resolvedTableCache[tableInfoObjectID] {
        return cached
      }
      if unresolvedTableObjectIDs.contains(tableInfoObjectID) {
        return nil
      }

      guard
        let tableInfo: TST_TableInfoArchive = decode(
          objectID: tableInfoObjectID,
          typeID: TypeID.tableInfoArchive,
          as: TST_TableInfoArchive.self
        )
      else {
        unresolvedTableObjectIDs.insert(tableInfoObjectID)
        return nil
      }

      guard tableInfo.hasTableModel else {
        unresolvedTableObjectIDs.insert(tableInfoObjectID)
        return nil
      }

      let tableModelObjectID = tableInfo.tableModel.identifier
      guard tableModelObjectID > 0 else {
        unresolvedTableObjectIDs.insert(tableInfoObjectID)
        return nil
      }

      guard
        let tableModel: TST_TableModelArchive = decode(
          objectID: tableModelObjectID,
          typeID: TypeID.tableModelArchive,
          as: TST_TableModelArchive.self
        )
      else {
        unresolvedTableObjectIDs.insert(tableInfoObjectID)
        return nil
      }

      let tableID = tableModel.tableID.isEmpty ? String(tableModelObjectID) : tableModel.tableID
      let tableName = tableModel.tableName.isEmpty ? "Table \(tableID)" : tableModel.tableName
      let rowCount = Int(tableModel.numberOfRows)
      let columnCount = Int(tableModel.numberOfColumns)
      let headerRowCount = Int(tableModel.numberOfHeaderRows)
      let headerColumnCount = Int(tableModel.numberOfHeaderColumns)
      let dataStore = tableModel.baseDataStore
      let rowHeights = decodeRowHeaderSizes(dataStore.rowHeaders, rowCount: rowCount)
      let columnWidths = decodeColumnHeaderSizes(
        dataStore.columnHeaders,
        columnCount: columnCount
      )
      let tableNameVisible = tableModel.hasTableNameEnabled ? tableModel.tableNameEnabled : nil
      let captionVisible =
        features.contains(.captions)
        ? (tableInfo.super.hasCaptionHidden ? !tableInfo.super.captionHidden : nil)
        : nil
      let caption =
        features.contains(.captions)
        ? resolveCaptionMetadata(drawable: tableInfo.super)
        : ResolvedCaptionMetadata(text: nil, isSupported: false)

      let stringLookup = decodeStringTable(dataStore.stringTable)
      let formulaLookup =
        features.contains(.formulas) ? decodeFormulaTable(dataStore.formulaTable) : [:]
      let styleObjectByID =
        features.contains(.styles) ? decodeStyleTable(dataStore.styleTable) : [:]
      let richTextPayloadByID =
        features.contains(.richText) ? decodeRichTextPayloadTable(dataStore.richTextTable) : [:]
      let styleDefaults = TableStyleDefaults(
        rowCount: rowCount,
        headerRows: Int(tableModel.numberOfHeaderRows),
        headerColumns: Int(tableModel.numberOfHeaderColumns),
        footerRows: Int(tableModel.numberOfFooterRows),
        bodyCellStyleObjectID: tableModel.bodyCellStyle.identifier,
        headerRowStyleObjectID: tableModel.headerRowStyle.identifier,
        headerColumnStyleObjectID: tableModel.headerColumnStyle.identifier,
        footerRowStyleObjectID: tableModel.footerRowStyle.identifier,
        bodyTextStyleObjectID: tableModel.bodyTextStyle.identifier,
        headerRowTextStyleObjectID: tableModel.headerRowTextStyle.identifier,
        headerColumnTextStyleObjectID: tableModel.headerColumnTextStyle.identifier,
        footerRowTextStyleObjectID: tableModel.footerRowTextStyle.identifier
      )
      let rowBuffers = decodeRowBuffers(
        dataStore.tiles,
        columnCount: columnCount
      )
      let rowStorageMap = decodeRowStorageMap(
        dataStore.rowHeaders,
        rowCount: rowCount,
        rowBufferCount: rowBuffers.count
      )

      let decodeResult = decodeCells(
        rowStorageMap: rowStorageMap,
        rowBuffers: rowBuffers,
        rowCount: rowCount,
        columnCount: columnCount,
        stringLookup: stringLookup,
        formulaLookup: formulaLookup,
        styleObjectByID: styleObjectByID,
        richTextPayloadByID: richTextPayloadByID,
        styleDefaults: styleDefaults,
        cellWindow: cellWindow,
        features: features
      )
      if !decodeResult.droppedCellTypeCounts.isEmpty {
        for (cellType, count) in decodeResult.droppedCellTypeCounts.sorted(by: { $0.key < $1.key })
        {
          addDiagnostic(
            .unsupportedCellTypeDropped,
            severity: .warning,
            message: "Dropped cells with unsupported/undecodable cell type during real-read.",
            objectPath: "table/\(tableID)",
            suggestion: "Use metadata fallback dump and share fixture to extend typed decode.",
            context: [
              "tableID": tableID,
              "tableName": tableName,
              "cellType": String(cellType),
              "count": String(count),
            ]
          )
        }
      }
      if !decodeResult.formulaUnsupportedNodeCounts.isEmpty {
        for nodeType in decodeResult.formulaUnsupportedNodeCounts.keys.sorted() {
          addDiagnostic(
            .formulaUnsupportedAstNodes,
            severity: .warning,
            message:
              "Encountered unsupported formula AST nodes; using best-effort fallback rendering.",
            objectPath: "table/\(tableID)",
            suggestion: "Extend TSCE AST decode for full formula fidelity on advanced functions.",
            context: [
              "tableID": tableID,
              "tableName": tableName,
              "affectedFormulaCells": String(decodeResult.formulasWithUnsupportedNodes),
              "fallbackFormulaCells": String(decodeResult.formulasUsingFallback),
              "unsupportedNodeType": nodeType,
              "unsupportedNodeCount": String(
                decodeResult.formulaUnsupportedNodeCounts[nodeType] ?? 0),
            ]
          )
        }
      }
      let cells = decodeResult.cells
      let merges =
        features.contains(.merges) ? decodeMergeRanges(dataStore.mergeRegionMap) : []

      let resolved = IWAResolvedTable(
        id: tableID,
        name: tableName,
        tableInfoObjectID: tableInfoObjectID,
        tableModelObjectID: tableModelObjectID,
        rowCount: rowCount,
        columnCount: columnCount,
        headerRowCount: headerRowCount,
        headerColumnCount: headerColumnCount,
        rowHeights: rowHeights,
        columnWidths: columnWidths,
        merges: merges,
        tableNameVisible: tableNameVisible,
        captionVisible: captionVisible,
        captionText: caption.text,
        captionTextSupported: caption.isSupported,
        pivotLinks: pivotLinksByTableInfoObjectID[tableInfoObjectID] ?? [],
        cells: cells
      )
      resolvedTableCache[tableInfoObjectID] = resolved
      return resolved
    }

    private struct ResolvedCaptionMetadata {
      let text: String?
      let isSupported: Bool
    }

    private func resolveCaptionMetadata(drawable: TSD_DrawableArchive) -> ResolvedCaptionMetadata {
      guard drawable.hasCaption else {
        return ResolvedCaptionMetadata(text: nil, isSupported: false)
      }

      let captionObjectID = drawable.caption.identifier
      guard captionObjectID > 0 else {
        return ResolvedCaptionMetadata(text: nil, isSupported: false)
      }

      guard let storageObjectID = resolveCaptionStorageObjectID(captionObjectID: captionObjectID)
      else {
        return ResolvedCaptionMetadata(text: nil, isSupported: false)
      }

      guard
        let storage: TSWP_StorageArchive = decodeAnyType(
          objectID: storageObjectID,
          typeIDs: [TypeID.wpStorageArchive, TypeID.wpStorageArchiveAlt],
          as: TSWP_StorageArchive.self
        )
      else {
        return ResolvedCaptionMetadata(text: nil, isSupported: false)
      }

      return ResolvedCaptionMetadata(text: storage.text.first ?? "", isSupported: true)
    }

    private func resolveCaptionStorageObjectID(captionObjectID: UInt64) -> UInt64? {
      if decodeAnyType(
        objectID: captionObjectID,
        typeIDs: [TypeID.wpStorageArchive, TypeID.wpStorageArchiveAlt],
        as: TSWP_StorageArchive.self
      ) != nil {
        return captionObjectID
      }

      if let captionInfo: TSWP_CaptionInfoArchiveProxy = decode(
        objectID: captionObjectID,
        typeID: TypeID.captionInfoArchive,
        as: TSWP_CaptionInfoArchiveProxy.self
      ),
        captionInfo.hasSuper,
        captionInfo.super.hasOwnedStorage
      {
        let storageObjectID = captionInfo.super.ownedStorage.identifier
        return storageObjectID > 0 ? storageObjectID : nil
      }

      if hasRecord(objectID: captionObjectID, typeID: TypeID.standinCaptionArchive) {
        return nil
      }

      return nil
    }

    private func decodeStringTable(_ reference: TSP_Reference) -> [UInt32: String] {
      let objectID = reference.identifier
      guard objectID > 0 else {
        return [:]
      }

      guard
        let tableDataList: TST_TableDataList = decode(
          objectID: objectID,
          typeID: TypeID.tableDataList,
          as: TST_TableDataList.self
        )
      else {
        return [:]
      }

      var lookup: [UInt32: String] = [:]
      for entry in tableDataList.entries where entry.hasStringValue {
        lookup[entry.key] = entry.stringValue
      }

      for segmentRef in tableDataList.segments {
        let segmentObjectID = segmentRef.identifier
        guard segmentObjectID > 0 else {
          continue
        }

        guard
          let segment: TST_TableDataListSegment = decode(
            objectID: segmentObjectID,
            typeID: TypeID.tableDataListSegment,
            as: TST_TableDataListSegment.self
          )
        else {
          continue
        }

        for entry in segment.entries where entry.hasStringValue {
          lookup[entry.key] = entry.stringValue
        }
      }

      return lookup
    }

    private struct DecodedFormula: Sendable {
      let rawFormula: String?
      let tokens: [String]
      let astSummary: String?
      let unsupportedNodeCounts: [String: Int]
      let usedUnsupportedFallback: Bool
    }

    private func decodeFormulaTable(_ reference: TSP_Reference) -> [Int32: TSCE_FormulaArchive] {
      let objectID = reference.identifier
      guard objectID > 0 else {
        return [:]
      }

      guard
        let tableDataList: TST_TableDataList = decode(
          objectID: objectID,
          typeID: TypeID.tableDataList,
          as: TST_TableDataList.self
        )
      else {
        return [:]
      }

      var lookup: [Int32: TSCE_FormulaArchive] = [:]
      for entry in tableDataList.entries where entry.hasFormula {
        let formulaID = Int32(clamping: entry.key)
        lookup[formulaID] = entry.formula
      }

      for segmentRef in tableDataList.segments {
        let segmentObjectID = segmentRef.identifier
        guard segmentObjectID > 0 else {
          continue
        }

        guard
          let segment: TST_TableDataListSegment = decode(
            objectID: segmentObjectID,
            typeID: TypeID.tableDataListSegment,
            as: TST_TableDataListSegment.self
          )
        else {
          continue
        }

        for entry in segment.entries where entry.hasFormula {
          let formulaID = Int32(clamping: entry.key)
          lookup[formulaID] = entry.formula
        }
      }

      return lookup
    }

    private func decodeStyleTable(_ reference: TSP_Reference) -> [Int32: UInt64] {
      let objectID = reference.identifier
      guard objectID > 0 else {
        return [:]
      }

      guard
        let tableDataList: TST_TableDataList = decode(
          objectID: objectID,
          typeID: TypeID.tableDataList,
          as: TST_TableDataList.self
        )
      else {
        return [:]
      }

      var lookup: [Int32: UInt64] = [:]
      for entry in tableDataList.entries where entry.hasReference {
        let key = Int32(clamping: entry.key)
        let styleObjectID = entry.reference.identifier
        guard styleObjectID > 0 else {
          continue
        }
        lookup[key] = styleObjectID
      }

      for segmentRef in tableDataList.segments {
        let segmentObjectID = segmentRef.identifier
        guard segmentObjectID > 0 else {
          continue
        }

        guard
          let segment: TST_TableDataListSegment = decode(
            objectID: segmentObjectID,
            typeID: TypeID.tableDataListSegment,
            as: TST_TableDataListSegment.self
          )
        else {
          continue
        }

        for entry in segment.entries where entry.hasReference {
          let key = Int32(clamping: entry.key)
          let styleObjectID = entry.reference.identifier
          guard styleObjectID > 0 else {
            continue
          }
          lookup[key] = styleObjectID
        }
      }

      return lookup
    }

    private func decodeRichTextPayloadTable(_ reference: TSP_Reference) -> [Int32: UInt64] {
      let objectID = reference.identifier
      guard objectID > 0 else {
        return [:]
      }

      guard
        let tableDataList: TST_TableDataList = decode(
          objectID: objectID,
          typeID: TypeID.tableDataList,
          as: TST_TableDataList.self
        )
      else {
        return [:]
      }

      var lookup: [Int32: UInt64] = [:]
      for entry in tableDataList.entries where entry.hasRichTextPayload {
        let key = Int32(clamping: entry.key)
        let payloadObjectID = entry.richTextPayload.identifier
        guard payloadObjectID > 0 else {
          continue
        }
        lookup[key] = payloadObjectID
      }

      for segmentRef in tableDataList.segments {
        let segmentObjectID = segmentRef.identifier
        guard segmentObjectID > 0 else {
          continue
        }

        guard
          let segment: TST_TableDataListSegment = decode(
            objectID: segmentObjectID,
            typeID: TypeID.tableDataListSegment,
            as: TST_TableDataListSegment.self
          )
        else {
          continue
        }

        for entry in segment.entries where entry.hasRichTextPayload {
          let key = Int32(clamping: entry.key)
          let payloadObjectID = entry.richTextPayload.identifier
          guard payloadObjectID > 0 else {
            continue
          }
          lookup[key] = payloadObjectID
        }
      }

      return lookup
    }

    private func decodeFormula(
      archive: TSCE_FormulaArchive,
      hostRow: Int,
      hostColumn: Int
    ) -> DecodedFormula {
      let nodes = archive.astNodeArray.nodes
      guard !nodes.isEmpty else {
        return DecodedFormula(
          rawFormula: nil,
          tokens: [],
          astSummary: "Decoded TSCE AST (0 nodes)",
          unsupportedNodeCounts: [:],
          usedUnsupportedFallback: false
        )
      }

      let nodeNames = nodes.map { IWARealDocumentReader.nodeTypeName($0.nodeType) }
      let astSummary =
        "Decoded TSCE AST (\(nodes.count) nodes): \(nodeNames.joined(separator: " -> "))"
      let render = IWARealDocumentReader.renderFormulaDetailed(
        nodes: nodes,
        hostRow: hostRow,
        hostColumn: hostColumn
      )
      let raw: String? = {
        guard let rendered = render.rendered, !rendered.isEmpty else {
          return nil
        }
        if rendered.hasPrefix("=") {
          return rendered
        }
        return "=" + rendered
      }()
      let tokens = raw.map(IWARealDocumentReader.tokenizeFormula) ?? []

      return DecodedFormula(
        rawFormula: raw,
        tokens: tokens,
        astSummary: astSummary,
        unsupportedNodeCounts: render.unsupportedNodeCounts,
        usedUnsupportedFallback: render.usedUnsupportedFallback
      )
    }

    private mutating func decodeRowStorageMap(
      _ headerStorage: TST_HeaderStorage,
      rowCount: Int,
      rowBufferCount: Int
    ) -> [Int?] {
      guard rowCount > 0 else {
        return []
      }

      var rowStorageMap = [Int?](repeating: nil, count: rowCount)
      var sequentialStorageIndex = 0

      for bucketRef in headerStorage.buckets {
        let bucketObjectID = bucketRef.identifier
        guard bucketObjectID > 0 else {
          continue
        }

        guard
          let bucket: TST_HeaderStorageBucket = decode(
            objectID: bucketObjectID,
            typeID: TypeID.headerStorageBucket,
            as: TST_HeaderStorageBucket.self
          )
        else {
          continue
        }

        for header in bucket.headers {
          let rowIndex = Int(header.index)
          guard rowIndex >= 0, rowIndex < rowStorageMap.count else {
            continue
          }
          rowStorageMap[rowIndex] = sequentialStorageIndex
          sequentialStorageIndex += 1
        }
      }

      var patchedRows = 0
      if rowBufferCount > 0 {
        for index in 0..<rowStorageMap.count where rowStorageMap[index] == nil {
          guard sequentialStorageIndex < rowBufferCount else {
            break
          }
          rowStorageMap[index] = sequentialStorageIndex
          sequentialStorageIndex += 1
          patchedRows += 1
        }
      }

      if patchedRows > 0 {
        addDiagnostic(
          .rowStorageMapPatched,
          severity: .info,
          message:
            "Patched row storage mapping with sequential fallback for missing header entries.",
          context: [
            "patchedRows": String(patchedRows),
            "rowCount": String(rowCount),
            "rowBufferCount": String(rowBufferCount),
          ]
        )
      }

      return rowStorageMap
    }

    private func decodeRowHeaderSizes(
      _ headerStorage: TST_HeaderStorage,
      rowCount: Int
    ) -> [Double?] {
      guard rowCount > 0 else {
        return []
      }
      var sizes = [Double?](repeating: nil, count: rowCount)

      for bucketRef in headerStorage.buckets {
        let bucketObjectID = bucketRef.identifier
        guard bucketObjectID > 0 else {
          continue
        }
        guard
          let bucket: TST_HeaderStorageBucket = decode(
            objectID: bucketObjectID,
            typeID: TypeID.headerStorageBucket,
            as: TST_HeaderStorageBucket.self
          )
        else {
          continue
        }
        for header in bucket.headers where header.hasSize {
          let rowIndex = Int(header.index)
          guard rowIndex >= 0, rowIndex < sizes.count else {
            continue
          }
          sizes[rowIndex] = Double(header.size)
        }
      }

      return sizes
    }

    private func decodeColumnHeaderSizes(
      _ columnHeadersRef: TSP_Reference,
      columnCount: Int
    ) -> [Double?] {
      guard columnCount > 0 else {
        return []
      }

      var sizes = [Double?](repeating: nil, count: columnCount)
      let bucketObjectID = columnHeadersRef.identifier
      guard bucketObjectID > 0 else {
        return sizes
      }
      guard
        let bucket: TST_HeaderStorageBucket = decode(
          objectID: bucketObjectID,
          typeID: TypeID.headerStorageBucket,
          as: TST_HeaderStorageBucket.self
        )
      else {
        return sizes
      }

      for header in bucket.headers where header.hasSize {
        let columnIndex = Int(header.index)
        guard columnIndex >= 0, columnIndex < sizes.count else {
          continue
        }
        sizes[columnIndex] = Double(header.size)
      }

      return sizes
    }

    private func decodeRowBuffers(_ tileStorage: TST_TileStorage, columnCount: Int) -> [[Data?]] {
      var allRows: [[Data?]] = []

      for tileRef in tileStorage.tiles {
        let tileObjectID = tileRef.tile.identifier
        guard tileObjectID > 0 else {
          continue
        }

        guard
          let tile: TST_Tile = decode(
            objectID: tileObjectID,
            typeID: TypeID.tileArchive,
            as: TST_Tile.self
          )
        else {
          continue
        }

        for rowInfo in tile.rowInfos {
          let storageBuffer =
            rowInfo.cellStorageBuffer.isEmpty
            ? rowInfo.cellStorageBufferPreBnc : rowInfo.cellStorageBuffer
          let offsetsBuffer =
            rowInfo.cellOffsets.isEmpty ? rowInfo.cellOffsetsPreBnc : rowInfo.cellOffsets

          if storageBuffer.isEmpty || offsetsBuffer.isEmpty {
            allRows.append([Data?](repeating: nil, count: max(columnCount, 0)))
            continue
          }

          var row = splitRowStorageBuffers(
            storageBuffer: storageBuffer,
            offsetsBuffer: offsetsBuffer,
            columnCount: columnCount,
            hasWideOffsets: rowInfo.hasHasWideOffsets_p ? rowInfo.hasWideOffsets_p : false
          )
          if row.count < columnCount {
            row.append(contentsOf: repeatElement(nil, count: columnCount - row.count))
          }
          allRows.append(row)
        }
      }

      return allRows
    }

    private struct TableStyleDefaults {
      let rowCount: Int
      let headerRows: Int
      let headerColumns: Int
      let footerRows: Int
      let bodyCellStyleObjectID: UInt64
      let headerRowStyleObjectID: UInt64
      let headerColumnStyleObjectID: UInt64
      let footerRowStyleObjectID: UInt64
      let bodyTextStyleObjectID: UInt64
      let headerRowTextStyleObjectID: UInt64
      let headerColumnTextStyleObjectID: UInt64
      let footerRowTextStyleObjectID: UInt64

      func defaultCellStyleObjectID(row: Int, column: Int) -> UInt64? {
        if row < max(headerRows, 0), headerRowStyleObjectID > 0 {
          return headerRowStyleObjectID
        }
        if column < max(headerColumns, 0), headerColumnStyleObjectID > 0 {
          return headerColumnStyleObjectID
        }
        let footerStart = max(rowCount - max(footerRows, 0), 0)
        if row >= footerStart, footerRows > 0, footerRowStyleObjectID > 0 {
          return footerRowStyleObjectID
        }
        return bodyCellStyleObjectID > 0 ? bodyCellStyleObjectID : nil
      }

      func defaultTextStyleObjectID(row: Int, column: Int) -> UInt64? {
        if row < max(headerRows, 0), headerRowTextStyleObjectID > 0 {
          return headerRowTextStyleObjectID
        }
        if column < max(headerColumns, 0), headerColumnTextStyleObjectID > 0 {
          return headerColumnTextStyleObjectID
        }
        let footerStart = max(rowCount - max(footerRows, 0), 0)
        if row >= footerStart, footerRows > 0, footerRowTextStyleObjectID > 0 {
          return footerRowTextStyleObjectID
        }
        return bodyTextStyleObjectID > 0 ? bodyTextStyleObjectID : nil
      }
    }

    private struct DecodedTextStyle {
      let horizontalAlignment: IWAResolvedHorizontalAlignment?
      let fontName: String?
      let fontSize: Double?
      let isBold: Bool?
      let isItalic: Bool?
      let textColorHex: String?
    }

    private struct DecodedCellStyle {
      let verticalAlignment: IWAResolvedVerticalAlignment?
      let backgroundColorHex: String?
      let hasTopBorder: Bool
      let hasRightBorder: Bool
      let hasBottomBorder: Bool
      let hasLeftBorder: Bool
    }

    private struct RichTextLinkSpan {
      let start: Int
      let end: Int
      let url: String
    }

    private func decodeCellStyleObject(_ objectID: UInt64) -> DecodedCellStyle? {
      guard objectID > 0 else {
        return nil
      }

      guard
        let styleArchive: TST_CellStyleArchive = decode(
          objectID: objectID,
          typeID: TypeID.cellStyleArchive,
          as: TST_CellStyleArchive.self
        ),
        styleArchive.hasCellProperties
      else {
        return nil
      }

      let properties = styleArchive.cellProperties
      let verticalAlignment: IWAResolvedVerticalAlignment? = {
        guard properties.hasVerticalAlignment else {
          return nil
        }
        switch properties.verticalAlignment {
        case 0:
          return .top
        case 1:
          return .middle
        case 2:
          return .bottom
        default:
          return .unknown(properties.verticalAlignment)
        }
      }()

      return DecodedCellStyle(
        verticalAlignment: verticalAlignment,
        backgroundColorHex: colorHex(properties.cellFill.color),
        hasTopBorder: properties.hasTopStroke,
        hasRightBorder: properties.hasRightStroke,
        hasBottomBorder: properties.hasBottomStroke,
        hasLeftBorder: properties.hasLeftStroke
      )
    }

    private func decodeParagraphTextStyleObject(_ objectID: UInt64) -> DecodedTextStyle? {
      guard objectID > 0 else {
        return nil
      }

      guard
        let styleArchive: TSWP_ParagraphStyleArchive = decode(
          objectID: objectID,
          typeID: TypeID.wpParagraphStyleArchive,
          as: TSWP_ParagraphStyleArchive.self
        )
      else {
        return nil
      }

      let horizontalAlignment: IWAResolvedHorizontalAlignment? = {
        guard styleArchive.hasParaProperties, styleArchive.paraProperties.hasAlignment else {
          return nil
        }
        switch styleArchive.paraProperties.alignment {
        case 0:
          return .left
        case 1:
          return .right
        case 2:
          return .center
        case 3:
          return .justified
        case 4:
          return .natural
        default:
          return .unknown(styleArchive.paraProperties.alignment)
        }
      }()

      let charProps =
        styleArchive.hasCharProperties
        ? styleArchive.charProperties
        : TSWP_CharacterStylePropertiesArchive()

      return DecodedTextStyle(
        horizontalAlignment: horizontalAlignment,
        fontName: charProps.hasFontName && !charProps.fontNameNull ? charProps.fontName : nil,
        fontSize: charProps.hasFontSize ? Double(charProps.fontSize) : nil,
        isBold: charProps.hasBold ? charProps.bold : nil,
        isItalic: charProps.hasItalic ? charProps.italic : nil,
        textColorHex: colorHex(charProps.fontColor)
      )
    }

    private func decodeCharacterStyleObject(_ objectID: UInt64) -> DecodedTextStyle? {
      guard objectID > 0 else {
        return nil
      }

      guard
        let styleArchive: TSWP_CharacterStyleArchive = decode(
          objectID: objectID,
          typeID: TypeID.wpCharacterStyleArchive,
          as: TSWP_CharacterStyleArchive.self
        ),
        styleArchive.hasCharProperties
      else {
        return nil
      }

      let charProps = styleArchive.charProperties
      return DecodedTextStyle(
        horizontalAlignment: nil,
        fontName: charProps.hasFontName && !charProps.fontNameNull ? charProps.fontName : nil,
        fontSize: charProps.hasFontSize ? Double(charProps.fontSize) : nil,
        isBold: charProps.hasBold ? charProps.bold : nil,
        isItalic: charProps.hasItalic ? charProps.italic : nil,
        textColorHex: colorHex(charProps.fontColor)
      )
    }

    private func decodeHyperlinkURL(_ objectID: UInt64) -> String? {
      guard objectID > 0 else {
        return nil
      }

      if let link: TSWP_HyperlinkFieldArchive = decode(
        objectID: objectID,
        typeID: TypeID.wpHyperlinkFieldArchive,
        as: TSWP_HyperlinkFieldArchive.self
      ),
        !link.urlRef.isEmpty
      {
        return link.urlRef
      }

      if let link: TSWP_UnsupportedHyperlinkFieldArchive = decode(
        objectID: objectID,
        typeID: TypeID.wpUnsupportedHyperlinkFieldArchive,
        as: TSWP_UnsupportedHyperlinkFieldArchive.self
      ),
        !link.urlRef.isEmpty
      {
        return link.urlRef
      }

      return nil
    }

    private func decodeRichText(
      richTextID: Int32?,
      payloadObjectByID: [Int32: UInt64]
    ) -> IWAResolvedRichText? {
      guard
        let richTextID,
        richTextID >= 0,
        let payloadObjectID = payloadObjectByID[richTextID],
        payloadObjectID > 0
      else {
        return nil
      }

      guard
        let payload: TST_RichTextPayloadArchive = decode(
          objectID: payloadObjectID,
          typeID: TypeID.richTextPayloadArchive,
          as: TST_RichTextPayloadArchive.self
        ),
        payload.hasStorage,
        payload.storage.identifier > 0
      else {
        return nil
      }

      guard
        let storage: TSWP_StorageArchive = decodeAnyType(
          objectID: payload.storage.identifier,
          typeIDs: [TypeID.wpStorageArchive, TypeID.wpStorageArchiveAlt],
          as: TSWP_StorageArchive.self
        )
      else {
        return nil
      }

      let mergedText = storage.text.joined()
      guard !mergedText.isEmpty else {
        return IWAResolvedRichText(text: "", runs: [])
      }

      let textLength = mergedText.count
      let charStyleEntries = storage.tableCharStyle.entries.sorted { lhs, rhs in
        lhs.characterIndex < rhs.characterIndex
      }

      let smartFieldEntries = storage.tableSmartfield.entries.sorted { lhs, rhs in
        lhs.characterIndex < rhs.characterIndex
      }

      var linkSpans: [RichTextLinkSpan] = []
      for (index, entry) in smartFieldEntries.enumerated() {
        let objectID = entry.object.identifier
        guard objectID > 0, let url = decodeHyperlinkURL(objectID), !url.isEmpty else {
          continue
        }
        let start = min(Int(entry.characterIndex), textLength)
        let end: Int
        if index + 1 < smartFieldEntries.count {
          end = min(Int(smartFieldEntries[index + 1].characterIndex), textLength)
        } else {
          end = textLength
        }
        guard start < end else {
          continue
        }
        linkSpans.append(RichTextLinkSpan(start: start, end: end, url: url))
      }

      func linkURL(at charIndex: Int) -> String? {
        for span in linkSpans where charIndex >= span.start && charIndex < span.end {
          return span.url
        }
        return nil
      }

      var runs: [IWAResolvedRichTextRun] = []
      if charStyleEntries.isEmpty {
        runs.append(
          IWAResolvedRichTextRun(
            start: 0,
            end: textLength,
            text: mergedText,
            linkURL: linkURL(at: 0)
          ))
        return IWAResolvedRichText(text: mergedText, runs: runs)
      }

      for index in 0..<charStyleEntries.count {
        let entry = charStyleEntries[index]
        let start = min(Int(entry.characterIndex), textLength)
        let end: Int
        if index + 1 < charStyleEntries.count {
          end = min(Int(charStyleEntries[index + 1].characterIndex), textLength)
        } else {
          end = textLength
        }
        guard start < end else {
          continue
        }

        let styleObjectID = entry.object.identifier
        let textStyle = decodeCharacterStyleObject(styleObjectID)
        let runText = substring(mergedText, start: start, end: end)
        runs.append(
          IWAResolvedRichTextRun(
            start: start,
            end: end,
            text: runText,
            fontName: textStyle?.fontName,
            fontSize: textStyle?.fontSize,
            isBold: textStyle?.isBold,
            isItalic: textStyle?.isItalic,
            textColorHex: textStyle?.textColorHex,
            linkURL: linkURL(at: start)
          ))
      }

      if runs.isEmpty {
        runs.append(
          IWAResolvedRichTextRun(
            start: 0,
            end: textLength,
            text: mergedText,
            linkURL: linkURL(at: 0)
          ))
      }

      return IWAResolvedRichText(text: mergedText, runs: runs)
    }

    private func resolvedNumberFormat(from decoded: DecodedCellStorage) -> IWAResolvedNumberFormat?
    {
      if let formatID = decoded.textFormatID {
        return IWAResolvedNumberFormat(kind: .text, formatID: formatID)
      }
      if let formatID = decoded.currencyFormatID {
        return IWAResolvedNumberFormat(kind: .currency, formatID: formatID)
      }
      if let formatID = decoded.boolFormatID {
        return IWAResolvedNumberFormat(kind: .bool, formatID: formatID)
      }
      if let formatID = decoded.numberFormatID {
        return IWAResolvedNumberFormat(kind: .number, formatID: formatID)
      }
      if let formatID = decoded.dateFormatID {
        return IWAResolvedNumberFormat(kind: .date, formatID: formatID)
      }
      if let formatID = decoded.durationFormatID {
        return IWAResolvedNumberFormat(kind: .duration, formatID: formatID)
      }
      return nil
    }

    private func colorHex(_ color: TSP_Color?) -> String? {
      IWARealDocumentReader.colorHex(color)
    }

    private func substring(_ text: String, start: Int, end: Int) -> String {
      IWARealDocumentReader.substring(text, start: start, end: end)
    }

    private struct DecodedCellsResult {
      let cells: [IWAResolvedCell]
      let droppedCellTypeCounts: [UInt8: Int]
      let formulaUnsupportedNodeCounts: [String: Int]
      let formulasWithUnsupportedNodes: Int
      let formulasUsingFallback: Int
    }

    private func decodeCells(
      rowStorageMap: [Int?],
      rowBuffers: [[Data?]],
      rowCount: Int,
      columnCount: Int,
      stringLookup: [UInt32: String],
      formulaLookup: [Int32: TSCE_FormulaArchive],
      styleObjectByID: [Int32: UInt64],
      richTextPayloadByID: [Int32: UInt64],
      styleDefaults: TableStyleDefaults,
      cellWindow: IWACellWindow?,
      features: IWAReadFeatures
    ) -> DecodedCellsResult {
      guard rowCount > 0, columnCount > 0 else {
        return DecodedCellsResult(
          cells: [],
          droppedCellTypeCounts: [:],
          formulaUnsupportedNodeCounts: [:],
          formulasWithUnsupportedNodes: 0,
          formulasUsingFallback: 0
        )
      }

      var cells: [IWAResolvedCell] = []
      cells.reserveCapacity(min(rowCount * columnCount, 1024))
      var droppedCellTypeCounts: [UInt8: Int] = [:]
      var formulaUnsupportedNodeCounts: [String: Int] = [:]
      var formulasWithUnsupportedNodes = 0
      var formulasUsingFallback = 0
      var cellStyleCache: [UInt64: DecodedCellStyle?] = [:]
      var textStyleCache: [UInt64: DecodedTextStyle?] = [:]
      var richTextCache: [Int32: IWAResolvedRichText?] = [:]

      for row in 0..<min(rowCount, rowStorageMap.count) {
        if let cellWindow, row < cellWindow.startRow || row > cellWindow.endRow {
          continue
        }
        guard let storageIndex = rowStorageMap[row], storageIndex >= 0,
          storageIndex < rowBuffers.count
        else {
          continue
        }

        let storageRow = rowBuffers[storageIndex]
        let maxColumn = min(columnCount, storageRow.count)

        for column in 0..<maxColumn {
          if let cellWindow, !cellWindow.contains(row: row, column: column) {
            continue
          }
          guard let buffer = storageRow[column] else {
            continue
          }
          guard let decoded = decodeCellStorage(buffer: buffer, stringLookup: stringLookup) else {
            if let cellType = detectedCellType(buffer: buffer) {
              droppedCellTypeCounts[cellType, default: 0] += 1
            }
            continue
          }

          guard let value = decoded.value else {
            droppedCellTypeCounts[decoded.cellType, default: 0] += 1
            continue
          }

          var formulaRaw: String?
          var formulaTokens: [String] = []
          var formulaASTSummary: String?

          if features.contains(.formulas),
            decoded.kind == .formula,
            let formulaID = decoded.formulaID,
            let formulaArchive = formulaLookup[formulaID]
          {
            let formula = decodeFormula(
              archive: formulaArchive,
              hostRow: row,
              hostColumn: column
            )
            formulaRaw = formula.rawFormula
            formulaTokens = formula.tokens
            formulaASTSummary = formula.astSummary
            if !formula.unsupportedNodeCounts.isEmpty {
              formulasWithUnsupportedNodes += 1
              for (nodeName, count) in formula.unsupportedNodeCounts {
                formulaUnsupportedNodeCounts[nodeName, default: 0] += count
              }
            }
            if formula.usedUnsupportedFallback {
              formulasUsingFallback += 1
            }
          }

          let richText: IWAResolvedRichText? = {
            guard features.contains(.richText) else {
              return nil
            }
            guard let richTextID = decoded.richTextID, richTextID >= 0 else {
              return nil
            }
            if let cached = richTextCache[richTextID] {
              return cached
            }
            let resolved = decodeRichText(
              richTextID: richTextID,
              payloadObjectByID: richTextPayloadByID
            )
            richTextCache[richTextID] = resolved
            return resolved
          }()

          let resolvedCellStyleObjectID: UInt64? = {
            guard features.contains(.styles) else {
              return nil
            }
            if let styleID = decoded.cellStyleID, let objectID = styleObjectByID[styleID],
              objectID > 0
            {
              return objectID
            }
            return styleDefaults.defaultCellStyleObjectID(row: row, column: column)
          }()

          let resolvedTextStyleObjectID: UInt64? = {
            guard features.contains(.styles) else {
              return nil
            }
            if let styleID = decoded.textStyleID, let objectID = styleObjectByID[styleID],
              objectID > 0
            {
              return objectID
            }
            return styleDefaults.defaultTextStyleObjectID(row: row, column: column)
          }()

          let cellStyle: DecodedCellStyle? = {
            guard let objectID = resolvedCellStyleObjectID, objectID > 0 else {
              return nil
            }
            if let cached = cellStyleCache[objectID] {
              return cached
            }
            let resolved = decodeCellStyleObject(objectID)
            cellStyleCache[objectID] = resolved
            return resolved
          }()

          let textStyle: DecodedTextStyle? = {
            guard let objectID = resolvedTextStyleObjectID, objectID > 0 else {
              return nil
            }
            if let cached = textStyleCache[objectID] {
              return cached
            }
            let resolved =
              decodeParagraphTextStyleObject(objectID) ?? decodeCharacterStyleObject(objectID)
            textStyleCache[objectID] = resolved
            return resolved
          }()

          let numberFormat = resolvedNumberFormat(from: decoded)
          let style: IWAResolvedCellStyle? = {
            guard
              cellStyle != nil || textStyle != nil || numberFormat != nil
            else {
              return nil
            }

            return IWAResolvedCellStyle(
              horizontalAlignment: textStyle?.horizontalAlignment,
              verticalAlignment: cellStyle?.verticalAlignment,
              backgroundColorHex: cellStyle?.backgroundColorHex,
              fontName: textStyle?.fontName,
              fontSize: textStyle?.fontSize,
              isBold: textStyle?.isBold,
              isItalic: textStyle?.isItalic,
              textColorHex: textStyle?.textColorHex,
              hasTopBorder: cellStyle?.hasTopBorder ?? false,
              hasRightBorder: cellStyle?.hasRightBorder ?? false,
              hasBottomBorder: cellStyle?.hasBottomBorder ?? false,
              hasLeftBorder: cellStyle?.hasLeftBorder ?? false,
              numberFormat: numberFormat
            )
          }()

          cells.append(
            IWAResolvedCell(
              row: row,
              column: column,
              value: value,
              kind: decoded.kind,
              richText: richText,
              style: style,
              rawCellType: decoded.cellType,
              stringID: decoded.stringID,
              richTextID: decoded.richTextID,
              formulaID: decoded.formulaID,
              formulaErrorID: decoded.formulaErrorID,
              formulaRaw: formulaRaw,
              formulaTokens: formulaTokens,
              formulaASTSummary: formulaASTSummary
            )
          )
        }
      }

      return DecodedCellsResult(
        cells: cells,
        droppedCellTypeCounts: droppedCellTypeCounts,
        formulaUnsupportedNodeCounts: formulaUnsupportedNodeCounts,
        formulasWithUnsupportedNodes: formulasWithUnsupportedNodes,
        formulasUsingFallback: formulasUsingFallback
      )
    }

    private func decodeMergeRanges(_ reference: TSP_Reference) -> [IWAResolvedMergeRange] {
      let objectID = reference.identifier
      guard objectID > 0 else {
        return []
      }

      guard
        let mergeMap: TST_MergeRegionMapArchive = decode(
          objectID: objectID,
          typeID: TypeID.mergeRegionMapArchive,
          as: TST_MergeRegionMapArchive.self
        )
      else {
        return []
      }

      var ranges: [IWAResolvedMergeRange] = []
      ranges.reserveCapacity(mergeMap.cellRange.count)

      for cellRange in mergeMap.cellRange {
        guard cellRange.hasOrigin, cellRange.hasSize else {
          continue
        }

        let origin = cellRange.origin.packedData
        let size = cellRange.size.packedData

        let startColumn = Int((origin >> 16) & 0xFFFF)
        let startRow = Int(origin & 0xFFFF)
        let width = Int((size >> 16) & 0xFFFF)
        let height = Int(size & 0xFFFF)

        guard width > 0, height > 0 else {
          continue
        }

        ranges.append(
          IWAResolvedMergeRange(
            startRow: startRow,
            endRow: startRow + height - 1,
            startColumn: startColumn,
            endColumn: startColumn + width - 1
          )
        )
      }

      return ranges
    }

    private mutating func addDiagnostic(
      _ code: DiagnosticCode,
      severity: IWAReadDiagnosticSeverity,
      message: String,
      objectPath: String? = nil,
      suggestion: String? = nil,
      context: [String: String] = [:]
    ) {
      diagnostics.append(
        IWAReadDiagnostic(
          code: code.rawValue,
          severity: severity,
          message: message,
          objectPath: objectPath,
          suggestion: suggestion,
          context: context
        ))
    }

    private func decode<MessageType: SwiftProtobuf.Message>(
      objectID: UInt64,
      typeID: UInt32,
      as type: MessageType.Type
    ) -> MessageType? {
      guard let candidates = recordsByObjectID[objectID] else {
        return nil
      }

      for record in candidates where record.typeID == typeID {
        if let decoded = try? MessageType(serializedBytes: record.payloadData) {
          return decoded
        }
      }
      return nil
    }

    private func decodeAnyType<MessageType: SwiftProtobuf.Message>(
      objectID: UInt64,
      typeIDs: [UInt32],
      as type: MessageType.Type
    ) -> MessageType? {
      for typeID in typeIDs {
        if let decoded: MessageType = decode(objectID: objectID, typeID: typeID, as: type) {
          return decoded
        }
      }
      return nil
    }
  }

  static func splitRowStorageBuffers(
    storageBuffer: Data,
    offsetsBuffer: Data,
    columnCount: Int,
    hasWideOffsets: Bool
  ) -> [Data?] {
    guard columnCount > 0 else {
      return []
    }

    var offsets = decodeSignedInt16Array(offsetsBuffer)
    if offsets.isEmpty {
      return [Data?](repeating: nil, count: columnCount)
    }
    if hasWideOffsets {
      offsets = offsets.map { $0 * 4 }
    }

    var rowData: [Data?] = []
    rowData.reserveCapacity(min(columnCount, offsets.count))

    let maxColumn = min(columnCount, offsets.count)
    for column in 0..<maxColumn {
      let start = offsets[column]
      if start < 0 {
        rowData.append(nil)
        continue
      }

      var end = storageBuffer.count
      if column < offsets.count - 1 {
        var nextOffsetIndex = column + 1
        while nextOffsetIndex < offsets.count {
          let candidate = offsets[nextOffsetIndex]
          if candidate >= 0 {
            end = candidate
            break
          }
          nextOffsetIndex += 1
        }
      }

      if start >= end || start >= storageBuffer.count {
        rowData.append(nil)
        continue
      }

      let safeEnd = min(end, storageBuffer.count)
      rowData.append(Data(storageBuffer[start..<safeEnd]))
    }

    if rowData.count < columnCount {
      rowData.append(contentsOf: repeatElement(nil, count: columnCount - rowData.count))
    }

    return rowData
  }

  struct DecodedCellStorage: Sendable {
    let cellType: UInt8
    let kind: IWAResolvedCellKind
    let value: IWAResolvedCellValue?
    let stringID: Int32?
    let richTextID: Int32?
    let cellStyleID: Int32?
    let textStyleID: Int32?
    let formulaID: Int32?
    let formulaErrorID: Int32?
    let numberFormatID: Int32?
    let currencyFormatID: Int32?
    let dateFormatID: Int32?
    let durationFormatID: Int32?
    let textFormatID: Int32?
    let boolFormatID: Int32?
  }

  static func decodeCellStorage(buffer: Data, stringLookup: [UInt32: String]) -> DecodedCellStorage?
  {
    guard buffer.count >= 12 else {
      return nil
    }

    let version = buffer[0]
    guard version == 5 else {
      return nil
    }

    let cellType = buffer[1]

    guard let flags = decodeInt32LittleEndian(buffer, offset: 8) else {
      return nil
    }

    var offset = 12
    var decimalNumber: Double?
    var doubleNumber: Double?
    var secondsNumber: Double?
    var stringID: Int32?
    var richTextID: Int32?
    var cellStyleID: Int32?
    var textStyleID: Int32?
    var formulaID: Int32?
    var formulaErrorID: Int32?
    var numberFormatID: Int32?
    var currencyFormatID: Int32?
    var dateFormatID: Int32?
    var durationFormatID: Int32?
    var textFormatID: Int32?
    var boolFormatID: Int32?

    if (flags & 0x1) != 0 {
      guard offset + 16 <= buffer.count else {
        return nil
      }
      decimalNumber = unpackDecimal128(Data(buffer[offset..<(offset + 16)]))
      offset += 16
    }

    if (flags & 0x2) != 0 {
      guard let value = decodeDoubleLittleEndian(buffer, offset: offset) else {
        return nil
      }
      doubleNumber = value
      offset += 8
    }

    if (flags & 0x4) != 0 {
      guard let value = decodeDoubleLittleEndian(buffer, offset: offset) else {
        return nil
      }
      secondsNumber = value
      offset += 8
    }

    if (flags & 0x8) != 0 {
      guard let value = decodeInt32LittleEndian(buffer, offset: offset) else {
        return nil
      }
      stringID = value
      offset += 4
    }

    if (flags & 0x10) != 0 {
      guard let value = decodeInt32LittleEndian(buffer, offset: offset) else {
        return nil
      }
      richTextID = value
      offset += 4
    }

    if (flags & 0x20) != 0 {
      guard let value = decodeInt32LittleEndian(buffer, offset: offset) else {
        return nil
      }
      cellStyleID = value
      offset += 4
    }

    if (flags & 0x40) != 0 {
      guard let value = decodeInt32LittleEndian(buffer, offset: offset) else {
        return nil
      }
      textStyleID = value
      offset += 4
    }

    if (flags & 0x80) != 0 {
      guard offset + 4 <= buffer.count else {
        return nil
      }
      offset += 4
    }

    if (flags & 0x100) != 0 {
      guard offset + 4 <= buffer.count else {
        return nil
      }
      offset += 4
    }

    if (flags & 0x200) != 0 {
      guard let value = decodeInt32LittleEndian(buffer, offset: offset) else {
        return nil
      }
      formulaID = value
      offset += 4
    }

    if (flags & 0x400) != 0 {
      guard offset + 4 <= buffer.count else {
        return nil
      }
      offset += 4
    }

    if (flags & 0x800) != 0 {
      guard let value = decodeInt32LittleEndian(buffer, offset: offset) else {
        return nil
      }
      formulaErrorID = value
      offset += 4
    }

    if (flags & 0x1000) != 0 {
      guard offset + 4 <= buffer.count else {
        return nil
      }
      offset += 4
    }

    if (flags & 0x2000) != 0 {
      guard let value = decodeInt32LittleEndian(buffer, offset: offset) else {
        return nil
      }
      numberFormatID = value
      offset += 4
    }

    if (flags & 0x4000) != 0 {
      guard let value = decodeInt32LittleEndian(buffer, offset: offset) else {
        return nil
      }
      currencyFormatID = value
      offset += 4
    }

    if (flags & 0x8000) != 0 {
      guard let value = decodeInt32LittleEndian(buffer, offset: offset) else {
        return nil
      }
      dateFormatID = value
      offset += 4
    }

    if (flags & 0x10000) != 0 {
      guard let value = decodeInt32LittleEndian(buffer, offset: offset) else {
        return nil
      }
      durationFormatID = value
      offset += 4
    }

    if (flags & 0x20000) != 0 {
      guard let value = decodeInt32LittleEndian(buffer, offset: offset) else {
        return nil
      }
      textFormatID = value
      offset += 4
    }

    if (flags & 0x40000) != 0 {
      guard let value = decodeInt32LittleEndian(buffer, offset: offset) else {
        return nil
      }
      boolFormatID = value
      offset += 4
    }

    if (flags & 0x80000) != 0 {
      guard offset + 4 <= buffer.count else {
        return nil
      }
      offset += 4
    }

    if (flags & 0x100000) != 0 {
      guard offset + 4 <= buffer.count else {
        return nil
      }
      offset += 4
    }

    let textValue: String? = {
      guard let stringID, stringID >= 0 else { return nil }
      return stringLookup[UInt32(stringID)] ?? ""
    }()

    let richTextValue: String? = {
      if let richTextID, richTextID >= 0, let value = stringLookup[UInt32(richTextID)] {
        return value
      }
      return textValue
    }()

    let numberValue: Double? = doubleNumber ?? decimalNumber

    let decoded: (kind: IWAResolvedCellKind, value: IWAResolvedCellValue?) = {
      switch cellType {
      case 0:
        return (.empty, .empty)
      case 2, 10:
        return (.number, numberValue.map(IWAResolvedCellValue.number))
      case 3:
        return (.text, .string(textValue ?? ""))
      case 4:
        if let textValue {
          return (.formula, .string(textValue))
        }
        if let numberValue {
          return (.formula, .number(numberValue))
        }
        return (.formula, nil)
      case 5:
        if let secondsNumber {
          return (
            .date,
            .date(Date(timeIntervalSinceReferenceDate: secondsNumber))
          )
        }
        if let numberValue {
          return (
            .date,
            .date(Date(timeIntervalSinceReferenceDate: numberValue))
          )
        }
        return (.date, nil)
      case 6:
        if let numberValue {
          return (.bool, .bool(numberValue > 0))
        }
        return (.bool, .bool(false))
      case 7:
        if let numberValue {
          return (.duration, .duration(numberValue))
        }
        return (.duration, nil)
      case 8:
        if let textValue, !textValue.isEmpty {
          return (.formulaError, .error(textValue))
        }
        return (.formulaError, .error("#ERROR!"))
      case 9:
        return (.richText, .richText(richTextValue ?? ""))
      default:
        // Unknown cell types: preserve raw payload best-effort.
        if let textValue {
          return (.unknown(cellType), .string(textValue))
        }
        if let numberValue {
          return (.unknown(cellType), .number(numberValue))
        }
        return (.unknown(cellType), nil)
      }
    }()

    let effectiveKind: IWAResolvedCellKind = {
      if let formulaErrorID, formulaErrorID >= 0 {
        return .formulaError
      }
      if let formulaID, formulaID >= 0 {
        return .formula
      }
      return decoded.kind
    }()

    let effectiveValue: IWAResolvedCellValue? = {
      if effectiveKind == .formulaError {
        if case .error = decoded.value {
          return decoded.value
        }
        if let textValue, !textValue.isEmpty {
          return .error(textValue)
        }
        return .error("#ERROR!")
      }
      return decoded.value
    }()

    return DecodedCellStorage(
      cellType: cellType,
      kind: effectiveKind,
      value: effectiveValue,
      stringID: stringID,
      richTextID: richTextID,
      cellStyleID: cellStyleID,
      textStyleID: textStyleID,
      formulaID: formulaID,
      formulaErrorID: formulaErrorID,
      numberFormatID: numberFormatID,
      currencyFormatID: currencyFormatID,
      dateFormatID: dateFormatID,
      durationFormatID: durationFormatID,
      textFormatID: textFormatID,
      boolFormatID: boolFormatID
    )
  }

  static func decodeCellValue(buffer: Data, stringLookup: [UInt32: String]) -> IWAResolvedCellValue?
  {
    decodeCellStorage(buffer: buffer, stringLookup: stringLookup)?.value
  }

  static func renderFormula(
    archive: TSCE_FormulaArchive,
    hostRow: Int,
    hostColumn: Int
  ) -> String? {
    let render = renderFormulaDetailed(
      nodes: archive.astNodeArray.nodes,
      hostRow: hostRow,
      hostColumn: hostColumn
    )
    let rendered = render.rendered

    guard let rendered, !rendered.isEmpty else {
      return nil
    }
    if rendered.hasPrefix("=") {
      return rendered
    }
    return "=" + rendered
  }

  static func renderFormula(
    nodes: [TSCE_ASTNodeArrayArchive.Node],
    hostRow: Int,
    hostColumn: Int
  ) -> String? {
    renderFormulaDetailed(
      nodes: nodes,
      hostRow: hostRow,
      hostColumn: hostColumn
    ).rendered
  }

  private struct FormulaRenderResult {
    let rendered: String?
    let unsupportedNodeCounts: [String: Int]
    let usedUnsupportedFallback: Bool
  }

  private static func renderFormulaDetailed(
    nodes: [TSCE_ASTNodeArrayArchive.Node],
    hostRow: Int,
    hostColumn: Int
  ) -> FormulaRenderResult {
    guard !nodes.isEmpty else {
      return FormulaRenderResult(
        rendered: nil,
        unsupportedNodeCounts: [:],
        usedUnsupportedFallback: false
      )
    }

    var stack: [String] = []
    stack.reserveCapacity(nodes.count)
    var unsupportedNodeCounts: [String: Int] = [:]
    var usedUnsupportedFallback = false

    func pop() -> String {
      stack.popLast() ?? ""
    }

    func popPair() -> (String, String) {
      let rhs = pop()
      let lhs = pop()
      return (lhs, rhs)
    }

    func push(_ value: String) {
      stack.append(value)
    }

    func markUnsupported(_ nodeType: TSCE_ASTNodeArrayArchive.NodeType) {
      let name = nodeTypeName(nodeType)
      unsupportedNodeCounts[name, default: 0] += 1
    }

    for node in nodes {
      switch node.nodeType {
      case .add:
        let (lhs, rhs) = popPair()
        push("\(lhs)+\(rhs)")
      case .sub:
        let (lhs, rhs) = popPair()
        push("\(lhs)-\(rhs)")
      case .mul:
        let (lhs, rhs) = popPair()
        push("\(lhs)*\(rhs)")
      case .div:
        let (lhs, rhs) = popPair()
        push("\(lhs)/\(rhs)")
      case .pow:
        let (lhs, rhs) = popPair()
        push("\(lhs)^\(rhs)")
      case .concat:
        let (lhs, rhs) = popPair()
        push("\(lhs)&\(rhs)")
      case .gt:
        let (lhs, rhs) = popPair()
        push("\(lhs)>\(rhs)")
      case .gte:
        let (lhs, rhs) = popPair()
        push("\(lhs)>=\(rhs)")
      case .lt:
        let (lhs, rhs) = popPair()
        push("\(lhs)<\(rhs)")
      case .lte:
        let (lhs, rhs) = popPair()
        push("\(lhs)<=\(rhs)")
      case .eq:
        let (lhs, rhs) = popPair()
        push("\(lhs)=\(rhs)")
      case .neq:
        let (lhs, rhs) = popPair()
        push("\(lhs)<>\(rhs)")
      case .neg:
        push("-\(pop())")
      case .plus:
        push("+\(pop())")
      case .percent:
        push("\(pop())%")
      case .function:
        let resolvedName = Self.functionName(for: node.functionIndex)
        let isUnknownFunctionIndex = resolvedName.hasPrefix("FUNC_")
        let count: Int = {
          let directCount = Int(node.functionNumArgs)
          if directCount > 0 {
            return directCount
          }
          if isUnknownFunctionIndex {
            return Int(node.unknownFunctionNumArgs)
          }
          return directCount
        }()
        var args: [String] = []
        args.reserveCapacity(max(count, 0))
        for _ in 0..<count {
          args.append(pop())
        }
        let orderedArgs = args.reversed().joined(separator: ",")
        let renderedFunctionName: String = {
          if isUnknownFunctionIndex, !node.unknownFunctionName.isEmpty {
            return node.unknownFunctionName
          }
          return resolvedName
        }()
        push("\(renderedFunctionName)(\(orderedArgs))")
      case .number:
        push(
          formattedNumber(
            node.numberValue, decimalLow: node.decimalLow, decimalHigh: node.decimalHigh))
      case .bool:
        push(node.boolValue ? "TRUE" : "FALSE")
      case .token:
        push(node.tokenBoolValue ? "TRUE" : "FALSE")
      case .string:
        let escaped = node.stringValue.replacingOccurrences(of: "\"", with: "\"\"")
        push("\"\(escaped)\"")
      case .date:
        let dt = Date(timeIntervalSinceReferenceDate: node.dateSeconds)
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: dt)
        let year = components.year ?? 2001
        let month = components.month ?? 1
        let day = components.day ?? 1
        push("DATE(\(year),\(month),\(day))")
      case .duration:
        push(formattedNumber(node.durationValue, decimalLow: 0, decimalHigh: 0))
      case .emptyArg:
        push("")
      case .array:
        let rows = max(Int(node.arrayNumRows), 0)
        let cols = max(Int(node.arrayNumColumns), 0)
        guard rows > 0, cols > 0 else {
          push("{}")
          continue
        }

        var rowChunks: [String] = []
        rowChunks.reserveCapacity(rows)
        for _ in 0..<rows {
          var values: [String] = []
          values.reserveCapacity(cols)
          for _ in 0..<cols {
            values.append(pop())
          }
          rowChunks.append(values.reversed().joined(separator: ","))
        }
        push("{\(rowChunks.reversed().joined(separator: ";"))}")
      case .list:
        let count = Int(node.listNumArgs)
        var args: [String] = []
        args.reserveCapacity(max(count, 0))
        for _ in 0..<count {
          args.append(pop())
        }
        push("(\(args.reversed().joined(separator: ",")))")
      case .range, .rangeUids:
        let (lhs, rhs) = popPair()
        push("\(lhs):\(rhs)")
      case .colonTract:
        push(renderColonTract(node.colonTract, sticky: node.stickyBits))
      case .localRef, .cellRef:
        push(renderCellReference(node: node, hostRow: hostRow, hostColumn: hostColumn))
      case .crossTableRef:
        // Keep cross-table references explicit for now.
        push(renderCellReference(node: node, hostRow: hostRow, hostColumn: hostColumn))
      case .refError, .refErrorUids:
        push("#REF!")
      case .unknownFunction:
        let count = Int(node.unknownFunctionNumArgs)
        var args: [String] = []
        args.reserveCapacity(max(count, 0))
        for _ in 0..<count {
          args.append(pop())
        }
        let name = node.unknownFunctionName.isEmpty ? "UNKNOWN_FUNC" : node.unknownFunctionName
        push("\(name)(\(args.reversed().joined(separator: ",")))")
      case .appendWs:
        if !stack.isEmpty {
          let top = pop()
          push(top + node.whitespace)
        }
      case .prependWs:
        if !stack.isEmpty {
          let top = pop()
          push(node.whitespace + top)
        }
      case .thunk:
        let thunk = renderFormulaDetailed(
          nodes: node.thunkNodeArray.nodes,
          hostRow: hostRow,
          hostColumn: hostColumn
        )
        for (nodeName, count) in thunk.unsupportedNodeCounts {
          unsupportedNodeCounts[nodeName, default: 0] += count
        }
        if thunk.usedUnsupportedFallback {
          usedUnsupportedFallback = true
        }
        if let thunkRendered = thunk.rendered, !thunkRendered.isEmpty {
          push(thunkRendered)
        }
      case .beginThunk, .endThunk:
        continue
      case .uidRef, .letBind, .var, .endScope, .lambda, .beginLambdaThunk,
        .endLambdaThunk, .linkedCellRef, .linkedColumnRef, .linkedRowRef, .categoryRef,
        .viewTractRef,
        .intersection, .spillRange, .unknown:
        markUnsupported(node.nodeType)
        continue
      }
    }

    let rendered = stack.last
    let hasFallbackCriticalUnsupportedNodes = unsupportedNodeCounts.keys.contains {
      isFallbackCriticalUnsupportedNodeName($0)
    }
    if hasFallbackCriticalUnsupportedNodes {
      usedUnsupportedFallback = true
      let summary = unsupportedNodeCounts.keys.sorted().joined(separator: ",")
      return FormulaRenderResult(
        rendered: "UNSUPPORTED_AST(\(summary))",
        unsupportedNodeCounts: unsupportedNodeCounts,
        usedUnsupportedFallback: usedUnsupportedFallback
      )
    }

    return FormulaRenderResult(
      rendered: rendered,
      unsupportedNodeCounts: unsupportedNodeCounts,
      usedUnsupportedFallback: usedUnsupportedFallback
    )
  }

  private static func isFallbackCriticalUnsupportedNodeName(_ name: String) -> Bool {
    switch name {
    case "UID_REF", "LET_BIND", "VAR", "END_SCOPE", "LAMBDA", "BEGIN_LAMBDA_THUNK",
      "END_LAMBDA_THUNK", "LINKED_CELL_REF", "LINKED_COLUMN_REF", "LINKED_ROW_REF",
      "CATEGORY_REF", "VIEW_TRACT_REF", "INTERSECTION", "SPILL_RANGE", "UNKNOWN":
      return true
    default:
      return false
    }
  }

  static func nodeTypeName(_ type: TSCE_ASTNodeArrayArchive.NodeType) -> String {
    switch type {
    case .unknown:
      return "UNKNOWN"
    case .add:
      return "ADD"
    case .sub:
      return "SUB"
    case .mul:
      return "MUL"
    case .div:
      return "DIV"
    case .pow:
      return "POW"
    case .concat:
      return "CONCAT"
    case .gt:
      return "GT"
    case .gte:
      return "GTE"
    case .lt:
      return "LT"
    case .lte:
      return "LTE"
    case .eq:
      return "EQ"
    case .neq:
      return "NEQ"
    case .neg:
      return "NEG"
    case .plus:
      return "PLUS"
    case .percent:
      return "PERCENT"
    case .function:
      return "FUNCTION"
    case .number:
      return "NUMBER"
    case .bool:
      return "BOOL"
    case .string:
      return "STRING"
    case .date:
      return "DATE"
    case .duration:
      return "DURATION"
    case .emptyArg:
      return "EMPTY_ARG"
    case .token:
      return "TOKEN"
    case .array:
      return "ARRAY"
    case .list:
      return "LIST"
    case .thunk:
      return "THUNK"
    case .localRef:
      return "LOCAL_REF"
    case .crossTableRef:
      return "CROSS_TABLE_REF"
    case .range:
      return "RANGE"
    case .refError:
      return "REF_ERROR"
    case .unknownFunction:
      return "UNKNOWN_FUNCTION"
    case .appendWs:
      return "APPEND_WS"
    case .prependWs:
      return "PREPEND_WS"
    case .beginThunk:
      return "BEGIN_THUNK"
    case .endThunk:
      return "END_THUNK"
    case .cellRef:
      return "CELL_REF"
    case .rangeUids:
      return "RANGE_UIDS"
    case .refErrorUids:
      return "REF_ERROR_UIDS"
    case .uidRef:
      return "UID_REF"
    case .letBind:
      return "LET_BIND"
    case .var:
      return "VAR"
    case .endScope:
      return "END_SCOPE"
    case .lambda:
      return "LAMBDA"
    case .beginLambdaThunk:
      return "BEGIN_LAMBDA_THUNK"
    case .endLambdaThunk:
      return "END_LAMBDA_THUNK"
    case .linkedCellRef:
      return "LINKED_CELL_REF"
    case .linkedColumnRef:
      return "LINKED_COLUMN_REF"
    case .linkedRowRef:
      return "LINKED_ROW_REF"
    case .categoryRef:
      return "CATEGORY_REF"
    case .colonTract:
      return "COLON_TRACT"
    case .viewTractRef:
      return "VIEW_TRACT_REF"
    case .intersection:
      return "INTERSECTION"
    case .spillRange:
      return "SPILL_RANGE"
    }
  }

  static func tokenizeFormula(_ formula: String) -> [String] {
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

  static func colorHex(_ color: TSP_Color?) -> String? {
    guard let color else {
      return nil
    }
    guard color.hasR, color.hasG, color.hasB else {
      return nil
    }

    func clamp(_ value: Float) -> Int {
      Int((max(0, min(1, value)) * 255).rounded())
    }

    let red = clamp(color.r)
    let green = clamp(color.g)
    let blue = clamp(color.b)
    let alpha = color.hasA ? clamp(color.a) : 255

    if alpha == 255 {
      return String(format: "#%02X%02X%02X", red, green, blue)
    }
    return String(format: "#%02X%02X%02X%02X", red, green, blue, alpha)
  }

  static func substring(_ text: String, start: Int, end: Int) -> String {
    let clampedStart = max(0, min(start, text.count))
    let clampedEnd = max(clampedStart, min(end, text.count))
    let startIndex = text.index(text.startIndex, offsetBy: clampedStart)
    let endIndex = text.index(text.startIndex, offsetBy: clampedEnd)
    return String(text[startIndex..<endIndex])
  }

  private static func functionName(for index: UInt32) -> String {
    knownFunctionNames[index] ?? "FUNC_\(index)"
  }

  private static func renderCellReference(
    node: TSCE_ASTNodeArrayArchive.Node,
    hostRow: Int,
    hostColumn: Int
  ) -> String {
    let row = node.row
    let col = node.column

    let hasRow = node.hasRow
    let hasColumn = node.hasColumn

    if !hasRow && !hasColumn {
      return "#REF!"
    }

    var resolvedRow = hostRow
    var resolvedColumn = hostColumn
    var rowAbsolute = false
    var columnAbsolute = false

    if hasRow {
      rowAbsolute = row.absolute
      resolvedRow = rowAbsolute ? Int(row.value) : hostRow + Int(row.value)
    }
    if hasColumn {
      columnAbsolute = col.absolute
      resolvedColumn = columnAbsolute ? Int(col.value) : hostColumn + Int(col.value)
    }

    if resolvedRow < 0 || resolvedColumn < 0 {
      return "#REF!"
    }

    let colLetters = a1ColumnLabel(for: resolvedColumn)
    let colPart = columnAbsolute ? "$\(colLetters)" : colLetters
    let rowPart = rowAbsolute ? "$\(resolvedRow + 1)" : "\(resolvedRow + 1)"
    return "\(colPart)\(rowPart)"
  }

  private static func renderColonTract(
    _ tract: TSCE_ASTNodeArrayArchive.ColonTract,
    sticky: TSCE_ASTNodeArrayArchive.StickyBits
  ) -> String {
    guard
      let startRowRange = tract.absoluteRows.first,
      let startColumnRange = tract.absoluteColumns.first
    else {
      return "#RANGE!"
    }

    let rowStart = Int(startRowRange.begin)
    let rowEnd = Int(startRowRange.hasEnd ? startRowRange.end : startRowRange.begin)
    let columnStart = Int(startColumnRange.begin)
    let columnEnd = Int(startColumnRange.hasEnd ? startColumnRange.end : startColumnRange.begin)

    let begin = renderA1(
      row: rowStart,
      column: columnStart,
      rowAbsolute: sticky.beginRowAbsolute,
      columnAbsolute: sticky.beginColumnAbsolute
    )
    let end = renderA1(
      row: rowEnd,
      column: columnEnd,
      rowAbsolute: sticky.endRowAbsolute,
      columnAbsolute: sticky.endColumnAbsolute
    )
    return "\(begin):\(end)"
  }

  private static func renderA1(
    row: Int,
    column: Int,
    rowAbsolute: Bool,
    columnAbsolute: Bool
  ) -> String {
    let colLetters = a1ColumnLabel(for: max(column, 0))
    let colPart = columnAbsolute ? "$\(colLetters)" : colLetters
    let rowPart = rowAbsolute ? "$\(max(row, 0) + 1)" : "\(max(row, 0) + 1)"
    return "\(colPart)\(rowPart)"
  }

  private static func a1ColumnLabel(for zeroBasedColumn: Int) -> String {
    var value = zeroBasedColumn + 1
    var result = ""
    while value > 0 {
      let remainder = (value - 1) % 26
      let scalar = UnicodeScalar(65 + remainder)!
      result = String(Character(scalar)) + result
      value = (value - 1) / 26
    }
    return result.isEmpty ? "A" : result
  }

  private static func formattedNumber(_ value: Double, decimalLow: UInt64, decimalHigh: UInt64)
    -> String
  {
    if decimalHigh == 0x3040_0000_0000_0000 {
      return String(decimalLow)
    }

    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.numberStyle = .decimal
    formatter.usesGroupingSeparator = false
    formatter.maximumFractionDigits = 15
    formatter.minimumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? String(value)
  }

  // Extended Numbers formula function map for readable rawFormula rendering.
  private static let knownFunctionNames: [UInt32: String] = [
    1: "ABS",
    2: "ACCRINT",
    3: "ACCRINTM",
    4: "ACOS",
    5: "ACOSH",
    6: "ADDRESS",
    7: "AND",
    8: "AREAS",
    9: "ASIN",
    10: "ASINH",
    11: "ATAN",
    12: "ATAN2",
    13: "ATANH",
    14: "AVEDEV",
    15: "AVERAGE",
    16: "AVERAGEA",
    17: "CEILING",
    18: "CHAR",
    19: "CHOOSE",
    20: "CLEAN",
    21: "CODE",
    22: "COLUMN",
    23: "COLUMNS",
    24: "COMBIN",
    25: "CONCATENATE",
    26: "CONFIDENCE",
    27: "CORREL",
    28: "COS",
    29: "COSH",
    30: "COUNT",
    31: "COUNTA",
    32: "COUNTBLANK",
    33: "COUNTIF",
    34: "COUPDAYBS",
    35: "COUPDAYS",
    36: "COUPDAYSNC",
    37: "COUPNUM",
    38: "COVAR",
    39: "DATE",
    40: "DATEDIF",
    41: "DAY",
    42: "DB",
    43: "DDB",
    44: "DEGREES",
    45: "DISC",
    46: "DOLLAR",
    47: "EDATE",
    48: "EVEN",
    49: "EXACT",
    50: "EXP",
    51: "FACT",
    52: "FALSE",
    53: "FIND",
    54: "FIXED",
    55: "FLOOR",
    56: "FORECAST",
    57: "FV",
    58: "GCD",
    59: "HLOOKUP",
    60: "HOUR",
    61: "HYPERLINK",
    62: "IF",
    63: "INDEX",
    64: "INDIRECT",
    65: "INT",
    66: "INTERCEPT",
    67: "IPMT",
    68: "IRR",
    69: "ISBLANK",
    70: "ISERROR",
    71: "ISEVEN",
    72: "ISODD",
    73: "ISPMT",
    74: "LARGE",
    75: "LCM",
    76: "LEFT",
    77: "LEN",
    78: "LN",
    79: "LOG",
    80: "LOG10",
    81: "LOOKUP",
    82: "LOWER",
    83: "MATCH",
    84: "MAX",
    85: "MAXA",
    86: "MEDIAN",
    87: "MID",
    88: "MIN",
    89: "MINA",
    90: "MINUTE",
    91: "MIRR",
    92: "MOD",
    93: "MODE",
    94: "MONTH",
    95: "MROUND",
    96: "NOT",
    97: "NOW",
    98: "NPER",
    99: "NPV",
    100: "ODD",
    101: "OFFSET",
    102: "OR",
    103: "PERCENTILE",
    104: "PI",
    105: "PMT",
    106: "POISSON",
    107: "POWER",
    108: "PPMT",
    109: "PRICE",
    110: "PRICEDISC",
    111: "PRICEMAT",
    112: "PROB",
    113: "PRODUCT",
    114: "PROPER",
    115: "PV",
    116: "QUOTIENT",
    117: "RADIANS",
    118: "RAND",
    119: "RANDBETWEEN",
    120: "RANK",
    121: "RATE",
    122: "REPLACE",
    123: "REPT",
    124: "RIGHT",
    125: "ROMAN",
    126: "ROUND",
    127: "ROUNDDOWN",
    128: "ROUNDUP",
    129: "ROW",
    130: "ROWS",
    131: "SEARCH",
    132: "SECOND",
    133: "SIGN",
    134: "SIN",
    135: "SINH",
    136: "SLN",
    137: "SLOPE",
    138: "SMALL",
    139: "SQRT",
    140: "STDEV",
    141: "STDEVA",
    142: "STDEVP",
    143: "STDEVPA",
    144: "SUBSTITUTE",
    145: "SUMIF",
    146: "SUMPRODUCT",
    147: "SUMSQ",
    148: "SYD",
    149: "T",
    150: "TAN",
    151: "TANH",
    152: "TIME",
    153: "TIMEVALUE",
    154: "TODAY",
    155: "TRIM",
    156: "TRUE",
    157: "TRUNC",
    158: "UPPER",
    159: "VALUE",
    160: "VAR",
    161: "VARA",
    162: "VARP",
    163: "VARPA",
    164: "VDB",
    165: "VLOOKUP",
    166: "WEEKDAY",
    167: "YEAR",
    168: "SUM",
    185: "EFFECT",
    186: "NOMINAL",
    187: "NORMDIST",
    188: "NORMSDIST",
    189: "NORMINV",
    190: "NORMSINV",
    191: "YIELD",
    192: "YIELDDISC",
    193: "YIELDMAT",
    194: "BONDDURATION",
    195: "BONDMDURATION",
    196: "ERF",
    197: "ERFC",
    198: "STANDARDIZE",
    199: "INTRATE",
    200: "RECEIVED",
    201: "CUMIPMT",
    202: "CUMPRINC",
    203: "EOMONTH",
    204: "WORKDAY",
    205: "MONTHNAME",
    206: "WEEKNUM",
    207: "DUR2HOURS",
    208: "DUR2MINUTES",
    209: "DUR2SECONDS",
    210: "DUR2DAYS",
    211: "DUR2WEEKS",
    212: "DURATION",
    213: "EXPONDIST",
    214: "YEARFRAC",
    215: "ZTEST",
    216: "SUMX2MY2",
    217: "SUMX2PY2",
    218: "SUMXMY2",
    219: "SQRTPI",
    220: "TRANSPOSE",
    221: "DEVSQ",
    222: "FREQUENCY",
    223: "DELTA",
    224: "FACTDOUBLE",
    225: "GESTEP",
    226: "PERCENTRANK",
    227: "GAMMALN",
    228: "DATEVALUE",
    229: "GAMMADIST",
    230: "GAMMAINV",
    231: "SUMIFS",
    232: "AVERAGEIFS",
    233: "COUNTIFS",
    234: "AVERAGEIF",
    235: "IFERROR",
    236: "DAYNAME",
    237: "BESSELJ",
    238: "BESSELY",
    239: "LOGNORMDIST",
    240: "LOGINV",
    241: "TDIST",
    242: "BINOMDIST",
    243: "NEGBINOMDIST",
    244: "FDIST",
    245: "PERMUT",
    246: "CHIDIST",
    247: "CHITEST",
    248: "TTEST",
    249: "QUARTILE",
    250: "MULTINOMIAL",
    251: "CRITBINOM",
    252: "BASETONUM",
    253: "NUMTOBASE",
    254: "TINV",
    255: "CONVERT",
    256: "CHIINV",
    257: "FINV",
    258: "BETADIST",
    259: "BETAINV",
    260: "NETWORKDAYS",
    261: "DAYS360",
    262: "HARMEAN",
    263: "GEOMEAN",
    264: "DEC2HEX",
    265: "DEC2BIN",
    266: "DEC2OCT",
    267: "BIN2HEX",
    268: "BIN2DEC",
    269: "BIN2OCT",
    270: "OCT2BIN",
    271: "OCT2DEC",
    272: "OCT2HEX",
    273: "HEX2BIN",
    274: "HEX2DEC",
    275: "HEX2OCT",
    276: "LINEST",
    277: "DUR2MILLISECONDS",
    278: "STRIPDURATION",
    280: "INTERSECT.RANGES",
    285: "UNION.RANGES",
    286: "SERIESSUM",
    287: "POLYNOMIAL",
    288: "WEIBULL",
    289: "CONFIDENCE.T",
    290: "COVARIANCE.S",
    291: "MODE.MULT",
    292: "PERCENTILE.EXC",
    293: "PERCENTRANK.EXC",
    294: "QUARTILE.EXC",
    295: "RANK.AVG",
    296: "FIND.CASEINSENSITIVE",
    297: "PLAINTEXT",
    298: "STOCK",
    299: "STOCKH",
    300: "CURRENCY",
    301: "CURRENCYH",
    302: "CURRENCYCONVERT",
    303: "CURRENCYCODE",
    304: "ISNUMBER",
    305: "ISTEXT",
    306: "ISDATE",
    309: "MAXIFS",
    310: "MINIFS",
    311: "XIRR",
    312: "XNPV",
    313: "IFS",
    314: "XLOOKUP",
    315: "XMATCH",
    316: "SUBTOTAL",
    317: "COUNTMATCHES",
    318: "TEXTBEFORE",
    319: "TEXTBETWEEN",
    320: "TEXTAFTER",
    321: "REGEX",
    322: "REFERENCE.NAME",
    323: "FORMULATEXT",
    324: "REGEX.EXTRACT",
    325: "GETPIVOTDATA",
    328: "TEXTJOIN",
    329: "CONCAT",
    330: "BITAND",
    331: "BITOR",
    332: "BITXOR",
    333: "BITLSHIFT",
    334: "BITRSHIFT",
    335: "ISOWEEKNUM",
    336: "SWITCH",
    338: "SEQUENCE",
    341: "ARRAYTOTEXT",
    342: "FILTER",
    343: "SORT",
    344: "SORTBY",
    345: "UNIQUE",
    346: "RANDARRAY",
    347: "TEXTSPLIT",
    348: "TOCOL",
    349: "TOROW",
    350: "TAKE",
    351: "DROP",
    352: "EXPAND",
    353: "CHOOSEROWS",
    354: "CHOOSECOLS",
    355: "HSTACK",
    356: "VSTACK",
    357: "WRAPCOLS",
    358: "WRAPROWS",
    359: "MDETERM",
    360: "MINVERSE",
    361: "MMULT",
    362: "MUNIT",
    363: "LET",
    364: "LAMBDA",
    365: "MAKEARRAY",
    366: "MAP",
    367: "REDUCE",
    368: "SCAN",
    369: "BYROW",
    370: "BYCOL",
    371: "ISOMITTED",
    372: "LAMBDA.APPLY",
    373: "ISNUMBERORDATE",
  ]

  static func detectedCellType(buffer: Data) -> UInt8? {
    guard buffer.count >= 2 else {
      return nil
    }
    guard buffer[0] == 5 else {
      return nil
    }
    return buffer[1]
  }

  static func decodeSignedInt16Array(_ data: Data) -> [Int] {
    let elementSize = MemoryLayout<Int16>.size
    guard data.count >= elementSize else {
      return []
    }

    let count = data.count / elementSize
    var values: [Int] = []
    values.reserveCapacity(count)

    for index in 0..<count {
      let start = index * elementSize
      let end = start + elementSize
      let lo = UInt16(data[start])
      let hi = UInt16(data[end - 1]) << 8
      let value = Int16(bitPattern: lo | hi)
      values.append(Int(Int16(littleEndian: value)))
    }

    return values
  }

  static func decodeInt32LittleEndian(_ data: Data, offset: Int) -> Int32? {
    let size = MemoryLayout<Int32>.size
    guard offset >= 0, offset + size <= data.count else {
      return nil
    }
    var value: UInt32 = 0
    value |= UInt32(data[offset])
    value |= UInt32(data[offset + 1]) << 8
    value |= UInt32(data[offset + 2]) << 16
    value |= UInt32(data[offset + 3]) << 24
    return Int32(bitPattern: value)
  }

  static func decodeDoubleLittleEndian(_ data: Data, offset: Int) -> Double? {
    let size = MemoryLayout<UInt64>.size
    guard offset >= 0, offset + size <= data.count else {
      return nil
    }
    var bits: UInt64 = 0
    bits |= UInt64(data[offset])
    bits |= UInt64(data[offset + 1]) << 8
    bits |= UInt64(data[offset + 2]) << 16
    bits |= UInt64(data[offset + 3]) << 24
    bits |= UInt64(data[offset + 4]) << 32
    bits |= UInt64(data[offset + 5]) << 40
    bits |= UInt64(data[offset + 6]) << 48
    bits |= UInt64(data[offset + 7]) << 56
    return Double(bitPattern: bits)
  }

  static func unpackDecimal128(_ data: Data) -> Double {
    guard data.count >= 16 else {
      return 0
    }

    let bytes = [UInt8](data)
    let exponent = (Int((bytes[15] & 0x7F) << 7) | Int(bytes[14] >> 1)) - 0x1820

    // Use Double accumulation to avoid Int64 overflow on high-magnitude decimal128 payloads.
    var mantissa = Double(bytes[14] & 0x01)
    for index in stride(from: 13, through: 0, by: -1) {
      mantissa = (mantissa * 256) + Double(bytes[index])
    }

    if (bytes[15] & 0x80) != 0 {
      mantissa = -mantissa
    }

    return mantissa * pow(10.0, Double(exponent))
  }
}
