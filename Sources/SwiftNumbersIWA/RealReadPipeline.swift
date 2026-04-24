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

public struct IWAResolvedCell: Hashable, Sendable {
  public let row: Int
  public let column: Int
  public let value: IWAResolvedCellValue
  public let kind: IWAResolvedCellKind
  public let rawCellType: UInt8
  public let stringID: Int32?
  public let richTextID: Int32?
  public let formulaID: Int32?
  public let formulaErrorID: Int32?

  public init(
    row: Int,
    column: Int,
    value: IWAResolvedCellValue,
    kind: IWAResolvedCellKind,
    rawCellType: UInt8,
    stringID: Int32? = nil,
    richTextID: Int32? = nil,
    formulaID: Int32? = nil,
    formulaErrorID: Int32? = nil
  ) {
    self.row = row
    self.column = column
    self.value = value
    self.kind = kind
    self.rawCellType = rawCellType
    self.stringID = stringID
    self.richTextID = richTextID
    self.formulaID = formulaID
    self.formulaErrorID = formulaErrorID
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

public struct IWAResolvedTable: Hashable, Sendable {
  public let id: String
  public let name: String
  public let rowCount: Int
  public let columnCount: Int
  public let merges: [IWAResolvedMergeRange]
  public let cells: [IWAResolvedCell]

  public init(
    id: String,
    name: String,
    rowCount: Int,
    columnCount: Int,
    merges: [IWAResolvedMergeRange],
    cells: [IWAResolvedCell]
  ) {
    self.id = id
    self.name = name
    self.rowCount = rowCount
    self.columnCount = columnCount
    self.merges = merges
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

public enum IWARealDocumentReader {
  private enum TypeID {
    static let documentArchive: UInt32 = 1
    static let sheetArchive: UInt32 = 2
    static let tableInfoArchive: UInt32 = 6000
    static let tableModelArchive: UInt32 = 6001
    static let tileArchive: UInt32 = 6002
    static let tableDataList: UInt32 = 6005
    static let headerStorageBucket: UInt32 = 6006
    static let tableDataListSegment: UInt32 = 6011
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
    case rowStorageMapPatched = "decode.rowStorage.patched"
    case unsupportedCellTypeDropped = "decode.cell.unsupportedTypeDropped"
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
    return resolver.resolve()
  }

  private struct Resolver {
    let inventory: IWAInventory
    private var diagnostics: [IWAReadDiagnostic]
    private let recordsByObjectID: [UInt64: [IWAObjectRecord]]

    init(inventory: IWAInventory, diagnostics: [IWAReadDiagnostic]) {
      self.inventory = inventory
      self.diagnostics = diagnostics

      var grouped: [UInt64: [IWAObjectRecord]] = [:]
      for record in inventory.records {
        grouped[record.objectID, default: []].append(record)
      }
      self.recordsByObjectID = grouped
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

        var tables = resolveTables(fromDrawableRefs: drawableRefs)
        if tables.isEmpty {
          tables = resolveTablesByParent(sheetObjectID: sheetObjectID)
        }

        sheets.append(
          IWAResolvedSheet(
            id: "sheet-\(sheetObjectID)",
            name: sheetName,
            tables: tables
          )
        )
      }

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

    private mutating func resolveTables(
      fromDrawableRefs refs: [TSP_Reference]
    ) -> [IWAResolvedTable] {
      var tables: [IWAResolvedTable] = []
      var seenTableIDs = Set<String>()

      for ref in refs {
        let tableInfoObjectID = ref.identifier
        guard let table = resolveTable(tableInfoObjectID: tableInfoObjectID) else {
          addDiagnostic(
            .tableResolveFailed,
            severity: .warning,
            message: "Could not resolve table from sheet drawable reference.",
            context: ["tableInfoObjectID": String(tableInfoObjectID)]
          )
          continue
        }

        if seenTableIDs.contains(table.id) {
          continue
        }
        seenTableIDs.insert(table.id)
        tables.append(table)
      }

      return tables
    }

    private mutating func resolveTablesByParent(sheetObjectID: UInt64) -> [IWAResolvedTable] {
      var tables: [IWAResolvedTable] = []

      let tableInfoObjectIDs = Set(
        inventory.records.filter { $0.typeID == TypeID.tableInfoArchive }.map(\.objectID))
      for tableInfoObjectID in tableInfoObjectIDs.sorted() {
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

        guard let table = resolveTable(tableInfoObjectID: tableInfoObjectID) else {
          addDiagnostic(
            .tableResolveFailed,
            severity: .warning,
            message: "Could not resolve table during sheet-parent traversal.",
            context: [
              "sheetObjectID": String(sheetObjectID),
              "tableInfoObjectID": String(tableInfoObjectID),
            ]
          )
          continue
        }

        tables.append(table)
      }

      return tables
    }

    private mutating func resolveTable(tableInfoObjectID: UInt64) -> IWAResolvedTable? {
      guard tableInfoObjectID > 0 else {
        return nil
      }

      guard
        let tableInfo: TST_TableInfoArchive = decode(
          objectID: tableInfoObjectID,
          typeID: TypeID.tableInfoArchive,
          as: TST_TableInfoArchive.self
        )
      else {
        return nil
      }

      guard tableInfo.hasTableModel else {
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
      let rowCount = Int(tableModel.numberOfRows)
      let columnCount = Int(tableModel.numberOfColumns)

      let dataStore = tableModel.baseDataStore
      let stringLookup = decodeStringTable(dataStore.stringTable)
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
        stringLookup: stringLookup
      )
      if !decodeResult.droppedCellTypeCounts.isEmpty {
        for (cellType, count) in decodeResult.droppedCellTypeCounts.sorted(by: { $0.key < $1.key }) {
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
      let cells = decodeResult.cells
      let merges = decodeMergeRanges(dataStore.mergeRegionMap)

      return IWAResolvedTable(
        id: tableID,
        name: tableName,
        rowCount: rowCount,
        columnCount: columnCount,
        merges: merges,
        cells: cells
      )
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

    private struct DecodedCellsResult {
      let cells: [IWAResolvedCell]
      let droppedCellTypeCounts: [UInt8: Int]
    }

    private func decodeCells(
      rowStorageMap: [Int?],
      rowBuffers: [[Data?]],
      rowCount: Int,
      columnCount: Int,
      stringLookup: [UInt32: String]
    ) -> DecodedCellsResult {
      guard rowCount > 0, columnCount > 0 else {
        return DecodedCellsResult(cells: [], droppedCellTypeCounts: [:])
      }

      var cells: [IWAResolvedCell] = []
      cells.reserveCapacity(min(rowCount * columnCount, 1024))
      var droppedCellTypeCounts: [UInt8: Int] = [:]

      for row in 0..<min(rowCount, rowStorageMap.count) {
        guard let storageIndex = rowStorageMap[row], storageIndex >= 0,
          storageIndex < rowBuffers.count
        else {
          continue
        }

        let storageRow = rowBuffers[storageIndex]
        let maxColumn = min(columnCount, storageRow.count)

        for column in 0..<maxColumn {
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

          cells.append(
            IWAResolvedCell(
              row: row,
              column: column,
              value: value,
              kind: decoded.kind,
              rawCellType: decoded.cellType,
              stringID: decoded.stringID,
              richTextID: decoded.richTextID,
              formulaID: decoded.formulaID,
              formulaErrorID: decoded.formulaErrorID
            )
          )
        }
      }

      return DecodedCellsResult(cells: cells, droppedCellTypeCounts: droppedCellTypeCounts)
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

      guard let record = candidates.first(where: { $0.typeID == typeID }) else {
        return nil
      }

      do {
        return try MessageType(serializedBytes: record.payloadData)
      } catch {
        return nil
      }
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
    let formulaID: Int32?
    let formulaErrorID: Int32?
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
    var formulaID: Int32?
    var formulaErrorID: Int32?

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
      guard offset + 4 <= buffer.count else {
        return nil
      }
      offset += 4
    }

    if (flags & 0x40) != 0 {
      guard offset + 4 <= buffer.count else {
        return nil
      }
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

    return DecodedCellStorage(
      cellType: cellType,
      kind: decoded.kind,
      value: decoded.value,
      stringID: stringID,
      richTextID: richTextID,
      formulaID: formulaID,
      formulaErrorID: formulaErrorID
    )
  }

  static func decodeCellValue(buffer: Data, stringLookup: [UInt32: String]) -> IWAResolvedCellValue?
  {
    decodeCellStorage(buffer: buffer, stringLookup: stringLookup)?.value
  }

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
