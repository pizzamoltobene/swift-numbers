import Foundation
import SwiftNumbersContainer
import SwiftNumbersIWA

public enum EditableNumbersError: LocalizedError {
  case sheetNotFound(String)
  case tableNotFound(sheet: String, table: String)
  case duplicateTableName(sheet: String, table: String)
  case invalidCellReference(String)
  case invalidRangeReference(String)
  case invalidRowIndex(Int)
  case invalidColumnIndex(Int)
  case groupedTableMutationUnsupported(sheet: String, table: String, operation: String)
  case pivotLinkedTableMutationUnsupported(sheet: String, table: String, operation: String)
  case nativeWriteFailed(String)

  public var errorDescription: String? {
    switch self {
    case .sheetNotFound(let name):
      return "Sheet not found: \(name)"
    case .tableNotFound(let sheet, let table):
      return "Table not found: \(sheet)/\(table)"
    case .duplicateTableName(let sheet, let table):
      return "Table already exists: \(sheet)/\(table)"
    case .invalidCellReference(let raw):
      return "Invalid cell reference: \(raw)"
    case .invalidRangeReference(let raw):
      return "Invalid range reference: \(raw)"
    case .invalidRowIndex(let row):
      return "Invalid row index: \(row)"
    case .invalidColumnIndex(let column):
      return "Invalid column index: \(column)"
    case .groupedTableMutationUnsupported(let sheet, let table, let operation):
      return
        "Unsafe grouped-table mutation blocked for \(sheet)/\(table) during \(operation). Grouped tables are currently read-only for structural edits. Remove grouping in Apple Numbers and retry."
    case .pivotLinkedTableMutationUnsupported(let sheet, let table, let operation):
      return
        "Unsafe pivot-linked mutation blocked for \(sheet)/\(table) during \(operation). This table is linked to a non-table analytical drawable (pivot-like structure) and is currently read-only for native writes. Remove pivot linkage in Apple Numbers and retry."
    case .nativeWriteFailed(let details):
      return "Swift-native write failed: \(details)"
    }
  }
}

public enum DocumentDirtyState: String, Sendable {
  case clean
  case dataDirty
  case structureDirty
}

public enum EditableCellFormat: Hashable, Sendable {
  case number(formatID: Int32 = 0)
  case date(formatID: Int32 = 0)
  case currency(formatID: Int32 = 0)
  case custom(formatID: Int32)
}

public struct CellReference: Hashable, Sendable, CustomStringConvertible {
  public let address: CellAddress
  public let a1: String

  public var description: String {
    a1
  }

  public init(_ rawValue: String) throws {
    let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    let pattern = #"^([A-Za-z]+)([1-9][0-9]*)$"#
    let range = NSRange(location: 0, length: trimmed.utf16.count)
    let regex = try NSRegularExpression(pattern: pattern)
    guard let match = regex.firstMatch(in: trimmed, options: [], range: range),
      match.numberOfRanges == 3
    else {
      throw EditableNumbersError.invalidCellReference(rawValue)
    }

    guard
      let lettersRange = Range(match.range(at: 1), in: trimmed),
      let numbersRange = Range(match.range(at: 2), in: trimmed),
      let rowOneBased = Int(trimmed[numbersRange]),
      rowOneBased > 0
    else {
      throw EditableNumbersError.invalidCellReference(rawValue)
    }

    let letters = String(trimmed[lettersRange]).uppercased()
    let column = try Self.columnIndex(from: letters, source: rawValue)
    let row = rowOneBased - 1
    self.address = CellAddress(row: row, column: column)
    self.a1 = Self.a1String(row: row, column: column)
  }

  public init(address: CellAddress) {
    self.address = address
    self.a1 = Self.a1String(row: address.row, column: address.column)
  }

  private static func columnIndex(from letters: String, source: String) throws -> Int {
    var value = 0
    for scalar in letters.unicodeScalars {
      guard scalar.value >= 65, scalar.value <= 90 else {
        throw EditableNumbersError.invalidCellReference(source)
      }
      let digit = Int(scalar.value - 64)
      let (multiplied, didOverflowMultiply) = value.multipliedReportingOverflow(by: 26)
      let (next, didOverflowAdd) = multiplied.addingReportingOverflow(digit)
      guard !didOverflowMultiply, !didOverflowAdd else {
        throw EditableNumbersError.invalidCellReference(source)
      }
      value = next
    }
    guard value > 0 else {
      throw EditableNumbersError.invalidCellReference(source)
    }
    return value - 1
  }

  private static func a1String(row: Int, column: Int) -> String {
    var col = column + 1
    var letters: [Character] = []
    while col > 0 {
      let remainder = (col - 1) % 26
      let scalar = UnicodeScalar(65 + remainder)!
      letters.append(Character(scalar))
      col = (col - 1) / 26
    }
    return String(letters.reversed()) + String(max(row + 1, 1))
  }
}

public final class EditableNumbersDocument {
  public let sourceURL: URL
  public private(set) var sheets: [EditableSheet] = []
  public private(set) var dirtyState: DocumentDirtyState = .clean

  private var operations: [EditOperation] = []
  private var workingSourceURL: URL

  public var hasChanges: Bool {
    !operations.isEmpty
  }

  public var firstSheet: EditableSheet? {
    sheets.first
  }

  private init(sourceURL: URL) {
    let normalized = sourceURL.standardizedFileURL
    self.sourceURL = normalized
    self.workingSourceURL = normalized
  }

  public static func open(at url: URL) throws -> EditableNumbersDocument {
    let readOnly = try NumbersDocument.open(at: url)
    let editable = EditableNumbersDocument(sourceURL: url)
    editable.bootstrap(from: readOnly.sheets)
    return editable
  }

  public static func canSaveEditableDocuments() -> Bool {
    true
  }

  public func sheet(named name: String) throws -> EditableSheet {
    guard let sheet = sheets.first(where: { $0.name == name }) else {
      throw EditableNumbersError.sheetNotFound(name)
    }
    return sheet
  }

  @discardableResult
  public func addSheet(named name: String) -> EditableSheet {
    let resolvedName = uniqueSheetName(from: normalizedSheetName(name))
    let sheetID = "sheet-\(UUID().uuidString.lowercased())"
    let table = EditableTable(
      id: "table-\(UUID().uuidString.lowercased())",
      name: "Table 1",
      rowCount: 1,
      columnCount: 1,
      mergeRanges: [],
      cells: [:],
      ownerSheetName: resolvedName,
      mutationSink: makeMutationSink()
    )
    let sheet = EditableSheet(
      id: sheetID,
      name: resolvedName,
      tables: [table],
      ownerDocument: self,
      mutationSink: makeMutationSink()
    )
    sheets.append(sheet)
    record(.addSheet(name: resolvedName), structureDirty: true)
    return sheet
  }

  @discardableResult
  public func addTable(named name: String, rows: Int, columns: Int, onSheetNamed sheetName: String)
    throws -> EditableTable
  {
    let sheet = try self.sheet(named: sheetName)
    return try sheet.addTable(named: name, rows: rows, columns: columns)
  }

  public func save(to outputURL: URL) throws {
    let destination = outputURL.standardizedFileURL
    if destination.path == workingSourceURL.path {
      guard hasChanges else {
        return
      }
      try persistInPlace(at: destination)
      return
    }

    try write(to: destination)
    markSaved()
    workingSourceURL = destination
  }

  private func write(to destinationURL: URL) throws {
    if operations.isEmpty {
      try copyContainer(from: workingSourceURL, to: destinationURL)
      return
    }
    try validateOperationAddressability()

    try NativeWriterBackend.save(
      sourceURL: workingSourceURL,
      destinationURL: destinationURL,
      operations: operations
    )
  }

  public func saveInPlace() throws {
    guard hasChanges else {
      return
    }

    try persistInPlace(at: workingSourceURL)
  }

  private func persistInPlace(at targetURL: URL) throws {
    let fileManager = FileManager.default
    let parent = targetURL.deletingLastPathComponent()
    let tempURL = parent.appendingPathComponent(
      ".swiftnumbers-save-\(UUID().uuidString)-\(targetURL.lastPathComponent)",
      isDirectory: false
    )
    defer {
      if fileManager.fileExists(atPath: tempURL.path) {
        try? fileManager.removeItem(at: tempURL)
      }
    }

    try write(to: tempURL)

    do {
      _ = try fileManager.replaceItemAt(
        targetURL,
        withItemAt: tempURL,
        backupItemName: nil,
        options: [.usingNewMetadataOnly]
      )
    } catch {
      if fileManager.fileExists(atPath: targetURL.path) {
        try fileManager.removeItem(at: targetURL)
      }
      try fileManager.moveItem(at: tempURL, to: targetURL)
    }

    markSaved()
    workingSourceURL = targetURL
  }

  private func markSaved() {
    operations.removeAll(keepingCapacity: true)
    dirtyState = .clean
    for sheet in sheets {
      sheet.markClean()
    }
  }

  private func bootstrap(from sourceSheets: [Sheet]) {
    let sink = makeMutationSink()
    self.sheets = sourceSheets.map { sourceSheet in
      let editableTables = sourceSheet.tables.map { table in
        let styleCells: [CellAddress: ReadCellStyle] = Dictionary(
          uniqueKeysWithValues: table.populatedCells(sorted: false).compactMap { readCell in
            guard let style = readCell.style else {
              return nil
            }
            return (readCell.address, style)
          })
        return EditableTable(
          id: table.id,
          name: table.name,
          rowCount: table.metadata.rowCount,
          columnCount: table.metadata.columnCount,
          mergeRanges: table.metadata.mergeRanges,
          objectIdentifiers: table.metadata.objectIdentifiers,
          pivotLinks: table.metadata.pivotLinks,
          tableNameVisible: table.metadata.tableNameVisible,
          captionVisible: table.metadata.captionVisible,
          captionText: table.metadata.captionText,
          captionTextSupported: table.metadata.captionTextSupported,
          cells: table.allCells,
          cellStyles: styleCells,
          ownerSheetName: sourceSheet.name,
          mutationSink: sink
        )
      }
      return EditableSheet(
        id: sourceSheet.id,
        name: sourceSheet.name,
        tables: editableTables,
        ownerDocument: self,
        mutationSink: sink
      )
    }
  }

  private func makeMutationSink() -> MutationSink {
    { [weak self] operation, structureDirty in
      self?.record(operation, structureDirty: structureDirty)
    }
  }

  private func record(_ operation: EditOperation, structureDirty: Bool) {
    operations.append(operation)
    if structureDirty {
      dirtyState = .structureDirty
    } else if dirtyState == .clean {
      dirtyState = .dataDirty
    }
  }

  private func copyContainer(from sourceURL: URL, to destinationURL: URL) throws {
    try NumbersContainer.copyContainer(from: sourceURL, to: destinationURL)
  }

  private func validateOperationAddressability() throws {
    let hasAddTableOperation = operations.contains {
      if case .addTable = $0 {
        return true
      }
      return false
    }
    if hasAddTableOperation {
      let duplicateSheetNames = Dictionary(grouping: sheets, by: \.name)
        .filter { $0.value.count > 1 }
        .keys
        .sorted()
      if !duplicateSheetNames.isEmpty {
        let names = duplicateSheetNames.joined(separator: ", ")
        throw EditableNumbersError.nativeWriteFailed(
          "Ambiguous sheet name(s) for addTable operation: \(names)")
      }
    }

    var tableNameKeys: [SheetTableNameKey: Int] = [:]
    for sheet in sheets {
      for table in sheet.tables {
        let key = SheetTableNameKey(sheet: sheet.name, table: table.name)
        tableNameKeys[key, default: 0] += 1
      }
    }
    if let duplicateKey = tableNameKeys.first(where: { $0.value > 1 })?.key {
      throw EditableNumbersError.nativeWriteFailed(
        "Ambiguous table identity for write operation: \(duplicateKey.sheet)/\(duplicateKey.table)"
      )
    }
  }

  private func normalizedSheetName(_ raw: String) -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmed.isEmpty {
      return trimmed
    }
    return "Sheet \(max(sheets.count + 1, 1))"
  }

  private func uniqueSheetName(from candidate: String) -> String {
    guard sheets.contains(where: { $0.name == candidate }) else {
      return candidate
    }

    var index = 2
    while true {
      let suffixed = "\(candidate) (\(index))"
      if !sheets.contains(where: { $0.name == suffixed }) {
        return suffixed
      }
      index += 1
    }
  }
}

private struct SheetTableNameKey: Hashable {
  let sheet: String
  let table: String
}

public final class EditableSheet {
  public let id: String
  public let name: String
  public private(set) var tables: [EditableTable]
  public private(set) var isDirty: Bool = false

  private unowned let ownerDocument: EditableNumbersDocument
  private let mutationSink: MutationSink

  public var firstTable: EditableTable? {
    tables.first
  }

  fileprivate init(
    id: String,
    name: String,
    tables: [EditableTable],
    ownerDocument: EditableNumbersDocument,
    mutationSink: @escaping MutationSink
  ) {
    self.id = id
    self.name = name
    self.tables = tables
    self.ownerDocument = ownerDocument
    self.mutationSink = mutationSink
  }

  public func table(named name: String) throws -> EditableTable {
    guard let table = tables.first(where: { $0.name == name }) else {
      throw EditableNumbersError.tableNotFound(sheet: self.name, table: name)
    }
    return table
  }

  @discardableResult
  public func addTable(named name: String, rows: Int, columns: Int) throws -> EditableTable {
    guard rows >= 0 else {
      throw EditableNumbersError.invalidRowIndex(rows)
    }
    guard columns >= 0 else {
      throw EditableNumbersError.invalidColumnIndex(columns)
    }
    let resolvedName = normalizedTableName(name)
    guard !tables.contains(where: { $0.name == resolvedName }) else {
      throw EditableNumbersError.duplicateTableName(sheet: self.name, table: resolvedName)
    }

    let table = EditableTable(
      id: "table-\(UUID().uuidString.lowercased())",
      name: resolvedName,
      rowCount: rows,
      columnCount: columns,
      mergeRanges: [],
      cells: [:],
      ownerSheetName: self.name,
      mutationSink: mutationSink
    )
    tables.append(table)
    isDirty = true
    mutationSink(
      .addTable(sheetName: self.name, tableName: resolvedName, rows: rows, columns: columns),
      true
    )
    _ = ownerDocument  // keeps lifetime explicit
    return table
  }

  fileprivate func markClean() {
    isDirty = false
    for table in tables {
      table.markClean()
    }
  }

  private func normalizedTableName(_ raw: String) -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmed.isEmpty {
      return trimmed
    }
    return "Table \(max(tables.count + 1, 1))"
  }
}

public final class EditableTable {
  public let id: String
  public let name: String
  public private(set) var isDirty: Bool = false
  public private(set) var isStructureDirty: Bool = false

  private(set) var rowCount: Int
  private(set) var columnCount: Int
  private(set) var mergeRanges: [MergeRange]
  private var objectIdentifiers: TableObjectIdentifiers?
  private var pivotLinks: [PivotLinkMetadata]
  private var tableNameVisible: Bool?
  private var captionVisible: Bool?
  private var captionText: String?
  private var captionTextSupported: Bool
  private var cells: [CellAddress: CellValue]
  private var cellStyles: [CellAddress: ReadCellStyle]
  private var dirtyCells: Set<CellAddress> = []
  private let ownerSheetName: String
  private let mutationSink: MutationSink

  public var metadata: TableMetadata {
    TableMetadata(
      rowCount: rowCount,
      columnCount: columnCount,
      mergeRanges: mergeRanges,
      tableNameVisible: tableNameVisible,
      captionVisible: captionVisible,
      captionText: captionText,
      captionTextSupported: captionTextSupported,
      objectIdentifiers: objectIdentifiers,
      pivotLinks: pivotLinks
    )
  }

  public var populatedCellCount: Int {
    cells.count
  }

  fileprivate var allCells: [CellAddress: CellValue] {
    cells
  }

  fileprivate var allCellStyles: [CellAddress: ReadCellStyle] {
    cellStyles
  }

  fileprivate init(
    id: String,
    name: String,
    rowCount: Int,
    columnCount: Int,
    mergeRanges: [MergeRange],
    objectIdentifiers: TableObjectIdentifiers? = nil,
    pivotLinks: [PivotLinkMetadata] = [],
    tableNameVisible: Bool? = nil,
    captionVisible: Bool? = nil,
    captionText: String? = nil,
    captionTextSupported: Bool = false,
    cells: [CellAddress: CellValue],
    cellStyles: [CellAddress: ReadCellStyle] = [:],
    ownerSheetName: String,
    mutationSink: @escaping MutationSink
  ) {
    self.id = id
    self.name = name
    self.rowCount = rowCount
    self.columnCount = columnCount
    self.mergeRanges = mergeRanges
    self.objectIdentifiers = objectIdentifiers
    self.pivotLinks = pivotLinks
    self.tableNameVisible = tableNameVisible
    self.captionVisible = captionVisible
    self.captionText = captionText
    self.captionTextSupported = captionTextSupported
    self.cells = cells
    self.cellStyles = cellStyles
    self.ownerSheetName = ownerSheetName
    self.mutationSink = mutationSink
  }

  public func cell(at address: CellAddress) -> CellValue? {
    cells[address]
  }

  public func style(at address: CellAddress) -> ReadCellStyle? {
    cellStyles[address]
  }

  public func format(at address: CellAddress) -> EditableCellFormat? {
    guard let numberFormat = cellStyles[address]?.numberFormat else {
      return nil
    }
    return EditableCellFormat(numberFormat: numberFormat)
  }

  public func cell(_ reference: String) throws -> EditableCell {
    let parsed = try CellReference(reference)
    return EditableCell(table: self, address: parsed.address)
  }

  public func cell(at reference: CellReference) -> EditableCell {
    EditableCell(table: self, address: reference.address)
  }

  public var isTableNameVisible: Bool? {
    tableNameVisible
  }

  public var isCaptionVisible: Bool? {
    captionVisible
  }

  public var tableCaptionText: String? {
    captionText
  }

  public func setTableNameVisible(_ isVisible: Bool) throws {
    guard tableNameVisible != nil else {
      throw EditableNumbersError.nativeWriteFailed(
        "Table name visibility metadata is unavailable for this table."
      )
    }
    guard tableNameVisible != isVisible else {
      return
    }
    tableNameVisible = isVisible
    markDirty(structureChanged: false)
    mutationSink(
      .setTableNameVisibility(
        sheetName: ownerSheetName,
        tableName: name,
        isVisible: isVisible
      ),
      false
    )
  }

  public func setCaptionVisible(_ isVisible: Bool) throws {
    guard captionVisible != nil else {
      throw EditableNumbersError.nativeWriteFailed(
        "Caption visibility metadata is unavailable for this table."
      )
    }
    guard captionVisible != isVisible else {
      return
    }
    captionVisible = isVisible
    markDirty(structureChanged: false)
    mutationSink(
      .setCaptionVisibility(
        sheetName: ownerSheetName,
        tableName: name,
        isVisible: isVisible
      ),
      false
    )
  }

  public func setCaptionText(_ text: String) throws {
    guard captionTextSupported else {
      throw EditableNumbersError.nativeWriteFailed(
        "Caption text storage is unavailable for this table."
      )
    }
    guard captionText != text else {
      return
    }
    captionText = text
    markDirty(structureChanged: false)
    mutationSink(
      .setCaptionText(
        sheetName: ownerSheetName,
        tableName: name,
        text: text
      ),
      false
    )
  }

  public func setValue(_ value: CellValue, at address: CellAddress) {
    guard address.row >= 0, address.column >= 0 else {
      return
    }

    let structureChanged = ensureCapacity(for: address)
    if value == .empty {
      cells.removeValue(forKey: address)
    } else {
      cells[address] = value
    }
    markDirty(address: address, structureChanged: structureChanged)
    mutationSink(
      .setCell(
        sheetName: ownerSheetName,
        tableName: name,
        row: address.row,
        column: address.column,
        value: value
      ),
      structureChanged
    )
  }

  public func setValue(_ value: CellValue, at reference: String) throws {
    let parsed = try CellReference(reference)
    setValue(value, at: parsed.address)
  }

  public func setStyle(_ style: ReadCellStyle?, at address: CellAddress) {
    guard address.row >= 0, address.column >= 0 else {
      return
    }

    let structureChanged = ensureCapacity(for: address)
    if let style {
      cellStyles[address] = style
    } else {
      cellStyles.removeValue(forKey: address)
    }
    markDirty(address: address, structureChanged: structureChanged)
    mutationSink(
      .setCellStyle(
        sheetName: ownerSheetName,
        tableName: name,
        row: address.row,
        column: address.column,
        style: style
      ),
      structureChanged
    )
  }

  public func setStyle(_ style: ReadCellStyle?, at reference: String) throws {
    let parsed = try CellReference(reference)
    setStyle(style, at: parsed.address)
  }

  public func setFormat(_ format: EditableCellFormat?, at address: CellAddress) {
    guard address.row >= 0, address.column >= 0 else {
      return
    }

    let currentStyle = cellStyles[address]
    let nextNumberFormat = format.map(\.readNumberFormat)
    let nextStyle: ReadCellStyle?
    if let currentStyle {
      let updatedStyle = Self.styleByUpdatingNumberFormat(
        currentStyle,
        numberFormat: nextNumberFormat
      )
      nextStyle = Self.styleHasVisibleFields(updatedStyle) ? updatedStyle : nil
    } else if let nextNumberFormat {
      nextStyle = ReadCellStyle(numberFormat: nextNumberFormat)
    } else {
      nextStyle = nil
    }

    guard currentStyle != nextStyle else {
      return
    }
    setStyle(nextStyle, at: address)
  }

  public func setFormat(_ format: EditableCellFormat?, at reference: String) throws {
    let parsed = try CellReference(reference)
    setFormat(format, at: parsed.address)
  }

  public func format(_ reference: String) -> EditableCellFormat? {
    guard let parsed = try? CellReference(reference) else {
      return nil
    }
    return format(at: parsed.address)
  }

  public func appendRow(_ values: [CellValue]) {
    let rowIndex = rowCount
    rowCount += 1
    if values.count > columnCount {
      columnCount = values.count
    }
    for (column, value) in values.enumerated() where value != .empty {
      cells[CellAddress(row: rowIndex, column: column)] = value
    }
    markDirty(structureChanged: true)
    mutationSink(.appendRow(sheetName: ownerSheetName, tableName: name, values: values), true)
  }

  public func insertRow(_ values: [CellValue], at rowIndex: Int) throws {
    guard rowIndex >= 0, rowIndex <= rowCount else {
      throw EditableNumbersError.invalidRowIndex(rowIndex)
    }

    var shifted: [CellAddress: CellValue] = [:]
    shifted.reserveCapacity(cells.count + values.count)

    for (address, value) in cells {
      if address.row >= rowIndex {
        shifted[CellAddress(row: address.row + 1, column: address.column)] = value
      } else {
        shifted[address] = value
      }
    }
    cells = shifted

    rowCount += 1
    if values.count > columnCount {
      columnCount = values.count
    }

    for (column, value) in values.enumerated() where value != .empty {
      cells[CellAddress(row: rowIndex, column: column)] = value
    }

    markDirty(structureChanged: true)
    mutationSink(
      .insertRow(
        sheetName: ownerSheetName,
        tableName: name,
        rowIndex: rowIndex,
        values: values
      ),
      true
    )
  }

  public func appendColumn(_ values: [CellValue]) {
    let columnIndex = columnCount
    columnCount += 1
    if values.count > rowCount {
      rowCount = values.count
    }
    for (row, value) in values.enumerated() where value != .empty {
      cells[CellAddress(row: row, column: columnIndex)] = value
    }
    markDirty(structureChanged: true)
    mutationSink(
      .appendColumn(sheetName: ownerSheetName, tableName: name, values: values),
      true
    )
  }

  public func deleteRow(at rowIndex: Int) throws {
    guard rowIndex >= 0, rowIndex < rowCount else {
      throw EditableNumbersError.invalidRowIndex(rowIndex)
    }

    var shiftedCells: [CellAddress: CellValue] = [:]
    shiftedCells.reserveCapacity(cells.count)
    for (address, value) in cells {
      if address.row == rowIndex {
        continue
      }
      if address.row > rowIndex {
        shiftedCells[CellAddress(row: address.row - 1, column: address.column)] = value
      } else {
        shiftedCells[address] = value
      }
    }
    cells = shiftedCells

    var shiftedStyles: [CellAddress: ReadCellStyle] = [:]
    shiftedStyles.reserveCapacity(cellStyles.count)
    for (address, style) in cellStyles {
      if address.row == rowIndex {
        continue
      }
      if address.row > rowIndex {
        shiftedStyles[CellAddress(row: address.row - 1, column: address.column)] = style
      } else {
        shiftedStyles[address] = style
      }
    }
    cellStyles = shiftedStyles

    rowCount -= 1
    mergeRanges = Self.mergeRangesByDeletingRow(rowIndex, from: mergeRanges)

    markDirty(structureChanged: true)
    mutationSink(.deleteRow(sheetName: ownerSheetName, tableName: name, rowIndex: rowIndex), true)
  }

  public func deleteColumn(at columnIndex: Int) throws {
    guard columnIndex >= 0, columnIndex < columnCount else {
      throw EditableNumbersError.invalidColumnIndex(columnIndex)
    }

    var shiftedCells: [CellAddress: CellValue] = [:]
    shiftedCells.reserveCapacity(cells.count)
    for (address, value) in cells {
      if address.column == columnIndex {
        continue
      }
      if address.column > columnIndex {
        shiftedCells[CellAddress(row: address.row, column: address.column - 1)] = value
      } else {
        shiftedCells[address] = value
      }
    }
    cells = shiftedCells

    var shiftedStyles: [CellAddress: ReadCellStyle] = [:]
    shiftedStyles.reserveCapacity(cellStyles.count)
    for (address, style) in cellStyles {
      if address.column == columnIndex {
        continue
      }
      if address.column > columnIndex {
        shiftedStyles[CellAddress(row: address.row, column: address.column - 1)] = style
      } else {
        shiftedStyles[address] = style
      }
    }
    cellStyles = shiftedStyles

    columnCount -= 1
    mergeRanges = Self.mergeRangesByDeletingColumn(columnIndex, from: mergeRanges)

    markDirty(structureChanged: true)
    mutationSink(
      .deleteColumn(sheetName: ownerSheetName, tableName: name, columnIndex: columnIndex),
      true
    )
  }

  public func mergeCells(_ rangeReference: String) throws {
    let range = try Self.parseMergeRange(rangeReference)
    try mergeCells(range)
  }

  public func mergeCells(from start: CellAddress, to end: CellAddress) throws {
    try mergeCells(Self.normalizedMergeRange(from: start, to: end))
  }

  public func unmergeCells(_ rangeReference: String) throws {
    let range = try Self.parseMergeRange(rangeReference)
    unmergeCells(range)
  }

  public func unmergeCells(from start: CellAddress, to end: CellAddress) {
    unmergeCells(Self.normalizedMergeRange(from: start, to: end))
  }

  fileprivate func value(for address: CellAddress) -> CellValue? {
    cells[address]
  }

  fileprivate func style(for address: CellAddress) -> ReadCellStyle? {
    cellStyles[address]
  }

  fileprivate func format(for address: CellAddress) -> EditableCellFormat? {
    format(at: address)
  }

  private func ensureCapacity(for address: CellAddress) -> Bool {
    var structureChanged = false
    if address.row >= rowCount {
      rowCount = address.row + 1
      structureChanged = true
    }
    if address.column >= columnCount {
      columnCount = address.column + 1
      structureChanged = true
    }
    return structureChanged
  }

  private func mergeCells(_ range: MergeRange) throws {
    if range.startRow < 0 || range.startColumn < 0 {
      throw EditableNumbersError.invalidRangeReference(
        "\(CellReference(address: CellAddress(row: range.startRow, column: range.startColumn)).a1):\(CellReference(address: CellAddress(row: range.endRow, column: range.endColumn)).a1)"
      )
    }

    let structureChanged = ensureCapacity(
      for: CellAddress(row: range.endRow, column: range.endColumn))

    for existing in mergeRanges where Self.rangesOverlap(existing, range) && existing != range {
      throw EditableNumbersError.nativeWriteFailed(
        "Overlapping merge range is not supported: \(Self.mergeRangeA1(existing))")
    }

    if mergeRanges.contains(range) {
      return
    }

    mergeRanges.append(range)
    mergeRanges.sort(by: Self.mergeRangeSort)
    markDirty(structureChanged: structureChanged)
    mutationSink(
      .mergeCells(sheetName: ownerSheetName, tableName: name, range: range),
      structureChanged
    )
  }

  private func unmergeCells(_ range: MergeRange) {
    let originalCount = mergeRanges.count
    mergeRanges.removeAll { $0 == range }
    guard mergeRanges.count != originalCount else {
      return
    }
    mergeRanges.sort(by: Self.mergeRangeSort)
    markDirty(structureChanged: false)
    mutationSink(
      .unmergeCells(sheetName: ownerSheetName, tableName: name, range: range),
      false
    )
  }

  private static func parseMergeRange(_ raw: String) throws -> MergeRange {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      throw EditableNumbersError.invalidRangeReference(raw)
    }

    let parts = trimmed.split(separator: ":", maxSplits: 1).map(String.init)
    guard parts.count == 1 || parts.count == 2 else {
      throw EditableNumbersError.invalidRangeReference(raw)
    }

    let start: CellReference
    do {
      start = try CellReference(parts[0])
    } catch {
      throw EditableNumbersError.invalidRangeReference(raw)
    }

    let end: CellReference
    if parts.count == 2 {
      do {
        end = try CellReference(parts[1])
      } catch {
        throw EditableNumbersError.invalidRangeReference(raw)
      }
    } else {
      end = start
    }

    return normalizedMergeRange(from: start.address, to: end.address)
  }

  private static func normalizedMergeRange(from start: CellAddress, to end: CellAddress) -> MergeRange
  {
    MergeRange(
      startRow: min(start.row, end.row),
      endRow: max(start.row, end.row),
      startColumn: min(start.column, end.column),
      endColumn: max(start.column, end.column)
    )
  }

  private static func rangesOverlap(_ lhs: MergeRange, _ rhs: MergeRange) -> Bool {
    !(lhs.endRow < rhs.startRow
      || rhs.endRow < lhs.startRow
      || lhs.endColumn < rhs.startColumn
      || rhs.endColumn < lhs.startColumn)
  }

  private static func mergeRangeSort(_ lhs: MergeRange, _ rhs: MergeRange) -> Bool {
    if lhs.startRow != rhs.startRow {
      return lhs.startRow < rhs.startRow
    }
    if lhs.startColumn != rhs.startColumn {
      return lhs.startColumn < rhs.startColumn
    }
    if lhs.endRow != rhs.endRow {
      return lhs.endRow < rhs.endRow
    }
    return lhs.endColumn < rhs.endColumn
  }

  private static func mergeRangesByDeletingRow(_ rowIndex: Int, from ranges: [MergeRange])
    -> [MergeRange]
  {
    var updated: [MergeRange] = []
    updated.reserveCapacity(ranges.count)

    for range in ranges {
      if rowIndex < range.startRow {
        updated.append(
          MergeRange(
            startRow: range.startRow - 1,
            endRow: range.endRow - 1,
            startColumn: range.startColumn,
            endColumn: range.endColumn
          ))
        continue
      }
      if rowIndex > range.endRow {
        updated.append(range)
      }
    }

    updated.sort(by: mergeRangeSort)
    return updated
  }

  private static func mergeRangesByDeletingColumn(_ columnIndex: Int, from ranges: [MergeRange])
    -> [MergeRange]
  {
    var updated: [MergeRange] = []
    updated.reserveCapacity(ranges.count)

    for range in ranges {
      if columnIndex < range.startColumn {
        updated.append(
          MergeRange(
            startRow: range.startRow,
            endRow: range.endRow,
            startColumn: range.startColumn - 1,
            endColumn: range.endColumn - 1
          ))
        continue
      }
      if columnIndex > range.endColumn {
        updated.append(range)
      }
    }

    updated.sort(by: mergeRangeSort)
    return updated
  }

  private static func mergeRangeA1(_ range: MergeRange) -> String {
    let start = CellReference(address: CellAddress(row: range.startRow, column: range.startColumn))
      .a1
    let end = CellReference(address: CellAddress(row: range.endRow, column: range.endColumn)).a1
    return "\(start):\(end)"
  }

  private func markDirty(address: CellAddress? = nil, structureChanged: Bool) {
    isDirty = true
    if structureChanged {
      isStructureDirty = true
    }
    if let address {
      dirtyCells.insert(address)
    }
  }

  fileprivate func markClean() {
    isDirty = false
    isStructureDirty = false
    dirtyCells.removeAll(keepingCapacity: true)
  }

  private static func styleByUpdatingNumberFormat(
    _ style: ReadCellStyle,
    numberFormat: ReadNumberFormat?
  ) -> ReadCellStyle {
    ReadCellStyle(
      horizontalAlignment: style.horizontalAlignment,
      verticalAlignment: style.verticalAlignment,
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
      numberFormat: numberFormat
    )
  }

  private static func styleHasVisibleFields(_ style: ReadCellStyle) -> Bool {
    style.horizontalAlignment != nil
      || style.verticalAlignment != nil
      || style.backgroundColorHex != nil
      || style.fontName != nil
      || style.fontSize != nil
      || style.isBold != nil
      || style.isItalic != nil
      || style.textColorHex != nil
      || style.hasTopBorder
      || style.hasRightBorder
      || style.hasBottomBorder
      || style.hasLeftBorder
      || style.numberFormat != nil
  }
}

public final class EditableCell {
  public let address: CellAddress
  private unowned let table: EditableTable

  fileprivate init(table: EditableTable, address: CellAddress) {
    self.table = table
    self.address = address
  }

  public var value: CellValue? {
    get { table.value(for: address) }
    set { table.setValue(newValue ?? .empty, at: address) }
  }

  public var style: ReadCellStyle? {
    get { table.style(for: address) }
    set { table.setStyle(newValue, at: address) }
  }

  public var format: EditableCellFormat? {
    get { table.format(for: address) }
    set { table.setFormat(newValue, at: address) }
  }
}

private extension EditableCellFormat {
  var readNumberFormat: ReadNumberFormat {
    switch self {
    case .number(let formatID):
      return ReadNumberFormat(kind: .number, formatID: formatID)
    case .date(let formatID):
      return ReadNumberFormat(kind: .date, formatID: formatID)
    case .currency(let formatID):
      return ReadNumberFormat(kind: .currency, formatID: formatID)
    case .custom(let formatID):
      return ReadNumberFormat(kind: .custom, formatID: formatID)
    }
  }

  init(numberFormat: ReadNumberFormat) {
    switch numberFormat.kind {
    case .number:
      self = .number(formatID: numberFormat.formatID)
    case .date:
      self = .date(formatID: numberFormat.formatID)
    case .currency:
      self = .currency(formatID: numberFormat.formatID)
    case .custom, .duration, .text, .bool:
      self = .custom(formatID: numberFormat.formatID)
    }
  }
}

private typealias MutationSink = (EditOperation, Bool) -> Void

enum EditOperation {
  case setCell(sheetName: String, tableName: String, row: Int, column: Int, value: CellValue)
  case setCellStyle(
    sheetName: String,
    tableName: String,
    row: Int,
    column: Int,
    style: ReadCellStyle?
  )
  case appendRow(sheetName: String, tableName: String, values: [CellValue])
  case insertRow(sheetName: String, tableName: String, rowIndex: Int, values: [CellValue])
  case appendColumn(sheetName: String, tableName: String, values: [CellValue])
  case deleteRow(sheetName: String, tableName: String, rowIndex: Int)
  case deleteColumn(sheetName: String, tableName: String, columnIndex: Int)
  case mergeCells(sheetName: String, tableName: String, range: MergeRange)
  case unmergeCells(sheetName: String, tableName: String, range: MergeRange)
  case setTableNameVisibility(sheetName: String, tableName: String, isVisible: Bool)
  case setCaptionVisibility(sheetName: String, tableName: String, isVisible: Bool)
  case setCaptionText(sheetName: String, tableName: String, text: String)
  case addTable(sheetName: String, tableName: String, rows: Int, columns: Int)
  case addSheet(name: String)
}

private enum NativeWriterBackend {
  static func save(
    sourceURL: URL,
    destinationURL: URL,
    operations: [EditOperation]
  ) throws {
    let lowLevelOperations = try IWASetCellWriter.lowLevelOperations(from: operations)
    try IWASetCellWriter.save(
      sourceURL: sourceURL,
      destinationURL: destinationURL,
      operations: lowLevelOperations
    )
  }
}
