import Foundation
import XCTest

@testable import SwiftNumbersContainer
@testable import SwiftNumbersCore

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
}
