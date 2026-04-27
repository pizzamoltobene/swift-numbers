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
  case formula(String)
  case number(Double)
  case bool(Bool)
  case date(Date)
}

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

public enum MergeRole: Hashable, Sendable {
  case none
  case anchor
  case member
}

public struct RichTextRun: Hashable, Sendable {
  public let range: Range<Int>
  public let text: String
  public let fontName: String?
  public let fontSize: Double?
  public let isBold: Bool?
  public let isItalic: Bool?
  public let textColorHex: String?
  public let linkURL: String?

  public init(
    range: Range<Int>,
    text: String,
    fontName: String? = nil,
    fontSize: Double? = nil,
    isBold: Bool? = nil,
    isItalic: Bool? = nil,
    textColorHex: String? = nil,
    linkURL: String? = nil
  ) {
    self.range = range
    self.text = text
    self.fontName = fontName
    self.fontSize = fontSize
    self.isBold = isBold
    self.isItalic = isItalic
    self.textColorHex = textColorHex
    self.linkURL = linkURL
  }
}

public struct RichTextRead: Hashable, Sendable {
  public let text: String
  public let runs: [RichTextRun]

  public init(text: String, runs: [RichTextRun]) {
    self.text = text
    self.runs = runs
  }
}

public enum ReadHorizontalAlignment: Hashable, Sendable {
  case left
  case center
  case right
  case justified
  case natural
  case unknown(Int32)
}

public enum ReadVerticalAlignment: Hashable, Sendable {
  case top
  case middle
  case bottom
  case unknown(Int32)
}

public enum ReadNumberFormatKind: String, Hashable, Sendable {
  case number
  case currency
  case date
  case duration
  case text
  case bool
  case base
  case fraction
  case percentage
  case scientific
  case custom
}

public struct ReadNumberFormat: Hashable, Sendable {
  public let kind: ReadNumberFormatKind
  public let formatID: Int32

  public init(kind: ReadNumberFormatKind, formatID: Int32) {
    self.kind = kind
    self.formatID = formatID
  }
}

public struct ReadCellStyle: Hashable, Sendable {
  public let horizontalAlignment: ReadHorizontalAlignment?
  public let verticalAlignment: ReadVerticalAlignment?
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
  public let numberFormat: ReadNumberFormat?

  public init(
    horizontalAlignment: ReadHorizontalAlignment? = nil,
    verticalAlignment: ReadVerticalAlignment? = nil,
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
    numberFormat: ReadNumberFormat? = nil
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

  public var isMerged: Bool {
    mergeRole != .none
  }

  public init(
    address: CellAddress,
    value: CellValue,
    kind: ReadCellKind,
    readValue: ReadCellValue? = nil,
    formulaResult: FormulaResultRead? = nil,
    formatted: String,
    richText: RichTextRead? = nil,
    style: ReadCellStyle? = nil,
    rawCellType: UInt8? = nil,
    stringID: Int32? = nil,
    richTextID: Int32? = nil,
    formulaID: Int32? = nil,
    formulaErrorID: Int32? = nil,
    mergeRange: MergeRange? = nil,
    mergeRole: MergeRole = .none
  ) {
    self.address = address
    self.value = value
    self.kind = kind
    self.formulaResult = formulaResult
    if let readValue {
      self.readValue = readValue
    } else if let formulaResult {
      self.readValue = .formulaResult(formulaResult)
    } else {
      self.readValue = Self.deriveReadValue(
        kind: kind,
        value: value,
        richText: richText
      )
    }
    self.formatted = formatted
    self.richText = richText
    self.style = style
    self.rawCellType = rawCellType
    self.stringID = stringID
    self.richTextID = richTextID
    self.formulaID = formulaID
    self.formulaErrorID = formulaErrorID
    self.mergeRange = mergeRange
    self.mergeRole = mergeRole
  }

  private static func deriveReadValue(
    kind: ReadCellKind,
    value: CellValue,
    richText: RichTextRead?
  ) -> ReadCellValue {
    switch kind {
    case .duration:
      if case .number(let seconds) = value {
        return .duration(seconds)
      }
      return .fromCellValue(value)
    case .formulaError:
      if case .string(let message) = value {
        return .error(message)
      }
      return .error("#ERROR!")
    case .richText:
      if let richText {
        return .richText(richText)
      }
      if case .string(let text) = value {
        return .richText(RichTextRead(text: text, runs: []))
      }
      return .fromCellValue(value)
    default:
      return .fromCellValue(value)
    }
  }
}

public struct FormulaRead: Hashable, Sendable {
  public let address: CellAddress
  public let reference: String
  public let formulaID: Int32?
  public let rawFormula: String?
  public let parsedTokens: [String]
  public let astSummary: String?
  public let result: CellValue
  public let resultFormatted: String

  public init(
    address: CellAddress,
    reference: String,
    formulaID: Int32?,
    rawFormula: String?,
    parsedTokens: [String],
    astSummary: String?,
    result: CellValue,
    resultFormatted: String
  ) {
    self.address = address
    self.reference = reference
    self.formulaID = formulaID
    self.rawFormula = rawFormula
    self.parsedTokens = parsedTokens
    self.astSummary = astSummary
    self.result = result
    self.resultFormatted = resultFormatted
  }
}

public struct FormulaResultRead: Hashable, Sendable {
  public let formulaID: Int32?
  public let rawFormula: String?
  public let parsedTokens: [String]
  public let astSummary: String?
  public let computedValue: CellValue
  public let computedFormatted: String

  public init(
    formulaID: Int32?,
    rawFormula: String?,
    parsedTokens: [String],
    astSummary: String?,
    computedValue: CellValue,
    computedFormatted: String
  ) {
    self.formulaID = formulaID
    self.rawFormula = rawFormula
    self.parsedTokens = parsedTokens
    self.astSummary = astSummary
    self.computedValue = computedValue
    self.computedFormatted = computedFormatted
  }
}

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

  public static func fromCellValue(_ value: CellValue) -> ReadCellValue {
    switch value {
    case .empty:
      return .empty
    case .string(let text):
      return .string(text)
    case .formula(let text):
      return .string(text)
    case .number(let number):
      return .number(number)
    case .bool(let bool):
      return .bool(bool)
    case .date(let date):
      return .date(date)
    }
  }
}

public enum ReadNumberFormatMode: Hashable, Sendable {
  case decimal
  case currency(code: String?)
  case percent
  case scientific
  case fraction(maxDenominator: Int)
  case base(radix: Int, uppercase: Bool)
  case pattern(String)
}

public enum ReadDateTimeStyle: String, Hashable, Sendable {
  case none
  case short
  case medium
  case long
  case full
}

public enum ReadDateFormatMode: Hashable, Sendable {
  case iso8601
  case styled(date: ReadDateTimeStyle, time: ReadDateTimeStyle)
  case pattern(String)
}

public enum ReadDurationFormatMode: String, Hashable, Sendable {
  case seconds
  case hhmmss
  case abbreviated
}

public struct ReadFormattingOptions: Hashable, Sendable {
  public let localeIdentifier: String
  public let timeZoneIdentifier: String?
  public let usesGroupingSeparator: Bool
  public let minimumFractionDigits: Int
  public let maximumFractionDigits: Int
  public let includeFractionalSeconds: Bool
  public let numberFormatMode: ReadNumberFormatMode
  public let dateFormatMode: ReadDateFormatMode
  public let durationFormatMode: ReadDurationFormatMode
  public let preferCellNumberFormatHints: Bool

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
  ) {
    self.localeIdentifier = localeIdentifier
    self.timeZoneIdentifier = timeZoneIdentifier
    self.usesGroupingSeparator = usesGroupingSeparator
    self.minimumFractionDigits = minimumFractionDigits
    self.maximumFractionDigits = maximumFractionDigits
    self.includeFractionalSeconds = includeFractionalSeconds
    self.numberFormatMode = numberFormatMode
    self.dateFormatMode = dateFormatMode
    self.durationFormatMode = durationFormatMode
    self.preferCellNumberFormatHints = preferCellNumberFormatHints
  }

  public static let `default` = ReadFormattingOptions()
}

public enum ReadDiagnosticSeverity: String, Sendable {
  case info
  case warning
  case error
}

public struct ReadDiagnostic: Hashable, Sendable {
  public let code: String
  public let severity: ReadDiagnosticSeverity
  public let message: String
  public let objectPath: String?
  public let suggestion: String?
  public let context: [String: String]

  public init(
    code: String,
    severity: ReadDiagnosticSeverity,
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

public enum TableReadError: LocalizedError {
  case invalidCellReference(String)
  case invalidRangeReference(String)
  case outOfBounds(CellAddress)
  case missingValue(CellAddress)
  case typeMismatch(expected: String, actual: CellValue)
  case headerNotFound(String)
  case decodingFailed(String)

  public var errorDescription: String? {
    switch self {
    case .invalidCellReference(let raw):
      return "Invalid cell reference: \(raw)"
    case .invalidRangeReference(let raw):
      return "Invalid range reference: \(raw)"
    case .outOfBounds(let address):
      let ref = CellReference(address: address).a1
      return "Cell out of table bounds: \(ref)"
    case .missingValue(let address):
      let ref = CellReference(address: address).a1
      return "Cell has no value: \(ref)"
    case .typeMismatch(let expected, let actual):
      return "Type mismatch: expected \(expected), got \(actual)"
    case .headerNotFound(let name):
      return "Column header not found: \(name)"
    case .decodingFailed(let message):
      return "Row decoding failed: \(message)"
    }
  }
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

public struct CellRange: Hashable, Sendable {
  public let start: CellAddress
  public let end: CellAddress

  public init(start: CellAddress, end: CellAddress) {
    self.start = start
    self.end = end
  }

  public var rowCount: Int {
    end.row - start.row + 1
  }

  public var columnCount: Int {
    end.column - start.column + 1
  }

  public var a1: String {
    let startRef = CellReference(address: start).a1
    let endRef = CellReference(address: end).a1
    if start == end {
      return startRef
    }
    return "\(startRef):\(endRef)"
  }

  public func contains(_ address: CellAddress) -> Bool {
    address.row >= start.row
      && address.row <= end.row
      && address.column >= start.column
      && address.column <= end.column
  }
}

public struct TableObjectIdentifiers: Hashable, Sendable {
  public let tableInfoObjectID: UInt64?
  public let tableModelObjectID: UInt64?

  public init(tableInfoObjectID: UInt64? = nil, tableModelObjectID: UInt64? = nil) {
    self.tableInfoObjectID = tableInfoObjectID
    self.tableModelObjectID = tableModelObjectID
  }
}

public struct TableCellGeometry: Hashable, Sendable {
  public let originX: Double
  public let originY: Double
  public let width: Double
  public let height: Double

  public init(originX: Double, originY: Double, width: Double, height: Double) {
    self.originX = originX
    self.originY = originY
    self.width = width
    self.height = height
  }
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
  ) {
    self.drawableObjectID = drawableObjectID
    self.drawableTypeIDs = drawableTypeIDs
    self.linkedTableInfoObjectIDs = linkedTableInfoObjectIDs
    self.linkedTableModelObjectIDs = linkedTableModelObjectIDs
  }
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
  ) {
    self.rowCount = rowCount
    self.columnCount = columnCount
    self.headerRowCount = headerRowCount
    self.headerColumnCount = headerColumnCount
    self.rowHeights = rowHeights
    self.columnWidths = columnWidths
    self.mergeRanges = mergeRanges
    self.tableNameVisible = tableNameVisible
    self.captionVisible = captionVisible
    self.captionText = captionText
    self.captionTextSupported = captionTextSupported
    self.objectIdentifiers = objectIdentifiers
    self.pivotLinks = pivotLinks
  }
}

public struct Table: Hashable, Sendable {
  public let id: String
  public let name: String
  public let metadata: TableMetadata
  private let cells: [CellAddress: CellValue]
  private let readCellsByAddress: [CellAddress: ReadCell]
  private let formulasByAddress: [CellAddress: FormulaRead]

  public init(
    id: String,
    name: String,
    metadata: TableMetadata,
    cells: [CellAddress: CellValue] = [:],
    readCells: [CellAddress: ReadCell] = [:],
    formulas: [CellAddress: FormulaRead] = [:]
  ) {
    self.id = id
    self.name = name
    self.metadata = metadata
    self.cells = cells
    self.readCellsByAddress = readCells
    self.formulasByAddress = formulas
  }

  public func cell(at address: CellAddress) -> CellValue? {
    cells[address]
  }

  public func cell(row: Int, column: Int) -> CellValue? {
    guard row >= 0, column >= 0 else {
      return nil
    }
    return cell(at: CellAddress(row: row, column: column))
  }

  public func cell(_ reference: String) -> CellValue? {
    guard let parsed = try? CellReference(reference) else {
      return nil
    }
    return cell(at: parsed.address)
  }

  public func readCell(at address: CellAddress) -> ReadCell? {
    guard contains(address: address) else {
      return nil
    }

    if let existing = readCellsByAddress[address] {
      return applyingMergeMetadata(to: existing, address: address)
    }

    return applyingMergeMetadata(
      to: ReadCell(
        address: address,
        value: .empty,
        kind: .empty,
        formatted: "",
        rawCellType: 0
      ),
      address: address
    )
  }

  public func readCell(_ reference: String) -> ReadCell? {
    guard let parsed = try? CellReference(reference) else {
      return nil
    }
    return readCell(at: parsed.address)
  }

  public var rowCount: Int {
    metadata.rowCount
  }

  public var columnCount: Int {
    metadata.columnCount
  }

  public func rowHeight(at rowIndex: Int) -> Double? {
    guard rowIndex >= 0, rowIndex < metadata.rowCount else {
      return nil
    }
    guard rowIndex < metadata.rowHeights.count else {
      return nil
    }
    return metadata.rowHeights[rowIndex]
  }

  public func columnWidth(at columnIndex: Int) -> Double? {
    guard columnIndex >= 0, columnIndex < metadata.columnCount else {
      return nil
    }
    guard columnIndex < metadata.columnWidths.count else {
      return nil
    }
    return metadata.columnWidths[columnIndex]
  }

  public func cellGeometry(
    at address: CellAddress,
    defaultRowHeight: Double = 20,
    defaultColumnWidth: Double = 100
  ) -> TableCellGeometry? {
    guard contains(address: address) else {
      return nil
    }
    let resolvedDefaultRowHeight = max(defaultRowHeight, 0)
    let resolvedDefaultColumnWidth = max(defaultColumnWidth, 0)

    var originY: Double = 0
    if address.row > 0 {
      for rowIndex in 0..<address.row {
        originY += rowHeight(at: rowIndex) ?? resolvedDefaultRowHeight
      }
    }

    var originX: Double = 0
    if address.column > 0 {
      for columnIndex in 0..<address.column {
        originX += columnWidth(at: columnIndex) ?? resolvedDefaultColumnWidth
      }
    }

    let height = rowHeight(at: address.row) ?? resolvedDefaultRowHeight
    let width = columnWidth(at: address.column) ?? resolvedDefaultColumnWidth
    return TableCellGeometry(originX: originX, originY: originY, width: width, height: height)
  }

  public func cellGeometry(
    _ reference: String,
    defaultRowHeight: Double = 20,
    defaultColumnWidth: Double = 100
  ) -> TableCellGeometry? {
    guard let parsed = try? CellReference(reference) else {
      return nil
    }
    return cellGeometry(
      at: parsed.address,
      defaultRowHeight: defaultRowHeight,
      defaultColumnWidth: defaultColumnWidth
    )
  }

  public var usedRange: CellRange? {
    let populated = readCellsByAddress.keys
    guard let first = populated.first else {
      return nil
    }

    var minRow = first.row
    var maxRow = first.row
    var minColumn = first.column
    var maxColumn = first.column

    for address in populated.dropFirst() {
      minRow = min(minRow, address.row)
      maxRow = max(maxRow, address.row)
      minColumn = min(minColumn, address.column)
      maxColumn = max(maxColumn, address.column)
    }

    return CellRange(
      start: CellAddress(row: minRow, column: minColumn),
      end: CellAddress(row: maxRow, column: maxColumn)
    )
  }

  public func populatedCells(sorted: Bool = true) -> [ReadCell] {
    let values = readCellsByAddress.values.map { applyingMergeMetadata(to: $0, address: $0.address) }
    guard sorted else {
      return values
    }

    return values.sorted { lhs, rhs in
      if lhs.address.row == rhs.address.row {
        return lhs.address.column < rhs.address.column
      }
      return lhs.address.row < rhs.address.row
    }
  }

  public func formula(at address: CellAddress) -> FormulaRead? {
    if let decoded = formulasByAddress[address] {
      return decoded
    }

    guard let readCell = readCell(at: address), readCell.kind == .formula else {
      return nil
    }

    let formulaResult = readCell.formulaResult
    let raw = formulaResult?.rawFormula ?? Self.extractRawFormula(from: readCell.value)
    let tokens: [String]
    if let parsedTokens = formulaResult?.parsedTokens, !parsedTokens.isEmpty {
      tokens = parsedTokens
    } else {
      tokens = raw.map(Self.tokenizeFormula) ?? []
    }
    let astSummary =
      formulaResult?.astSummary
      ?? (tokens.isEmpty ? nil : "Tokenized formula (\(tokens.count) tokens)")
    let computedValue = formulaResult?.computedValue ?? readCell.value
    let computedFormatted = formulaResult?.computedFormatted ?? readCell.formatted

    return FormulaRead(
      address: address,
      reference: CellReference(address: address).a1,
      formulaID: readCell.formulaID,
      rawFormula: raw,
      parsedTokens: tokens,
      astSummary: astSummary,
      result: computedValue,
      resultFormatted: computedFormatted
    )
  }

  public func formula(_ reference: String) -> FormulaRead? {
    guard let parsed = try? CellReference(reference) else {
      return nil
    }
    return formula(at: parsed.address)
  }

  public func richText(at address: CellAddress) -> RichTextRead? {
    readCell(at: address)?.richText
  }

  public func richText(_ reference: String) -> RichTextRead? {
    guard let parsed = try? CellReference(reference) else {
      return nil
    }
    return richText(at: parsed.address)
  }

  public func style(at address: CellAddress) -> ReadCellStyle? {
    readCell(at: address)?.style
  }

  public func style(_ reference: String) -> ReadCellStyle? {
    guard let parsed = try? CellReference(reference) else {
      return nil
    }
    return style(at: parsed.address)
  }

  public func formulaResult(at address: CellAddress) -> FormulaResultRead? {
    readCell(at: address)?.formulaResult
  }

  public func formulaResult(_ reference: String) -> FormulaResultRead? {
    guard let parsed = try? CellReference(reference) else {
      return nil
    }
    return formulaResult(at: parsed.address)
  }

  public func readValue(at address: CellAddress) -> ReadCellValue? {
    readCell(at: address)?.readValue
  }

  public func readValue(_ reference: String) -> ReadCellValue? {
    guard let parsed = try? CellReference(reference) else {
      return nil
    }
    return readValue(at: parsed.address)
  }

  public func formulas() -> [FormulaRead] {
    if !formulasByAddress.isEmpty {
      return formulasByAddress.values.sorted { lhs, rhs in
        if lhs.address.row == rhs.address.row {
          return lhs.address.column < rhs.address.column
        }
        return lhs.address.row < rhs.address.row
      }
    }

    return readCellsByAddress.keys
      .sorted { lhs, rhs in
        if lhs.row == rhs.row {
          return lhs.column < rhs.column
        }
        return lhs.row < rhs.row
      }
      .compactMap { formula(at: $0) }
  }

  public func rows() -> [[CellValue]] {
    guard metadata.rowCount > 0, metadata.columnCount > 0 else {
      return []
    }

    var result: [[CellValue]] = []
    result.reserveCapacity(metadata.rowCount)

    for row in 0..<metadata.rowCount {
      var rowValues = [CellValue]()
      rowValues.reserveCapacity(metadata.columnCount)

      for column in 0..<metadata.columnCount {
        let address = CellAddress(row: row, column: column)
        rowValues.append(cell(at: address) ?? .empty)
      }

      result.append(rowValues)
    }

    return result
  }

  public func rows(valuesOnly: Bool = true) -> [[CellValue]] {
    _ = valuesOnly
    return rows()
  }

  public func rows(lazy: Bool) -> AnySequence<[CellValue]> {
    if !lazy {
      return AnySequence(rows())
    }

    let sequence = (0..<metadata.rowCount).lazy.map { row in
      (0..<metadata.columnCount).map { column in
        cell(at: CellAddress(row: row, column: column)) ?? .empty
      }
    }
    return AnySequence(sequence)
  }

  public func readRows() -> [[ReadCell]] {
    guard metadata.rowCount > 0, metadata.columnCount > 0 else {
      return []
    }

    var result: [[ReadCell]] = []
    result.reserveCapacity(metadata.rowCount)

    for row in 0..<metadata.rowCount {
      var rowValues: [ReadCell] = []
      rowValues.reserveCapacity(metadata.columnCount)
      for column in 0..<metadata.columnCount {
        let address = CellAddress(row: row, column: column)
        if let cell = readCell(at: address) {
          rowValues.append(cell)
        }
      }
      result.append(rowValues)
    }

    return result
  }

  public func readRows(lazy: Bool) -> AnySequence<[ReadCell]> {
    if !lazy {
      return AnySequence(readRows())
    }

    let sequence = (0..<metadata.rowCount).lazy.map { row in
      (0..<metadata.columnCount).compactMap { column in
        readCell(at: CellAddress(row: row, column: column))
      }
    }
    return AnySequence(sequence)
  }

  public func readValues() -> [[ReadCellValue]] {
    readRows().map { row in
      row.map(\.readValue)
    }
  }

  public func readValues(lazy: Bool) -> AnySequence<[ReadCellValue]> {
    if !lazy {
      return AnySequence(readValues())
    }

    let sequence = readRows(lazy: true).lazy.map { row in
      row.map(\.readValue)
    }
    return AnySequence(sequence)
  }

  public func column(named name: String, headerRow: Int = 0, includeHeader: Bool = false) throws
    -> [CellValue]
  {
    guard headerRow >= 0, headerRow < metadata.rowCount else {
      throw TableReadError.outOfBounds(CellAddress(row: headerRow, column: 0))
    }

    let headers = rows()[headerRow]
    guard
      let columnIndex = headers.firstIndex(where: {
        Self.normalizeHeader($0) == Self.normalizeHeader(.string(name))
      })
    else {
      throw TableReadError.headerNotFound(name)
    }

    let startRow = includeHeader ? headerRow : headerRow + 1
    guard startRow < metadata.rowCount else {
      return []
    }

    return (startRow..<metadata.rowCount).map { row in
      cell(at: CellAddress(row: row, column: columnIndex)) ?? .empty
    }
  }

  public func column(at index: Int, from startRow: Int = 0) throws -> [CellValue] {
    guard index >= 0, index < metadata.columnCount else {
      throw TableReadError.outOfBounds(CellAddress(row: 0, column: index))
    }
    guard startRow >= 0, startRow <= metadata.rowCount else {
      throw TableReadError.outOfBounds(CellAddress(row: startRow, column: index))
    }
    guard startRow < metadata.rowCount else {
      return []
    }

    return (startRow..<metadata.rowCount).map { row in
      cell(at: CellAddress(row: row, column: index)) ?? .empty
    }
  }

  public func readColumn(at index: Int, from startRow: Int = 0) throws -> [ReadCell] {
    guard index >= 0, index < metadata.columnCount else {
      throw TableReadError.outOfBounds(CellAddress(row: 0, column: index))
    }
    guard startRow >= 0, startRow <= metadata.rowCount else {
      throw TableReadError.outOfBounds(CellAddress(row: startRow, column: index))
    }
    guard startRow < metadata.rowCount else {
      return []
    }

    return try (startRow..<metadata.rowCount).map { row in
      let address = CellAddress(row: row, column: index)
      guard let read = readCell(at: address) else {
        throw TableReadError.outOfBounds(address)
      }
      return read
    }
  }

  public func values(in rangeReference: String) throws -> [[CellValue]] {
    let range = try parseRangeReference(rangeReference)
    var matrix: [[CellValue]] = []

    for row in range.start.row...range.end.row {
      var rowValues: [CellValue] = []
      for column in range.start.column...range.end.column {
        rowValues.append(cell(at: CellAddress(row: row, column: column)) ?? .empty)
      }
      matrix.append(rowValues)
    }

    return matrix
  }

  public func readCells(in rangeReference: String) throws -> [[ReadCell]] {
    let range = try parseRangeReference(rangeReference)
    var matrix: [[ReadCell]] = []

    for row in range.start.row...range.end.row {
      var rowCells: [ReadCell] = []
      for column in range.start.column...range.end.column {
        let address = CellAddress(row: row, column: column)
        guard let cell = readCell(at: address) else {
          throw TableReadError.outOfBounds(address)
        }
        rowCells.append(cell)
      }
      matrix.append(rowCells)
    }

    return matrix
  }

  public func value<T>(_ type: T.Type, at address: CellAddress) throws -> T {
    guard let readCell = readCell(at: address) else {
      throw TableReadError.outOfBounds(address)
    }

    return try cast(type, from: readCell)
  }

  public func value<T>(_ type: T.Type, at reference: String) throws -> T {
    let parsed: CellReference
    do {
      parsed = try CellReference(reference)
    } catch {
      throw TableReadError.invalidCellReference(reference)
    }
    return try value(type, at: parsed.address)
  }

  public func optionalValue<T>(_ type: T.Type, at address: CellAddress) throws -> T? {
    guard let readCell = readCell(at: address) else {
      throw TableReadError.outOfBounds(address)
    }

    if readCell.value == .empty {
      return nil
    }

    return try cast(type, from: readCell)
  }

  public func optionalValue<T>(_ type: T.Type, at reference: String) throws -> T? {
    let parsed: CellReference
    do {
      parsed = try CellReference(reference)
    } catch {
      throw TableReadError.invalidCellReference(reference)
    }
    return try optionalValue(type, at: parsed.address)
  }

  public func decodeRows<Row: Decodable>(
    as type: Row.Type,
    headerRow: Int = 0,
    decoder: JSONDecoder = JSONDecoder()
  ) throws -> [Row] {
    guard headerRow >= 0, headerRow < metadata.rowCount else {
      throw TableReadError.outOfBounds(CellAddress(row: headerRow, column: 0))
    }

    let matrix = rows()
    let headers = makeUniqueHeaders(from: matrix[headerRow])
    if headers.isEmpty {
      return []
    }

    var decodedRows: [Row] = []
    decodedRows.reserveCapacity(max(metadata.rowCount - (headerRow + 1), 0))

    for rowIndex in (headerRow + 1)..<metadata.rowCount {
      let rowValues = matrix[rowIndex]
      var object: [String: Any] = [:]

      for (column, header) in headers.enumerated() {
        guard column < rowValues.count else {
          continue
        }
        let value = rowValues[column]
        guard value != .empty else {
          continue
        }
        object[header] = jsonObject(for: value)
      }

      if object.isEmpty {
        continue
      }

      do {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        let row = try decoder.decode(Row.self, from: data)
        decodedRows.append(row)
      } catch {
        throw TableReadError.decodingFailed("row \(rowIndex + 1): \(error.localizedDescription)")
      }
    }

    return decodedRows
  }

  public func formattedValue(
    at address: CellAddress,
    options: ReadFormattingOptions = .default
  ) -> String? {
    guard contains(address: address) else {
      return nil
    }

    if let readCell = readCell(at: address) {
      return Self.formattedValueString(for: readCell, options: options)
    }

    let value = cell(at: address) ?? .empty
    return Self.formattedValueString(for: value, options: options)
  }

  public func formattedValue(
    _ reference: String,
    options: ReadFormattingOptions = .default
  ) -> String? {
    guard let parsed = try? CellReference(reference) else {
      return nil
    }

    return formattedValue(at: parsed.address, options: options)
  }

  public func mergeRange(containing address: CellAddress) -> MergeRange? {
    metadata.mergeRanges.first { range in
      address.row >= range.startRow
        && address.row <= range.endRow
        && address.column >= range.startColumn
        && address.column <= range.endColumn
    }
  }

  public func mergeRange(containing reference: String) -> MergeRange? {
    guard let parsed = try? CellReference(reference) else {
      return nil
    }
    return mergeRange(containing: parsed.address)
  }

  public func isMergedCell(at address: CellAddress) -> Bool {
    mergeRange(containing: address) != nil
  }

  public func isMergedCell(_ reference: String) -> Bool {
    mergeRange(containing: reference) != nil
  }

  public var allCells: [CellAddress: CellValue] {
    cells
  }

  public var populatedCellCount: Int {
    readCellsByAddress.count
  }

  private static func normalizeHeader(_ value: CellValue) -> String {
    formattedValueString(for: value, options: .default)
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
  }

  private static func formattedValueString(for readCell: ReadCell, options: ReadFormattingOptions)
    -> String
  {
    formattedValueString(for: readCell.readValue, style: readCell.style, options: options)
  }

  private static func formattedValueString(
    for readValue: ReadCellValue,
    style: ReadCellStyle?,
    options: ReadFormattingOptions
  ) -> String {
    switch readValue {
    case .empty:
      return ""
    case .string(let text):
      return text
    case .number(let number):
      let mode =
        if options.preferCellNumberFormatHints,
        let styleMode = numberFormatModeHint(from: style)
        {
          styleMode
        } else {
          options.numberFormatMode
        }
      return numberString(for: number, mode: mode, options: options)
    case .bool(let bool):
      return bool ? "TRUE" : "FALSE"
    case .date(let date):
      return dateString(for: date, mode: options.dateFormatMode, options: options)
    case .duration(let seconds):
      return durationString(seconds: seconds, mode: options.durationFormatMode, options: options)
    case .error(let message):
      return message
    case .richText(let richText):
      return richText.text
    case .formulaResult(let formulaResult):
      return formattedValueString(
        for: .fromCellValue(formulaResult.computedValue),
        style: style,
        options: options
      )
    }
  }

  private static func formattedValueString(for value: CellValue, options: ReadFormattingOptions)
    -> String
  {
    formattedValueString(for: .fromCellValue(value), style: nil, options: options)
  }

  private static func numberFormatModeHint(from style: ReadCellStyle?) -> ReadNumberFormatMode? {
    guard let numberFormat = style?.numberFormat else {
      return nil
    }

    switch numberFormat.kind {
    case .number:
      return .decimal
    case .currency:
      return .currency(code: nil)
    case .percentage:
      return .percent
    case .scientific:
      return .scientific
    case .fraction:
      return .fraction(maxDenominator: normalizedMaxDenominator(from: numberFormat.formatID))
    case .base:
      return .base(radix: normalizedRadix(from: numberFormat.formatID), uppercase: true)
    case .date, .duration, .text, .bool, .custom:
      return nil
    }
  }

  private static func numberString(
    for value: Double,
    mode: ReadNumberFormatMode,
    options: ReadFormattingOptions
  ) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: options.localeIdentifier)
    formatter.usesGroupingSeparator = options.usesGroupingSeparator
    formatter.minimumFractionDigits = max(options.minimumFractionDigits, 0)
    formatter.maximumFractionDigits = max(
      options.maximumFractionDigits,
      formatter.minimumFractionDigits
    )

    switch mode {
    case .decimal:
      formatter.numberStyle = .decimal
    case .currency(let code):
      formatter.numberStyle = .currency
      if let code, !code.isEmpty {
        formatter.currencyCode = code
      }
    case .percent:
      formatter.numberStyle = .percent
    case .scientific:
      formatter.numberStyle = .scientific
    case .fraction(let maxDenominator):
      return fractionString(for: value, maxDenominator: maxDenominator)
    case .base(let radix, let uppercase):
      return baseString(
        for: value,
        radix: radix,
        uppercase: uppercase,
        maximumFractionDigits: options.maximumFractionDigits
      )
    case .pattern(let pattern):
      formatter.numberStyle = .decimal
      formatter.positiveFormat = pattern
    }

    return formatter.string(from: NSNumber(value: value)) ?? String(value)
  }

  private static func normalizedMaxDenominator(from formatID: Int32) -> Int {
    let raw = abs(Int(formatID))
    let defaultDenominator = 16
    if raw == 0 {
      return defaultDenominator
    }
    return min(max(raw, 2), 1024)
  }

  private static func normalizedRadix(from formatID: Int32) -> Int {
    let raw = abs(Int(formatID))
    let defaultRadix = 16
    if raw == 0 {
      return defaultRadix
    }
    return min(max(raw, 2), 36)
  }

  private static func fractionString(for value: Double, maxDenominator: Int) -> String {
    guard value.isFinite else {
      return String(value)
    }

    let sign = value < 0 ? "-" : ""
    let absolute = abs(value)
    let whole = Int(absolute.rounded(.down))
    let fractional = absolute - Double(whole)
    if fractional < 1e-12 {
      return sign + String(whole)
    }

    let denominatorLimit = min(max(maxDenominator, 2), 4096)
    var bestNumerator = 0
    var bestDenominator = 1
    var bestError = Double.greatestFiniteMagnitude

    for denominator in 1...denominatorLimit {
      let scaled = fractional * Double(denominator)
      let numerator = Int(scaled.rounded())
      let error = abs(scaled - Double(numerator))
      if error < bestError {
        bestError = error
        bestNumerator = numerator
        bestDenominator = denominator
      }
      if error < 1e-10 {
        break
      }
    }

    if bestNumerator == 0 {
      return sign + String(whole)
    }

    if bestNumerator == bestDenominator {
      return sign + String(whole + 1)
    }

    let divisor = greatestCommonDivisor(bestNumerator, bestDenominator)
    let numerator = bestNumerator / divisor
    let denominator = bestDenominator / divisor
    if whole > 0 {
      return "\(sign)\(whole) \(numerator)/\(denominator)"
    }
    return "\(sign)\(numerator)/\(denominator)"
  }

  private static func baseString(
    for value: Double,
    radix: Int,
    uppercase: Bool,
    maximumFractionDigits: Int
  ) -> String {
    guard value.isFinite else {
      return String(value)
    }

    let normalizedRadix = min(max(radix, 2), 36)
    let symbols = uppercase
      ? Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")
      : Array("0123456789abcdefghijklmnopqrstuvwxyz")

    let sign = value < 0 ? "-" : ""
    let absolute = abs(value)
    guard absolute <= Double(Int64.max) else {
      return String(value)
    }

    let wholePart = Int64(absolute.rounded(.towardZero))
    var integerDigits: [Character] = []
    var wholeRemainder = wholePart
    repeat {
      let digit = Int(wholeRemainder % Int64(normalizedRadix))
      integerDigits.append(symbols[digit])
      wholeRemainder /= Int64(normalizedRadix)
    } while wholeRemainder > 0
    let integerString = String(integerDigits.reversed())

    var fractional = absolute - Double(wholePart)
    let fractionDigitLimit = min(max(maximumFractionDigits, 0), 12)
    if fractionDigitLimit == 0 || fractional < 1e-12 {
      return sign + integerString
    }

    var fractionDigits: [Character] = []
    for _ in 0..<fractionDigitLimit {
      if fractional < 1e-12 {
        break
      }
      fractional *= Double(normalizedRadix)
      let digit = Int(fractional.rounded(.down))
      fractionDigits.append(symbols[min(max(digit, 0), normalizedRadix - 1)])
      fractional -= Double(digit)
    }

    while fractionDigits.last == "0" {
      fractionDigits.removeLast()
    }
    if fractionDigits.isEmpty {
      return sign + integerString
    }
    return sign + integerString + "." + String(fractionDigits)
  }

  private static func greatestCommonDivisor(_ lhs: Int, _ rhs: Int) -> Int {
    var a = abs(lhs)
    var b = abs(rhs)
    while b != 0 {
      let remainder = a % b
      a = b
      b = remainder
    }
    return max(a, 1)
  }

  private static func dateString(
    for value: Date,
    mode: ReadDateFormatMode,
    options: ReadFormattingOptions
  ) -> String {
    switch mode {
    case .iso8601:
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions =
        options.includeFractionalSeconds
        ? [.withInternetDateTime, .withFractionalSeconds]
        : [.withInternetDateTime]
      formatter.timeZone = userTimeZone(for: options) ?? TimeZone(secondsFromGMT: 0)
      return formatter.string(from: value)
    case .styled(let dateStyle, let timeStyle):
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: options.localeIdentifier)
      formatter.dateStyle = dateFormatterStyle(for: dateStyle)
      formatter.timeStyle = dateFormatterStyle(for: timeStyle)
      formatter.timeZone = userTimeZone(for: options) ?? TimeZone(secondsFromGMT: 0)
      return formatter.string(from: value)
    case .pattern(let pattern):
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: options.localeIdentifier)
      formatter.timeZone = userTimeZone(for: options) ?? TimeZone(secondsFromGMT: 0)
      formatter.dateFormat =
        pattern.isEmpty ? "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX" : pattern
      return formatter.string(from: value)
    }
  }

  private static func durationString(
    seconds: TimeInterval,
    mode: ReadDurationFormatMode,
    options: ReadFormattingOptions
  ) -> String {
    switch mode {
    case .seconds:
      return numberString(for: seconds, mode: .decimal, options: options)
    case .hhmmss:
      let sign = seconds < 0 ? "-" : ""
      let absolute = Int(abs(seconds.rounded(.towardZero)))
      let hours = absolute / 3600
      let minutes = (absolute % 3600) / 60
      let secs = absolute % 60
      return String(format: "%@%02d:%02d:%02d", sign, hours, minutes, secs)
    case .abbreviated:
      let sign = seconds < 0 ? "-" : ""
      let absolute = Int(abs(seconds.rounded(.towardZero)))
      let hours = absolute / 3600
      let minutes = (absolute % 3600) / 60
      let secs = absolute % 60
      var parts: [String] = []
      if hours > 0 {
        parts.append("\(hours)h")
      }
      if minutes > 0 {
        parts.append("\(minutes)m")
      }
      if secs > 0 || parts.isEmpty {
        parts.append("\(secs)s")
      }
      return sign + parts.joined(separator: " ")
    }
  }

  private static func dateFormatterStyle(for style: ReadDateTimeStyle) -> DateFormatter.Style {
    switch style {
    case .none:
      return .none
    case .short:
      return .short
    case .medium:
      return .medium
    case .long:
      return .long
    case .full:
      return .full
    }
  }

  private static func userTimeZone(for options: ReadFormattingOptions) -> TimeZone? {
    guard let identifier = options.timeZoneIdentifier else {
      return nil
    }
    return TimeZone(identifier: identifier)
  }

  private static func extractRawFormula(from value: CellValue) -> String? {
    switch value {
    case .formula(let text):
      return text
    case .string(let text) where text.hasPrefix("="):
      return text
    default:
      return nil
    }
  }

  private static func tokenizeFormula(_ formula: String) -> [String] {
    if formula.isEmpty {
      return []
    }

    let punctuation = Set<Character>(["(", ")", ",", ":", "+", "-", "*", "/", "^", "&", "=", "<", ">"])
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

  private func contains(address: CellAddress) -> Bool {
    address.row >= 0
      && address.column >= 0
      && address.row < metadata.rowCount
      && address.column < metadata.columnCount
  }

  private func applyingMergeMetadata(to cell: ReadCell, address: CellAddress) -> ReadCell {
    guard let mergeRange = mergeRange(containing: address) else {
      return ReadCell(
        address: cell.address,
        value: cell.value,
        kind: cell.kind,
        readValue: cell.readValue,
        formulaResult: cell.formulaResult,
        formatted: cell.formatted,
        richText: cell.richText,
        style: cell.style,
        rawCellType: cell.rawCellType,
        stringID: cell.stringID,
        richTextID: cell.richTextID,
        formulaID: cell.formulaID,
        formulaErrorID: cell.formulaErrorID,
        mergeRange: nil,
        mergeRole: .none
      )
    }

    let role: MergeRole =
      address.row == mergeRange.startRow && address.column == mergeRange.startColumn
      ? .anchor : .member

    return ReadCell(
      address: cell.address,
      value: cell.value,
      kind: cell.kind,
      readValue: cell.readValue,
      formulaResult: cell.formulaResult,
      formatted: cell.formatted,
      richText: cell.richText,
      style: cell.style,
      rawCellType: cell.rawCellType,
      stringID: cell.stringID,
      richTextID: cell.richTextID,
      formulaID: cell.formulaID,
      formulaErrorID: cell.formulaErrorID,
      mergeRange: mergeRange,
      mergeRole: role
    )
  }

  private func cast<T>(_ type: T.Type, from readCell: ReadCell) throws -> T {
    if type == CellValue.self {
      return readCell.value as! T
    }
    if type == ReadCell.self {
      return readCell as! T
    }
    if type == ReadCellValue.self {
      return readCell.readValue as! T
    }
    if type == FormulaResultRead.self {
      guard let formulaResult = readCell.formulaResult else {
        throw TableReadError.missingValue(readCell.address)
      }
      return formulaResult as! T
    }

    if case .duration(let durationValue) = readCell.readValue, type == TimeInterval.self {
      return durationValue as! T
    }

    switch readCell.value {
    case .string(let value) where type == String.self:
      return value as! T
    case .formula(let value) where type == String.self:
      return value as! T
    case .number(let value) where type == Double.self:
      return value as! T
    case .bool(let value) where type == Bool.self:
      return value as! T
    case .date(let value) where type == Date.self:
      return value as! T
    case .number(let value)
      where type == TimeInterval.self && (readCell.kind == .duration || readCell.kind == .number):
      return value as! T
    case .empty:
      throw TableReadError.missingValue(readCell.address)
    default:
      throw TableReadError.typeMismatch(expected: String(describing: type), actual: readCell.value)
    }
  }

  private func makeUniqueHeaders(from headerValues: [CellValue]) -> [String] {
    var seen: [String: Int] = [:]
    var headers: [String] = []
    headers.reserveCapacity(headerValues.count)

    for (index, value) in headerValues.enumerated() {
      let raw = Self.formattedValueString(for: value, options: .default)
        .trimmingCharacters(in: .whitespacesAndNewlines)
      let base = raw.isEmpty ? "column_\(index + 1)" : raw
      let count = seen[base, default: 0] + 1
      seen[base] = count
      headers.append(count == 1 ? base : "\(base)_\(count)")
    }

    return headers
  }

  private func jsonObject(for value: CellValue) -> Any {
    switch value {
    case .empty:
      return NSNull()
    case .string(let text):
      return text
    case .formula(let text):
      return text
    case .number(let number):
      return number
    case .bool(let bool):
      return bool
    case .date(let date):
      return Self.formattedValueString(for: .date(date), options: .default)
    }
  }

  private func parseRangeReference(_ raw: String) throws -> (start: CellAddress, end: CellAddress) {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      throw TableReadError.invalidRangeReference(raw)
    }

    let parts = trimmed.split(separator: ":", maxSplits: 1).map(String.init)
    guard parts.count == 1 || parts.count == 2 else {
      throw TableReadError.invalidRangeReference(raw)
    }

    let startRef: CellReference
    do {
      startRef = try CellReference(parts[0])
    } catch {
      throw TableReadError.invalidRangeReference(raw)
    }

    let endRef: CellReference
    if parts.count == 2 {
      do {
        endRef = try CellReference(parts[1])
      } catch {
        throw TableReadError.invalidRangeReference(raw)
      }
    } else {
      endRef = startRef
    }

    let normalizedStart = CellAddress(
      row: min(startRef.address.row, endRef.address.row),
      column: min(startRef.address.column, endRef.address.column)
    )
    let normalizedEnd = CellAddress(
      row: max(startRef.address.row, endRef.address.row),
      column: max(startRef.address.column, endRef.address.column)
    )

    guard contains(address: normalizedStart), contains(address: normalizedEnd) else {
      throw TableReadError.invalidRangeReference(raw)
    }

    return (start: normalizedStart, end: normalizedEnd)
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

  public var firstTable: Table? {
    tables.first
  }

  public var tableNames: [String] {
    tables.map(\.name)
  }

  public subscript(_ index: Int) -> Table? {
    table(at: index)
  }

  public subscript(_ name: String) -> Table? {
    table(named: name)
  }

  public func table(named name: String) -> Table? {
    tables.first(where: { $0.name == name })
  }

  public func table(at index: Int) -> Table? {
    guard index >= 0, index < tables.count else {
      return nil
    }
    return tables[index]
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
  public let structuredDiagnostics: [ReadDiagnostic]

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
    diagnostics: [String] = [],
    structuredDiagnostics: [ReadDiagnostic] = []
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
    self.structuredDiagnostics = structuredDiagnostics
  }
}

public enum DocumentReadPath: String, Sendable {
  case real
  case metadataFallback
}
