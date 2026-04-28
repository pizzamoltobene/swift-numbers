import Foundation
import SwiftNumbersContainer
import SwiftNumbersIWA

public enum EditableNumbersError: LocalizedError {
  case sheetNotFound(String)
  case tableNotFound(sheet: String, table: String)
  case duplicateTableName(sheet: String, table: String)
  case duplicateStyleName(String)
  case styleNotFound(String)
  case duplicateCustomFormatName(String)
  case customFormatNotFound(String)
  case invalidCellReference(String)
  case invalidRangeReference(String)
  case invalidRowIndex(Int)
  case invalidColumnIndex(Int)
  case invalidHeaderRowCount(Int)
  case invalidHeaderColumnCount(Int)
  case groupedTableMutationUnsupported(sheet: String, table: String, operation: String)
  case pivotLinkedTableMutationUnsupported(
    sheet: String,
    table: String,
    operation: String,
    linkedObjectIDs: [UInt64]
  )
  case nativeWriteFailed(String)

  public var errorDescription: String? {
    switch self {
    case .sheetNotFound(let name):
      return "Sheet not found: \(name)"
    case .tableNotFound(let sheet, let table):
      return "Table not found: \(sheet)/\(table)"
    case .duplicateTableName(let sheet, let table):
      return "Table already exists: \(sheet)/\(table)"
    case .duplicateStyleName(let name):
      return "Style already exists: \(name)"
    case .styleNotFound(let identifier):
      return "Style not found: \(identifier)"
    case .duplicateCustomFormatName(let name):
      return "Custom format already exists: \(name)"
    case .customFormatNotFound(let identifier):
      return "Custom format not found: \(identifier)"
    case .invalidCellReference(let raw):
      return "Invalid cell reference: \(raw)"
    case .invalidRangeReference(let raw):
      return "Invalid range reference: \(raw)"
    case .invalidRowIndex(let row):
      return "Invalid row index: \(row)"
    case .invalidColumnIndex(let column):
      return "Invalid column index: \(column)"
    case .invalidHeaderRowCount(let count):
      return "Invalid header row count: \(count)"
    case .invalidHeaderColumnCount(let count):
      return "Invalid header column count: \(count)"
    case .groupedTableMutationUnsupported(let sheet, let table, let operation):
      return
        "Unsafe grouped-table mutation blocked for \(sheet)/\(table) during \(operation). Grouped tables are currently read-only for structural edits. Remove grouping in Apple Numbers and retry."
    case .pivotLinkedTableMutationUnsupported(let sheet, let table, let operation, let linkedObjectIDs):
      let renderedLinkedObjectIDs: String
      if linkedObjectIDs.isEmpty {
        renderedLinkedObjectIDs = "none"
      } else {
        renderedLinkedObjectIDs = linkedObjectIDs.sorted().map(String.init).joined(separator: ",")
      }
      return
        "Unsafe pivot-linked mutation blocked for \(sheet)/\(table) during \(operation). Linked object identifiers: [\(renderedLinkedObjectIDs)]. This table is linked to a non-table analytical drawable (pivot-like structure) and is currently read-only for native writes. Remove pivot linkage in Apple Numbers and retry."
    case .nativeWriteFailed(let details):
      return "Swift-native write failed: \(details)"
    }
  }
}

public struct RegisteredDocumentStyle: Hashable, Sendable {
  public let id: String
  public let name: String
  public let style: ReadCellStyle

  public init(id: String, name: String, style: ReadCellStyle) {
    self.id = id
    self.name = name
    self.style = style
  }
}

public struct RegisteredDocumentCustomFormat: Hashable, Sendable {
  public let id: String
  public let name: String
  public let formatID: Int32

  public init(id: String, name: String, formatID: Int32) {
    self.id = id
    self.name = name
    self.formatID = formatID
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

public enum EditableBorderSide: String, CaseIterable, Hashable, Sendable {
  case top
  case right
  case bottom
  case left
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

  private static let styleRegistryMetadataFilename = "SwiftNumbersStyleRegistry.json"
  private static let customFormatRegistryMetadataFilename = "SwiftNumbersCustomFormatRegistry.json"

  private var operations: [EditOperation] = []
  private var workingSourceURL: URL
  private var styleRegistryDirty = false
  private var customFormatRegistryDirty = false
  private var registeredStylesByID: [String: RegisteredDocumentStyle] = [:]
  private var styleIDsByName: [String: String] = [:]
  private var styleOrder: [String] = []
  private var nextStyleOrdinal: Int = 1
  private var registeredCustomFormatsByID: [String: RegisteredDocumentCustomFormat] = [:]
  private var customFormatIDsByName: [String: String] = [:]
  private var customFormatOrder: [String] = []
  private var nextCustomFormatOrdinal: Int = 1

  public var hasChanges: Bool {
    !operations.isEmpty || styleRegistryDirty || customFormatRegistryDirty
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
    try editable.loadStyleRegistryOverlay(from: url)
    try editable.loadCustomFormatRegistryOverlay(from: url)
    return editable
  }

  public static func canSaveEditableDocuments() -> Bool {
    true
  }

  @discardableResult
  public func registerStyle(named name: String, style: ReadCellStyle) throws -> String {
    let normalizedName = normalizedStyleName(name)
    guard styleIDsByName[normalizedName] == nil else {
      throw EditableNumbersError.duplicateStyleName(normalizedName)
    }

    let styleID = allocateStyleID()
    let definition = RegisteredDocumentStyle(id: styleID, name: normalizedName, style: style)
    registeredStylesByID[styleID] = definition
    styleIDsByName[normalizedName] = styleID
    styleOrder.append(styleID)
    markStyleRegistryDirty()
    return styleID
  }

  public func registeredStyles() -> [RegisteredDocumentStyle] {
    styleOrder.compactMap { registeredStylesByID[$0] }
  }

  public func registeredStyle(id styleID: String) -> RegisteredDocumentStyle? {
    registeredStylesByID[styleID]
  }

  @discardableResult
  public func registerCustomFormat(named name: String, formatID: Int32) throws -> String {
    let normalizedName = normalizedCustomFormatName(name)
    guard customFormatIDsByName[normalizedName] == nil else {
      throw EditableNumbersError.duplicateCustomFormatName(normalizedName)
    }

    let customFormatID = allocateCustomFormatID()
    let definition = RegisteredDocumentCustomFormat(
      id: customFormatID,
      name: normalizedName,
      formatID: formatID
    )
    registeredCustomFormatsByID[customFormatID] = definition
    customFormatIDsByName[normalizedName] = customFormatID
    customFormatOrder.append(customFormatID)
    markCustomFormatRegistryDirty()
    return customFormatID
  }

  public func registeredCustomFormats() -> [RegisteredDocumentCustomFormat] {
    customFormatOrder.compactMap { registeredCustomFormatsByID[$0] }
  }

  public func registeredCustomFormat(id customFormatID: String) -> RegisteredDocumentCustomFormat? {
    registeredCustomFormatsByID[customFormatID]
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
      ownerDocument: self,
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
    } else {
      try validateOperationAddressability()

      try NativeWriterBackend.save(
        sourceURL: workingSourceURL,
        destinationURL: destinationURL,
        operations: operations
      )
    }
    try writeStyleRegistryOverlay(to: destinationURL)
    try writeCustomFormatRegistryOverlay(to: destinationURL)
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
    styleRegistryDirty = false
    customFormatRegistryDirty = false
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
          headerRowCount: table.metadata.headerRowCount,
          headerColumnCount: table.metadata.headerColumnCount,
          rowHeights: table.metadata.rowHeights,
          columnWidths: table.metadata.columnWidths,
          mergeRanges: table.metadata.mergeRanges,
          objectIdentifiers: table.metadata.objectIdentifiers,
          pivotLinks: table.metadata.pivotLinks,
          tableNameVisible: table.metadata.tableNameVisible,
          captionVisible: table.metadata.captionVisible,
          captionText: table.metadata.captionText,
          captionTextSupported: table.metadata.captionTextSupported,
          cells: table.allCells,
          cellStyles: styleCells,
          ownerDocument: self,
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

  private func normalizedStyleName(_ raw: String) -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "Style \(max(styleOrder.count + 1, 1))" : trimmed
  }

  private func normalizedCustomFormatName(_ raw: String) -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "Custom Format \(max(customFormatOrder.count + 1, 1))" : trimmed
  }

  private func allocateStyleID() -> String {
    while true {
      let candidate = "style-\(nextStyleOrdinal)"
      nextStyleOrdinal += 1
      if registeredStylesByID[candidate] == nil {
        return candidate
      }
    }
  }

  private func allocateCustomFormatID() -> String {
    while true {
      let candidate = "custom-format-\(nextCustomFormatOrdinal)"
      nextCustomFormatOrdinal += 1
      if registeredCustomFormatsByID[candidate] == nil {
        return candidate
      }
    }
  }

  fileprivate func markStyleRegistryDirty() {
    styleRegistryDirty = true
    if dirtyState == .clean {
      dirtyState = .dataDirty
    }
  }

  fileprivate func markCustomFormatRegistryDirty() {
    customFormatRegistryDirty = true
    if dirtyState == .clean {
      dirtyState = .dataDirty
    }
  }

  fileprivate func registeredStyleValue(for styleID: String) -> ReadCellStyle? {
    registeredStylesByID[styleID]?.style
  }

  fileprivate func styleIdentifier(for style: ReadCellStyle) -> String? {
    for styleID in styleOrder {
      guard let candidate = registeredStylesByID[styleID] else {
        continue
      }
      if candidate.style == style {
        return styleID
      }
    }
    return nil
  }

  fileprivate func ensureStyleRegisteredForAssignment(
    _ style: ReadCellStyle,
    preferredNamePrefix: String = "Auto Style"
  ) {
    if styleIdentifier(for: style) != nil {
      return
    }

    let styleID = allocateStyleID()
    let baseName = normalizedStyleName("\(preferredNamePrefix) \(styleID)")
    var candidateName = baseName
    var duplicateOrdinal = 2
    while styleIDsByName[candidateName] != nil {
      candidateName = normalizedStyleName("\(baseName) \(duplicateOrdinal)")
      duplicateOrdinal += 1
    }

    let definition = RegisteredDocumentStyle(id: styleID, name: candidateName, style: style)
    registeredStylesByID[styleID] = definition
    styleIDsByName[candidateName] = styleID
    styleOrder.append(styleID)
    markStyleRegistryDirty()
  }

  fileprivate func registeredCustomFormatValue(for customFormatID: String) -> Int32? {
    registeredCustomFormatsByID[customFormatID]?.formatID
  }

  fileprivate func customFormatIdentifier(for formatID: Int32) -> String? {
    for customFormatID in customFormatOrder {
      guard let definition = registeredCustomFormatsByID[customFormatID] else {
        continue
      }
      if definition.formatID == formatID {
        return customFormatID
      }
    }
    return nil
  }

  private func loadStyleRegistryOverlay(from sourceURL: URL) throws {
    let container = try NumbersContainer.open(at: sourceURL)
    guard
      let data = try container.readMetadataFile(named: Self.styleRegistryMetadataFilename),
      !data.isEmpty
    else {
      return
    }

    let decoder = JSONDecoder()
    let overlay = try decoder.decode(StyleRegistryOverlay.self, from: data)

    registeredStylesByID.removeAll(keepingCapacity: true)
    styleIDsByName.removeAll(keepingCapacity: true)
    styleOrder.removeAll(keepingCapacity: true)

    var maxObservedOrdinal = 0
    for styleRecord in overlay.styles {
      let normalizedName = normalizedStyleName(styleRecord.name)
      guard styleIDsByName[normalizedName] == nil else {
        continue
      }
      let style = styleRecord.style.toReadCellStyle()
      let definition = RegisteredDocumentStyle(id: styleRecord.id, name: normalizedName, style: style)
      registeredStylesByID[styleRecord.id] = definition
      styleIDsByName[normalizedName] = styleRecord.id
      styleOrder.append(styleRecord.id)

      if styleRecord.id.hasPrefix("style-"),
        let ordinal = Int(styleRecord.id.dropFirst("style-".count))
      {
        maxObservedOrdinal = max(maxObservedOrdinal, ordinal)
      }
    }

    nextStyleOrdinal = max(maxObservedOrdinal + 1, max(overlay.nextStyleOrdinal, 1))

    for assignment in overlay.assignments {
      guard let table = table(named: assignment.tableName, onSheetNamed: assignment.sheetName) else {
        continue
      }
      guard let style = registeredStyleValue(for: assignment.styleID) else {
        continue
      }
      table.restoreRegisteredStyle(
        id: assignment.styleID,
        style: style,
        at: CellAddress(row: assignment.row, column: assignment.column)
      )
    }

    styleRegistryDirty = false
  }

  private func loadCustomFormatRegistryOverlay(from sourceURL: URL) throws {
    let container = try NumbersContainer.open(at: sourceURL)
    guard
      let data = try container.readMetadataFile(named: Self.customFormatRegistryMetadataFilename),
      !data.isEmpty
    else {
      return
    }

    let decoder = JSONDecoder()
    let overlay = try decoder.decode(CustomFormatRegistryOverlay.self, from: data)

    registeredCustomFormatsByID.removeAll(keepingCapacity: true)
    customFormatIDsByName.removeAll(keepingCapacity: true)
    customFormatOrder.removeAll(keepingCapacity: true)

    var maxObservedOrdinal = 0
    for record in overlay.formats {
      let normalizedName = normalizedCustomFormatName(record.name)
      guard customFormatIDsByName[normalizedName] == nil else {
        continue
      }

      let definition = RegisteredDocumentCustomFormat(
        id: record.id,
        name: normalizedName,
        formatID: record.formatID
      )
      registeredCustomFormatsByID[record.id] = definition
      customFormatIDsByName[normalizedName] = record.id
      customFormatOrder.append(record.id)

      if record.id.hasPrefix("custom-format-"),
        let ordinal = Int(record.id.dropFirst("custom-format-".count))
      {
        maxObservedOrdinal = max(maxObservedOrdinal, ordinal)
      }
    }

    nextCustomFormatOrdinal = max(maxObservedOrdinal + 1, max(overlay.nextCustomFormatOrdinal, 1))

    for assignment in overlay.assignments {
      guard let table = table(named: assignment.tableName, onSheetNamed: assignment.sheetName) else {
        continue
      }
      guard let formatID = registeredCustomFormatValue(for: assignment.customFormatID) else {
        continue
      }
      table.restoreRegisteredCustomFormat(
        id: assignment.customFormatID,
        formatID: formatID,
        at: CellAddress(row: assignment.row, column: assignment.column)
      )
    }

    customFormatRegistryDirty = false
  }

  private func writeStyleRegistryOverlay(to destinationURL: URL) throws {
    guard !registeredStylesByID.isEmpty else {
      return
    }

    let overlay = buildStyleRegistryOverlay()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let overlayData = try encoder.encode(overlay)

    let fileManager = FileManager.default
    let tempURL = destinationURL.deletingLastPathComponent().appendingPathComponent(
      ".swiftnumbers-style-registry-\(UUID().uuidString)-\(destinationURL.lastPathComponent)",
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
      replacingMetadataFiles: [Self.styleRegistryMetadataFilename: overlayData]
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

  private func writeCustomFormatRegistryOverlay(to destinationURL: URL) throws {
    guard !registeredCustomFormatsByID.isEmpty else {
      return
    }

    let overlay = buildCustomFormatRegistryOverlay()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let overlayData = try encoder.encode(overlay)

    let fileManager = FileManager.default
    let tempURL = destinationURL.deletingLastPathComponent().appendingPathComponent(
      ".swiftnumbers-custom-format-registry-\(UUID().uuidString)-\(destinationURL.lastPathComponent)",
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
      replacingMetadataFiles: [Self.customFormatRegistryMetadataFilename: overlayData]
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

  private func buildStyleRegistryOverlay() -> StyleRegistryOverlay {
    let styleRecords: [StyleRegistryStyleRecord] = styleOrder.compactMap { styleID in
      guard let definition = registeredStylesByID[styleID] else {
        return nil
      }
      return StyleRegistryStyleRecord(
        id: definition.id,
        name: definition.name,
        style: .init(from: definition.style)
      )
    }

    var assignmentRecords: [StyleRegistryAssignmentRecord] = []
    for sheet in sheets {
      for table in sheet.tables {
        let styleCells = table.allCellStyles.sorted { lhs, rhs in
          if lhs.key.row != rhs.key.row {
            return lhs.key.row < rhs.key.row
          }
          return lhs.key.column < rhs.key.column
        }
        for (address, style) in styleCells {
          guard let styleID = styleIdentifier(for: style) else {
            continue
          }
          assignmentRecords.append(
            StyleRegistryAssignmentRecord(
              sheetName: sheet.name,
              tableName: table.name,
              row: address.row,
              column: address.column,
              styleID: styleID
            )
          )
        }
      }
    }

    assignmentRecords.sort {
      if $0.sheetName != $1.sheetName {
        return $0.sheetName < $1.sheetName
      }
      if $0.tableName != $1.tableName {
        return $0.tableName < $1.tableName
      }
      if $0.row != $1.row {
        return $0.row < $1.row
      }
      if $0.column != $1.column {
        return $0.column < $1.column
      }
      return $0.styleID < $1.styleID
    }

    return StyleRegistryOverlay(
      version: 1,
      nextStyleOrdinal: nextStyleOrdinal,
      styles: styleRecords,
      assignments: assignmentRecords
    )
  }

  private func buildCustomFormatRegistryOverlay() -> CustomFormatRegistryOverlay {
    let records: [CustomFormatRegistryFormatRecord] = customFormatOrder.compactMap { customFormatID in
      guard let definition = registeredCustomFormatsByID[customFormatID] else {
        return nil
      }
      return CustomFormatRegistryFormatRecord(
        id: definition.id,
        name: definition.name,
        formatID: definition.formatID
      )
    }

    var assignmentRecords: [CustomFormatRegistryAssignmentRecord] = []
    for sheet in sheets {
      for table in sheet.tables {
        let styleCells = table.allCellStyles.sorted { lhs, rhs in
          if lhs.key.row != rhs.key.row {
            return lhs.key.row < rhs.key.row
          }
          return lhs.key.column < rhs.key.column
        }
        for (address, style) in styleCells {
          guard
            let numberFormat = style.numberFormat,
            numberFormat.kind == .custom,
            let customFormatID = customFormatIdentifier(for: numberFormat.formatID)
          else {
            continue
          }
          assignmentRecords.append(
            CustomFormatRegistryAssignmentRecord(
              sheetName: sheet.name,
              tableName: table.name,
              row: address.row,
              column: address.column,
              customFormatID: customFormatID
            )
          )
        }
      }
    }

    assignmentRecords.sort {
      if $0.sheetName != $1.sheetName {
        return $0.sheetName < $1.sheetName
      }
      if $0.tableName != $1.tableName {
        return $0.tableName < $1.tableName
      }
      if $0.row != $1.row {
        return $0.row < $1.row
      }
      if $0.column != $1.column {
        return $0.column < $1.column
      }
      return $0.customFormatID < $1.customFormatID
    }

    return CustomFormatRegistryOverlay(
      version: 1,
      nextCustomFormatOrdinal: nextCustomFormatOrdinal,
      formats: records,
      assignments: assignmentRecords
    )
  }

  private func table(named tableName: String, onSheetNamed sheetName: String) -> EditableTable? {
    guard let sheet = sheets.first(where: { $0.name == sheetName }) else {
      return nil
    }
    return sheet.tables.first(where: { $0.name == tableName })
  }
}

private struct StyleRegistryOverlay: Codable {
  let version: Int
  let nextStyleOrdinal: Int
  let styles: [StyleRegistryStyleRecord]
  let assignments: [StyleRegistryAssignmentRecord]
}

private struct StyleRegistryStyleRecord: Codable {
  let id: String
  let name: String
  let style: StyleRegistryStylePayload
}

private struct StyleRegistryAssignmentRecord: Codable {
  let sheetName: String
  let tableName: String
  let row: Int
  let column: Int
  let styleID: String
}

private struct CustomFormatRegistryOverlay: Codable {
  let version: Int
  let nextCustomFormatOrdinal: Int
  let formats: [CustomFormatRegistryFormatRecord]
  let assignments: [CustomFormatRegistryAssignmentRecord]

  private enum CodingKeys: String, CodingKey {
    case version
    case nextCustomFormatOrdinal
    case formats
    case assignments
  }

  init(
    version: Int,
    nextCustomFormatOrdinal: Int,
    formats: [CustomFormatRegistryFormatRecord],
    assignments: [CustomFormatRegistryAssignmentRecord]
  ) {
    self.version = version
    self.nextCustomFormatOrdinal = nextCustomFormatOrdinal
    self.formats = formats
    self.assignments = assignments
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    version = try container.decode(Int.self, forKey: .version)
    nextCustomFormatOrdinal = try container.decode(Int.self, forKey: .nextCustomFormatOrdinal)
    formats = try container.decode([CustomFormatRegistryFormatRecord].self, forKey: .formats)
    assignments = try container.decodeIfPresent([CustomFormatRegistryAssignmentRecord].self, forKey: .assignments) ?? []
  }
}

private struct CustomFormatRegistryFormatRecord: Codable {
  let id: String
  let name: String
  let formatID: Int32
}

private struct CustomFormatRegistryAssignmentRecord: Codable {
  let sheetName: String
  let tableName: String
  let row: Int
  let column: Int
  let customFormatID: String
}

private struct StyleRegistryStylePayload: Codable {
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

  init(from style: ReadCellStyle) {
    self.horizontalAlignment = Self.encodeHorizontalAlignment(style.horizontalAlignment)
    self.verticalAlignment = Self.encodeVerticalAlignment(style.verticalAlignment)
    self.backgroundColorHex = style.backgroundColorHex
    self.fontName = style.fontName
    self.fontSize = style.fontSize
    self.isBold = style.isBold
    self.isItalic = style.isItalic
    self.textColorHex = style.textColorHex
    self.hasTopBorder = style.hasTopBorder
    self.hasRightBorder = style.hasRightBorder
    self.hasBottomBorder = style.hasBottomBorder
    self.hasLeftBorder = style.hasLeftBorder
    self.numberFormatKind = style.numberFormat?.kind.rawValue
    self.numberFormatID = style.numberFormat?.formatID
  }

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

  private static func encodeHorizontalAlignment(_ value: ReadHorizontalAlignment?) -> String? {
    guard let value else {
      return nil
    }
    switch value {
    case .left:
      return "left"
    case .center:
      return "center"
    case .right:
      return "right"
    case .justified:
      return "justified"
    case .natural:
      return "natural"
    case .unknown(let raw):
      return "unknown:\(raw)"
    }
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

  private static func encodeVerticalAlignment(_ value: ReadVerticalAlignment?) -> String? {
    guard let value else {
      return nil
    }
    switch value {
    case .top:
      return "top"
    case .middle:
      return "middle"
    case .bottom:
      return "bottom"
    case .unknown(let raw):
      return "unknown:\(raw)"
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
      ownerDocument: ownerDocument,
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
  private(set) var headerRowCount: Int
  private(set) var headerColumnCount: Int
  private(set) var rowHeights: [Double?]
  private(set) var columnWidths: [Double?]
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
  private unowned let ownerDocument: EditableNumbersDocument
  private let ownerSheetName: String
  private let mutationSink: MutationSink

  public var metadata: TableMetadata {
    TableMetadata(
      rowCount: rowCount,
      columnCount: columnCount,
      headerRowCount: headerRowCount,
      headerColumnCount: headerColumnCount,
      rowHeights: rowHeights,
      columnWidths: columnWidths,
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
    headerRowCount: Int = 0,
    headerColumnCount: Int = 0,
    rowHeights: [Double?] = [],
    columnWidths: [Double?] = [],
    mergeRanges: [MergeRange],
    objectIdentifiers: TableObjectIdentifiers? = nil,
    pivotLinks: [PivotLinkMetadata] = [],
    tableNameVisible: Bool? = nil,
    captionVisible: Bool? = nil,
    captionText: String? = nil,
    captionTextSupported: Bool = false,
    cells: [CellAddress: CellValue],
    cellStyles: [CellAddress: ReadCellStyle] = [:],
    ownerDocument: EditableNumbersDocument,
    ownerSheetName: String,
    mutationSink: @escaping MutationSink
  ) {
    self.id = id
    self.name = name
    self.rowCount = rowCount
    self.columnCount = columnCount
    self.headerRowCount = max(min(headerRowCount, rowCount), 0)
    self.headerColumnCount = max(min(headerColumnCount, columnCount), 0)
    self.rowHeights = Self.normalizedGeometryValues(rowHeights, count: rowCount)
    self.columnWidths = Self.normalizedGeometryValues(columnWidths, count: columnCount)
    self.mergeRanges = mergeRanges
    self.objectIdentifiers = objectIdentifiers
    self.pivotLinks = pivotLinks
    self.tableNameVisible = tableNameVisible
    self.captionVisible = captionVisible
    self.captionText = captionText
    self.captionTextSupported = captionTextSupported
    self.cells = cells
    self.cellStyles = cellStyles
    self.ownerDocument = ownerDocument
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

  public func rowHeight(at rowIndex: Int) -> Double? {
    guard rowIndex >= 0, rowIndex < rowCount else {
      return nil
    }
    guard rowIndex < rowHeights.count else {
      return nil
    }
    return rowHeights[rowIndex]
  }

  public func columnWidth(at columnIndex: Int) -> Double? {
    guard columnIndex >= 0, columnIndex < columnCount else {
      return nil
    }
    guard columnIndex < columnWidths.count else {
      return nil
    }
    return columnWidths[columnIndex]
  }

  public func setRowHeight(_ height: Double, at rowIndex: Int) throws {
    guard rowIndex >= 0, rowIndex < rowCount else {
      throw EditableNumbersError.invalidRowIndex(rowIndex)
    }
    guard height >= 0 else {
      throw EditableNumbersError.nativeWriteFailed("Row height must be >= 0.")
    }
    if rowIndex >= rowHeights.count {
      rowHeights.append(contentsOf: repeatElement(nil, count: rowIndex - rowHeights.count + 1))
    }
    guard rowHeights[rowIndex] != height else {
      return
    }
    rowHeights[rowIndex] = height
    markDirty(structureChanged: false)
    mutationSink(
      .setRowHeight(
        sheetName: ownerSheetName,
        tableName: name,
        rowIndex: rowIndex,
        height: height
      ),
      false
    )
  }

  public func setColumnWidth(_ width: Double, at columnIndex: Int) throws {
    guard columnIndex >= 0, columnIndex < columnCount else {
      throw EditableNumbersError.invalidColumnIndex(columnIndex)
    }
    guard width >= 0 else {
      throw EditableNumbersError.nativeWriteFailed("Column width must be >= 0.")
    }
    if columnIndex >= columnWidths.count {
      columnWidths.append(
        contentsOf: repeatElement(nil, count: columnIndex - columnWidths.count + 1))
    }
    guard columnWidths[columnIndex] != width else {
      return
    }
    columnWidths[columnIndex] = width
    markDirty(structureChanged: false)
    mutationSink(
      .setColumnWidth(
        sheetName: ownerSheetName,
        tableName: name,
        columnIndex: columnIndex,
        width: width
      ),
      false
    )
  }

  public func setHeaderRowCount(_ count: Int) throws {
    guard count >= 0, count <= rowCount else {
      throw EditableNumbersError.invalidHeaderRowCount(count)
    }
    guard headerRowCount != count else {
      return
    }
    headerRowCount = count
    markDirty(structureChanged: true)
    mutationSink(
      .setHeaderCounts(
        sheetName: ownerSheetName,
        tableName: name,
        headerRowCount: headerRowCount,
        headerColumnCount: headerColumnCount
      ),
      true
    )
  }

  public func setHeaderColumnCount(_ count: Int) throws {
    guard count >= 0, count <= columnCount else {
      throw EditableNumbersError.invalidHeaderColumnCount(count)
    }
    guard headerColumnCount != count else {
      return
    }
    headerColumnCount = count
    markDirty(structureChanged: true)
    mutationSink(
      .setHeaderCounts(
        sheetName: ownerSheetName,
        tableName: name,
        headerRowCount: headerRowCount,
        headerColumnCount: headerColumnCount
      ),
      true
    )
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

  public func setBorder(_ isVisible: Bool, side: EditableBorderSide, at address: CellAddress) {
    guard address.row >= 0, address.column >= 0 else {
      return
    }

    let targetAddresses = borderTargetAddresses(for: side, at: address)
    guard !targetAddresses.isEmpty else {
      return
    }

    var changedAddresses: [CellAddress] = []
    changedAddresses.reserveCapacity(targetAddresses.count)
    var structureChanged = false

    for target in targetAddresses {
      structureChanged = ensureCapacity(for: target) || structureChanged
      let currentStyle = cellStyles[target]
      let baselineStyle = currentStyle ?? ReadCellStyle()
      let updatedStyle = Self.styleByUpdatingBorder(
        baselineStyle,
        side: side,
        isVisible: isVisible
      )
      let nextStyle: ReadCellStyle? = Self.styleHasVisibleFields(updatedStyle) ? updatedStyle : nil
      guard currentStyle != nextStyle else {
        continue
      }

      if let nextStyle {
        cellStyles[target] = nextStyle
        ownerDocument.ensureStyleRegisteredForAssignment(
          nextStyle,
          preferredNamePrefix: "Auto Border Style"
        )
      } else {
        cellStyles.removeValue(forKey: target)
      }
      changedAddresses.append(target)
    }

    guard !changedAddresses.isEmpty else {
      return
    }
    dirtyCells.formUnion(changedAddresses)
    markDirty(structureChanged: structureChanged)
    ownerDocument.markStyleRegistryDirty()
  }

  public func setBorder(_ isVisible: Bool, side: EditableBorderSide, at reference: String) throws {
    let parsed = try CellReference(reference)
    setBorder(isVisible, side: side, at: parsed.address)
  }

  public func applyStyle(id styleID: String, at address: CellAddress) throws {
    guard let style = ownerDocument.registeredStyleValue(for: styleID) else {
      throw EditableNumbersError.styleNotFound(styleID)
    }
    applyRegisteredStyle(style, at: address, markDocumentDirty: true)
  }

  public func applyStyle(id styleID: String, at reference: String) throws {
    let parsed = try CellReference(reference)
    try applyStyle(id: styleID, at: parsed.address)
  }

  public func applyCustomFormat(id customFormatID: String, at address: CellAddress) throws {
    guard let formatID = ownerDocument.registeredCustomFormatValue(for: customFormatID) else {
      throw EditableNumbersError.customFormatNotFound(customFormatID)
    }
    applyRegisteredCustomFormat(formatID, at: address, markDocumentDirty: true)
  }

  public func applyCustomFormat(id customFormatID: String, at reference: String) throws {
    let parsed = try CellReference(reference)
    try applyCustomFormat(id: customFormatID, at: parsed.address)
  }

  public func setFormat(_ format: EditableCellFormat?, at address: CellAddress) {
    guard address.row >= 0, address.column >= 0 else {
      return
    }

    let structureChanged = ensureCapacity(for: address)
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

    if let nextStyle {
      cellStyles[address] = nextStyle
      ownerDocument.ensureStyleRegisteredForAssignment(
        nextStyle,
        preferredNamePrefix: "Auto Format Style"
      )
    } else {
      cellStyles.removeValue(forKey: address)
    }
    markDirty(address: address, structureChanged: structureChanged)
    ownerDocument.markStyleRegistryDirty()
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
    rowHeights.append(nil)
    if values.count > columnCount {
      let previous = columnCount
      columnCount = values.count
      if values.count > previous {
        columnWidths.append(contentsOf: repeatElement(nil, count: values.count - previous))
      }
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
    rowHeights.insert(nil, at: rowIndex)
    if values.count > columnCount {
      let previous = columnCount
      columnCount = values.count
      if values.count > previous {
        columnWidths.append(contentsOf: repeatElement(nil, count: values.count - previous))
      }
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
    columnWidths.append(nil)
    if values.count > rowCount {
      let previous = rowCount
      rowCount = values.count
      if values.count > previous {
        rowHeights.append(contentsOf: repeatElement(nil, count: values.count - previous))
      }
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
    if rowIndex < rowHeights.count {
      rowHeights.remove(at: rowIndex)
    }
    headerRowCount = min(headerRowCount, rowCount)
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
    if columnIndex < columnWidths.count {
      columnWidths.remove(at: columnIndex)
    }
    headerColumnCount = min(headerColumnCount, columnCount)
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

  fileprivate func restoreRegisteredStyle(
    id styleID: String,
    style: ReadCellStyle,
    at address: CellAddress
  ) {
    _ = styleID
    guard address.row >= 0, address.column >= 0 else {
      return
    }
    guard address.row < rowCount, address.column < columnCount else {
      return
    }
    cellStyles[address] = style
  }

  fileprivate func restoreRegisteredCustomFormat(
    id customFormatID: String,
    formatID: Int32,
    at address: CellAddress
  ) {
    _ = customFormatID
    applyRegisteredCustomFormat(formatID, at: address, markDocumentDirty: false)
  }

  fileprivate func format(for address: CellAddress) -> EditableCellFormat? {
    format(at: address)
  }

  private func ensureCapacity(for address: CellAddress) -> Bool {
    var structureChanged = false
    if address.row >= rowCount {
      let previous = rowCount
      rowCount = address.row + 1
      rowHeights.append(contentsOf: repeatElement(nil, count: rowCount - previous))
      structureChanged = true
    }
    if address.column >= columnCount {
      let previous = columnCount
      columnCount = address.column + 1
      columnWidths.append(contentsOf: repeatElement(nil, count: columnCount - previous))
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

  private static func styleByUpdatingBorder(
    _ style: ReadCellStyle,
    side: EditableBorderSide,
    isVisible: Bool
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
      hasTopBorder: side == .top ? isVisible : style.hasTopBorder,
      hasRightBorder: side == .right ? isVisible : style.hasRightBorder,
      hasBottomBorder: side == .bottom ? isVisible : style.hasBottomBorder,
      hasLeftBorder: side == .left ? isVisible : style.hasLeftBorder,
      numberFormat: style.numberFormat
    )
  }

  private func borderTargetAddresses(for side: EditableBorderSide, at address: CellAddress)
    -> [CellAddress]
  {
    guard let mergeRange = mergeRange(containing: address) else {
      return [address]
    }

    var addresses: [CellAddress] = []
    switch side {
    case .top:
      addresses.reserveCapacity(mergeRange.endColumn - mergeRange.startColumn + 1)
      for column in mergeRange.startColumn...mergeRange.endColumn {
        addresses.append(CellAddress(row: mergeRange.startRow, column: column))
      }
    case .right:
      addresses.reserveCapacity(mergeRange.endRow - mergeRange.startRow + 1)
      for row in mergeRange.startRow...mergeRange.endRow {
        addresses.append(CellAddress(row: row, column: mergeRange.endColumn))
      }
    case .bottom:
      addresses.reserveCapacity(mergeRange.endColumn - mergeRange.startColumn + 1)
      for column in mergeRange.startColumn...mergeRange.endColumn {
        addresses.append(CellAddress(row: mergeRange.endRow, column: column))
      }
    case .left:
      addresses.reserveCapacity(mergeRange.endRow - mergeRange.startRow + 1)
      for row in mergeRange.startRow...mergeRange.endRow {
        addresses.append(CellAddress(row: row, column: mergeRange.startColumn))
      }
    }
    return addresses
  }

  private func mergeRange(containing address: CellAddress) -> MergeRange? {
    mergeRanges.first { range in
      range.startRow <= address.row
        && address.row <= range.endRow
        && range.startColumn <= address.column
        && address.column <= range.endColumn
    }
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

  private static func normalizedGeometryValues(_ values: [Double?], count: Int) -> [Double?] {
    guard count > 0 else {
      return []
    }
    if values.count >= count {
      return Array(values.prefix(count))
    }
    return values + Array(repeating: nil, count: count - values.count)
  }

  private func applyRegisteredCustomFormat(
    _ formatID: Int32,
    at address: CellAddress,
    markDocumentDirty: Bool
  ) {
    guard address.row >= 0, address.column >= 0 else {
      return
    }

    let structureChanged = ensureCapacity(for: address)
    let currentStyle = cellStyles[address]
    let nextStyle: ReadCellStyle?
    if let currentStyle {
      let updatedStyle = Self.styleByUpdatingNumberFormat(
        currentStyle,
        numberFormat: ReadNumberFormat(kind: .custom, formatID: formatID)
      )
      nextStyle = Self.styleHasVisibleFields(updatedStyle) ? updatedStyle : nil
    } else {
      nextStyle = ReadCellStyle(numberFormat: ReadNumberFormat(kind: .custom, formatID: formatID))
    }

    guard currentStyle != nextStyle else {
      return
    }

    if let nextStyle {
      cellStyles[address] = nextStyle
    } else {
      cellStyles.removeValue(forKey: address)
    }
    markDirty(address: address, structureChanged: structureChanged)
    if markDocumentDirty {
      ownerDocument.markCustomFormatRegistryDirty()
    }
  }

  private func applyRegisteredStyle(
    _ style: ReadCellStyle,
    at address: CellAddress,
    markDocumentDirty: Bool
  ) {
    guard address.row >= 0, address.column >= 0 else {
      return
    }
    let structureChanged = ensureCapacity(for: address)
    guard cellStyles[address] != style else {
      return
    }
    cellStyles[address] = style
    markDirty(address: address, structureChanged: structureChanged)
    if markDocumentDirty {
      ownerDocument.markStyleRegistryDirty()
    }
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

  public func setBorder(_ isVisible: Bool, side: EditableBorderSide) {
    table.setBorder(isVisible, side: side, at: address)
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
    case .base(let formatID):
      return ReadNumberFormat(kind: .base, formatID: formatID)
    case .fraction(let formatID):
      return ReadNumberFormat(kind: .fraction, formatID: formatID)
    case .percentage(let formatID):
      return ReadNumberFormat(kind: .percentage, formatID: formatID)
    case .scientific(let formatID):
      return ReadNumberFormat(kind: .scientific, formatID: formatID)
    case .tickbox(let formatID):
      return ReadNumberFormat(kind: .tickbox, formatID: formatID)
    case .rating(let formatID):
      return ReadNumberFormat(kind: .rating, formatID: formatID)
    case .slider(let formatID):
      return ReadNumberFormat(kind: .slider, formatID: formatID)
    case .stepper(let formatID):
      return ReadNumberFormat(kind: .stepper, formatID: formatID)
    case .popup(let formatID):
      return ReadNumberFormat(kind: .popup, formatID: formatID)
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
    case .base:
      self = .base(formatID: numberFormat.formatID)
    case .fraction:
      self = .fraction(formatID: numberFormat.formatID)
    case .percentage:
      self = .percentage(formatID: numberFormat.formatID)
    case .scientific:
      self = .scientific(formatID: numberFormat.formatID)
    case .tickbox:
      self = .tickbox(formatID: numberFormat.formatID)
    case .rating:
      self = .rating(formatID: numberFormat.formatID)
    case .slider:
      self = .slider(formatID: numberFormat.formatID)
    case .stepper:
      self = .stepper(formatID: numberFormat.formatID)
    case .popup:
      self = .popup(formatID: numberFormat.formatID)
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
  case setHeaderCounts(
    sheetName: String,
    tableName: String,
    headerRowCount: Int,
    headerColumnCount: Int
  )
  case setRowHeight(sheetName: String, tableName: String, rowIndex: Int, height: Double)
  case setColumnWidth(sheetName: String, tableName: String, columnIndex: Int, width: Double)
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
