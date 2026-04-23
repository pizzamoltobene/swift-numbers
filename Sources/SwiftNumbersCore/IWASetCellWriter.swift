import Foundation
import SwiftNumbersContainer
import SwiftNumbersIWA
import SwiftNumbersProto
import SwiftProtobuf

enum IWASetCellWriter {
  private static let editableDateMarkerPrefix = "__SWIFTNUMBERS_DATE__:"

  private enum TypeID {
    static let documentArchive: UInt32 = 1
    static let sheetArchive: UInt32 = 2
    static let tableInfoArchive: UInt32 = 6000
    static let tableModelArchive: UInt32 = 6001
    static let tileArchive: UInt32 = 6002
    static let tableDataList: UInt32 = 6005
    static let headerStorageBucket: UInt32 = 6006
    static let tableDataListSegment: UInt32 = 6011
  }

  enum LowLevelOperation: Hashable {
    case setCell(sheetName: String, tableName: String, row: Int, column: Int, value: CellValue)
    case appendRow(sheetName: String, tableName: String, values: [CellValue])
    case insertRow(sheetName: String, tableName: String, rowIndex: Int, values: [CellValue])
    case appendColumn(sheetName: String, tableName: String, values: [CellValue])
    case addTable(sheetName: String, tableName: String, rows: Int, columns: Int)
    case addSheet(name: String, defaultTableName: String, rows: Int, columns: Int)
  }

  private struct TableKey: Hashable {
    let sheetName: String
    let tableName: String
  }

  private struct RowStorageLocation {
    let tileObjectID: UInt64
    let rowInfoIndex: Int
    let hasWideOffsets: Bool
  }

  private struct TableContext {
    let key: TableKey
    var rowCount: Int
    var columnCount: Int
    var rowStorageMap: [Int?]
    var rowBuffers: [[Data?]]
    var rowLocations: [RowStorageLocation]
    var tilesByObjectID: [UInt64: TST_Tile]
    var dirtyStorageIndices: Set<Int>
    var dirtyTileObjectIDs: Set<UInt64>
    var rowHeaderBucketObjectIDs: [UInt64]
    var rowHeaderBucketsByObjectID: [UInt64: TST_HeaderStorageBucket]
    var dirtyRowHeaderBucketObjectIDs: Set<UInt64>
    let stringTableObjectID: UInt64?
    var stringTable: TST_TableDataList?
    var stringLookup: [UInt32: String]
    var reverseStringLookup: [String: UInt32]
    var nextStringID: UInt32
    let tableModelObjectID: UInt64
    var tableModel: TST_TableModelArchive
    var tableModelDirty: Bool
  }

  private struct SheetContext {
    let objectID: UInt64
    let sourceBlobPath: String
    var sheet: TN_SheetArchive
    var dirty: Bool
  }

  private struct DocumentContext {
    let objectID: UInt64
    let sourceBlobPath: String
    var document: TN_DocumentArchive
    var dirty: Bool
  }

  private struct CreatedTable {
    let tableInfoObjectID: UInt64
    let context: TableContext
    let records: [IWAObjectRecord]
  }

  private struct RecordKey: Hashable {
    let objectID: UInt64
    let typeID: UInt32
  }

  static func lowLevelOperations(from operations: [EditOperation]) -> [LowLevelOperation]? {
    guard !operations.isEmpty else {
      return nil
    }

    var converted: [LowLevelOperation] = []
    converted.reserveCapacity(operations.count)

    for operation in operations {
      switch operation {
      case .setCell(let sheetName, let tableName, let row, let column, let value):
        converted.append(
          .setCell(
            sheetName: sheetName,
            tableName: tableName,
            row: row,
            column: column,
            value: value
          ))
      case .appendRow(let sheetName, let tableName, let values):
        converted.append(.appendRow(sheetName: sheetName, tableName: tableName, values: values))
      case .insertRow(let sheetName, let tableName, let rowIndex, let values):
        converted.append(
          .insertRow(
            sheetName: sheetName,
            tableName: tableName,
            rowIndex: rowIndex,
            values: values
          ))
      case .appendColumn(let sheetName, let tableName, let values):
        converted.append(
          .appendColumn(sheetName: sheetName, tableName: tableName, values: values)
        )
      case .addTable(let sheetName, let tableName, let rows, let columns):
        converted.append(
          .addTable(
            sheetName: sheetName,
            tableName: tableName,
            rows: rows,
            columns: columns
          ))
      case .addSheet(let name):
        converted.append(
          .addSheet(name: name, defaultTableName: "Table 1", rows: 1, columns: 1)
        )
      }
    }

    return converted
  }

  static func save(
    sourceURL: URL,
    destinationURL: URL,
    operations: [LowLevelOperation]
  ) throws {
    let container = try NumbersContainer.open(at: sourceURL)
    let blobs = try container.loadIndexBlobs()
    let inventory = try IWAInventoryBuilder.build(from: blobs)

    let recordsByObjectID = Dictionary(grouping: inventory.records, by: \.objectID)
    let recordsByBlobPath = Dictionary(grouping: inventory.records, by: \.sourceBlobPath)

    guard let documentObjectID = selectDocumentObjectID(inventory: inventory) else {
      throw EditableNumbersError.nativeWriteFailed("IWA writer: document root not found")
    }

    guard
      let documentRecord = record(
        objectID: documentObjectID,
        typeID: TypeID.documentArchive,
        recordsByObjectID: recordsByObjectID
      ),
      let document: TN_DocumentArchive = decodeMessage(
        objectID: documentObjectID,
        typeID: TypeID.documentArchive,
        recordsByObjectID: recordsByObjectID
      )
    else {
      throw EditableNumbersError.nativeWriteFailed(
        "IWA writer: failed to decode TN.DocumentArchive")
    }

    var documentContext = DocumentContext(
      objectID: documentObjectID,
      sourceBlobPath: documentRecord.sourceBlobPath,
      document: document,
      dirty: false
    )
    var sheetContexts = try buildSheetContexts(
      document: documentContext.document,
      recordsByObjectID: recordsByObjectID
    )
    var contexts = try buildTableContexts(
      document: documentContext.document,
      recordsByObjectID: recordsByObjectID
    )
    var addedRecordsByBlobPath: [String: [IWAObjectRecord]] = [:]

    var maxObjectID = inventory.records.map(\.objectID).max() ?? 0
    func allocateObjectID() -> UInt64 {
      maxObjectID += 1
      return maxObjectID
    }

    let typePreferredBlobPaths = preferredBlobPaths(records: inventory.records)
    let templateTableContext = contexts.values.sorted(by: { lhs, rhs in
      if lhs.key.sheetName == rhs.key.sheetName {
        return lhs.key.tableName < rhs.key.tableName
      }
      return lhs.key.sheetName < rhs.key.sheetName
    }).first

    for operation in operations {
      switch operation {
      case .setCell, .appendRow, .insertRow, .appendColumn:
        let key = tableKey(for: operation)
        guard var context = contexts[key] else {
          let names = tableNames(for: operation)
          throw EditableNumbersError.nativeWriteFailed(
            "IWA writer: table not found \(names.sheet)/\(names.table)")
        }

        try apply(operation: operation, to: &context)
        contexts[key] = context

      case .addTable(let sheetName, let tableName, let rows, let columns):
        guard rows >= 0 else {
          throw EditableNumbersError.nativeWriteFailed("IWA writer: addTable rows must be >= 0")
        }
        guard columns >= 0 else {
          throw EditableNumbersError.nativeWriteFailed("IWA writer: addTable columns must be >= 0")
        }

        let newKey = TableKey(sheetName: sheetName, tableName: tableName)
        guard contexts[newKey] == nil else {
          throw EditableNumbersError.nativeWriteFailed(
            "IWA writer: table already exists \(sheetName)/\(tableName)")
        }

        guard
          let sheetObjectID = resolveSheetObjectID(
            named: sheetName,
            document: documentContext.document,
            sheetContexts: sheetContexts
          ),
          var sheetContext = sheetContexts[sheetObjectID]
        else {
          throw EditableNumbersError.nativeWriteFailed("IWA writer: sheet not found \(sheetName)")
        }

        let createdTable = try createTable(
          sheetName: sheetName,
          parentSheetObjectID: sheetObjectID,
          tableName: tableName,
          rows: rows,
          columns: columns,
          template: templateTableContext,
          allocateObjectID: allocateObjectID,
          preferredBlobPathResolver: { typeID in
            preferredBlobPath(
              for: typeID,
              typePreferredBlobPaths: typePreferredBlobPaths,
              fallback: documentContext.sourceBlobPath
            )
          }
        )

        sheetContext.sheet.drawableInfos.append(reference(createdTable.tableInfoObjectID))
        sheetContext.dirty = true
        sheetContexts[sheetObjectID] = sheetContext
        contexts[createdTable.context.key] = createdTable.context
        appendAddedRecords(createdTable.records, into: &addedRecordsByBlobPath)

      case .addSheet(let name, let defaultTableName, let rows, let columns):
        guard rows >= 0 else {
          throw EditableNumbersError.nativeWriteFailed("IWA writer: addSheet rows must be >= 0")
        }
        guard columns >= 0 else {
          throw EditableNumbersError.nativeWriteFailed("IWA writer: addSheet columns must be >= 0")
        }

        let newSheetObjectID = allocateObjectID()
        let sheetBlobPath = preferredBlobPath(
          for: TypeID.sheetArchive,
          typePreferredBlobPaths: typePreferredBlobPaths,
          fallback: documentContext.sourceBlobPath
        )

        var newSheetArchive = TN_SheetArchive()
        newSheetArchive.name = name

        var newSheetContext = SheetContext(
          objectID: newSheetObjectID,
          sourceBlobPath: sheetBlobPath,
          sheet: newSheetArchive,
          dirty: true
        )

        let defaultTable = try createTable(
          sheetName: name,
          parentSheetObjectID: newSheetObjectID,
          tableName: defaultTableName,
          rows: rows,
          columns: columns,
          template: templateTableContext,
          allocateObjectID: allocateObjectID,
          preferredBlobPathResolver: { typeID in
            preferredBlobPath(
              for: typeID,
              typePreferredBlobPaths: typePreferredBlobPaths,
              fallback: documentContext.sourceBlobPath
            )
          }
        )
        newSheetContext.sheet.drawableInfos.append(reference(defaultTable.tableInfoObjectID))
        sheetContexts[newSheetObjectID] = newSheetContext
        contexts[defaultTable.context.key] = defaultTable.context
        appendAddedRecords(defaultTable.records, into: &addedRecordsByBlobPath)

        documentContext.document.sheets.append(reference(newSheetObjectID))
        documentContext.dirty = true
      }
    }

    var payloadOverrides: [RecordKey: Data] = [:]
    for key in contexts.keys.sorted(by: { lhs, rhs in
      if lhs.sheetName == rhs.sheetName {
        return lhs.tableName < rhs.tableName
      }
      return lhs.sheetName < rhs.sheetName
    }) {
      guard var context = contexts[key] else {
        continue
      }
      try flushDirtyRows(context: &context)
      contexts[key] = context

      for tileObjectID in context.dirtyTileObjectIDs {
        guard let tile = context.tilesByObjectID[tileObjectID] else {
          continue
        }
        payloadOverrides[RecordKey(objectID: tileObjectID, typeID: TypeID.tileArchive)] =
          try tile.serializedData()
      }

      for bucketObjectID in context.dirtyRowHeaderBucketObjectIDs {
        guard let bucket = context.rowHeaderBucketsByObjectID[bucketObjectID] else {
          continue
        }
        payloadOverrides[RecordKey(objectID: bucketObjectID, typeID: TypeID.headerStorageBucket)] =
          try bucket.serializedData()
      }

      if context.tableModelDirty {
        payloadOverrides[
          RecordKey(objectID: context.tableModelObjectID, typeID: TypeID.tableModelArchive)] =
          try context.tableModel.serializedData()
      }

      if let stringTableObjectID = context.stringTableObjectID,
        let stringTable = context.stringTable
      {
        payloadOverrides[
          RecordKey(objectID: stringTableObjectID, typeID: TypeID.tableDataList)
        ] = try stringTable.serializedData()
      }
    }

    for sheetRef in documentContext.document.sheets {
      let sheetObjectID = sheetRef.identifier
      guard sheetObjectID > 0, let sheetContext = sheetContexts[sheetObjectID], sheetContext.dirty
      else {
        continue
      }

      let sheetPayload = try sheetContext.sheet.serializedData()
      if record(
        objectID: sheetObjectID,
        typeID: TypeID.sheetArchive,
        recordsByObjectID: recordsByObjectID
      ) != nil {
        payloadOverrides[RecordKey(objectID: sheetObjectID, typeID: TypeID.sheetArchive)] =
          sheetPayload
      } else {
        let refs = sheetContext.sheet.drawableInfos.compactMap { ref -> UInt64? in
          ref.identifier > 0 ? ref.identifier : nil
        }
        let newRecord = IWAObjectRecord(
          objectID: sheetObjectID,
          typeID: TypeID.sheetArchive,
          payloadSize: sheetPayload.count,
          payloadData: sheetPayload,
          sourceBlobPath: sheetContext.sourceBlobPath,
          objectReferences: refs
        )
        addedRecordsByBlobPath[sheetContext.sourceBlobPath, default: []].append(newRecord)
      }
    }

    if documentContext.dirty {
      payloadOverrides[
        RecordKey(objectID: documentContext.objectID, typeID: TypeID.documentArchive)] =
        try documentContext.document.serializedData()
    }

    let hasAddedRecords = addedRecordsByBlobPath.values.contains(where: { !$0.isEmpty })
    guard !payloadOverrides.isEmpty || hasAddedRecords else {
      throw EditableNumbersError.nativeWriteFailed("IWA writer: no payload overrides were produced")
    }

    var replacedBlobs: [String: Data] = [:]
    var blobPathsToRebuild = Set(recordsByBlobPath.keys)
    blobPathsToRebuild.formUnion(addedRecordsByBlobPath.keys)

    for blobPath in blobPathsToRebuild.sorted() {
      let existingRecords = recordsByBlobPath[blobPath] ?? []
      let addedRecords = addedRecordsByBlobPath[blobPath] ?? []

      let containsModifiedPayload = existingRecords.contains { record in
        payloadOverrides[RecordKey(objectID: record.objectID, typeID: record.typeID)] != nil
      }
      guard containsModifiedPayload || !addedRecords.isEmpty else {
        continue
      }
      let rebuilt = try rebuildIWAArchiveBlob(
        records: existingRecords,
        payloadOverrides: payloadOverrides,
        additionalRecords: addedRecords
      )
      replacedBlobs[blobPath] = rebuilt
    }

    guard !replacedBlobs.isEmpty else {
      throw EditableNumbersError.nativeWriteFailed("IWA writer: no index blobs were rebuilt")
    }

    try NumbersContainer.copyContainer(
      from: sourceURL,
      to: destinationURL,
      replacingIndexBlobs: replacedBlobs
    )
  }

  private static func buildTableContexts(
    document: TN_DocumentArchive,
    recordsByObjectID: [UInt64: [IWAObjectRecord]]
  ) throws -> [TableKey: TableContext] {
    var contexts: [TableKey: TableContext] = [:]

    for (sheetIndex, sheetReference) in document.sheets.enumerated() {
      let sheetObjectID = sheetReference.identifier
      guard sheetObjectID > 0 else {
        continue
      }

      let decodedSheet: TN_SheetArchive? = decodeMessage(
        objectID: sheetObjectID,
        typeID: TypeID.sheetArchive,
        recordsByObjectID: recordsByObjectID
      )
      let sheetName =
        decodedSheet?.name.isEmpty == false ? decodedSheet!.name : "Sheet \(sheetIndex + 1)"
      let drawableRefs = decodedSheet?.drawableInfos ?? []

      for drawableRef in drawableRefs {
        let tableInfoObjectID = drawableRef.identifier
        guard tableInfoObjectID > 0 else {
          continue
        }

        guard
          let tableInfo: TST_TableInfoArchive = decodeMessage(
            objectID: tableInfoObjectID,
            typeID: TypeID.tableInfoArchive,
            recordsByObjectID: recordsByObjectID
          ),
          tableInfo.hasTableModel
        else {
          continue
        }

        let tableModelObjectID = tableInfo.tableModel.identifier
        guard tableModelObjectID > 0 else {
          continue
        }

        guard
          let tableModel: TST_TableModelArchive = decodeMessage(
            objectID: tableModelObjectID,
            typeID: TypeID.tableModelArchive,
            recordsByObjectID: recordsByObjectID
          )
        else {
          continue
        }

        let tableName =
          tableModel.tableName.isEmpty
          ? (tableModel.tableID.isEmpty ? "Table \(tableModelObjectID)" : tableModel.tableID)
          : tableModel.tableName
        let key = TableKey(sheetName: sheetName, tableName: tableName)

        let rowCount = Int(tableModel.numberOfRows)
        let columnCount = Int(tableModel.numberOfColumns)
        let dataStore = tableModel.baseDataStore

        let rowDecode = decodeRowsFromTiles(
          tileStorage: dataStore.tiles,
          columnCount: columnCount,
          recordsByObjectID: recordsByObjectID
        )
        let rowStorageMap = decodeRowStorageMap(
          headerStorage: dataStore.rowHeaders,
          rowCount: rowCount,
          rowBufferCount: rowDecode.rows.count,
          recordsByObjectID: recordsByObjectID
        )
        let headerBuckets = decodeRowHeaderBuckets(
          headerStorage: dataStore.rowHeaders,
          recordsByObjectID: recordsByObjectID
        )
        let stringTableContext = decodeStringTableContext(
          reference: dataStore.stringTable,
          recordsByObjectID: recordsByObjectID
        )

        contexts[key] = TableContext(
          key: key,
          rowCount: rowCount,
          columnCount: columnCount,
          rowStorageMap: rowStorageMap,
          rowBuffers: rowDecode.rows,
          rowLocations: rowDecode.locations,
          tilesByObjectID: rowDecode.tilesByObjectID,
          dirtyStorageIndices: [],
          dirtyTileObjectIDs: [],
          rowHeaderBucketObjectIDs: headerBuckets.objectIDs,
          rowHeaderBucketsByObjectID: headerBuckets.bucketsByObjectID,
          dirtyRowHeaderBucketObjectIDs: [],
          stringTableObjectID: stringTableContext.objectID,
          stringTable: stringTableContext.tableDataList,
          stringLookup: stringTableContext.lookup,
          reverseStringLookup: stringTableContext.reverseLookup,
          nextStringID: stringTableContext.nextID,
          tableModelObjectID: tableModelObjectID,
          tableModel: tableModel,
          tableModelDirty: false
        )
      }
    }

    return contexts
  }

  private static func buildSheetContexts(
    document: TN_DocumentArchive,
    recordsByObjectID: [UInt64: [IWAObjectRecord]]
  ) throws -> [UInt64: SheetContext] {
    var contexts: [UInt64: SheetContext] = [:]

    for (index, sheetRef) in document.sheets.enumerated() {
      let sheetObjectID = sheetRef.identifier
      guard sheetObjectID > 0 else {
        continue
      }
      guard
        let sheetRecord = record(
          objectID: sheetObjectID,
          typeID: TypeID.sheetArchive,
          recordsByObjectID: recordsByObjectID
        ),
        let sheetArchive: TN_SheetArchive = decodeMessage(
          objectID: sheetObjectID,
          typeID: TypeID.sheetArchive,
          recordsByObjectID: recordsByObjectID
        )
      else {
        continue
      }

      var sheet = sheetArchive
      if sheet.name.isEmpty {
        sheet.name = "Sheet \(index + 1)"
      }

      contexts[sheetObjectID] = SheetContext(
        objectID: sheetObjectID,
        sourceBlobPath: sheetRecord.sourceBlobPath,
        sheet: sheet,
        dirty: false
      )
    }

    return contexts
  }

  private static func preferredBlobPaths(records: [IWAObjectRecord]) -> [UInt32: String] {
    var mapping: [UInt32: String] = [:]
    let ordered = records.sorted { lhs, rhs in
      if lhs.typeID == rhs.typeID {
        if lhs.sourceBlobPath == rhs.sourceBlobPath {
          return lhs.objectID < rhs.objectID
        }
        return lhs.sourceBlobPath < rhs.sourceBlobPath
      }
      return lhs.typeID < rhs.typeID
    }

    for record in ordered where mapping[record.typeID] == nil {
      mapping[record.typeID] = record.sourceBlobPath
    }

    return mapping
  }

  private static func preferredBlobPath(
    for typeID: UInt32,
    typePreferredBlobPaths: [UInt32: String],
    fallback: String
  ) -> String {
    typePreferredBlobPaths[typeID] ?? fallback
  }

  private static func resolveSheetObjectID(
    named sheetName: String,
    document: TN_DocumentArchive,
    sheetContexts: [UInt64: SheetContext]
  ) -> UInt64? {
    for sheetRef in document.sheets {
      let objectID = sheetRef.identifier
      guard objectID > 0, let context = sheetContexts[objectID] else {
        continue
      }
      if context.sheet.name == sheetName {
        return objectID
      }
    }
    return nil
  }

  private static func appendAddedRecords(
    _ records: [IWAObjectRecord],
    into grouped: inout [String: [IWAObjectRecord]]
  ) {
    for record in records {
      grouped[record.sourceBlobPath, default: []].append(record)
    }
  }

  private static func createTable(
    sheetName: String,
    parentSheetObjectID: UInt64,
    tableName: String,
    rows: Int,
    columns: Int,
    template: TableContext?,
    allocateObjectID: () -> UInt64,
    preferredBlobPathResolver: (UInt32) -> String
  ) throws -> CreatedTable {
    let rowCount = max(rows, 0)
    let columnCount = max(columns, 0)

    let headerBucketObjectID = allocateObjectID()
    let tileObjectID = allocateObjectID()
    let stringTableObjectID = allocateObjectID()
    let tableModelObjectID = allocateObjectID()
    let tableInfoObjectID = allocateObjectID()

    let hasWideOffsets =
      template?.tilesByObjectID.values.sorted(by: { $0.maxRow < $1.maxRow }).first
      .map { tile in
        tile.hasShouldUseWideRows ? tile.shouldUseWideRows : false
      } ?? false

    var headerBucket = TST_HeaderStorageBucket()
    if let templateBucketID = template?.rowHeaderBucketObjectIDs.first,
      let templateBucket = template?.rowHeaderBucketsByObjectID[templateBucketID]
    {
      headerBucket.bucketHashFunction = templateBucket.bucketHashFunction
    }
    let headerTemplate = template?.rowHeaderBucketObjectIDs.first
      .flatMap { template?.rowHeaderBucketsByObjectID[$0]?.headers.first }
    for rowIndex in 0..<rowCount {
      var header = makeRowHeader(for: rowIndex, template: headerTemplate)
      header.numberOfCells = UInt32(clamping: columnCount)
      headerBucket.headers.append(header)
    }

    var headerStorage = TST_HeaderStorage()
    if let templateHash = template?.tableModel.baseDataStore.rowHeaders.hasBucketHashFunction,
      templateHash
    {
      headerStorage.bucketHashFunction =
        template!.tableModel.baseDataStore.rowHeaders.bucketHashFunction
    } else if headerBucket.hasBucketHashFunction {
      headerStorage.bucketHashFunction = headerBucket.bucketHashFunction
    }
    headerStorage.buckets = [reference(headerBucketObjectID)]

    var tile = TST_Tile()
    tile.shouldUseWideRows = hasWideOffsets
    tile.numrows = UInt32(clamping: rowCount)
    if rowCount > 0 {
      tile.maxRow = UInt32(clamping: rowCount - 1)
    }
    if columnCount > 0 {
      tile.maxColumn = UInt32(clamping: columnCount - 1)
    }

    let emptyRow = [Data?](repeating: nil, count: columnCount)
    for rowIndex in 0..<rowCount {
      var rowInfo = TST_TileRowInfo()
      rowInfo.tileRowIndex = UInt32(clamping: rowIndex)
      rowInfo.cellCount = UInt32(clamping: columnCount)
      rowInfo.hasWideOffsets_p = hasWideOffsets

      let encoded = try encodeRowStorageBuffers(
        row: emptyRow,
        columnCount: columnCount,
        hasWideOffsets: hasWideOffsets
      )
      rowInfo.cellStorageBuffer = encoded.storageBuffer
      rowInfo.cellOffsets = encoded.offsetsBuffer
      rowInfo.clearCellStorageBufferPreBnc()
      rowInfo.clearCellOffsetsPreBnc()
      tile.rowInfos.append(rowInfo)
    }

    var tileEntry = TST_TileStorage.TileEntry()
    tileEntry.tileid = 0
    tileEntry.tile = reference(tileObjectID)

    var tileStorage = TST_TileStorage()
    tileStorage.tiles = [tileEntry]
    tileStorage.shouldUseWideRows = hasWideOffsets
    if template?.tableModel.baseDataStore.tiles.hasTileSize == true {
      tileStorage.tileSize = template!.tableModel.baseDataStore.tiles.tileSize
    }

    var stringTable = TST_TableDataList()
    stringTable.nextListID = 1
    if template?.stringTable?.hasListType == true {
      stringTable.listType = template!.stringTable!.listType
    }

    var dataStore = TST_DataStore()
    dataStore.rowHeaders = headerStorage
    dataStore.tiles = tileStorage
    dataStore.stringTable = reference(stringTableObjectID)
    if let templateColumnHeaders = template?.tableModel.baseDataStore.columnHeaders,
      templateColumnHeaders.identifier > 0
    {
      dataStore.columnHeaders = templateColumnHeaders
    }

    var tableModel = TST_TableModelArchive()
    tableModel.tableID = "table-\(tableModelObjectID)"
    tableModel.tableName = tableName
    tableModel.numberOfRows = UInt32(clamping: rowCount)
    tableModel.numberOfColumns = UInt32(clamping: columnCount)
    tableModel.baseDataStore = dataStore

    var tableInfo = TST_TableInfoArchive()
    var drawable = TSD_DrawableArchive()
    drawable.parent = reference(parentSheetObjectID)
    tableInfo.super = drawable
    tableInfo.tableModel = reference(tableModelObjectID)

    let rowStorageMap = rowCount > 0 ? Array(0..<rowCount).map { Optional($0) } : []
    let rowBuffers = Array(repeating: emptyRow, count: rowCount)
    let rowLocations = (0..<rowCount).map { rowIndex in
      RowStorageLocation(
        tileObjectID: tileObjectID,
        rowInfoIndex: rowIndex,
        hasWideOffsets: hasWideOffsets
      )
    }

    let context = TableContext(
      key: TableKey(sheetName: sheetName, tableName: tableName),
      rowCount: rowCount,
      columnCount: columnCount,
      rowStorageMap: rowStorageMap,
      rowBuffers: rowBuffers,
      rowLocations: rowLocations,
      tilesByObjectID: [tileObjectID: tile],
      dirtyStorageIndices: [],
      dirtyTileObjectIDs: [],
      rowHeaderBucketObjectIDs: [headerBucketObjectID],
      rowHeaderBucketsByObjectID: [headerBucketObjectID: headerBucket],
      dirtyRowHeaderBucketObjectIDs: [],
      stringTableObjectID: stringTableObjectID,
      stringTable: stringTable,
      stringLookup: [:],
      reverseStringLookup: [:],
      nextStringID: 1,
      tableModelObjectID: tableModelObjectID,
      tableModel: tableModel,
      tableModelDirty: false
    )

    let tableInfoRefs = uniqueReferences([parentSheetObjectID, tableModelObjectID])
    let rowHeaderRefs = dataStore.rowHeaders.buckets.compactMap {
      $0.identifier > 0 ? $0.identifier : nil
    }
    let tileRefs = dataStore.tiles.tiles.compactMap {
      $0.tile.identifier > 0 ? $0.tile.identifier : nil
    }
    let columnHeaderRefs =
      dataStore.columnHeaders.identifier > 0 ? [dataStore.columnHeaders.identifier] : []
    let stringTableDataStoreRefs =
      dataStore.stringTable.identifier > 0 ? [dataStore.stringTable.identifier] : []
    let mergeRegionRefs =
      dataStore.mergeRegionMap.identifier > 0 ? [dataStore.mergeRegionMap.identifier] : []
    let tableModelRefs = uniqueReferences(
      rowHeaderRefs + tileRefs + columnHeaderRefs + stringTableDataStoreRefs + mergeRegionRefs
    )
    let stringTableRefs = uniqueReferences(
      stringTable.segments.compactMap { $0.identifier > 0 ? $0.identifier : nil })

    let records: [IWAObjectRecord] = [
      IWAObjectRecord(
        objectID: tableInfoObjectID,
        typeID: TypeID.tableInfoArchive,
        payloadSize: (try tableInfo.serializedData()).count,
        payloadData: try tableInfo.serializedData(),
        sourceBlobPath: preferredBlobPathResolver(TypeID.tableInfoArchive),
        objectReferences: tableInfoRefs
      ),
      IWAObjectRecord(
        objectID: tableModelObjectID,
        typeID: TypeID.tableModelArchive,
        payloadSize: (try tableModel.serializedData()).count,
        payloadData: try tableModel.serializedData(),
        sourceBlobPath: preferredBlobPathResolver(TypeID.tableModelArchive),
        objectReferences: tableModelRefs
      ),
      IWAObjectRecord(
        objectID: tileObjectID,
        typeID: TypeID.tileArchive,
        payloadSize: (try tile.serializedData()).count,
        payloadData: try tile.serializedData(),
        sourceBlobPath: preferredBlobPathResolver(TypeID.tileArchive)
      ),
      IWAObjectRecord(
        objectID: headerBucketObjectID,
        typeID: TypeID.headerStorageBucket,
        payloadSize: (try headerBucket.serializedData()).count,
        payloadData: try headerBucket.serializedData(),
        sourceBlobPath: preferredBlobPathResolver(TypeID.headerStorageBucket)
      ),
      IWAObjectRecord(
        objectID: stringTableObjectID,
        typeID: TypeID.tableDataList,
        payloadSize: (try stringTable.serializedData()).count,
        payloadData: try stringTable.serializedData(),
        sourceBlobPath: preferredBlobPathResolver(TypeID.tableDataList),
        objectReferences: stringTableRefs
      ),
    ]

    return CreatedTable(
      tableInfoObjectID: tableInfoObjectID,
      context: context,
      records: records
    )
  }

  private static func decodeStringTableContext(
    reference: TSP_Reference,
    recordsByObjectID: [UInt64: [IWAObjectRecord]]
  ) -> (
    objectID: UInt64?, tableDataList: TST_TableDataList?, lookup: [UInt32: String],
    reverseLookup: [String: UInt32], nextID: UInt32
  ) {
    let objectID = reference.identifier
    guard objectID > 0 else {
      return (nil, nil, [:], [:], 1)
    }

    guard
      let tableDataList: TST_TableDataList = decodeMessage(
        objectID: objectID,
        typeID: TypeID.tableDataList,
        recordsByObjectID: recordsByObjectID
      )
    else {
      return (objectID, nil, [:], [:], 1)
    }

    var lookup: [UInt32: String] = [:]
    var reverseLookup: [String: UInt32] = [:]
    var maxID: UInt32 = 0

    for entry in tableDataList.entries where entry.hasStringValue {
      lookup[entry.key] = entry.stringValue
      reverseLookup[entry.stringValue] = entry.key
      maxID = max(maxID, entry.key)
    }

    for segmentRef in tableDataList.segments {
      let segmentObjectID = segmentRef.identifier
      guard segmentObjectID > 0 else {
        continue
      }
      guard
        let segment: TST_TableDataListSegment = decodeMessage(
          objectID: segmentObjectID,
          typeID: TypeID.tableDataListSegment,
          recordsByObjectID: recordsByObjectID
        )
      else {
        continue
      }

      for entry in segment.entries where entry.hasStringValue {
        lookup[entry.key] = entry.stringValue
        reverseLookup[entry.stringValue] = entry.key
        maxID = max(maxID, entry.key)
      }
    }

    let nextID = max(maxID + 1, tableDataList.nextListID == 0 ? 1 : tableDataList.nextListID)
    return (objectID, tableDataList, lookup, reverseLookup, nextID)
  }

  private static func decodeRowsFromTiles(
    tileStorage: TST_TileStorage,
    columnCount: Int,
    recordsByObjectID: [UInt64: [IWAObjectRecord]]
  ) -> (rows: [[Data?]], locations: [RowStorageLocation], tilesByObjectID: [UInt64: TST_Tile]) {
    var rows: [[Data?]] = []
    var locations: [RowStorageLocation] = []
    var tilesByObjectID: [UInt64: TST_Tile] = [:]

    for tileRef in tileStorage.tiles {
      let tileObjectID = tileRef.tile.identifier
      guard tileObjectID > 0 else {
        continue
      }

      guard
        let tile: TST_Tile = decodeMessage(
          objectID: tileObjectID,
          typeID: TypeID.tileArchive,
          recordsByObjectID: recordsByObjectID
        )
      else {
        continue
      }
      tilesByObjectID[tileObjectID] = tile

      for (rowInfoIndex, rowInfo) in tile.rowInfos.enumerated() {
        let storageBuffer =
          rowInfo.cellStorageBuffer.isEmpty
          ? rowInfo.cellStorageBufferPreBnc : rowInfo.cellStorageBuffer
        let offsetsBuffer =
          rowInfo.cellOffsets.isEmpty ? rowInfo.cellOffsetsPreBnc : rowInfo.cellOffsets
        let hasWideOffsets = rowInfo.hasHasWideOffsets_p ? rowInfo.hasWideOffsets_p : false

        let row: [Data?]
        if storageBuffer.isEmpty || offsetsBuffer.isEmpty {
          row = [Data?](repeating: nil, count: max(columnCount, 0))
        } else {
          row = splitRowStorageBuffers(
            storageBuffer: storageBuffer,
            offsetsBuffer: offsetsBuffer,
            columnCount: columnCount,
            hasWideOffsets: hasWideOffsets
          )
        }

        rows.append(row)
        locations.append(
          RowStorageLocation(
            tileObjectID: tileObjectID,
            rowInfoIndex: rowInfoIndex,
            hasWideOffsets: hasWideOffsets
          ))
      }
    }

    return (rows, locations, tilesByObjectID)
  }

  private static func allocateRowStorage(forRow row: Int, context: inout TableContext) throws -> Int
  {
    guard let tileObjectID = context.tilesByObjectID.keys.sorted().first,
      var tile = context.tilesByObjectID[tileObjectID]
    else {
      throw EditableNumbersError.nativeWriteFailed(
        "IWA writer: no tile objects available for allocation")
    }

    let hasWideOffsets = tile.hasShouldUseWideRows ? tile.shouldUseWideRows : false
    let emptyRow = [Data?](repeating: nil, count: max(context.columnCount, 0))
    let encodedRow = try encodeRowStorageBuffers(
      row: emptyRow,
      columnCount: context.columnCount,
      hasWideOffsets: hasWideOffsets
    )

    var rowInfo = TST_TileRowInfo()
    rowInfo.tileRowIndex = UInt32(clamping: tile.rowInfos.count)
    rowInfo.cellCount = UInt32(clamping: context.columnCount)
    rowInfo.hasWideOffsets_p = hasWideOffsets
    rowInfo.cellStorageBuffer = encodedRow.storageBuffer
    rowInfo.cellOffsets = encodedRow.offsetsBuffer
    rowInfo.clearCellStorageBufferPreBnc()
    rowInfo.clearCellOffsetsPreBnc()

    tile.rowInfos.append(rowInfo)
    tile.numrows = UInt32(clamping: tile.rowInfos.count)
    tile.maxRow = UInt32(clamping: max(Int(tile.maxRow), row))
    if context.columnCount > 0 {
      tile.maxColumn = UInt32(clamping: max(Int(tile.maxColumn), context.columnCount - 1))
    }
    context.tilesByObjectID[tileObjectID] = tile
    context.dirtyTileObjectIDs.insert(tileObjectID)

    let storageIndex = context.rowBuffers.count
    context.rowBuffers.append(emptyRow)
    context.rowLocations.append(
      RowStorageLocation(
        tileObjectID: tileObjectID,
        rowInfoIndex: tile.rowInfos.count - 1,
        hasWideOffsets: hasWideOffsets
      ))
    if row < context.rowStorageMap.count {
      context.rowStorageMap[row] = storageIndex
    }
    context.dirtyStorageIndices.insert(storageIndex)
    return storageIndex
  }

  private static func decodeRowStorageMap(
    headerStorage: TST_HeaderStorage,
    rowCount: Int,
    rowBufferCount: Int,
    recordsByObjectID: [UInt64: [IWAObjectRecord]]
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
        let bucket: TST_HeaderStorageBucket = decodeMessage(
          objectID: bucketObjectID,
          typeID: TypeID.headerStorageBucket,
          recordsByObjectID: recordsByObjectID
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

    if rowBufferCount > 0 {
      for index in 0..<rowStorageMap.count where rowStorageMap[index] == nil {
        guard sequentialStorageIndex < rowBufferCount else {
          break
        }
        rowStorageMap[index] = sequentialStorageIndex
        sequentialStorageIndex += 1
      }
    }

    return rowStorageMap
  }

  private static func decodeRowHeaderBuckets(
    headerStorage: TST_HeaderStorage,
    recordsByObjectID: [UInt64: [IWAObjectRecord]]
  ) -> (objectIDs: [UInt64], bucketsByObjectID: [UInt64: TST_HeaderStorageBucket]) {
    var orderedObjectIDs: [UInt64] = []
    var bucketsByObjectID: [UInt64: TST_HeaderStorageBucket] = [:]

    for bucketRef in headerStorage.buckets {
      let objectID = bucketRef.identifier
      guard objectID > 0 else {
        continue
      }
      guard
        let bucket: TST_HeaderStorageBucket = decodeMessage(
          objectID: objectID,
          typeID: TypeID.headerStorageBucket,
          recordsByObjectID: recordsByObjectID
        )
      else {
        continue
      }
      orderedObjectIDs.append(objectID)
      bucketsByObjectID[objectID] = bucket
    }

    return (orderedObjectIDs, bucketsByObjectID)
  }

  private static func decodeMessage<MessageType: SwiftProtobuf.Message>(
    objectID: UInt64,
    typeID: UInt32,
    recordsByObjectID: [UInt64: [IWAObjectRecord]]
  ) -> MessageType? {
    guard let candidates = recordsByObjectID[objectID] else {
      return nil
    }
    guard let record = candidates.first(where: { $0.typeID == typeID }) else {
      return nil
    }
    return try? MessageType(serializedBytes: record.payloadData)
  }

  private static func record(
    objectID: UInt64,
    typeID: UInt32,
    recordsByObjectID: [UInt64: [IWAObjectRecord]]
  ) -> IWAObjectRecord? {
    recordsByObjectID[objectID]?.first(where: { $0.typeID == typeID })
  }

  private static func reference(_ objectID: UInt64) -> TSP_Reference {
    var ref = TSP_Reference()
    ref.identifier = objectID
    return ref
  }

  private static func uniqueReferences(_ references: [UInt64]) -> [UInt64] {
    var seen: Set<UInt64> = []
    var ordered: [UInt64] = []
    ordered.reserveCapacity(references.count)

    for reference in references where reference > 0 && !seen.contains(reference) {
      seen.insert(reference)
      ordered.append(reference)
    }

    return ordered
  }

  private static func selectDocumentObjectID(inventory: IWAInventory) -> UInt64? {
    let candidates = Set(
      inventory.records.filter { $0.typeID == TypeID.documentArchive }.map(\.objectID)
    )
    .sorted()
    guard !candidates.isEmpty else {
      return nil
    }

    let rootCandidates = inventory.rootObjectIDs.filter { candidates.contains($0) }.sorted()
    return rootCandidates.first ?? candidates.first
  }

  private static func tableKey(for operation: LowLevelOperation) -> TableKey {
    let names = tableNames(for: operation)
    return TableKey(sheetName: names.sheet, tableName: names.table)
  }

  private static func tableNames(for operation: LowLevelOperation) -> (sheet: String, table: String)
  {
    switch operation {
    case .setCell(let sheetName, let tableName, _, _, _):
      return (sheetName, tableName)
    case .appendRow(let sheetName, let tableName, _):
      return (sheetName, tableName)
    case .insertRow(let sheetName, let tableName, _, _):
      return (sheetName, tableName)
    case .appendColumn(let sheetName, let tableName, _):
      return (sheetName, tableName)
    case .addTable(let sheetName, let tableName, _, _):
      return (sheetName, tableName)
    case .addSheet(let name, let defaultTableName, _, _):
      return (name, defaultTableName)
    }
  }

  private static func apply(operation: LowLevelOperation, to context: inout TableContext) throws {
    switch operation {
    case .setCell(_, _, let row, let column, let value):
      try applySetCell(row: row, column: column, value: value, context: &context)
    case .appendRow(_, _, let values):
      let requiredColumnCount = max(context.columnCount, values.count)
      try ensureColumnCount(requiredColumnCount, context: &context)
      let rowIndex = context.rowCount
      try ensureRowCount(rowIndex + 1, context: &context)
      for (column, value) in values.enumerated() where value != .empty {
        try applySetCell(row: rowIndex, column: column, value: value, context: &context)
      }
    case .insertRow(_, _, let rowIndex, let values):
      guard rowIndex >= 0, rowIndex <= context.rowCount else {
        throw EditableNumbersError.nativeWriteFailed(
          "IWA writer: invalid insert row index \(rowIndex) for rowCount \(context.rowCount)"
        )
      }
      let requiredColumnCount = max(context.columnCount, values.count)
      try ensureColumnCount(requiredColumnCount, context: &context)
      try insertLogicalRow(at: rowIndex, context: &context)
      for (column, value) in values.enumerated() where value != .empty {
        try applySetCell(row: rowIndex, column: column, value: value, context: &context)
      }
    case .appendColumn(_, _, let values):
      let columnIndex = context.columnCount
      try ensureColumnCount(columnIndex + 1, context: &context)
      try ensureRowCount(max(context.rowCount, values.count), context: &context)
      for (row, value) in values.enumerated() where value != .empty {
        try applySetCell(row: row, column: columnIndex, value: value, context: &context)
      }
    case .addTable, .addSheet:
      throw EditableNumbersError.nativeWriteFailed(
        "IWA writer: addTable/addSheet are handled at document level and should not be applied to existing table context"
      )
    }
  }

  private static func applySetCell(
    row: Int,
    column: Int,
    value: CellValue,
    context: inout TableContext
  ) throws {
    guard row >= 0, column >= 0 else {
      throw EditableNumbersError.nativeWriteFailed(
        "IWA writer: negative cell address is not supported"
      )
    }

    try ensureRowCount(row + 1, context: &context)
    try ensureColumnCount(column + 1, context: &context)

    let storageIndex = try storageIndex(forRow: row, context: &context)
    guard storageIndex >= 0, storageIndex < context.rowBuffers.count else {
      throw EditableNumbersError.nativeWriteFailed(
        "IWA writer: invalid storage index \(storageIndex) for row \(row)"
      )
    }

    var rowBuffer = context.rowBuffers[storageIndex]
    if rowBuffer.count < context.columnCount {
      rowBuffer.append(contentsOf: repeatElement(nil, count: context.columnCount - rowBuffer.count))
    }

    rowBuffer[column] = try encodeCellBuffer(value: value, context: &context)
    context.rowBuffers[storageIndex] = rowBuffer
    context.dirtyStorageIndices.insert(storageIndex)
  }

  private static func ensureRowCount(_ minimum: Int, context: inout TableContext) throws {
    guard minimum > context.rowCount else {
      return
    }

    while context.rowCount < minimum {
      let newRowIndex = context.rowCount
      context.rowStorageMap.append(nil)
      context.rowCount += 1
      appendRowHeader(rowIndex: newRowIndex, context: &context)
      _ = try allocateRowStorage(forRow: newRowIndex, context: &context)
    }

    markTableModelDimensionsDirty(context: &context)
  }

  private static func ensureColumnCount(_ minimum: Int, context: inout TableContext) throws {
    guard minimum > context.columnCount else {
      return
    }

    context.columnCount = minimum
    for storageIndex in context.rowBuffers.indices {
      if context.rowBuffers[storageIndex].count < minimum {
        context.rowBuffers[storageIndex].append(
          contentsOf: repeatElement(nil, count: minimum - context.rowBuffers[storageIndex].count))
      }
      context.dirtyStorageIndices.insert(storageIndex)
    }

    markTableModelDimensionsDirty(context: &context)
  }

  private static func insertLogicalRow(at rowIndex: Int, context: inout TableContext) throws {
    context.rowStorageMap.insert(nil, at: rowIndex)
    context.rowCount += 1
    try insertRowHeader(rowIndex: rowIndex, context: &context)
    _ = try allocateRowStorage(forRow: rowIndex, context: &context)
    markTableModelDimensionsDirty(context: &context)
  }

  private static func storageIndex(forRow row: Int, context: inout TableContext) throws -> Int {
    guard row >= 0, row < context.rowStorageMap.count else {
      throw EditableNumbersError.nativeWriteFailed(
        "IWA writer: missing row storage mapping for row \(row)"
      )
    }

    if let index = context.rowStorageMap[row] {
      return index
    }

    return try allocateRowStorage(forRow: row, context: &context)
  }

  private static func appendRowHeader(rowIndex: Int, context: inout TableContext) {
    guard
      let bucketObjectID = context.rowHeaderBucketObjectIDs.first,
      var bucket = context.rowHeaderBucketsByObjectID[bucketObjectID]
    else {
      return
    }

    let header = makeRowHeader(for: rowIndex, template: bucket.headers.first)
    bucket.headers.append(header)
    context.rowHeaderBucketsByObjectID[bucketObjectID] = bucket
    context.dirtyRowHeaderBucketObjectIDs.insert(bucketObjectID)
  }

  private static func insertRowHeader(rowIndex: Int, context: inout TableContext) throws {
    guard let primaryBucketObjectID = context.rowHeaderBucketObjectIDs.first else {
      throw EditableNumbersError.nativeWriteFailed(
        "IWA writer: insertRow requires row header buckets"
      )
    }

    for bucketObjectID in context.rowHeaderBucketObjectIDs {
      guard var bucket = context.rowHeaderBucketsByObjectID[bucketObjectID] else {
        continue
      }

      var changed = false
      for index in bucket.headers.indices where Int(bucket.headers[index].index) >= rowIndex {
        bucket.headers[index].index = UInt32(clamping: Int(bucket.headers[index].index) + 1)
        changed = true
      }

      if changed {
        context.rowHeaderBucketsByObjectID[bucketObjectID] = bucket
        context.dirtyRowHeaderBucketObjectIDs.insert(bucketObjectID)
      }
    }

    guard var primaryBucket = context.rowHeaderBucketsByObjectID[primaryBucketObjectID] else {
      throw EditableNumbersError.nativeWriteFailed(
        "IWA writer: primary row header bucket \(primaryBucketObjectID) not found"
      )
    }

    let header = makeRowHeader(for: rowIndex, template: primaryBucket.headers.first)
    primaryBucket.headers.append(header)
    context.rowHeaderBucketsByObjectID[primaryBucketObjectID] = primaryBucket
    context.dirtyRowHeaderBucketObjectIDs.insert(primaryBucketObjectID)
  }

  private static func makeRowHeader(
    for rowIndex: Int,
    template: TST_HeaderStorageBucket.Header?
  ) -> TST_HeaderStorageBucket.Header {
    var header = TST_HeaderStorageBucket.Header()
    header.index = UInt32(clamping: rowIndex)

    if let template {
      if template.hasSize {
        header.size = template.size
      }
      if template.hasHidingState {
        header.hidingState = template.hidingState
      }
      if template.hasNumberOfCells {
        header.numberOfCells = template.numberOfCells
      }
    }

    return header
  }

  private static func markTableModelDimensionsDirty(context: inout TableContext) {
    context.tableModel.numberOfRows = UInt32(clamping: max(context.rowCount, 0))
    context.tableModel.numberOfColumns = UInt32(clamping: max(context.columnCount, 0))
    context.tableModelDirty = true
  }

  private static func flushDirtyRows(context: inout TableContext) throws {
    guard !context.dirtyStorageIndices.isEmpty else {
      return
    }

    for storageIndex in context.dirtyStorageIndices.sorted() {
      guard storageIndex >= 0, storageIndex < context.rowBuffers.count,
        storageIndex < context.rowLocations.count
      else {
        throw EditableNumbersError.nativeWriteFailed(
          "IWA writer: invalid storage index \(storageIndex) while flushing rows"
        )
      }

      let location = context.rowLocations[storageIndex]
      guard var tile = context.tilesByObjectID[location.tileObjectID] else {
        throw EditableNumbersError.nativeWriteFailed(
          "IWA writer: tile object \(location.tileObjectID) not found"
        )
      }
      guard location.rowInfoIndex >= 0, location.rowInfoIndex < tile.rowInfos.count else {
        throw EditableNumbersError.nativeWriteFailed(
          "IWA writer: invalid row-info index \(location.rowInfoIndex)"
        )
      }

      var rowInfo = tile.rowInfos[location.rowInfoIndex]
      var row = context.rowBuffers[storageIndex]
      if row.count < context.columnCount {
        row.append(contentsOf: repeatElement(nil, count: context.columnCount - row.count))
        context.rowBuffers[storageIndex] = row
      }

      let encodedRow = try encodeRowStorageBuffers(
        row: row,
        columnCount: context.columnCount,
        hasWideOffsets: location.hasWideOffsets
      )

      if rowInfo.hasCellStorageBuffer || !rowInfo.cellStorageBuffer.isEmpty {
        rowInfo.cellStorageBuffer = encodedRow.storageBuffer
        rowInfo.cellOffsets = encodedRow.offsetsBuffer
        rowInfo.clearCellStorageBufferPreBnc()
        rowInfo.clearCellOffsetsPreBnc()
      } else {
        rowInfo.cellStorageBufferPreBnc = encodedRow.storageBuffer
        rowInfo.cellOffsetsPreBnc = encodedRow.offsetsBuffer
        rowInfo.clearCellStorageBuffer()
        rowInfo.clearCellOffsets()
      }
      rowInfo.cellCount = UInt32(clamping: context.columnCount)
      tile.rowInfos[location.rowInfoIndex] = rowInfo
      tile.numrows = UInt32(clamping: tile.rowInfos.count)

      if context.rowCount > 0 {
        tile.maxRow = UInt32(clamping: max(Int(tile.maxRow), context.rowCount - 1))
      }
      if context.columnCount > 0 {
        tile.maxColumn = UInt32(clamping: max(Int(tile.maxColumn), context.columnCount - 1))
      }

      context.tilesByObjectID[location.tileObjectID] = tile
      context.dirtyTileObjectIDs.insert(location.tileObjectID)
    }

    context.dirtyStorageIndices.removeAll()
  }

  private static func encodeCellBuffer(value: CellValue, context: inout TableContext) throws
    -> Data?
  {
    switch value {
    case .empty:
      return nil
    case .number(let number):
      return encodeNumericCell(value: number, typeID: 2)
    case .bool(let bool):
      return encodeNumericCell(value: bool ? 1.0 : 0.0, typeID: 6)
    case .string(let string):
      let stringID = try resolveStringID(for: string, context: &context)
      return encodeStringCell(stringID: stringID)
    case .date(let date):
      let marker = editableDateMarkerPrefix + formatDate(date)
      let stringID = try resolveStringID(for: marker, context: &context)
      return encodeStringCell(stringID: stringID)
    }
  }

  private static func resolveStringID(for string: String, context: inout TableContext) throws
    -> UInt32
  {
    if let existing = context.reverseStringLookup[string] {
      return existing
    }

    guard var list = context.stringTable else {
      throw EditableNumbersError.nativeWriteFailed("IWA writer: string table is unavailable")
    }

    let newID = context.nextStringID
    context.nextStringID += 1

    var entry = TST_TableDataList.ListEntry()
    entry.key = newID
    entry.refcount = 1
    entry.stringValue = string

    list.entries.append(entry)
    if list.nextListID <= newID {
      list.nextListID = newID + 1
    }

    context.stringTable = list
    context.stringLookup[newID] = string
    context.reverseStringLookup[string] = newID
    return newID
  }

  private static func encodeNumericCell(value: Double, typeID: UInt8) -> Data {
    var buffer = Data(repeating: 0, count: 12)
    buffer[0] = 5
    buffer[1] = typeID

    writeInt32LittleEndian(0x2, into: &buffer, at: 8)
    appendDoubleLittleEndian(value, to: &buffer)
    return buffer
  }

  private static func encodeStringCell(stringID: UInt32) -> Data {
    var buffer = Data(repeating: 0, count: 12)
    buffer[0] = 5
    buffer[1] = 3

    writeInt32LittleEndian(0x8, into: &buffer, at: 8)
    appendInt32LittleEndian(Int32(bitPattern: stringID), to: &buffer)
    return buffer
  }

  private static func encodeRowStorageBuffers(
    row: [Data?],
    columnCount: Int,
    hasWideOffsets: Bool
  ) throws -> (storageBuffer: Data, offsetsBuffer: Data) {
    var storageBuffer = Data()
    var offsets: [Int16] = []
    offsets.reserveCapacity(columnCount)

    for column in 0..<columnCount {
      guard column < row.count, let cell = row[column], !cell.isEmpty else {
        offsets.append(-1)
        continue
      }

      if hasWideOffsets {
        let remainder = storageBuffer.count % 4
        if remainder != 0 {
          storageBuffer.append(contentsOf: repeatElement(0, count: 4 - remainder))
        }
      }

      let offsetValue: Int
      if hasWideOffsets {
        offsetValue = storageBuffer.count / 4
      } else {
        offsetValue = storageBuffer.count
      }
      guard offsetValue <= Int(Int16.max) else {
        throw EditableNumbersError.nativeWriteFailed(
          "IWA writer: row offset exceeds Int16 capacity")
      }
      offsets.append(Int16(offsetValue))
      storageBuffer.append(cell)
    }

    var offsetsBuffer = Data(capacity: offsets.count * 2)
    for offset in offsets {
      var littleEndian = offset.littleEndian
      withUnsafeBytes(of: &littleEndian) { bytes in
        offsetsBuffer.append(contentsOf: bytes)
      }
    }

    return (storageBuffer, offsetsBuffer)
  }

  private static func rebuildIWAArchiveBlob(
    records: [IWAObjectRecord],
    payloadOverrides: [RecordKey: Data],
    additionalRecords: [IWAObjectRecord] = []
  ) throws -> Data {
    var decompressedPayload = Data()

    for record in records {
      let key = RecordKey(objectID: record.objectID, typeID: record.typeID)
      let payload = payloadOverrides[key] ?? record.payloadData

      var messageInfo = TSP_MessageInfo()
      messageInfo.type = record.typeID
      messageInfo.length = UInt32(clamping: payload.count)
      messageInfo.objectReferences = record.objectReferences
      messageInfo.dataReferences = record.dataReferences

      var archiveInfo = TSP_ArchiveInfo()
      archiveInfo.identifier = record.objectID
      archiveInfo.messageInfos = [messageInfo]

      let archiveInfoData = try archiveInfo.serializedData()
      appendVarint(UInt64(archiveInfoData.count), to: &decompressedPayload)
      decompressedPayload.append(archiveInfoData)
      decompressedPayload.append(payload)
    }

    for record in additionalRecords.sorted(by: { lhs, rhs in
      if lhs.objectID == rhs.objectID {
        return lhs.typeID < rhs.typeID
      }
      return lhs.objectID < rhs.objectID
    }) {
      let key = RecordKey(objectID: record.objectID, typeID: record.typeID)
      let payload = payloadOverrides[key] ?? record.payloadData

      var messageInfo = TSP_MessageInfo()
      messageInfo.type = record.typeID
      messageInfo.length = UInt32(clamping: payload.count)
      messageInfo.objectReferences = record.objectReferences
      messageInfo.dataReferences = record.dataReferences

      var archiveInfo = TSP_ArchiveInfo()
      archiveInfo.identifier = record.objectID
      archiveInfo.messageInfos = [messageInfo]

      let archiveInfoData = try archiveInfo.serializedData()
      appendVarint(UInt64(archiveInfoData.count), to: &decompressedPayload)
      decompressedPayload.append(archiveInfoData)
      decompressedPayload.append(payload)
    }

    return encodeIWAChunks(decompressedPayload)
  }

  private static func encodeIWAChunks(_ payload: Data) -> Data {
    let maxChunkSize = 0x00FF_FFFF
    var output = Data()
    var cursor = 0

    while cursor < payload.count {
      let end = min(cursor + maxChunkSize, payload.count)
      let chunk = payload[cursor..<end]
      let length = chunk.count

      output.append(0x00)
      output.append(UInt8(length & 0xFF))
      output.append(UInt8((length >> 8) & 0xFF))
      output.append(UInt8((length >> 16) & 0xFF))
      output.append(contentsOf: chunk)

      cursor = end
    }

    if output.isEmpty {
      output.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
    }
    return output
  }

  private static func splitRowStorageBuffers(
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

  private static func decodeSignedInt16Array(_ data: Data) -> [Int] {
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

  private static func appendVarint(_ value: UInt64, to data: inout Data) {
    var value = value
    while value >= 0x80 {
      data.append(UInt8(value & 0x7F | 0x80))
      value >>= 7
    }
    data.append(UInt8(value & 0x7F))
  }

  private static func appendDoubleLittleEndian(_ value: Double, to data: inout Data) {
    var bits = value.bitPattern.littleEndian
    withUnsafeBytes(of: &bits) { bytes in
      data.append(contentsOf: bytes)
    }
  }

  private static func appendInt32LittleEndian(_ value: Int32, to data: inout Data) {
    var littleEndian = value.littleEndian
    withUnsafeBytes(of: &littleEndian) { bytes in
      data.append(contentsOf: bytes)
    }
  }

  private static func writeInt32LittleEndian(_ value: Int32, into data: inout Data, at offset: Int)
  {
    guard offset >= 0, offset + 4 <= data.count else {
      return
    }
    let littleEndian = UInt32(bitPattern: value.littleEndian)
    data[offset] = UInt8(littleEndian & 0xFF)
    data[offset + 1] = UInt8((littleEndian >> 8) & 0xFF)
    data[offset + 2] = UInt8((littleEndian >> 16) & 0xFF)
    data[offset + 3] = UInt8((littleEndian >> 24) & 0xFF)
  }

  private static func formatDate(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
  }
}
