import Foundation
import XCTest

@testable import SwiftNumbersIWA
import SwiftNumbersProto

final class RealReadPipelineUnitTests: XCTestCase {
  func testDecodeSignedInt16Array() {
    let values: [Int16] = [0, 1, -1, 320]
    var data = Data()
    for value in values {
      var little = value.littleEndian
      data.append(Data(bytes: &little, count: MemoryLayout<Int16>.size))
    }

    let decoded = IWARealDocumentReader.decodeSignedInt16Array(data)
    XCTAssertEqual(decoded, [0, 1, -1, 320])
  }

  func testSplitRowStorageBuffersWithWideOffsets() {
    let storage = Data("AAAABBBB".utf8)

    var offsets = Data()
    for value in [Int16(0), Int16(1), Int16(-1)] {
      var little = value.littleEndian
      offsets.append(Data(bytes: &little, count: MemoryLayout<Int16>.size))
    }

    let row = IWARealDocumentReader.splitRowStorageBuffers(
      storageBuffer: storage,
      offsetsBuffer: offsets,
      columnCount: 3,
      hasWideOffsets: true
    )

    XCTAssertEqual(row.count, 3)
    XCTAssertEqual(row[0], Data("AAAA".utf8))
    XCTAssertEqual(row[1], Data("BBBB".utf8))
    XCTAssertNil(row[2])
  }

  func testDecodeCellValueForStringNumberAndBool() {
    let stringBuffer = makeCellBuffer(type: 3, flags: 0x8) { data in
      appendInt32(7, to: &data)
    }
    let numberBuffer = makeCellBuffer(type: 2, flags: 0x2) { data in
      appendDouble(42.5, to: &data)
    }
    let boolBuffer = makeCellBuffer(type: 6, flags: 0x2) { data in
      appendDouble(1.0, to: &data)
    }

    let lookup: [UInt32: String] = [7: "Hello"]

    XCTAssertEqual(
      IWARealDocumentReader.decodeCellValue(buffer: stringBuffer, stringLookup: lookup),
      .string("Hello")
    )
    XCTAssertEqual(
      IWARealDocumentReader.decodeCellValue(buffer: numberBuffer, stringLookup: lookup),
      .number(42.5)
    )
    XCTAssertEqual(
      IWARealDocumentReader.decodeCellValue(buffer: boolBuffer, stringLookup: lookup),
      .bool(true)
    )
  }

  func testDecodeCellValueFallsBackForUnknownTypeUsingStringPayload() {
    let unknownStringBuffer = makeCellBuffer(type: 17, flags: 0x8) { data in
      appendInt32(42, to: &data)
    }
    let lookup: [UInt32: String] = [42: "Fallback String"]

    XCTAssertEqual(
      IWARealDocumentReader.decodeCellValue(buffer: unknownStringBuffer, stringLookup: lookup),
      .string("Fallback String")
    )
  }

  func testDecodeCellValueFallsBackForUnknownTypeUsingNumberPayload() {
    let unknownNumberBuffer = makeCellBuffer(type: 23, flags: 0x2) { data in
      appendDouble(12.25, to: &data)
    }

    XCTAssertEqual(
      IWARealDocumentReader.decodeCellValue(
        buffer: unknownNumberBuffer,
        stringLookup: [:]
      ),
      .number(12.25)
    )
  }

  func testDecodeCellTypeDetection() {
    var valid = Data(repeating: 0, count: 12)
    valid[0] = 5
    valid[1] = 77
    XCTAssertEqual(IWARealDocumentReader.detectedCellType(buffer: valid), 77)

    var wrongVersion = Data(repeating: 0, count: 12)
    wrongVersion[0] = 4
    wrongVersion[1] = 77
    XCTAssertNil(IWARealDocumentReader.detectedCellType(buffer: wrongVersion))

    XCTAssertNil(IWARealDocumentReader.detectedCellType(buffer: Data([5])))
  }

  func testDecodeCellValueUnknownTypeWithoutPayloadReturnsNil() {
    let unknownWithoutPayload = makeCellBuffer(type: 91, flags: 0) { _ in }
    XCTAssertNil(
      IWARealDocumentReader.decodeCellValue(
        buffer: unknownWithoutPayload,
        stringLookup: [:]
      )
    )
  }

  func testDecodeCellStorageSupportsDateDurationFormulaAndRichTextKinds() {
    let dateBuffer = makeCellBuffer(type: 5, flags: 0x4) { data in
      appendDouble(120.0, to: &data)
    }
    let durationBuffer = makeCellBuffer(type: 7, flags: 0x2) { data in
      appendDouble(95.0, to: &data)
    }
    let formulaBuffer = makeCellBuffer(type: 4, flags: 0x202) { data in
      appendDouble(7.5, to: &data)
      appendInt32(55, to: &data)
    }
    let richTextBuffer = makeCellBuffer(type: 9, flags: 0x10) { data in
      appendInt32(8, to: &data)
    }
    let formulaResultNumberBuffer = makeCellBuffer(type: 2, flags: 0x202) { data in
      appendDouble(99.75, to: &data)
      appendInt32(77, to: &data)
    }
    let formulaErrorFromNumberBuffer = makeCellBuffer(type: 2, flags: 0x802) { data in
      appendDouble(0, to: &data)
      appendInt32(88, to: &data)
    }

    let dateDecoded = IWARealDocumentReader.decodeCellStorage(buffer: dateBuffer, stringLookup: [:])
    XCTAssertEqual(dateDecoded?.kind, .date)
    XCTAssertNotNil(dateDecoded?.value)

    let durationDecoded = IWARealDocumentReader.decodeCellStorage(
      buffer: durationBuffer,
      stringLookup: [:]
    )
    XCTAssertEqual(durationDecoded?.kind, .duration)
    XCTAssertEqual(durationDecoded?.value, .duration(95.0))

    let formulaDecoded = IWARealDocumentReader.decodeCellStorage(
      buffer: formulaBuffer,
      stringLookup: [:]
    )
    XCTAssertEqual(formulaDecoded?.kind, .formula)
    XCTAssertEqual(formulaDecoded?.formulaID, 55)
    XCTAssertEqual(formulaDecoded?.value, .number(7.5))

    let richTextDecoded = IWARealDocumentReader.decodeCellStorage(
      buffer: richTextBuffer,
      stringLookup: [8: "RT payload"]
    )
    XCTAssertEqual(richTextDecoded?.kind, .richText)
    XCTAssertEqual(richTextDecoded?.richTextID, 8)
    XCTAssertEqual(richTextDecoded?.value, .richText("RT payload"))

    let formulaResultNumberDecoded = IWARealDocumentReader.decodeCellStorage(
      buffer: formulaResultNumberBuffer,
      stringLookup: [:]
    )
    XCTAssertEqual(formulaResultNumberDecoded?.kind, .formula)
    XCTAssertEqual(formulaResultNumberDecoded?.formulaID, 77)
    XCTAssertEqual(formulaResultNumberDecoded?.value, .number(99.75))

    let formulaErrorFromNumberDecoded = IWARealDocumentReader.decodeCellStorage(
      buffer: formulaErrorFromNumberBuffer,
      stringLookup: [:]
    )
    XCTAssertEqual(formulaErrorFromNumberDecoded?.kind, .formulaError)
    XCTAssertEqual(formulaErrorFromNumberDecoded?.formulaErrorID, 88)
    XCTAssertEqual(formulaErrorFromNumberDecoded?.value, .error("#ERROR!"))
  }

  func testDecodeCellStorageParsesStyleAndFormatIdentifiers() {
    let flags: Int32 = 0x8 | 0x20 | 0x40 | 0x2000 | 0x4000 | 0x8000 | 0x10000 | 0x20000 | 0x40000
    let buffer = makeCellBuffer(type: 3, flags: flags) { data in
      appendInt32(11, to: &data)  // string id
      appendInt32(12, to: &data)  // cell style id
      appendInt32(13, to: &data)  // text style id
      appendInt32(21, to: &data)  // number format id
      appendInt32(22, to: &data)  // currency format id
      appendInt32(23, to: &data)  // date format id
      appendInt32(24, to: &data)  // duration format id
      appendInt32(25, to: &data)  // text format id
      appendInt32(26, to: &data)  // bool format id
    }

    let decoded = IWARealDocumentReader.decodeCellStorage(
      buffer: buffer,
      stringLookup: [11: "Styled"]
    )

    XCTAssertEqual(decoded?.stringID, 11)
    XCTAssertEqual(decoded?.cellStyleID, 12)
    XCTAssertEqual(decoded?.textStyleID, 13)
    XCTAssertEqual(decoded?.numberFormatID, 21)
    XCTAssertEqual(decoded?.currencyFormatID, 22)
    XCTAssertEqual(decoded?.dateFormatID, 23)
    XCTAssertEqual(decoded?.durationFormatID, 24)
    XCTAssertEqual(decoded?.textFormatID, 25)
    XCTAssertEqual(decoded?.boolFormatID, 26)
  }

  func testColorHexEncodesRGBAndAlpha() {
    var color = TSP_Color()
    color.model = .rgb
    color.r = 0.2
    color.g = 0.4
    color.b = 0.6
    color.a = 1.0
    XCTAssertEqual(IWARealDocumentReader.colorHex(color), "#336699")

    color.a = 0.5
    XCTAssertEqual(IWARealDocumentReader.colorHex(color), "#33669980")
  }

  func testUnsupportedVersionDiagnostic() {
    let warning = NumbersDocumentVersion.unsupportedVersionDiagnostic(for: "99.0.1")
    XCTAssertNotNil(warning)
    XCTAssertTrue(warning?.contains("99.0.1") == true)

    XCTAssertNil(NumbersDocumentVersion.unsupportedVersionDiagnostic(for: "14.5"))
  }

  func testDeduplicateUnsupportedDecodeDiagnosticsByObjectAndNodeTypePreservesOrder() {
    let diagnostics: [IWAReadDiagnostic] = [
      IWAReadDiagnostic(
        code: "decode.formula.unsupportedAstNodes",
        severity: .warning,
        message: "formula let first",
        objectPath: "table/100",
        context: ["unsupportedNodeType": "let", "unsupportedNodeCount": "2"]
      ),
      IWAReadDiagnostic(
        code: "decode.formula.unsupportedAstNodes",
        severity: .warning,
        message: "formula let duplicate",
        objectPath: "table/100",
        context: ["unsupportedNodeType": "let", "unsupportedNodeCount": "7"]
      ),
      IWAReadDiagnostic(
        code: "decode.formula.unsupportedAstNodes",
        severity: .warning,
        message: "formula call first",
        objectPath: "table/100",
        context: ["unsupportedNodeType": "call", "unsupportedNodeCount": "1"]
      ),
      IWAReadDiagnostic(
        code: "decode.formula.unsupportedAstNodes",
        severity: .warning,
        message: "formula let other table",
        objectPath: "table/101",
        context: ["unsupportedNodeType": "let", "unsupportedNodeCount": "1"]
      ),
      IWAReadDiagnostic(
        code: "decode.cell.unsupportedTypeDropped",
        severity: .warning,
        message: "cell type first",
        objectPath: "table/100",
        context: ["cellType": "37", "count": "4"]
      ),
      IWAReadDiagnostic(
        code: "decode.cell.unsupportedTypeDropped",
        severity: .warning,
        message: "cell type duplicate",
        objectPath: "table/100",
        context: ["cellType": "37", "count": "9"]
      ),
      IWAReadDiagnostic(
        code: "resolver.sheet.empty",
        severity: .warning,
        message: "non-deduplicated code"
      ),
    ]

    let deduplicated = IWARealDocumentReader.deduplicateUnsupportedDecodeDiagnostics(diagnostics)
    XCTAssertEqual(
      deduplicated.map(\.message),
      [
        "formula let first",
        "formula call first",
        "formula let other table",
        "cell type first",
        "non-deduplicated code",
      ]
    )
    XCTAssertEqual(deduplicated.count, 5)
  }

  func testDeduplicateUnsupportedDecodeDiagnosticsNormalizesWhitespaceInNodeType() {
    let diagnostics: [IWAReadDiagnostic] = [
      IWAReadDiagnostic(
        code: "decode.formula.unsupportedAstNodes",
        severity: .warning,
        message: "formula let first",
        objectPath: "table/100",
        context: ["unsupportedNodeType": " let "]
      ),
      IWAReadDiagnostic(
        code: "decode.formula.unsupportedAstNodes",
        severity: .warning,
        message: "formula let duplicate trimmed",
        objectPath: "table/100",
        context: ["unsupportedNodeType": "let"]
      ),
      IWAReadDiagnostic(
        code: "decode.cell.unsupportedTypeDropped",
        severity: .warning,
        message: "cell type first",
        objectPath: "table/100",
        context: ["cellType": " 37 "]
      ),
      IWAReadDiagnostic(
        code: "decode.cell.unsupportedTypeDropped",
        severity: .warning,
        message: "cell type duplicate trimmed",
        objectPath: "table/100",
        context: ["cellType": "37"]
      ),
    ]

    let deduplicated = IWARealDocumentReader.deduplicateUnsupportedDecodeDiagnostics(diagnostics)
    XCTAssertEqual(
      deduplicated.map(\.message),
      [
        "formula let first",
        "cell type first",
      ]
    )
    XCTAssertEqual(deduplicated.count, 2)
  }

  func testDeduplicateUnsupportedDecodeDiagnosticsNormalizesNodeTypeListsAndObjectPathWhitespace() {
    let diagnostics: [IWAReadDiagnostic] = [
      IWAReadDiagnostic(
        code: "decode.formula.unsupportedAstNodes",
        severity: .warning,
        message: "formula list first",
        objectPath: "table/100",
        context: ["unsupportedNodeTypes": " Let,Call "]
      ),
      IWAReadDiagnostic(
        code: "decode.formula.unsupportedAstNodes",
        severity: .warning,
        message: "formula list duplicate reordered",
        objectPath: " table/100 ",
        context: ["unsupportedNodeTypes": "call, let"]
      ),
      IWAReadDiagnostic(
        code: "decode.formula.unsupportedAstNodes",
        severity: .warning,
        message: "formula list distinct",
        objectPath: "table/100",
        context: ["unsupportedNodeTypes": "call, thunk"]
      ),
    ]

    let deduplicated = IWARealDocumentReader.deduplicateUnsupportedDecodeDiagnostics(diagnostics)
    XCTAssertEqual(
      deduplicated.map(\.message),
      [
        "formula list first",
        "formula list distinct",
      ]
    )
    XCTAssertEqual(deduplicated.count, 2)
  }

  func testResolverChoosesDeterministicDocumentCandidate() {
    let records = [
      IWAObjectRecord(objectID: 20, typeID: 1, payloadSize: 0, sourceBlobPath: "A.iwa"),
      IWAObjectRecord(objectID: 10, typeID: 1, payloadSize: 0, sourceBlobPath: "B.iwa"),
    ]
    let inventory = IWAInventory(records: records, unparsedBlobPaths: [])

    let result = IWARealDocumentReader.read(from: inventory, documentVersion: nil)
    let noSheets = result.structuredDiagnostics.first { $0.code == "resolver.sheet.empty" }
    XCTAssertEqual(noSheets?.context["objectID"], "10")
  }

  func testResolverSkipsNonTableDrawableReferencesWithoutWarning() throws {
    var document = TN_DocumentArchive()
    document.sheets = [reference(200)]

    var sheet = TN_SheetArchive()
    sheet.name = "Main"
    sheet.drawableInfos = [reference(300)]

    let documentPayload = try document.serializedData()
    let sheetPayload = try sheet.serializedData()

    let records = [
      IWAObjectRecord(
        objectID: 100,
        typeID: 1,
        payloadSize: documentPayload.count,
        payloadData: documentPayload,
        sourceBlobPath: "Doc.iwa",
        objectReferences: [200]
      ),
      IWAObjectRecord(
        objectID: 200,
        typeID: 2,
        payloadSize: sheetPayload.count,
        payloadData: sheetPayload,
        sourceBlobPath: "Sheet.iwa",
        objectReferences: [300]
      ),
      // Drawable object that is not a TableInfo archive.
      IWAObjectRecord(
        objectID: 300,
        typeID: 9999,
        payloadSize: 0,
        sourceBlobPath: "Drawable.iwa"
      ),
    ]

    let inventory = IWAInventory(records: records, unparsedBlobPaths: [])
    let result = IWARealDocumentReader.read(from: inventory, documentVersion: nil)

    XCTAssertEqual(result.sheets.count, 1)
    XCTAssertEqual(result.sheets.first?.tables.count, 0)
    XCTAssertFalse(
      result.structuredDiagnostics.contains { $0.code == "resolver.table.resolveFailed" }
    )
    XCTAssertFalse(
      result.structuredDiagnostics.contains { $0.code == "resolver.pivot.candidateDetected" }
    )
  }

  func testResolverEmitsPivotCandidateDiagnosticForLinkedNonTableDrawable() throws {
    var document = TN_DocumentArchive()
    document.sheets = [reference(200)]

    var sheet = TN_SheetArchive()
    sheet.name = "Main"
    sheet.drawableInfos = [reference(300), reference(500)]

    var tableInfo = TST_TableInfoArchive()
    var drawable = TSD_DrawableArchive()
    drawable.parent = reference(200)
    tableInfo.super = drawable
    tableInfo.tableModel = reference(400)

    var tableModel = TST_TableModelArchive()
    tableModel.tableID = "table-400"
    tableModel.tableName = "Data"
    tableModel.numberOfRows = 0
    tableModel.numberOfColumns = 0

    let documentPayload = try document.serializedData()
    let sheetPayload = try sheet.serializedData()
    let tableInfoPayload = try tableInfo.serializedData()
    let tableModelPayload = try tableModel.serializedData()

    let records = [
      IWAObjectRecord(
        objectID: 100,
        typeID: 1,
        payloadSize: documentPayload.count,
        payloadData: documentPayload,
        sourceBlobPath: "Doc.iwa",
        objectReferences: [200]
      ),
      IWAObjectRecord(
        objectID: 200,
        typeID: 2,
        payloadSize: sheetPayload.count,
        payloadData: sheetPayload,
        sourceBlobPath: "Sheet.iwa",
        objectReferences: [300, 500]
      ),
      IWAObjectRecord(
        objectID: 300,
        typeID: 7777,
        payloadSize: 0,
        sourceBlobPath: "PivotCandidate.iwa",
        objectReferences: [500, 400]
      ),
      IWAObjectRecord(
        objectID: 500,
        typeID: 6000,
        payloadSize: tableInfoPayload.count,
        payloadData: tableInfoPayload,
        sourceBlobPath: "TableInfo.iwa",
        objectReferences: [200, 400]
      ),
      IWAObjectRecord(
        objectID: 400,
        typeID: 6001,
        payloadSize: tableModelPayload.count,
        payloadData: tableModelPayload,
        sourceBlobPath: "TableModel.iwa"
      ),
    ]

    let inventory = IWAInventory(records: records, unparsedBlobPaths: [])
    let result = IWARealDocumentReader.read(from: inventory, documentVersion: nil)

    XCTAssertEqual(result.sheets.count, 1)
    XCTAssertEqual(result.sheets.first?.tables.count, 1)
    let resolvedTable = try XCTUnwrap(result.sheets.first?.tables.first)
    XCTAssertEqual(resolvedTable.tableInfoObjectID, 500)
    XCTAssertEqual(resolvedTable.tableModelObjectID, 400)
    let pivotLink = try XCTUnwrap(resolvedTable.pivotLinks.first)
    XCTAssertEqual(pivotLink.drawableObjectID, 300)
    XCTAssertEqual(pivotLink.drawableTypeIDs, [7777])
    XCTAssertEqual(pivotLink.drawableTypeCount, 1)
    XCTAssertEqual(pivotLink.linkedTableInfoObjectIDs, [500])
    XCTAssertEqual(pivotLink.linkedTableInfoCount, 1)
    XCTAssertEqual(pivotLink.linkedTableModelObjectIDs, [400])
    XCTAssertEqual(pivotLink.linkedTableModelCount, 1)
    let diagnostic = result.structuredDiagnostics.first { $0.code == "resolver.pivot.candidateDetected" }
    XCTAssertNotNil(diagnostic)
    XCTAssertEqual(diagnostic?.severity, .info)
    XCTAssertEqual(diagnostic?.context["drawableObjectID"], "300")
    XCTAssertEqual(diagnostic?.context["drawableTypeIDs"], "7777")
    XCTAssertEqual(diagnostic?.context["drawableTypeCount"], "1")
    XCTAssertEqual(diagnostic?.context["referencedObjectCount"], "2")
    XCTAssertEqual(diagnostic?.context["linkedTableInfoObjectIDs"], "500")
    XCTAssertEqual(diagnostic?.context["linkedTableInfoCount"], "1")
    XCTAssertEqual(diagnostic?.context["linkedTableModelObjectIDs"], "400")
    XCTAssertEqual(diagnostic?.context["linkedTableModelCount"], "1")
    let summary = result.structuredDiagnostics.first { $0.code == "resolver.pivot.candidateSummary" }
    XCTAssertNotNil(summary)
    XCTAssertEqual(summary?.severity, .info)
    XCTAssertEqual(summary?.context["candidateObjectIDs"], "300")
    XCTAssertEqual(summary?.context["candidateCount"], "1")
    XCTAssertEqual(summary?.context["linkedTableInfoObjectIDs"], "500")
    XCTAssertEqual(summary?.context["linkedTableInfoCount"], "1")
    XCTAssertEqual(summary?.context["linkedTableModelObjectIDs"], "400")
    XCTAssertEqual(summary?.context["linkedTableModelCount"], "1")
  }

  func testResolverMergesParentTraversalTablesWhenDrawableListIsPartial() throws {
    var document = TN_DocumentArchive()
    document.sheets = [reference(200)]

    var sheet = TN_SheetArchive()
    sheet.name = "Main"
    // Only one table is listed directly in drawableInfos.
    sheet.drawableInfos = [reference(300)]

    var firstTableInfo = TST_TableInfoArchive()
    var firstDrawable = TSD_DrawableArchive()
    firstDrawable.parent = reference(200)
    firstTableInfo.super = firstDrawable
    firstTableInfo.tableModel = reference(400)

    var firstTableModel = TST_TableModelArchive()
    firstTableModel.tableID = "table-400"
    firstTableModel.tableName = "Table A"
    firstTableModel.numberOfRows = 0
    firstTableModel.numberOfColumns = 0

    var secondTableInfo = TST_TableInfoArchive()
    var secondDrawable = TSD_DrawableArchive()
    secondDrawable.parent = reference(200)
    secondTableInfo.super = secondDrawable
    secondTableInfo.tableModel = reference(401)

    var secondTableModel = TST_TableModelArchive()
    secondTableModel.tableID = "table-401"
    secondTableModel.tableName = "Table B"
    secondTableModel.numberOfRows = 0
    secondTableModel.numberOfColumns = 0

    let documentPayload = try document.serializedData()
    let sheetPayload = try sheet.serializedData()
    let firstTableInfoPayload = try firstTableInfo.serializedData()
    let firstTableModelPayload = try firstTableModel.serializedData()
    let secondTableInfoPayload = try secondTableInfo.serializedData()
    let secondTableModelPayload = try secondTableModel.serializedData()

    let records = [
      IWAObjectRecord(
        objectID: 100,
        typeID: 1,
        payloadSize: documentPayload.count,
        payloadData: documentPayload,
        sourceBlobPath: "Doc.iwa",
        objectReferences: [200]
      ),
      IWAObjectRecord(
        objectID: 200,
        typeID: 2,
        payloadSize: sheetPayload.count,
        payloadData: sheetPayload,
        sourceBlobPath: "Sheet.iwa",
        objectReferences: [300]
      ),
      IWAObjectRecord(
        objectID: 300,
        typeID: 6000,
        payloadSize: firstTableInfoPayload.count,
        payloadData: firstTableInfoPayload,
        sourceBlobPath: "TableA.iwa",
        objectReferences: [200, 400]
      ),
      IWAObjectRecord(
        objectID: 400,
        typeID: 6001,
        payloadSize: firstTableModelPayload.count,
        payloadData: firstTableModelPayload,
        sourceBlobPath: "TableAModel.iwa"
      ),
      IWAObjectRecord(
        objectID: 301,
        typeID: 6000,
        payloadSize: secondTableInfoPayload.count,
        payloadData: secondTableInfoPayload,
        sourceBlobPath: "TableB.iwa",
        objectReferences: [200, 401]
      ),
      IWAObjectRecord(
        objectID: 401,
        typeID: 6001,
        payloadSize: secondTableModelPayload.count,
        payloadData: secondTableModelPayload,
        sourceBlobPath: "TableBModel.iwa"
      ),
    ]

    let inventory = IWAInventory(records: records, unparsedBlobPaths: [])
    let result = IWARealDocumentReader.read(from: inventory, documentVersion: nil)

    XCTAssertEqual(result.sheets.count, 1)
    XCTAssertEqual(result.sheets.first?.tables.count, 2)
    XCTAssertEqual(
      Set(result.sheets.first?.tables.map(\.name) ?? []),
      Set(["Table A", "Table B"])
    )
  }

  func testResolverMergedTraversalOrderIsStableAndDeduplicatedAcrossInventoryOrder() throws {
    var document = TN_DocumentArchive()
    document.sheets = [reference(200)]

    var sheet = TN_SheetArchive()
    sheet.name = "Main"
    // Deliberately unsorted + duplicate drawable refs.
    sheet.drawableInfos = [reference(301), reference(300), reference(301)]

    var tableInfo300 = TST_TableInfoArchive()
    var drawable300 = TSD_DrawableArchive()
    drawable300.parent = reference(200)
    tableInfo300.super = drawable300
    tableInfo300.tableModel = reference(400)

    var tableInfo301 = TST_TableInfoArchive()
    var drawable301 = TSD_DrawableArchive()
    drawable301.parent = reference(200)
    tableInfo301.super = drawable301
    tableInfo301.tableModel = reference(401)

    var tableInfo302 = TST_TableInfoArchive()
    var drawable302 = TSD_DrawableArchive()
    drawable302.parent = reference(200)
    tableInfo302.super = drawable302
    tableInfo302.tableModel = reference(402)

    var tableModel400 = TST_TableModelArchive()
    tableModel400.tableID = "table-400"
    tableModel400.tableName = "Table A"
    tableModel400.numberOfRows = 0
    tableModel400.numberOfColumns = 0

    var tableModel401 = TST_TableModelArchive()
    tableModel401.tableID = "table-401"
    tableModel401.tableName = "Table B"
    tableModel401.numberOfRows = 0
    tableModel401.numberOfColumns = 0

    var tableModel402 = TST_TableModelArchive()
    tableModel402.tableID = "table-402"
    tableModel402.tableName = "Table C"
    tableModel402.numberOfRows = 0
    tableModel402.numberOfColumns = 0

    let documentPayload = try document.serializedData()
    let sheetPayload = try sheet.serializedData()
    let tableInfo300Payload = try tableInfo300.serializedData()
    let tableInfo301Payload = try tableInfo301.serializedData()
    let tableInfo302Payload = try tableInfo302.serializedData()
    let tableModel400Payload = try tableModel400.serializedData()
    let tableModel401Payload = try tableModel401.serializedData()
    let tableModel402Payload = try tableModel402.serializedData()

    let orderedRecords = [
      IWAObjectRecord(
        objectID: 100,
        typeID: 1,
        payloadSize: documentPayload.count,
        payloadData: documentPayload,
        sourceBlobPath: "Doc.iwa",
        objectReferences: [200]
      ),
      IWAObjectRecord(
        objectID: 200,
        typeID: 2,
        payloadSize: sheetPayload.count,
        payloadData: sheetPayload,
        sourceBlobPath: "Sheet.iwa",
        objectReferences: [301, 300, 301]
      ),
      IWAObjectRecord(
        objectID: 301,
        typeID: 6000,
        payloadSize: tableInfo301Payload.count,
        payloadData: tableInfo301Payload,
        sourceBlobPath: "TableB.iwa",
        objectReferences: [200, 401]
      ),
      IWAObjectRecord(
        objectID: 401,
        typeID: 6001,
        payloadSize: tableModel401Payload.count,
        payloadData: tableModel401Payload,
        sourceBlobPath: "TableBModel.iwa"
      ),
      IWAObjectRecord(
        objectID: 300,
        typeID: 6000,
        payloadSize: tableInfo300Payload.count,
        payloadData: tableInfo300Payload,
        sourceBlobPath: "TableA.iwa",
        objectReferences: [200, 400]
      ),
      IWAObjectRecord(
        objectID: 400,
        typeID: 6001,
        payloadSize: tableModel400Payload.count,
        payloadData: tableModel400Payload,
        sourceBlobPath: "TableAModel.iwa"
      ),
      // Parent traversal should merge this table even though it is not in drawableInfos.
      IWAObjectRecord(
        objectID: 302,
        typeID: 6000,
        payloadSize: tableInfo302Payload.count,
        payloadData: tableInfo302Payload,
        sourceBlobPath: "TableC.iwa",
        objectReferences: [200, 402]
      ),
      IWAObjectRecord(
        objectID: 402,
        typeID: 6001,
        payloadSize: tableModel402Payload.count,
        payloadData: tableModel402Payload,
        sourceBlobPath: "TableCModel.iwa"
      ),
    ]

    for records in [orderedRecords, Array(orderedRecords.reversed())] {
      let inventory = IWAInventory(records: records, unparsedBlobPaths: [])
      let result = IWARealDocumentReader.read(from: inventory, documentVersion: nil)
      let resolvedSheet = try XCTUnwrap(result.sheets.first)
      XCTAssertEqual(resolvedSheet.tables.count, 3)
      XCTAssertEqual(resolvedSheet.tables.map(\.tableInfoObjectID), [300, 301, 302])
    }
  }

  func testResolverMergedTraversalIgnoresNonTableDrawableRefsAndZeroIdentifiers() throws {
    var document = TN_DocumentArchive()
    document.sheets = [reference(200)]

    var sheet = TN_SheetArchive()
    sheet.name = "Main"
    // Includes zero + non-table drawable references that should not perturb table traversal order.
    sheet.drawableInfos = [reference(900), reference(301), reference(0), reference(300), reference(900), reference(301)]

    var tableInfo300 = TST_TableInfoArchive()
    var drawable300 = TSD_DrawableArchive()
    drawable300.parent = reference(200)
    tableInfo300.super = drawable300
    tableInfo300.tableModel = reference(400)

    var tableInfo301 = TST_TableInfoArchive()
    var drawable301 = TSD_DrawableArchive()
    drawable301.parent = reference(200)
    tableInfo301.super = drawable301
    tableInfo301.tableModel = reference(401)

    var tableInfo302 = TST_TableInfoArchive()
    var drawable302 = TSD_DrawableArchive()
    drawable302.parent = reference(200)
    tableInfo302.super = drawable302
    tableInfo302.tableModel = reference(402)

    var tableModel400 = TST_TableModelArchive()
    tableModel400.tableID = "table-400"
    tableModel400.tableName = "Table A"
    tableModel400.numberOfRows = 0
    tableModel400.numberOfColumns = 0

    var tableModel401 = TST_TableModelArchive()
    tableModel401.tableID = "table-401"
    tableModel401.tableName = "Table B"
    tableModel401.numberOfRows = 0
    tableModel401.numberOfColumns = 0

    var tableModel402 = TST_TableModelArchive()
    tableModel402.tableID = "table-402"
    tableModel402.tableName = "Table C"
    tableModel402.numberOfRows = 0
    tableModel402.numberOfColumns = 0

    let documentPayload = try document.serializedData()
    let sheetPayload = try sheet.serializedData()
    let tableInfo300Payload = try tableInfo300.serializedData()
    let tableInfo301Payload = try tableInfo301.serializedData()
    let tableInfo302Payload = try tableInfo302.serializedData()
    let tableModel400Payload = try tableModel400.serializedData()
    let tableModel401Payload = try tableModel401.serializedData()
    let tableModel402Payload = try tableModel402.serializedData()
    let nonTableDrawablePayload = Data([0x00, 0x01, 0x02])

    let orderedRecords = [
      IWAObjectRecord(
        objectID: 100,
        typeID: 1,
        payloadSize: documentPayload.count,
        payloadData: documentPayload,
        sourceBlobPath: "Doc.iwa",
        objectReferences: [200]
      ),
      IWAObjectRecord(
        objectID: 200,
        typeID: 2,
        payloadSize: sheetPayload.count,
        payloadData: sheetPayload,
        sourceBlobPath: "Sheet.iwa",
        objectReferences: [900, 301, 0, 300, 900, 301]
      ),
      IWAObjectRecord(
        objectID: 900,
        typeID: 7777,
        payloadSize: nonTableDrawablePayload.count,
        payloadData: nonTableDrawablePayload,
        sourceBlobPath: "PivotLikeDrawable.iwa",
        objectReferences: [302, 402]
      ),
      IWAObjectRecord(
        objectID: 301,
        typeID: 6000,
        payloadSize: tableInfo301Payload.count,
        payloadData: tableInfo301Payload,
        sourceBlobPath: "TableB.iwa",
        objectReferences: [200, 401]
      ),
      IWAObjectRecord(
        objectID: 401,
        typeID: 6001,
        payloadSize: tableModel401Payload.count,
        payloadData: tableModel401Payload,
        sourceBlobPath: "TableBModel.iwa"
      ),
      IWAObjectRecord(
        objectID: 300,
        typeID: 6000,
        payloadSize: tableInfo300Payload.count,
        payloadData: tableInfo300Payload,
        sourceBlobPath: "TableA.iwa",
        objectReferences: [200, 400]
      ),
      IWAObjectRecord(
        objectID: 400,
        typeID: 6001,
        payloadSize: tableModel400Payload.count,
        payloadData: tableModel400Payload,
        sourceBlobPath: "TableAModel.iwa"
      ),
      // Parent traversal should merge this table even though it is not a table drawable ref.
      IWAObjectRecord(
        objectID: 302,
        typeID: 6000,
        payloadSize: tableInfo302Payload.count,
        payloadData: tableInfo302Payload,
        sourceBlobPath: "TableC.iwa",
        objectReferences: [200, 402]
      ),
      IWAObjectRecord(
        objectID: 402,
        typeID: 6001,
        payloadSize: tableModel402Payload.count,
        payloadData: tableModel402Payload,
        sourceBlobPath: "TableCModel.iwa"
      ),
    ]

    for records in [orderedRecords, Array(orderedRecords.reversed())] {
      let inventory = IWAInventory(records: records, unparsedBlobPaths: [])
      let result = IWARealDocumentReader.read(from: inventory, documentVersion: nil)
      let resolvedSheet = try XCTUnwrap(result.sheets.first)
      XCTAssertEqual(resolvedSheet.tables.count, 3)
      XCTAssertEqual(resolvedSheet.tables.map(\.tableInfoObjectID), [300, 301, 302])
      XCTAssertEqual(Set(resolvedSheet.tables.map(\.tableInfoObjectID)).count, resolvedSheet.tables.count)

      let pivotCandidate = result.structuredDiagnostics.first {
        $0.code == "resolver.pivot.candidateDetected" && $0.context["drawableObjectID"] == "900"
      }
      XCTAssertNotNil(pivotCandidate)
      let pivotSummary = result.structuredDiagnostics.first {
        $0.code == "resolver.pivot.candidateSummary"
      }
      XCTAssertNotNil(pivotSummary)
      XCTAssertEqual(pivotSummary?.context["candidateObjectIDs"], "900")
      XCTAssertEqual(pivotSummary?.context["candidateCount"], "1")
      XCTAssertEqual(pivotSummary?.context["linkedTableInfoObjectIDs"], "302")
      XCTAssertEqual(pivotSummary?.context["linkedTableInfoCount"], "1")
      XCTAssertEqual(pivotSummary?.context["linkedTableModelObjectIDs"], "402")
      XCTAssertEqual(pivotSummary?.context["linkedTableModelCount"], "1")
    }
  }

  func testResolverMergedTraversalSnapshotStaysStableWithDuplicateTableInfoRecords() throws {
    var document = TN_DocumentArchive()
    document.sheets = [reference(200)]

    var sheet = TN_SheetArchive()
    sheet.name = "Main"
    sheet.drawableInfos = [reference(301), reference(300), reference(301)]

    var tableInfo300 = TST_TableInfoArchive()
    var drawable300 = TSD_DrawableArchive()
    drawable300.parent = reference(200)
    tableInfo300.super = drawable300
    tableInfo300.tableModel = reference(400)

    var tableInfo301 = TST_TableInfoArchive()
    var drawable301 = TSD_DrawableArchive()
    drawable301.parent = reference(200)
    tableInfo301.super = drawable301
    tableInfo301.tableModel = reference(401)

    var tableInfo302 = TST_TableInfoArchive()
    var drawable302 = TSD_DrawableArchive()
    drawable302.parent = reference(200)
    tableInfo302.super = drawable302
    tableInfo302.tableModel = reference(402)

    var tableModel400 = TST_TableModelArchive()
    tableModel400.tableID = "table-400"
    tableModel400.tableName = "Table A"
    tableModel400.numberOfRows = 0
    tableModel400.numberOfColumns = 0

    var tableModel401 = TST_TableModelArchive()
    tableModel401.tableID = "table-401"
    tableModel401.tableName = "Table B"
    tableModel401.numberOfRows = 0
    tableModel401.numberOfColumns = 0

    var tableModel402 = TST_TableModelArchive()
    tableModel402.tableID = "table-402"
    tableModel402.tableName = "Table C"
    tableModel402.numberOfRows = 0
    tableModel402.numberOfColumns = 0

    let documentPayload = try document.serializedData()
    let sheetPayload = try sheet.serializedData()
    let tableInfo300Payload = try tableInfo300.serializedData()
    let tableInfo301Payload = try tableInfo301.serializedData()
    let tableInfo302Payload = try tableInfo302.serializedData()
    let tableModel400Payload = try tableModel400.serializedData()
    let tableModel401Payload = try tableModel401.serializedData()
    let tableModel402Payload = try tableModel402.serializedData()
    let corruptTableInfoPayload = Data(repeating: 0x80, count: tableInfo301Payload.count + 8)

    let baselineRecords = [
      IWAObjectRecord(
        objectID: 100,
        typeID: 1,
        payloadSize: documentPayload.count,
        payloadData: documentPayload,
        sourceBlobPath: "Doc.iwa",
        objectReferences: [200]
      ),
      IWAObjectRecord(
        objectID: 200,
        typeID: 2,
        payloadSize: sheetPayload.count,
        payloadData: sheetPayload,
        sourceBlobPath: "Sheet.iwa",
        objectReferences: [301, 300, 301]
      ),
      IWAObjectRecord(
        objectID: 301,
        typeID: 6000,
        payloadSize: tableInfo301Payload.count,
        payloadData: tableInfo301Payload,
        sourceBlobPath: "TableB.iwa",
        objectReferences: [200, 401]
      ),
      IWAObjectRecord(
        objectID: 401,
        typeID: 6001,
        payloadSize: tableModel401Payload.count,
        payloadData: tableModel401Payload,
        sourceBlobPath: "TableBModel.iwa"
      ),
      IWAObjectRecord(
        objectID: 300,
        typeID: 6000,
        payloadSize: tableInfo300Payload.count,
        payloadData: tableInfo300Payload,
        sourceBlobPath: "TableA.iwa",
        objectReferences: [200, 400]
      ),
      IWAObjectRecord(
        objectID: 400,
        typeID: 6001,
        payloadSize: tableModel400Payload.count,
        payloadData: tableModel400Payload,
        sourceBlobPath: "TableAModel.iwa"
      ),
      IWAObjectRecord(
        objectID: 302,
        typeID: 6000,
        payloadSize: tableInfo302Payload.count,
        payloadData: tableInfo302Payload,
        sourceBlobPath: "TableC.iwa",
        objectReferences: [200, 402]
      ),
      IWAObjectRecord(
        objectID: 402,
        typeID: 6001,
        payloadSize: tableModel402Payload.count,
        payloadData: tableModel402Payload,
        sourceBlobPath: "TableCModel.iwa"
      ),
    ]

    let withCorruptDuplicate = [
      IWAObjectRecord(
        objectID: 301,
        typeID: 6000,
        payloadSize: corruptTableInfoPayload.count,
        payloadData: corruptTableInfoPayload,
        sourceBlobPath: "TableBCorrupt.iwa",
        objectReferences: [200, 401]
      )
    ] + baselineRecords

    let variants: [[IWAObjectRecord]] = [
      baselineRecords,
      Array(baselineRecords.reversed()),
      withCorruptDuplicate,
    ]
    let expectedSnapshot = "300:400:Table A|301:401:Table B|302:402:Table C"

    for records in variants {
      let inventory = IWAInventory(records: records, unparsedBlobPaths: [])
      let result = IWARealDocumentReader.read(from: inventory, documentVersion: nil)
      let resolvedSheet = try XCTUnwrap(result.sheets.first)
      let snapshot = resolvedSheet.tables.map {
        "\($0.tableInfoObjectID):\($0.tableModelObjectID):\($0.name)"
      }.joined(separator: "|")
      XCTAssertEqual(snapshot, expectedSnapshot)
      XCTAssertEqual(Set(resolvedSheet.tables.map(\.tableInfoObjectID)).count, resolvedSheet.tables.count)
    }
  }

  func testResolverFallsBackToDecodableDuplicateRecordForSameObjectAndType() throws {
    var document = TN_DocumentArchive()
    document.sheets = [reference(200)]

    var sheet = TN_SheetArchive()
    sheet.name = "Main"
    sheet.drawableInfos = [reference(300)]

    var tableInfo = TST_TableInfoArchive()
    var drawable = TSD_DrawableArchive()
    drawable.parent = reference(200)
    tableInfo.super = drawable
    tableInfo.tableModel = reference(400)

    var tableModel = TST_TableModelArchive()
    tableModel.tableID = "table-400"
    tableModel.tableName = "Stable Table"
    tableModel.numberOfRows = 0
    tableModel.numberOfColumns = 0

    let documentPayload = try document.serializedData()
    let sheetPayload = try sheet.serializedData()
    let tableInfoPayload = try tableInfo.serializedData()
    let tableModelPayload = try tableModel.serializedData()
    let corruptPayload = Data(repeating: 0x80, count: tableInfoPayload.count + 8)

    let records = [
      IWAObjectRecord(
        objectID: 100,
        typeID: 1,
        payloadSize: documentPayload.count,
        payloadData: documentPayload,
        sourceBlobPath: "Doc.iwa",
        objectReferences: [200]
      ),
      IWAObjectRecord(
        objectID: 200,
        typeID: 2,
        payloadSize: sheetPayload.count,
        payloadData: sheetPayload,
        sourceBlobPath: "Sheet.iwa",
        objectReferences: [300]
      ),
      // Corrupt duplicate record for the same object/type.
      IWAObjectRecord(
        objectID: 300,
        typeID: 6000,
        payloadSize: corruptPayload.count,
        payloadData: corruptPayload,
        sourceBlobPath: "CorruptTableInfo.iwa",
        objectReferences: [200, 400]
      ),
      IWAObjectRecord(
        objectID: 300,
        typeID: 6000,
        payloadSize: tableInfoPayload.count,
        payloadData: tableInfoPayload,
        sourceBlobPath: "ValidTableInfo.iwa",
        objectReferences: [200, 400]
      ),
      IWAObjectRecord(
        objectID: 400,
        typeID: 6001,
        payloadSize: tableModelPayload.count,
        payloadData: tableModelPayload,
        sourceBlobPath: "TableModel.iwa"
      ),
    ]

    let inventory = IWAInventory(records: records, unparsedBlobPaths: [])
    let result = IWARealDocumentReader.read(from: inventory, documentVersion: nil)

    let resolvedSheet = try XCTUnwrap(result.sheets.first)
    XCTAssertEqual(resolvedSheet.tables.count, 1)
    XCTAssertEqual(resolvedSheet.tables.first?.tableInfoObjectID, 300)
    XCTAssertEqual(resolvedSheet.tables.first?.name, "Stable Table")
  }

  func testSplitRowStorageBuffersReturnsNilCellsWhenOffsetsMissing() {
    let row = IWARealDocumentReader.splitRowStorageBuffers(
      storageBuffer: Data("AAAA".utf8),
      offsetsBuffer: Data(),
      columnCount: 3,
      hasWideOffsets: false
    )

    XCTAssertEqual(row.count, 3)
    XCTAssertEqual(row[0], nil)
    XCTAssertEqual(row[1], nil)
    XCTAssertEqual(row[2], nil)
  }

  func testUnpackDecimal128HandlesLargeMantissaWithoutOverflow() {
    var bytes = [UInt8](repeating: 0xFF, count: 16)
    // Encoded exponent for zero: 0x1820.
    bytes[14] = 0x41  // exponent low bits + mantissa low bit
    bytes[15] = 0x30  // exponent high bits, positive sign

    let value = IWARealDocumentReader.unpackDecimal128(Data(bytes))
    XCTAssertTrue(value.isFinite)
    XCTAssertFalse(value.isNaN)
  }

  func testRenderFormulaFromASTArithmetic() {
    var left = TSCE_ASTNodeArrayArchive.Node()
    left.nodeType = .number
    left.numberValue = 2

    var right = TSCE_ASTNodeArrayArchive.Node()
    right.nodeType = .number
    right.numberValue = 3

    var add = TSCE_ASTNodeArrayArchive.Node()
    add.nodeType = .add

    var ast = TSCE_ASTNodeArrayArchive()
    ast.nodes = [left, right, add]

    var archive = TSCE_FormulaArchive()
    archive.astNodeArray = ast

    XCTAssertEqual(
      IWARealDocumentReader.renderFormula(
        archive: archive,
        hostRow: 0,
        hostColumn: 0
      ),
      "=2+3"
    )
  }

  func testRenderFormulaFromASTRangeReference() {
    var startRow = TSCE_ASTNodeArrayArchive.Coordinate()
    startRow.value = 0
    startRow.absolute = true
    var startColumn = TSCE_ASTNodeArrayArchive.Coordinate()
    startColumn.value = 0
    startColumn.absolute = true

    var startRef = TSCE_ASTNodeArrayArchive.Node()
    startRef.nodeType = .cellRef
    startRef.row = startRow
    startRef.column = startColumn

    var endRow = TSCE_ASTNodeArrayArchive.Coordinate()
    endRow.value = 1
    endRow.absolute = true
    var endColumn = TSCE_ASTNodeArrayArchive.Coordinate()
    endColumn.value = 1
    endColumn.absolute = true

    var endRef = TSCE_ASTNodeArrayArchive.Node()
    endRef.nodeType = .cellRef
    endRef.row = endRow
    endRef.column = endColumn

    var range = TSCE_ASTNodeArrayArchive.Node()
    range.nodeType = .range

    var ast = TSCE_ASTNodeArrayArchive()
    ast.nodes = [startRef, endRef, range]

    var archive = TSCE_FormulaArchive()
    archive.astNodeArray = ast

    XCTAssertEqual(
      IWARealDocumentReader.renderFormula(
        archive: archive,
        hostRow: 10,
        hostColumn: 10
      ),
      "=$A$1:$B$2"
    )
  }

  func testRenderFormulaFromASTFunctionCall() {
    var first = TSCE_ASTNodeArrayArchive.Node()
    first.nodeType = .number
    first.numberValue = 1

    var second = TSCE_ASTNodeArrayArchive.Node()
    second.nodeType = .number
    second.numberValue = 2

    var function = TSCE_ASTNodeArrayArchive.Node()
    function.nodeType = .function
    function.functionIndex = 168
    function.functionNumArgs = 2

    var ast = TSCE_ASTNodeArrayArchive()
    ast.nodes = [first, second, function]

    var archive = TSCE_FormulaArchive()
    archive.astNodeArray = ast

    XCTAssertEqual(
      IWARealDocumentReader.renderFormula(
        archive: archive,
        hostRow: 0,
        hostColumn: 0
      ),
      "=SUM(1,2)"
    )
  }

  func testRenderFormulaUsesUnknownFunctionNameFallback() {
    var arg = TSCE_ASTNodeArrayArchive.Node()
    arg.nodeType = .number
    arg.numberValue = 2

    var function = TSCE_ASTNodeArrayArchive.Node()
    function.nodeType = .function
    function.functionIndex = 999
    function.functionNumArgs = 1
    function.unknownFunctionName = "CUSTOMFUNC"

    var ast = TSCE_ASTNodeArrayArchive()
    ast.nodes = [arg, function]

    var archive = TSCE_FormulaArchive()
    archive.astNodeArray = ast

    XCTAssertEqual(
      IWARealDocumentReader.renderFormula(
        archive: archive,
        hostRow: 0,
        hostColumn: 0
      ),
      "=CUSTOMFUNC(2)"
    )
  }

  func testRenderFormulaUsesUnknownFunctionNumArgsForFunctionFallback() {
    var firstArg = TSCE_ASTNodeArrayArchive.Node()
    firstArg.nodeType = .number
    firstArg.numberValue = 2

    var secondArg = TSCE_ASTNodeArrayArchive.Node()
    secondArg.nodeType = .number
    secondArg.numberValue = 5

    var function = TSCE_ASTNodeArrayArchive.Node()
    function.nodeType = .function
    function.functionIndex = 999
    function.functionNumArgs = 0
    function.unknownFunctionName = "CUSTOMFUNC"
    function.unknownFunctionNumArgs = 2

    var ast = TSCE_ASTNodeArrayArchive()
    ast.nodes = [firstArg, secondArg, function]

    var archive = TSCE_FormulaArchive()
    archive.astNodeArray = ast

    XCTAssertEqual(
      IWARealDocumentReader.renderFormula(
        archive: archive,
        hostRow: 0,
        hostColumn: 0
      ),
      "=CUSTOMFUNC(2,5)"
    )
  }

  func testRenderFormulaFallsBackForUnsupportedLetNode() {
    var number = TSCE_ASTNodeArrayArchive.Node()
    number.nodeType = .number
    number.numberValue = 1

    var letBind = TSCE_ASTNodeArrayArchive.Node()
    letBind.nodeType = .letBind

    var ast = TSCE_ASTNodeArrayArchive()
    ast.nodes = [number, letBind]

    var archive = TSCE_FormulaArchive()
    archive.astNodeArray = ast

    XCTAssertEqual(
      IWARealDocumentReader.renderFormula(
        archive: archive,
        hostRow: 0,
        hostColumn: 0
      ),
      "=UNSUPPORTED_AST(LET_BIND)"
    )
  }

  func testRenderFormulaIgnoresThunkBoundaryMarkersInFallbackSummary() {
    var number = TSCE_ASTNodeArrayArchive.Node()
    number.nodeType = .number
    number.numberValue = 1

    var beginThunk = TSCE_ASTNodeArrayArchive.Node()
    beginThunk.nodeType = .beginThunk

    var letBind = TSCE_ASTNodeArrayArchive.Node()
    letBind.nodeType = .letBind

    var endThunk = TSCE_ASTNodeArrayArchive.Node()
    endThunk.nodeType = .endThunk

    var ast = TSCE_ASTNodeArrayArchive()
    ast.nodes = [number, beginThunk, letBind, endThunk]

    var archive = TSCE_FormulaArchive()
    archive.astNodeArray = ast

    XCTAssertEqual(
      IWARealDocumentReader.renderFormula(
        archive: archive,
        hostRow: 0,
        hostColumn: 0
      ),
      "=UNSUPPORTED_AST(LET_BIND)"
    )
  }

  func testRenderFormulaFallbackSummaryIsSortedAndDeterministic() {
    var number = TSCE_ASTNodeArrayArchive.Node()
    number.nodeType = .number
    number.numberValue = 1

    var lambda = TSCE_ASTNodeArrayArchive.Node()
    lambda.nodeType = .lambda

    var letBind = TSCE_ASTNodeArrayArchive.Node()
    letBind.nodeType = .letBind

    var ast = TSCE_ASTNodeArrayArchive()
    ast.nodes = [number, lambda, letBind]

    var archive = TSCE_FormulaArchive()
    archive.astNodeArray = ast

    XCTAssertEqual(
      IWARealDocumentReader.renderFormula(
        archive: archive,
        hostRow: 0,
        hostColumn: 0
      ),
      "=UNSUPPORTED_AST(LAMBDA,LET_BIND)"
    )
  }

  func testResolverExtractsTablePresentationMetadataWhenCaptionStorageExists() throws {
    var document = TN_DocumentArchive()
    document.sheets = [reference(200)]

    var sheet = TN_SheetArchive()
    sheet.name = "Main"
    sheet.drawableInfos = [reference(500)]

    var tableInfo = TST_TableInfoArchive()
    var drawable = TSD_DrawableArchive()
    drawable.parent = reference(200)
    drawable.caption = reference(800)
    drawable.captionHidden = true
    tableInfo.super = drawable
    tableInfo.tableModel = reference(400)

    var tableModel = TST_TableModelArchive()
    tableModel.tableID = "table-400"
    tableModel.tableName = "Metrics"
    tableModel.tableNameEnabled = false
    tableModel.numberOfRows = 0
    tableModel.numberOfColumns = 0

    var captionInfo = TSWP_CaptionInfoArchiveProxy()
    var captionShape = TSWP_ShapeInfoArchive()
    captionShape.ownedStorage = reference(900)
    captionInfo.super = captionShape

    var captionStorage = TSWP_StorageArchive()
    captionStorage.text = ["Quarterly KPI summary"]

    let documentPayload = try document.serializedData()
    let sheetPayload = try sheet.serializedData()
    let tableInfoPayload = try tableInfo.serializedData()
    let tableModelPayload = try tableModel.serializedData()
    let captionInfoPayload = try captionInfo.serializedData()
    let captionStoragePayload = try captionStorage.serializedData()

    let records = [
      IWAObjectRecord(
        objectID: 100,
        typeID: 1,
        payloadSize: documentPayload.count,
        payloadData: documentPayload,
        sourceBlobPath: "Doc.iwa",
        objectReferences: [200]
      ),
      IWAObjectRecord(
        objectID: 200,
        typeID: 2,
        payloadSize: sheetPayload.count,
        payloadData: sheetPayload,
        sourceBlobPath: "Sheet.iwa",
        objectReferences: [500]
      ),
      IWAObjectRecord(
        objectID: 500,
        typeID: 6000,
        payloadSize: tableInfoPayload.count,
        payloadData: tableInfoPayload,
        sourceBlobPath: "TableInfo.iwa",
        objectReferences: [200, 400, 800]
      ),
      IWAObjectRecord(
        objectID: 400,
        typeID: 6001,
        payloadSize: tableModelPayload.count,
        payloadData: tableModelPayload,
        sourceBlobPath: "TableModel.iwa"
      ),
      IWAObjectRecord(
        objectID: 800,
        typeID: 633,
        payloadSize: captionInfoPayload.count,
        payloadData: captionInfoPayload,
        sourceBlobPath: "CaptionInfo.iwa",
        objectReferences: [900]
      ),
      IWAObjectRecord(
        objectID: 900,
        typeID: 2001,
        payloadSize: captionStoragePayload.count,
        payloadData: captionStoragePayload,
        sourceBlobPath: "CaptionStorage.iwa"
      ),
    ]

    let inventory = IWAInventory(records: records, unparsedBlobPaths: [])
    let result = IWARealDocumentReader.read(from: inventory, documentVersion: nil)

    let resolvedTable = try XCTUnwrap(result.sheets.first?.tables.first)
    XCTAssertEqual(resolvedTable.tableNameVisible, false)
    XCTAssertEqual(resolvedTable.captionVisible, false)
    XCTAssertEqual(resolvedTable.captionTextSupported, true)
    XCTAssertEqual(resolvedTable.captionText, "Quarterly KPI summary")
  }

  private func makeCellBuffer(
    type: UInt8,
    flags: Int32,
    payloadBuilder: (inout Data) -> Void
  ) -> Data {
    var data = Data(repeating: 0, count: 12)
    data[0] = 5
    data[1] = type

    var flagsLE = flags.littleEndian
    withUnsafeBytes(of: &flagsLE) { bytes in
      data.replaceSubrange(8..<12, with: bytes)
    }
    payloadBuilder(&data)

    return data
  }

  private func appendInt32(_ value: Int32, to data: inout Data) {
    var little = value.littleEndian
    data.append(Data(bytes: &little, count: MemoryLayout<Int32>.size))
  }

  private func appendDouble(_ value: Double, to data: inout Data) {
    var bits = value.bitPattern.littleEndian
    data.append(Data(bytes: &bits, count: MemoryLayout<UInt64>.size))
  }

  private func reference(_ objectID: UInt64) -> TSP_Reference {
    var reference = TSP_Reference()
    reference.identifier = objectID
    return reference
  }
}
