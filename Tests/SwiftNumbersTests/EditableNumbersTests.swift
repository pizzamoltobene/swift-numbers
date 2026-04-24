import Foundation
import XCTest

@testable import SwiftNumbersContainer
@testable import SwiftNumbersCore
@testable import SwiftNumbersIWA
@testable import SwiftNumbersProto

final class CellReferenceTests: XCTestCase {
  func testParsesA1Reference() throws {
    let ref = try CellReference("C4")
    XCTAssertEqual(ref.address.row, 3)
    XCTAssertEqual(ref.address.column, 2)
    XCTAssertEqual(ref.a1, "C4")
  }

  func testFormatsFromAddress() {
    let ref = CellReference(address: CellAddress(row: 0, column: 27))
    XCTAssertEqual(ref.a1, "AB1")
  }

  func testRejectsInvalidReferences() {
    XCTAssertThrowsError(try CellReference("1A"))
    XCTAssertThrowsError(try CellReference("A0"))
    XCTAssertThrowsError(try CellReference(""))
    XCTAssertThrowsError(try CellReference(String(repeating: "A", count: 64) + "1"))
  }
}

final class EditableNumbersDocumentTests: XCTestCase {
  private func temporaryOutputURL(_ name: String) -> URL {
    URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent("swiftnumbers-tests-\(UUID().uuidString)", isDirectory: true)
      .appendingPathComponent(name, isDirectory: true)
  }

  private func temporaryArchiveOutputURL(_ name: String) -> URL {
    URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent("swiftnumbers-tests-\(UUID().uuidString)", isDirectory: true)
      .appendingPathComponent(name, isDirectory: false)
  }

  private func temporaryWorkingCopyURL(_ name: String, isDirectory: Bool) -> URL {
    URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent("swiftnumbers-tests-\(UUID().uuidString)", isDirectory: true)
      .appendingPathComponent(name, isDirectory: isDirectory)
  }

  private func makeWorkingCopy(from source: URL, name: String, isDirectory: Bool) throws -> URL {
    let destination = temporaryWorkingCopyURL(name, isDirectory: isDirectory)
    try FileManager.default.createDirectory(
      at: destination.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try FileManager.default.copyItem(at: source, to: destination)
    return destination
  }

  func testSetCellValuesAndSaveRoundTrip() throws {
    XCTAssertTrue(EditableNumbersDocument.canSaveEditableDocuments())
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)

    let sheet = try XCTUnwrap(editable.firstSheet)
    let table = try XCTUnwrap(sheet.firstTable)
    XCTAssertEqual(editable.dirtyState, .clean)

    table.setValue(.string("Done"), at: CellAddress(row: 0, column: 0))
    try table.setValue(.number(1499.99), at: "B2")
    table.setValue(.bool(false), at: CellAddress(row: 2, column: 1))

    let dateCell = try table.cell("C4")
    dateCell.value = .date(Date(timeIntervalSince1970: 1_714_764_800))

    XCTAssertTrue(editable.hasChanges)
    XCTAssertEqual(editable.dirtyState, .dataDirty)

    let output = temporaryOutputURL("editable-set-roundtrip.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.cell(at: CellAddress(row: 0, column: 0)), .string("Done"))
    XCTAssertEqual(reopenedTable.cell(at: CellAddress(row: 1, column: 1)), .number(1499.99))
    XCTAssertEqual(reopenedTable.cell(at: CellAddress(row: 2, column: 1)), .bool(false))

    let writtenDate = reopenedTable.cell(at: CellAddress(row: 3, column: 2))
    switch writtenDate {
    case .date(let date):
      XCTAssertEqual(date.timeIntervalSince1970, 1_714_764_800, accuracy: 0.001)
    default:
      XCTFail("Expected date at C4 after round-trip")
    }
  }

  func testAppendInsertAndCreateSheetTableRoundTrip() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)

    let sheet = try XCTUnwrap(editable.firstSheet)
    let table = try XCTUnwrap(sheet.firstTable)

    table.appendRow([.string("Alice"), .number(42), .bool(true)])
    try table.insertRow([.string("Header"), .number(1)], at: 0)
    table.appendColumn([.string("Col"), .string("X"), .string("Y")])

    _ = editable.addSheet(named: "SwiftNumbers Added")
    let created = try editable.addTable(
      named: "Imported Data",
      rows: 2,
      columns: 2,
      onSheetNamed: "SwiftNumbers Added"
    )
    created.setValue(.string("Ready"), at: CellAddress(row: 0, column: 0))

    let output = temporaryOutputURL("editable-structure-roundtrip.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let addedSheet = try reopened.sheet(named: "SwiftNumbers Added")
    let addedTable = try addedSheet.table(named: "Imported Data")
    XCTAssertEqual(addedTable.cell(at: CellAddress(row: 0, column: 0)), .string("Ready"))

    let reopenedPrimary = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertGreaterThanOrEqual(reopenedPrimary.metadata.rowCount, 6)
    XCTAssertGreaterThanOrEqual(reopenedPrimary.metadata.columnCount, 4)
  }

  func testAddTableRejectsDuplicateTableNameInSheet() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let sheet = try XCTUnwrap(editable.firstSheet)
    let existing = try XCTUnwrap(sheet.firstTable)

    XCTAssertThrowsError(
      try sheet.addTable(
        named: existing.name,
        rows: 1,
        columns: 1
      )
    )
  }

  func testAddSheetAutoSuffixesDuplicateSheetName() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let originalName = try XCTUnwrap(editable.firstSheet?.name)

    let added = editable.addSheet(named: originalName)
    XCTAssertNotEqual(added.name, originalName)
    XCTAssertTrue(added.name.hasPrefix(originalName + " ("))

    let output = temporaryArchiveOutputURL("editable-duplicate-sheet-name.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    _ = try reopened.sheet(named: originalName)
    _ = try reopened.sheet(named: added.name)
  }

  func testNoOpSaveCopiesSourceContainer() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    XCTAssertEqual(editable.dirtyState, .clean)
    XCTAssertFalse(editable.hasChanges)

    let output = temporaryOutputURL("editable-noop-copy.numbers")
    try editable.save(to: output)

    let sourceIndex = fixture.appendingPathComponent("Index.zip", isDirectory: false)
    let outputIndex = output.appendingPathComponent("Index.zip", isDirectory: false)
    XCTAssertEqual(try Data(contentsOf: sourceIndex), try Data(contentsOf: outputIndex))

    let reopened = try NumbersDocument.open(at: output)
    XCTAssertGreaterThan(reopened.sheets.count, 0)
  }

  func testSaveOnSingleFileArchiveUsesLowLevelIWAWriterForSetCell() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)
    table.setValue(.string("Low Level Value"), at: CellAddress(row: 0, column: 0))

    let output = temporaryArchiveOutputURL("editable-overlay-output.numbers")
    try editable.save(to: output)

    XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
    var isDirectory: ObjCBool = false
    FileManager.default.fileExists(atPath: output.path, isDirectory: &isDirectory)
    XCTAssertFalse(isDirectory.boolValue)

    let reopened = try EditableNumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(
      reopenedTable.cell(at: CellAddress(row: 0, column: 0)), .string("Low Level Value"))

    let container = try NumbersContainer.open(at: output)
    let metadataOverlay = try container.readMetadataFile(named: "DocumentMetadata.json")
    XCTAssertNil(metadataOverlay, "Low-level write path should not inject metadata overlay JSON.")
  }

  func testSaveOnSingleFileArchiveUsesLowLevelIWAWriterForDateCell() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)
    let targetDate = Date(timeIntervalSince1970: 1_714_764_800)
    table.setValue(.date(targetDate), at: CellAddress(row: 0, column: 0))

    let output = temporaryArchiveOutputURL("editable-date-low-level-output.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.cell(at: CellAddress(row: 0, column: 0)), .date(targetDate))

    let container = try NumbersContainer.open(at: output)
    let metadataOverlay = try container.readMetadataFile(named: "DocumentMetadata.json")
    XCTAssertNil(metadataOverlay, "Date setValue should persist via low-level IWA writer.")
  }

  func testSaveOnSingleFileArchiveUsesLowLevelIWAWriterForStructuralMutations() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let baseline = try EditableNumbersDocument.open(at: fixture)
    let baselineTable = try XCTUnwrap(baseline.firstSheet?.firstTable)
    let baselineRows = baselineTable.metadata.rowCount
    let baselineColumns = baselineTable.metadata.columnCount

    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    table.appendRow([.string("Tail")])
    try table.insertRow([.string("Inserted")], at: 0)
    table.appendColumn([.string("C"), .string("1"), .string("2")])

    let output = temporaryArchiveOutputURL("editable-structural-low-level-output.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertGreaterThanOrEqual(reopenedTable.metadata.rowCount, baselineRows + 2)
    XCTAssertGreaterThanOrEqual(reopenedTable.metadata.columnCount, baselineColumns + 1)
    XCTAssertEqual(reopenedTable.cell(at: CellAddress(row: 0, column: 0)), .string("Inserted"))
    XCTAssertEqual(
      reopenedTable.cell(at: CellAddress(row: reopenedTable.metadata.rowCount - 1, column: 0)),
      .string("Tail")
    )
    XCTAssertEqual(
      reopenedTable.cell(at: CellAddress(row: 0, column: baselineColumns)), .string("C"))

    let container = try NumbersContainer.open(at: output)
    let metadataOverlay = try container.readMetadataFile(named: "DocumentMetadata.json")
    XCTAssertNil(
      metadataOverlay,
      "Structural mutations (append/insert/appendColumn) should persist via low-level IWA writer."
    )
  }

  func testSaveOnSingleFileArchiveUsesLowLevelIWAWriterForAddSheetAndAddTable() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)

    let originalSheet = try XCTUnwrap(editable.firstSheet)
    let appendedTable = try editable.addTable(
      named: "Appended Table",
      rows: 2,
      columns: 2,
      onSheetNamed: originalSheet.name
    )
    appendedTable.setValue(.string("Existing Sheet"), at: CellAddress(row: 0, column: 0))

    let newSheet = editable.addSheet(named: "Inserted Sheet")
    let defaultTable = try XCTUnwrap(newSheet.firstTable)
    defaultTable.setValue(.string("Default Table"), at: CellAddress(row: 0, column: 0))
    let extraTable = try editable.addTable(
      named: "Extra Data",
      rows: 1,
      columns: 1,
      onSheetNamed: "Inserted Sheet"
    )
    extraTable.setValue(.number(42), at: CellAddress(row: 0, column: 0))

    let output = temporaryArchiveOutputURL("editable-add-sheet-table-low-level-output.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let reopenedOriginalSheet = try reopened.sheet(named: originalSheet.name)
    let reopenedAppendedTable = try reopenedOriginalSheet.table(named: "Appended Table")
    XCTAssertEqual(
      reopenedAppendedTable.cell(at: CellAddress(row: 0, column: 0)),
      .string("Existing Sheet")
    )

    let reopenedInsertedSheet = try reopened.sheet(named: "Inserted Sheet")
    let reopenedDefaultTable = try reopenedInsertedSheet.table(named: "Table 1")
    XCTAssertEqual(
      reopenedDefaultTable.cell(at: CellAddress(row: 0, column: 0)),
      .string("Default Table")
    )
    let reopenedExtraTable = try reopenedInsertedSheet.table(named: "Extra Data")
    XCTAssertEqual(reopenedExtraTable.cell(at: CellAddress(row: 0, column: 0)), .number(42))

    let container = try NumbersContainer.open(at: output)
    let metadataOverlay = try container.readMetadataFile(named: "DocumentMetadata.json")
    XCTAssertNil(
      metadataOverlay,
      "addSheet/addTable should persist via low-level IWA writer without metadata overlay."
    )
  }

  func testSaveInPlaceMutatesExistingPackageDocument() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let workingCopy = try makeWorkingCopy(
      from: fixture,
      name: "editable-in-place-package.numbers",
      isDirectory: true
    )

    let editable = try EditableNumbersDocument.open(at: workingCopy)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)
    table.setValue(.string("In Place"), at: CellAddress(row: 0, column: 0))
    try editable.saveInPlace()

    let reopened = try EditableNumbersDocument.open(at: workingCopy)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.cell(at: CellAddress(row: 0, column: 0)), .string("In Place"))
  }

  func testSaveInPlaceMutatesExistingArchiveDocument() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let workingCopy = try makeWorkingCopy(
      from: fixture,
      name: "editable-in-place-archive.numbers",
      isDirectory: false
    )

    let editable = try EditableNumbersDocument.open(at: workingCopy)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)
    table.setValue(.string("In Place Archive"), at: CellAddress(row: 0, column: 0))
    try editable.saveInPlace()

    let reopened = try EditableNumbersDocument.open(at: workingCopy)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(
      reopenedTable.cell(at: CellAddress(row: 0, column: 0)),
      .string("In Place Archive")
    )
  }

  func testSaveToSamePathPerformsInPlaceReplace() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let workingCopy = try makeWorkingCopy(
      from: fixture,
      name: "editable-save-to-source-archive.numbers",
      isDirectory: false
    )

    let editable = try EditableNumbersDocument.open(at: workingCopy)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)
    table.setValue(.string("Same Path"), at: CellAddress(row: 0, column: 0))
    try editable.save(to: workingCopy)

    let reopened = try EditableNumbersDocument.open(at: workingCopy)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.cell(at: CellAddress(row: 0, column: 0)), .string("Same Path"))
  }

  func testSaveInPlaceAfterSaveToNewPathTargetsLatestWorkingDocument() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let sourceCopy = try makeWorkingCopy(
      from: fixture,
      name: "editable-saveinplace-source.numbers",
      isDirectory: false
    )
    let outputCopy = temporaryArchiveOutputURL("editable-saveinplace-output.numbers")

    let editable = try EditableNumbersDocument.open(at: sourceCopy)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    table.setValue(.string("V1"), at: CellAddress(row: 0, column: 0))
    try editable.save(to: outputCopy)

    table.setValue(.string("V2"), at: CellAddress(row: 0, column: 0))
    try editable.saveInPlace()

    let reopenedOutput = try EditableNumbersDocument.open(at: outputCopy)
    let reopenedOutputTable = try XCTUnwrap(reopenedOutput.firstSheet?.firstTable)
    XCTAssertEqual(reopenedOutputTable.cell(at: CellAddress(row: 0, column: 0)), .string("V2"))

    let reopenedSource = try EditableNumbersDocument.open(at: sourceCopy)
    let reopenedSourceTable = try XCTUnwrap(reopenedSource.firstSheet?.firstTable)
    XCTAssertNil(reopenedSourceTable.cell(at: CellAddress(row: 0, column: 0)))
  }

  func testSetValueIgnoresNegativeCellAddress() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    table.setValue(.string("NEG"), at: CellAddress(row: -1, column: 0))
    table.setValue(.string("NEG"), at: CellAddress(row: 0, column: -1))

    XCTAssertFalse(editable.hasChanges)
    XCTAssertEqual(editable.dirtyState, .clean)
    XCTAssertEqual(table.cell(at: CellAddress(row: 0, column: 0)), .string("Name"))
  }

  func testSaveInPlaceDoesNotReplayOperations() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let workingCopy = try makeWorkingCopy(
      from: fixture,
      name: "editable-in-place-replay-guard.numbers",
      isDirectory: false
    )

    let editable = try EditableNumbersDocument.open(at: workingCopy)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)
    let baselineRows = table.metadata.rowCount

    table.appendRow([.string("Only Once")])
    try editable.saveInPlace()
    try editable.saveInPlace()

    let reopened = try EditableNumbersDocument.open(at: workingCopy)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.metadata.rowCount, baselineRows + 1)
  }

  func testDateMarkerLookingStringRoundTripsAsString() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)
    let markerLookingString = "__SWIFTNUMBERS_DATE__:2024-05-16T00:00:00Z"

    table.setValue(.string(markerLookingString), at: CellAddress(row: 0, column: 0))

    let output = temporaryArchiveOutputURL("editable-date-marker-string-roundtrip.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(
      reopenedTable.cell(at: CellAddress(row: 0, column: 0)),
      .string(markerLookingString)
    )
  }

  func testLowLevelSaveRefreshesEditableOverlayWhenSourceHasOverlayMetadata() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let sourceWithOverlay = temporaryArchiveOutputURL("editable-overlay-source.numbers")

    var metadata = Swiftnumbers_DocumentMetadata()
    metadata.documentID = "swiftnumbers-editable-v1:test"

    var sheet = Swiftnumbers_SheetMetadata()
    sheet.sheetID = "sheet-1"
    sheet.name = "Sheet 1"

    var table = Swiftnumbers_TableMetadata()
    table.tableID = "table-1"
    table.name = "Table 1"
    table.rowCount = 1
    table.columnCount = 1

    var cell = Swiftnumbers_Cell()
    cell.row = 0
    cell.column = 0
    cell.value = .stringValue("OLD")
    table.cells = [cell]
    sheet.tables = [table]
    metadata.sheets = [sheet]

    try NumbersContainer.copyContainer(
      from: fixture,
      to: sourceWithOverlay,
      replacingMetadataFiles: ["DocumentMetadata.json": try metadata.jsonUTF8Data()]
    )

    let editable = try EditableNumbersDocument.open(at: sourceWithOverlay)
    let editableTable = try XCTUnwrap(editable.firstSheet?.firstTable)
    XCTAssertEqual(editableTable.cell(at: CellAddress(row: 0, column: 0)), .string("OLD"))

    editableTable.setValue(.string("NEW"), at: CellAddress(row: 0, column: 0))

    let output = temporaryArchiveOutputURL("editable-overlay-refreshed-output.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.cell(at: CellAddress(row: 0, column: 0)), .string("NEW"))
  }

  func testSaveFailsFastForAmbiguousAddTableOnDuplicateSheetNames() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let sourceWithOverlay = temporaryArchiveOutputURL(
      "editable-ambiguous-sheet-overlay-source.numbers"
    )

    var metadata = Swiftnumbers_DocumentMetadata()
    metadata.documentID = "swiftnumbers-editable-v1:ambiguous"

    func makeTable(id: String, name: String) -> Swiftnumbers_TableMetadata {
      var table = Swiftnumbers_TableMetadata()
      table.tableID = id
      table.name = name
      table.rowCount = 1
      table.columnCount = 1
      return table
    }

    var firstSheet = Swiftnumbers_SheetMetadata()
    firstSheet.sheetID = "sheet-1"
    firstSheet.name = "Dup"
    firstSheet.tables = [makeTable(id: "table-1", name: "T1")]

    var secondSheet = Swiftnumbers_SheetMetadata()
    secondSheet.sheetID = "sheet-2"
    secondSheet.name = "Dup"
    secondSheet.tables = [makeTable(id: "table-2", name: "T2")]

    metadata.sheets = [firstSheet, secondSheet]

    try NumbersContainer.copyContainer(
      from: fixture,
      to: sourceWithOverlay,
      replacingMetadataFiles: ["DocumentMetadata.json": try metadata.jsonUTF8Data()]
    )

    let editable = try EditableNumbersDocument.open(at: sourceWithOverlay)
    _ = try editable.addTable(named: "New Table", rows: 1, columns: 1, onSheetNamed: "Dup")

    let output = temporaryArchiveOutputURL("editable-ambiguous-sheet-overlay-output.numbers")
    XCTAssertThrowsError(try editable.save(to: output))
  }

  func testSecondSaveWithoutNewMutationsUsesLastSavedState() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    table.setValue(.string("Persisted"), at: CellAddress(row: 0, column: 0))
    let firstOutput = temporaryArchiveOutputURL("editable-first-save.numbers")
    try editable.save(to: firstOutput)

    XCTAssertFalse(editable.hasChanges)
    XCTAssertEqual(editable.dirtyState, .clean)

    let secondOutput = temporaryArchiveOutputURL("editable-second-save.numbers")
    try editable.save(to: secondOutput)

    let reopened = try EditableNumbersDocument.open(at: secondOutput)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.cell(at: CellAddress(row: 0, column: 0)), .string("Persisted"))
  }

  func testFallbackMetadataUsesEditableDocumentIDPrefix() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)
    table.setValue(.string("Fallback Overlay"), at: CellAddress(row: 0, column: 0))

    let output = temporaryOutputURL("editable-fallback-prefix.numbers")
    try editable.save(to: output)

    let container = try NumbersContainer.open(at: output)
    let metadataData = try XCTUnwrap(container.readMetadataFile(named: "DocumentMetadata.json"))
    let metadata = try Swiftnumbers_DocumentMetadata(jsonUTF8Data: metadataData)
    XCTAssertTrue(metadata.documentID.hasPrefix("swiftnumbers-editable-v1:"))
  }

  func testSaveToLatestOutputPathPerformsInPlaceUpdate() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    table.setValue(.string("V1"), at: CellAddress(row: 0, column: 0))
    let output = temporaryArchiveOutputURL("editable-latest-output-in-place.numbers")
    try editable.save(to: output)

    table.setValue(.string("V2"), at: CellAddress(row: 0, column: 0))
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.cell(at: CellAddress(row: 0, column: 0)), .string("V2"))
  }
}

final class IWASetCellWriterTests: XCTestCase {
  func testCandidateTableInfoObjectIDsIncludesParentOnlyTables() throws {
    var tableInfoA = TST_TableInfoArchive()
    var drawableA = TSD_DrawableArchive()
    drawableA.parent = reference(200)
    tableInfoA.super = drawableA

    var tableInfoB = TST_TableInfoArchive()
    var drawableB = TSD_DrawableArchive()
    drawableB.parent = reference(200)
    tableInfoB.super = drawableB

    var tableInfoOtherSheet = TST_TableInfoArchive()
    var drawableOther = TSD_DrawableArchive()
    drawableOther.parent = reference(201)
    tableInfoOtherSheet.super = drawableOther

    let payloadA = try tableInfoA.serializedData()
    let payloadB = try tableInfoB.serializedData()
    let payloadOther = try tableInfoOtherSheet.serializedData()

    let recordsByObjectID: [UInt64: [IWAObjectRecord]] = [
      300: [
        IWAObjectRecord(
          objectID: 300,
          typeID: 6000,
          payloadSize: payloadA.count,
          payloadData: payloadA,
          sourceBlobPath: "A.iwa"
        )
      ],
      301: [
        IWAObjectRecord(
          objectID: 301,
          typeID: 6000,
          payloadSize: payloadB.count,
          payloadData: payloadB,
          sourceBlobPath: "B.iwa"
        )
      ],
      302: [
        IWAObjectRecord(
          objectID: 302,
          typeID: 6000,
          payloadSize: payloadOther.count,
          payloadData: payloadOther,
          sourceBlobPath: "Other.iwa"
        )
      ],
    ]

    let ids = IWASetCellWriter.candidateTableInfoObjectIDs(
      forSheetObjectID: 200,
      drawableRefs: [reference(300)],
      recordsByObjectID: recordsByObjectID
    )

    XCTAssertEqual(ids, [300, 301])
  }

  func testCandidateTableInfoObjectIDsDeduplicatesDrawableAndParentMatches() throws {
    var tableInfo = TST_TableInfoArchive()
    var drawable = TSD_DrawableArchive()
    drawable.parent = reference(500)
    tableInfo.super = drawable
    let payload = try tableInfo.serializedData()

    let recordsByObjectID: [UInt64: [IWAObjectRecord]] = [
      700: [
        IWAObjectRecord(
          objectID: 700,
          typeID: 6000,
          payloadSize: payload.count,
          payloadData: payload,
          sourceBlobPath: "Table.iwa"
        )
      ]
    ]

    let ids = IWASetCellWriter.candidateTableInfoObjectIDs(
      forSheetObjectID: 500,
      drawableRefs: [reference(700), reference(700)],
      recordsByObjectID: recordsByObjectID
    )

    XCTAssertEqual(ids, [700])
  }

  private func reference(_ objectID: UInt64) -> TSP_Reference {
    var reference = TSP_Reference()
    reference.identifier = objectID
    return reference
  }
}
