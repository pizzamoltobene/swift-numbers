import Foundation
import SwiftNumbersContainer
import SwiftNumbersIWA
import SwiftNumbersProto
import SwiftProtobuf

public enum EditableNumbersError: LocalizedError {
  case sheetNotFound(String)
  case tableNotFound(sheet: String, table: String)
  case duplicateTableName(sheet: String, table: String)
  case invalidCellReference(String)
  case invalidRowIndex(Int)
  case invalidColumnIndex(Int)
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
    case .invalidRowIndex(let row):
      return "Invalid row index: \(row)"
    case .invalidColumnIndex(let column):
      return "Invalid column index: \(column)"
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
  private let sourceDocumentID: String?

  public var hasChanges: Bool {
    !operations.isEmpty
  }

  public var firstSheet: EditableSheet? {
    sheets.first
  }

  private init(sourceURL: URL, sourceDocumentID: String?) {
    let normalized = sourceURL.standardizedFileURL
    self.sourceURL = normalized
    self.workingSourceURL = normalized
    self.sourceDocumentID = sourceDocumentID
  }

  public static func open(at url: URL) throws -> EditableNumbersDocument {
    let readOnly = try NumbersDocument.open(at: url)
    let sourceMetadataDocumentID = try loadSourceMetadataDocumentID(from: url)
    let editable = EditableNumbersDocument(
      sourceURL: url,
      sourceDocumentID: sourceMetadataDocumentID
    )
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
      sourceDocumentID: sourceDocumentID,
      operations: operations,
      sheets: sheets
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
        EditableTable(
          id: table.id,
          name: table.name,
          rowCount: table.metadata.rowCount,
          columnCount: table.metadata.columnCount,
          mergeRanges: table.metadata.mergeRanges,
          cells: table.allCells,
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

  private static func loadSourceMetadataDocumentID(from url: URL) throws -> String? {
    let container = try NumbersContainer.open(at: url)
    return try MetadataLoader.loadDocumentMetadata(from: container)?.documentID
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
  private var cells: [CellAddress: CellValue]
  private var dirtyCells: Set<CellAddress> = []
  private let ownerSheetName: String
  private let mutationSink: MutationSink

  public var metadata: TableMetadata {
    TableMetadata(
      rowCount: rowCount,
      columnCount: columnCount,
      mergeRanges: mergeRanges
    )
  }

  public var populatedCellCount: Int {
    cells.count
  }

  fileprivate var allCells: [CellAddress: CellValue] {
    cells
  }

  fileprivate init(
    id: String,
    name: String,
    rowCount: Int,
    columnCount: Int,
    mergeRanges: [MergeRange],
    cells: [CellAddress: CellValue],
    ownerSheetName: String,
    mutationSink: @escaping MutationSink
  ) {
    self.id = id
    self.name = name
    self.rowCount = rowCount
    self.columnCount = columnCount
    self.mergeRanges = mergeRanges
    self.cells = cells
    self.ownerSheetName = ownerSheetName
    self.mutationSink = mutationSink
  }

  public func cell(at address: CellAddress) -> CellValue? {
    cells[address]
  }

  public func cell(_ reference: String) throws -> EditableCell {
    let parsed = try CellReference(reference)
    return EditableCell(table: self, address: parsed.address)
  }

  public func cell(at reference: CellReference) -> EditableCell {
    EditableCell(table: self, address: reference.address)
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

  fileprivate func value(for address: CellAddress) -> CellValue? {
    cells[address]
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
}

private typealias MutationSink = (EditOperation, Bool) -> Void

enum EditOperation {
  case setCell(sheetName: String, tableName: String, row: Int, column: Int, value: CellValue)
  case appendRow(sheetName: String, tableName: String, values: [CellValue])
  case insertRow(sheetName: String, tableName: String, rowIndex: Int, values: [CellValue])
  case appendColumn(sheetName: String, tableName: String, values: [CellValue])
  case addTable(sheetName: String, tableName: String, rows: Int, columns: Int)
  case addSheet(name: String)
}

private enum NativeWriterBackend {
  private static let editableDocumentIDPrefix = "swiftnumbers-editable-v1:"
  private static let editableDateMarkerPrefix = "__SWIFTNUMBERS_DATE__:"

  static func save(
    sourceURL: URL,
    destinationURL: URL,
    sourceDocumentID: String?,
    operations: [EditOperation],
    sheets: [EditableSheet]
  ) throws {
    if let lowLevelOperations = IWASetCellWriter.lowLevelOperations(from: operations) {
      do {
        try IWASetCellWriter.save(
          sourceURL: sourceURL,
          destinationURL: destinationURL,
          operations: lowLevelOperations
        )
        try refreshEditableOverlayIfNeeded(
          destinationURL: destinationURL,
          sourceDocumentID: sourceDocumentID,
          sheets: sheets
        )
        return
      } catch {
        // The low-level path is still being hardened; keep metadata overlay as
        // a safety net for unsupported files/structures.
      }
    }

    try saveUsingMetadataOverlay(
      sourceURL: sourceURL,
      destinationURL: destinationURL,
      sourceDocumentID: sourceDocumentID,
      sheets: sheets
    )
  }

  private static func saveUsingMetadataOverlay(
    sourceURL: URL,
    destinationURL: URL,
    sourceDocumentID: String?,
    sheets: [EditableSheet]
  ) throws {
    let metadata = buildMetadata(sourceDocumentID: sourceDocumentID, sheets: sheets)
    let jsonData: Data
    do {
      jsonData = try metadata.jsonUTF8Data()
    } catch {
      throw EditableNumbersError.nativeWriteFailed(
        "Failed to serialize metadata JSON: \(error.localizedDescription)"
      )
    }

    do {
      try NumbersContainer.copyContainer(
        from: sourceURL,
        to: destinationURL,
        replacingMetadataFiles: ["DocumentMetadata.json": jsonData]
      )
    } catch {
      throw EditableNumbersError.nativeWriteFailed(error.localizedDescription)
    }
  }

  private static func refreshEditableOverlayIfNeeded(
    destinationURL: URL,
    sourceDocumentID: String?,
    sheets: [EditableSheet]
  ) throws {
    guard let sourceDocumentID, sourceDocumentID.hasPrefix(editableDocumentIDPrefix) else {
      return
    }

    let metadata = buildMetadata(sourceDocumentID: sourceDocumentID, sheets: sheets)
    let jsonData = try metadata.jsonUTF8Data()

    let fileManager = FileManager.default
    let tempURL = destinationURL.deletingLastPathComponent().appendingPathComponent(
      ".swiftnumbers-overlay-\(UUID().uuidString)-\(destinationURL.lastPathComponent)",
      isDirectory: false
    )
    defer {
      if fileManager.fileExists(atPath: tempURL.path) {
        try? fileManager.removeItem(at: tempURL)
      }
    }

    try NumbersContainer.copyContainer(
      from: destinationURL,
      to: tempURL,
      replacingMetadataFiles: ["DocumentMetadata.json": jsonData]
    )

    do {
      _ = try fileManager.replaceItemAt(
        destinationURL,
        withItemAt: tempURL,
        backupItemName: nil,
        options: [.usingNewMetadataOnly]
      )
    } catch {
      if fileManager.fileExists(atPath: destinationURL.path) {
        try fileManager.removeItem(at: destinationURL)
      }
      try fileManager.moveItem(at: tempURL, to: destinationURL)
    }
  }

  private static func buildMetadata(
    sourceDocumentID: String?,
    sheets: [EditableSheet]
  ) -> Swiftnumbers_DocumentMetadata {
    var metadata = Swiftnumbers_DocumentMetadata()
    if let sourceDocumentID,
      !sourceDocumentID.isEmpty,
      sourceDocumentID.hasPrefix(editableDocumentIDPrefix)
    {
      metadata.documentID = sourceDocumentID
    } else if let sourceDocumentID, !sourceDocumentID.isEmpty {
      metadata.documentID = editableDocumentIDPrefix + sourceDocumentID
    } else {
      metadata.documentID = editableDocumentIDPrefix + UUID().uuidString.lowercased()
    }

    metadata.sheets = sheets.map { sheet in
      var mappedSheet = Swiftnumbers_SheetMetadata()
      mappedSheet.sheetID = sheet.id
      mappedSheet.name = sheet.name

      mappedSheet.tables = sheet.tables.map { table in
        var mappedTable = Swiftnumbers_TableMetadata()
        mappedTable.tableID = table.id
        mappedTable.name = table.name
        mappedTable.rowCount = toUInt32(table.rowCount)
        mappedTable.columnCount = toUInt32(table.columnCount)
        mappedTable.merges = table.mergeRanges.map { merge in
          var mappedMerge = Swiftnumbers_MergeRange()
          mappedMerge.startRow = toUInt32(merge.startRow)
          mappedMerge.endRow = toUInt32(merge.endRow)
          mappedMerge.startColumn = toUInt32(merge.startColumn)
          mappedMerge.endColumn = toUInt32(merge.endColumn)
          return mappedMerge
        }

        mappedTable.cells = table.allCells
          .sorted(by: { lhs, rhs in
            if lhs.key.row == rhs.key.row {
              return lhs.key.column < rhs.key.column
            }
            return lhs.key.row < rhs.key.row
          })
          .compactMap { address, value in
            var mappedCell = Swiftnumbers_Cell()
            mappedCell.row = toUInt32(address.row)
            mappedCell.column = toUInt32(address.column)

            switch value {
            case .empty:
              return nil
            case .string(let string):
              mappedCell.value = .stringValue(encodeStoredString(string))
            case .number(let number):
              mappedCell.value = .numberValue(number)
            case .bool(let bool):
              mappedCell.value = .boolValue(bool)
            case .date(let date):
              mappedCell.value = .stringValue(editableDateMarkerPrefix + formatDate(date))
            }
            return mappedCell
          }

        return mappedTable
      }

      return mappedSheet
    }

    return metadata
  }

  private static func toUInt32(_ value: Int) -> UInt32 {
    guard value > 0 else {
      return 0
    }
    return UInt32(clamping: value)
  }

  private static func formatDate(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
  }

  private static func encodeStoredString(_ string: String) -> String {
    if string.hasPrefix(editableDateMarkerPrefix) || string.hasPrefix(editableStringEscapePrefix) {
      return editableStringEscapePrefix + string
    }
    return string
  }
}

private let editableStringEscapePrefix = "__SWIFTNUMBERS_STRING__:"
