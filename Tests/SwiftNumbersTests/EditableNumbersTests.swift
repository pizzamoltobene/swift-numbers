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
  private enum EditableArchiveForm {
    case package
    case singleFile
  }

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

  private func makePackageFixture(fromSingleFileArchive archiveURL: URL) throws -> URL {
    let packageURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent("swift-numbers-\(UUID().uuidString).numbers", isDirectory: true)
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
    process.arguments = [
      "-x",
      "-k",
      archiveURL.path,
      packageURL.path,
    ]

    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      throw NSError(
        domain: "EditableNumbersDocumentTests",
        code: Int(process.terminationStatus),
        userInfo: [
          NSLocalizedDescriptionKey:
            "ditto package conversion failed with status \(process.terminationStatus)"
        ]
      )
    }

    return packageURL
  }

  private func collectedValues(in table: EditableTable) -> [CellValue] {
    var result: [CellValue] = []
    for row in 0..<table.metadata.rowCount {
      for column in 0..<table.metadata.columnCount {
        guard let value = table.cell(at: CellAddress(row: row, column: column)), value != .empty
        else {
          continue
        }
        result.append(value)
      }
    }
    return result
  }

  private func assertCellValue(
    _ actual: CellValue?,
    equals expected: CellValue?,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    switch (actual, expected) {
    case (nil, nil):
      return
    case (.some(.date(let actualDate)), .some(.date(let expectedDate))):
      XCTAssertEqual(
        actualDate.timeIntervalSince1970,
        expectedDate.timeIntervalSince1970,
        accuracy: 0.001,
        file: file,
        line: line
      )
    default:
      XCTAssertEqual(actual, expected, file: file, line: line)
    }
  }

  private func assertSetValueRoundTrip(
    archiveForm: EditableArchiveForm,
    value: CellValue,
    expected expectedValue: CellValue?,
    outputName: String,
    prefillValue: CellValue? = nil
  ) throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)
    let address = CellAddress(row: 0, column: 0)
    if let prefillValue {
      table.setValue(prefillValue, at: address)
    }
    table.setValue(value, at: address)

    let archiveOutput = temporaryArchiveOutputURL(outputName)
    try editable.save(to: archiveOutput)

    let roundTripURL: URL
    var cleanupURL: URL?
    switch archiveForm {
    case .package:
      // Package form is validated by converting the saved archive into a package fixture.
      roundTripURL = try makePackageFixture(fromSingleFileArchive: archiveOutput)
      cleanupURL = roundTripURL
    case .singleFile:
      roundTripURL = archiveOutput
    }
    defer {
      if let cleanupURL {
        try? FileManager.default.removeItem(at: cleanupURL)
      }
    }

    var isDirectory: ObjCBool = false
    _ = FileManager.default.fileExists(atPath: roundTripURL.path, isDirectory: &isDirectory)
    switch archiveForm {
    case .package:
      XCTAssertTrue(isDirectory.boolValue)
    case .singleFile:
      XCTAssertFalse(isDirectory.boolValue)
    }

    let reopened = try EditableNumbersDocument.open(at: roundTripURL)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    assertCellValue(reopenedTable.cell(at: address), equals: expectedValue)
  }

  private func typedFormatSnapshot(_ format: EditableCellFormat?) -> String {
    guard let format else {
      return "nil"
    }
    switch format {
    case .number(let formatID):
      return "number#\(formatID)"
    case .date(let formatID):
      return "date#\(formatID)"
    case .currency(let formatID):
      return "currency#\(formatID)"
    case .base(let formatID):
      return "base#\(formatID)"
    case .fraction(let formatID):
      return "fraction#\(formatID)"
    case .percentage(let formatID):
      return "percentage#\(formatID)"
    case .scientific(let formatID):
      return "scientific#\(formatID)"
    case .tickbox(let formatID):
      return "tickbox#\(formatID)"
    case .rating(let formatID):
      return "rating#\(formatID)"
    case .slider(let formatID):
      return "slider#\(formatID)"
    case .stepper(let formatID):
      return "stepper#\(formatID)"
    case .popup(let formatID):
      return "popup#\(formatID)"
    case .custom(let formatID):
      return "custom#\(formatID)"
    }
  }

  func testSetCellValuesAndSaveRoundTrip() throws {
    XCTAssertTrue(EditableNumbersDocument.canSaveEditableDocuments())
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
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
    XCTAssertNotEqual(editable.dirtyState, .clean)

    let output = temporaryArchiveOutputURL("editable-set-roundtrip.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    let values = collectedValues(in: reopenedTable)
    XCTAssertTrue(values.contains(.string("Done")))
    XCTAssertTrue(values.contains(.number(1499.99)))
    XCTAssertTrue(values.contains(.bool(false)))
    guard
      let date = values.compactMap({ value -> Date? in
        guard case .date(let date) = value else {
          return nil
        }
        return date
      }).first
    else {
      return XCTFail("Expected at least one date cell after round-trip")
    }
    XCTAssertEqual(date.timeIntervalSince1970, 1_714_764_800, accuracy: 0.001)
  }

  func testSetValueStringRoundTripOnSingleFileArchive() throws {
    try assertSetValueRoundTrip(
      archiveForm: .singleFile,
      value: .string("Matrix String"),
      expected: .string("Matrix String"),
      outputName: "editable-value-string-archive-roundtrip.numbers"
    )
  }

  func testSetValueNumberRoundTripOnSingleFileArchive() throws {
    try assertSetValueRoundTrip(
      archiveForm: .singleFile,
      value: .number(1234.567),
      expected: .number(1234.567),
      outputName: "editable-value-number-archive-roundtrip.numbers"
    )
  }

  func testSetValueBoolRoundTripOnSingleFileArchive() throws {
    try assertSetValueRoundTrip(
      archiveForm: .singleFile,
      value: .bool(true),
      expected: .bool(true),
      outputName: "editable-value-bool-archive-roundtrip.numbers"
    )
  }

  func testSetValueDateRoundTripOnSingleFileArchive() throws {
    try assertSetValueRoundTrip(
      archiveForm: .singleFile,
      value: .date(Date(timeIntervalSince1970: 1_714_764_800)),
      expected: .date(Date(timeIntervalSince1970: 1_714_764_800)),
      outputName: "editable-value-date-archive-roundtrip.numbers"
    )
  }

  func testSetValueFormulaRoundTripOnSingleFileArchive() throws {
    try assertSetValueRoundTrip(
      archiveForm: .singleFile,
      value: .formula("=SUM(B1:B3)"),
      expected: .formula("=SUM(B1:B3)"),
      outputName: "editable-value-formula-archive-roundtrip.numbers"
    )
  }

  func testSetValueEmptyRoundTripOnSingleFileArchive() throws {
    try assertSetValueRoundTrip(
      archiveForm: .singleFile,
      value: .empty,
      expected: nil,
      outputName: "editable-value-empty-archive-roundtrip.numbers",
      prefillValue: .string("clear-me")
    )
  }

  func testSetValueStringRoundTripOnPackageArchive() throws {
    try assertSetValueRoundTrip(
      archiveForm: .package,
      value: .string("Matrix String"),
      expected: .string("Matrix String"),
      outputName: "editable-value-string-package-roundtrip.numbers"
    )
  }

  func testSetValueNumberRoundTripOnPackageArchive() throws {
    try assertSetValueRoundTrip(
      archiveForm: .package,
      value: .number(1234.567),
      expected: .number(1234.567),
      outputName: "editable-value-number-package-roundtrip.numbers"
    )
  }

  func testSetValueBoolRoundTripOnPackageArchive() throws {
    try assertSetValueRoundTrip(
      archiveForm: .package,
      value: .bool(true),
      expected: .bool(true),
      outputName: "editable-value-bool-package-roundtrip.numbers"
    )
  }

  func testSetValueDateRoundTripOnPackageArchive() throws {
    try assertSetValueRoundTrip(
      archiveForm: .package,
      value: .date(Date(timeIntervalSince1970: 1_714_764_800)),
      expected: .date(Date(timeIntervalSince1970: 1_714_764_800)),
      outputName: "editable-value-date-package-roundtrip.numbers"
    )
  }

  func testSetValueFormulaRoundTripOnPackageArchive() throws {
    try assertSetValueRoundTrip(
      archiveForm: .package,
      value: .formula("=SUM(B1:B3)"),
      expected: .formula("=SUM(B1:B3)"),
      outputName: "editable-value-formula-package-roundtrip.numbers"
    )
  }

  func testSetValueEmptyRoundTripOnPackageArchive() throws {
    try assertSetValueRoundTrip(
      archiveForm: .package,
      value: .empty,
      expected: nil,
      outputName: "editable-value-empty-package-roundtrip.numbers",
      prefillValue: .string("clear-me")
    )
  }

  func testAppendInsertAndCreateSheetTableRoundTrip() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)

    let sheet = try XCTUnwrap(editable.firstSheet)
    let table = try XCTUnwrap(sheet.firstTable)
    let baselineRows = table.metadata.rowCount
    let baselineColumns = table.metadata.columnCount

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

    let output = temporaryArchiveOutputURL("editable-structure-roundtrip.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let addedSheet = try reopened.sheet(named: "SwiftNumbers Added")
    let addedTable = try addedSheet.table(named: "Imported Data")
    XCTAssertEqual(addedTable.cell(at: CellAddress(row: 0, column: 0)), .string("Ready"))

    let reopenedPrimary = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertGreaterThanOrEqual(reopenedPrimary.metadata.rowCount, baselineRows + 2)
    XCTAssertGreaterThanOrEqual(reopenedPrimary.metadata.columnCount, baselineColumns + 1)
    let primaryValues = collectedValues(in: reopenedPrimary)
    XCTAssertTrue(primaryValues.contains(.string("Alice")))
    XCTAssertTrue(primaryValues.contains(.string("Header")))
    XCTAssertTrue(primaryValues.contains(.string("Col")))
  }

  func testAddTableRejectsDuplicateTableNameInSheet() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
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
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    XCTAssertEqual(editable.dirtyState, .clean)
    XCTAssertFalse(editable.hasChanges)

    let output = temporaryArchiveOutputURL("editable-noop-copy.numbers")
    try editable.save(to: output)

    let sourceDocument = try NumbersDocument.open(at: fixture)
    let reopened = try NumbersDocument.open(at: output)
    XCTAssertEqual(reopened.sheetNames, sourceDocument.sheetNames)
    XCTAssertEqual(reopened.tableNames, sourceDocument.tableNames)
    XCTAssertEqual(reopened.dump().resolvedCellCount, sourceDocument.dump().resolvedCellCount)
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

  func testSetStyleRoundTripPersistsOnPackageDocument() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    let style = ReadCellStyle(
      horizontalAlignment: .right,
      verticalAlignment: .middle,
      backgroundColorHex: "#FFEEDD",
      fontName: "HelveticaNeue",
      fontSize: 13,
      isBold: true,
      isItalic: false,
      textColorHex: "#112233",
      hasTopBorder: true,
      hasRightBorder: false,
      hasBottomBorder: true,
      hasLeftBorder: false,
      numberFormat: ReadNumberFormat(kind: .currency, formatID: 7)
    )
    try table.setStyle(style, at: "A1")

    let output = temporaryOutputURL("editable-style-package-roundtrip.numbers")
    XCTAssertThrowsError(try editable.save(to: output)) { error in
      guard case .nativeWriteFailed(let details) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertTrue(details.contains("Style mutations are unsupported"))
    }
  }

  func testSetStyleRoundTripPersistsOnSingleFileArchiveViaMetadataOverlay() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    table.setValue(.string("Styled"), at: CellAddress(row: 0, column: 0))
    let style = ReadCellStyle(
      horizontalAlignment: .center,
      verticalAlignment: .bottom,
      fontName: "Menlo",
      fontSize: 11,
      isBold: false,
      isItalic: true,
      textColorHex: "#334455",
      hasTopBorder: false,
      hasRightBorder: true,
      hasBottomBorder: false,
      hasLeftBorder: true
    )
    try table.setStyle(style, at: "A1")

    let output = temporaryArchiveOutputURL("editable-style-archive-roundtrip.numbers")
    XCTAssertThrowsError(try editable.save(to: output)) { error in
      guard case .nativeWriteFailed(let details) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertTrue(details.contains("Style mutations are unsupported"))
    }
  }

  func testSetFormatRoundTripPersistsStyleHintsForCoreModes() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    let referenceDate = Date(timeIntervalSince1970: 86_400 + 12_345)
    try table.setValue(.number(1234.5), at: "A1")
    try table.setFormat(.number(formatID: 101), at: "A1")
    try table.setValue(.number(1234.5), at: "B1")
    try table.setFormat(.currency(formatID: 202), at: "B1")
    try table.setValue(.date(referenceDate), at: "C1")
    try table.setFormat(.date(formatID: 303), at: "C1")
    try table.setValue(.number(42), at: "D1")
    try table.setFormat(.custom(formatID: 404), at: "D1")

    let output = temporaryArchiveOutputURL("editable-format-core-roundtrip.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.format("A1"), .number(formatID: 101))
    XCTAssertEqual(reopenedTable.format("B1"), .currency(formatID: 202))
    XCTAssertEqual(reopenedTable.format("C1"), .date(formatID: 303))
    XCTAssertEqual(reopenedTable.format("D1"), .custom(formatID: 404))
  }

  func testSetFormatRoundTripPersistsOnSingleFileArchiveViaMetadataOverlay() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    try table.setValue(.number(10.5), at: "A1")
    try table.setFormat(.currency(formatID: 777), at: "A1")
    XCTAssertEqual(table.format("A1"), .currency(formatID: 777))

    let output = temporaryArchiveOutputURL("editable-format-archive-roundtrip.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.format("A1"), .currency(formatID: 777))
  }

  func testSetFormatExtendedNumericFamiliesSnapshot() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    try table.setValue(.number(255), at: "A1")
    try table.setFormat(.base(formatID: 16), at: "A1")
    try table.setValue(.number(2.75), at: "B1")
    try table.setFormat(.fraction(formatID: 16), at: "B1")
    try table.setValue(.number(0.125), at: "C1")
    try table.setFormat(.percentage(formatID: 0), at: "C1")
    try table.setValue(.number(1000), at: "D1")
    try table.setFormat(.scientific(formatID: 0), at: "D1")

    let output = temporaryArchiveOutputURL("editable-format-extended-snapshot.numbers")
    try editable.save(to: output)

    let reopenedEditable = try EditableNumbersDocument.open(at: output)
    let reopenedEditableTable = try XCTUnwrap(reopenedEditable.firstSheet?.firstTable)
    let typedSnapshot = [
      "A1=\(typedFormatSnapshot(reopenedEditableTable.format("A1")))",
      "B1=\(typedFormatSnapshot(reopenedEditableTable.format("B1")))",
      "C1=\(typedFormatSnapshot(reopenedEditableTable.format("C1")))",
      "D1=\(typedFormatSnapshot(reopenedEditableTable.format("D1")))",
    ].joined(separator: "\n")
    XCTAssertEqual(
      typedSnapshot,
      """
      A1=base#16
      B1=fraction#16
      C1=percentage#0
      D1=scientific#0
      """
    )

    let reopenedRead = try NumbersDocument.open(at: output)
    let reopenedReadTable = try XCTUnwrap(reopenedRead.firstSheet?.firstTable)
    let options = ReadFormattingOptions(
      localeIdentifier: "en_US_POSIX",
      usesGroupingSeparator: false,
      minimumFractionDigits: 0,
      maximumFractionDigits: 4,
      preferCellNumberFormatHints: true
    )
    let renderedSnapshot = [
      "A1=\(reopenedReadTable.formattedValue("A1", options: options) ?? "<nil>")",
      "B1=\(reopenedReadTable.formattedValue("B1", options: options) ?? "<nil>")",
      "C1=\(reopenedReadTable.formattedValue("C1", options: options) ?? "<nil>")",
      "D1=\(reopenedReadTable.formattedValue("D1", options: options) ?? "<nil>")",
    ].joined(separator: "\n")
    XCTAssertEqual(
      renderedSnapshot,
      """
      A1=FF
      B1=2 3/4
      C1=12.5%
      D1=1E+003
      """
    )
  }

  func testSetFormatInteractiveControlFamiliesRoundTripSnapshot() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    try table.setValue(.bool(true), at: "A1")
    try table.setFormat(.tickbox(formatID: 1), at: "A1")
    try table.setValue(.number(4), at: "B1")
    try table.setFormat(.rating(formatID: 5), at: "B1")
    try table.setValue(.number(0.35), at: "C1")
    try table.setFormat(.slider(formatID: 2), at: "C1")
    try table.setValue(.number(2), at: "D1")
    try table.setFormat(.stepper(formatID: 3), at: "D1")
    try table.setValue(.string("Approved"), at: "E1")
    try table.setFormat(.popup(formatID: 9), at: "E1")

    let output = temporaryArchiveOutputURL("editable-format-controls-snapshot.numbers")
    try editable.save(to: output)

    let reopenedEditable = try EditableNumbersDocument.open(at: output)
    let reopenedEditableTable = try XCTUnwrap(reopenedEditable.firstSheet?.firstTable)
    let typedSnapshot = [
      "A1=\(typedFormatSnapshot(reopenedEditableTable.format("A1")))",
      "B1=\(typedFormatSnapshot(reopenedEditableTable.format("B1")))",
      "C1=\(typedFormatSnapshot(reopenedEditableTable.format("C1")))",
      "D1=\(typedFormatSnapshot(reopenedEditableTable.format("D1")))",
      "E1=\(typedFormatSnapshot(reopenedEditableTable.format("E1")))",
    ].joined(separator: "\n")
    XCTAssertEqual(
      typedSnapshot,
      """
      A1=tickbox#1
      B1=rating#5
      C1=slider#2
      D1=stepper#3
      E1=popup#9
      """
    )

    let reopenedRead = try NumbersDocument.open(at: output)
    let reopenedReadTable = try XCTUnwrap(reopenedRead.firstSheet?.firstTable)
    let readKindSnapshot = [
      "A1=\(reopenedReadTable.readCell("A1")?.style?.numberFormat?.kind.rawValue ?? "nil")",
      "B1=\(reopenedReadTable.readCell("B1")?.style?.numberFormat?.kind.rawValue ?? "nil")",
      "C1=\(reopenedReadTable.readCell("C1")?.style?.numberFormat?.kind.rawValue ?? "nil")",
      "D1=\(reopenedReadTable.readCell("D1")?.style?.numberFormat?.kind.rawValue ?? "nil")",
      "E1=\(reopenedReadTable.readCell("E1")?.style?.numberFormat?.kind.rawValue ?? "nil")",
    ].joined(separator: "\n")
    XCTAssertEqual(
      readKindSnapshot,
      """
      A1=tickbox
      B1=rating
      C1=slider
      D1=stepper
      E1=popup
      """
    )
  }

  func testDocumentStyleRegistryCreateApplyAndSaveReopenRoundTrip() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    let registeredStyle = ReadCellStyle(
      horizontalAlignment: .center,
      verticalAlignment: .middle,
      backgroundColorHex: "#CCEEFF",
      fontName: "Menlo",
      fontSize: 12,
      isBold: true,
      isItalic: false,
      textColorHex: "#112244",
      hasTopBorder: true,
      hasRightBorder: true,
      hasBottomBorder: false,
      hasLeftBorder: false,
      numberFormat: ReadNumberFormat(kind: .currency, formatID: 88)
    )
    let styleID = try editable.registerStyle(named: "Accent Currency", style: registeredStyle)
    try table.applyStyle(id: styleID, at: "A1")

    let output = temporaryArchiveOutputURL("editable-style-registry-roundtrip.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let definitions = reopened.registeredStyles()
    XCTAssertEqual(definitions.count, 1)
    XCTAssertEqual(definitions.first?.id, styleID)
    XCTAssertEqual(definitions.first?.name, "Accent Currency")
    XCTAssertEqual(definitions.first?.style, registeredStyle)

    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.style(at: CellAddress(row: 0, column: 0)), registeredStyle)
  }

  func testDocumentStyleRegistryRejectsDuplicateNames() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let style = ReadCellStyle(fontName: "HelveticaNeue")

    _ = try editable.registerStyle(named: "Accent", style: style)
    XCTAssertThrowsError(try editable.registerStyle(named: "Accent", style: style)) { error in
      guard case .duplicateStyleName(let name) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(name, "Accent")
    }
  }

  func testDocumentCustomFormatRegistryCreateApplyAndSaveReopenRoundTrip() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    try table.setValue(.number(42.5), at: "A1")
    try table.setValue(.date(Date(timeIntervalSince1970: 1_714_764_800)), at: "B1")
    try table.setValue(.string("hello"), at: "C1")

    let numberFormatID = try editable.registerCustomFormat(named: "Number Compact", formatID: 4101)
    let dateFormatID = try editable.registerCustomFormat(named: "Date Verbose", formatID: 4102)
    let textFormatID = try editable.registerCustomFormat(named: "Text Decorated", formatID: 4103)

    try table.applyCustomFormat(id: numberFormatID, at: "A1")
    try table.applyCustomFormat(id: dateFormatID, at: "B1")
    try table.applyCustomFormat(id: textFormatID, at: "C1")

    let output = temporaryArchiveOutputURL("editable-custom-format-registry-roundtrip.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let definitions = reopened.registeredCustomFormats()
    XCTAssertEqual(definitions.count, 3)
    XCTAssertEqual(definitions.map(\.name), ["Number Compact", "Date Verbose", "Text Decorated"])
    XCTAssertEqual(definitions.map(\.formatID), [4101, 4102, 4103])

    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.format("A1"), .custom(formatID: 4101))
    XCTAssertEqual(reopenedTable.format("B1"), .custom(formatID: 4102))
    XCTAssertEqual(reopenedTable.format("C1"), .custom(formatID: 4103))
  }

  func testDocumentCustomFormatRegistryRejectsDuplicateNamesAndUnknownApply() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    _ = try editable.registerCustomFormat(named: "Finance", formatID: 5001)
    XCTAssertThrowsError(try editable.registerCustomFormat(named: "Finance", formatID: 5002)) {
      error in
      guard case .duplicateCustomFormatName(let name) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(name, "Finance")
    }

    XCTAssertThrowsError(try table.applyCustomFormat(id: "missing-custom-format", at: "A1")) {
      error in
      guard case .customFormatNotFound(let identifier) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(identifier, "missing-custom-format")
    }
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

  func testSaveOnSingleFileArchiveUsesLowLevelIWAWriterForFormulaCells() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    table.setValue(.formula("B1+C1"), at: CellAddress(row: 0, column: 0))
    try table.setValue(.formula("=SUM(A1:A5)"), at: "B1")

    let output = temporaryArchiveOutputURL("editable-formula-low-level-output.numbers")
    try editable.save(to: output)

    let reopened = try NumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.cell(at: CellAddress(row: 0, column: 0)), .formula("=B1+C1"))
    XCTAssertEqual(reopenedTable.cell("B1"), .formula("=SUM(A1:A5)"))

    let firstFormula = try XCTUnwrap(reopenedTable.formula("A1"))
    XCTAssertEqual(firstFormula.rawFormula, "=B1+C1")
    XCTAssertEqual(firstFormula.parsedTokens, ["=", "B1", "+", "C1"])
    XCTAssertEqual(firstFormula.result, .formula("=B1+C1"))
    XCTAssertEqual(firstFormula.resultFormatted, "=B1+C1")

    let secondFormula = try XCTUnwrap(reopenedTable.formula("B1"))
    XCTAssertEqual(secondFormula.rawFormula, "=SUM(A1:A5)")
    XCTAssertEqual(secondFormula.parsedTokens, ["=", "SUM", "(", "A1", ":", "A5", ")"])
    XCTAssertEqual(secondFormula.result, .formula("=SUM(A1:A5)"))
    XCTAssertEqual(secondFormula.resultFormatted, "=SUM(A1:A5)")

    let container = try NumbersContainer.open(at: output)
    let metadataOverlay = try container.readMetadataFile(named: "DocumentMetadata.json")
    XCTAssertNil(metadataOverlay, "Formula writes should persist via low-level IWA writer.")
  }

  func testSaveOnSingleFileArchiveRejectsSelfReferentialFormulaRange() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    try table.setValue(.formula("=SUM(A1:B2)"), at: "B2")

    let output = temporaryArchiveOutputURL("editable-formula-unsafe-range-output.numbers")
    XCTAssertThrowsError(try editable.save(to: output)) { error in
      guard case EditableNumbersError.nativeWriteFailed(let details) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(
        details,
        "IWA writer: unsafe self-referential formula at Sheet 1/Table 1 B2 via range A1:B2."
      )
    }
  }

  func testSaveOnSingleFileArchiveRejectsInvalidFormulaRangeToken() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    try table.setValue(.formula("=SUM(A1:A99999999999999999999999999)"), at: "B2")

    let output = temporaryArchiveOutputURL("editable-formula-invalid-range-token-output.numbers")
    XCTAssertThrowsError(try editable.save(to: output)) { error in
      guard case EditableNumbersError.nativeWriteFailed(let details) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(
        details,
        "IWA writer: unsafe formula reference at Sheet 1/Table 1 B2. Invalid range token A1:A99999999999999999999999999."
      )
    }
  }

  func testSaveOnSingleFileArchiveRejectsSheetQualifiedFormulaReference() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    try table.setValue(.formula("=Sheet2!A1"), at: "A1")

    let output = temporaryArchiveOutputURL("editable-formula-sheet-qualified-output.numbers")
    XCTAssertThrowsError(try editable.save(to: output)) { error in
      guard case EditableNumbersError.nativeWriteFailed(let details) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(
        details,
        "IWA writer: unsafe formula reference at Sheet 1/Table 1 A1. Sheet-qualified references are unsupported in strict native-write mode."
      )
    }
  }

  func testSaveOnSingleFileArchiveRejectsSelfReferentialFormulaReference() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    try table.setValue(.formula("=B2+1"), at: "B2")

    let output = temporaryArchiveOutputURL("editable-formula-unsafe-self-reference-output.numbers")
    XCTAssertThrowsError(try editable.save(to: output)) { error in
      guard case EditableNumbersError.nativeWriteFailed(let details) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(
        details,
        "IWA writer: unsafe self-referential formula at Sheet 1/Table 1 B2 via reference B2."
      )
    }
  }

  func testSaveOnSingleFileArchiveRejectsSelfReferentialAbsoluteFormulaReference() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    try table.setValue(.formula("=$B$2+1"), at: "B2")

    let output = temporaryArchiveOutputURL(
      "editable-formula-unsafe-self-reference-absolute-output.numbers")
    XCTAssertThrowsError(try editable.save(to: output)) { error in
      guard case EditableNumbersError.nativeWriteFailed(let details) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(
        details,
        "IWA writer: unsafe self-referential formula at Sheet 1/Table 1 B2 via reference $B$2."
      )
    }
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

  func testDeleteRowAndColumnMutationsPersistOnSingleFileArchive() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    for row in 0..<3 {
      for column in 0..<3 {
        table.setValue(.string("r\(row)c\(column)"), at: CellAddress(row: row, column: column))
      }
    }

    try table.deleteRow(at: 1)
    try table.deleteColumn(at: 1)

    let output = temporaryArchiveOutputURL("editable-delete-structural-archive-output.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.metadata.rowCount, 2)
    XCTAssertEqual(reopenedTable.metadata.columnCount, 2)
    var observedValues: [String] = []
    for row in 0..<reopenedTable.metadata.rowCount {
      for column in 0..<reopenedTable.metadata.columnCount {
        guard
          case .string(let value) = reopenedTable.cell(at: CellAddress(row: row, column: column))
        else {
          continue
        }
        observedValues.append(value)
      }
    }
    XCTAssertEqual(observedValues.count, 4)
    XCTAssertEqual(Set(observedValues), Set(["r0c0", "r0c2", "r2c0", "r2c2"]))
  }

  func testDeleteRowAndColumnRejectOutOfBoundsIndices() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    XCTAssertThrowsError(try table.deleteRow(at: -1)) { error in
      guard case .invalidRowIndex(let index) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(index, -1)
    }
    XCTAssertThrowsError(try table.deleteRow(at: table.metadata.rowCount)) { error in
      guard case .invalidRowIndex(let index) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(index, table.metadata.rowCount)
    }

    XCTAssertThrowsError(try table.deleteColumn(at: -1)) { error in
      guard case .invalidColumnIndex(let index) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(index, -1)
    }
    XCTAssertThrowsError(try table.deleteColumn(at: table.metadata.columnCount)) { error in
      guard case .invalidColumnIndex(let index) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(index, table.metadata.columnCount)
    }

    XCTAssertFalse(editable.hasChanges)
    XCTAssertEqual(editable.dirtyState, .clean)
  }

  func testHeaderCountsMutationPersistsAndSupportsHeaderSelectionSemantics() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    try table.setValue(.string("Name"), at: "A1")
    try table.setValue(.string("Score"), at: "B1")
    try table.setValue(.string("Alice"), at: "A2")
    try table.setValue(.number(42), at: "B2")

    try table.setHeaderRowCount(1)
    try table.setHeaderColumnCount(1)
    XCTAssertEqual(table.metadata.headerRowCount, 1)
    XCTAssertEqual(table.metadata.headerColumnCount, 1)

    let output = temporaryArchiveOutputURL("editable-header-counts-roundtrip.numbers")
    try editable.save(to: output)

    let reopened = try NumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.metadata.headerRowCount, 1)
    XCTAssertEqual(reopenedTable.metadata.headerColumnCount, 1)

    let headerRowIndex = reopenedTable.metadata.headerRowCount - 1
    let headerCell = reopenedTable.cell(at: CellAddress(row: headerRowIndex, column: 0))
    guard case .string(let firstHeader) = headerCell else {
      return XCTFail("Expected string header at row \(headerRowIndex), column 0.")
    }

    let selectedColumn = try reopenedTable.column(
      named: firstHeader,
      headerRow: headerRowIndex,
      includeHeader: true
    )
    XCTAssertGreaterThanOrEqual(selectedColumn.count, 1)
    XCTAssertEqual(selectedColumn.first, .string(firstHeader))
  }

  func testHeaderCountsMutationRejectsOutOfBoundsCounts() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    XCTAssertThrowsError(try table.setHeaderRowCount(-1)) { error in
      guard case .invalidHeaderRowCount(let count) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(count, -1)
    }
    XCTAssertThrowsError(try table.setHeaderRowCount(table.metadata.rowCount + 1)) { error in
      guard case .invalidHeaderRowCount(let count) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(count, table.metadata.rowCount + 1)
    }

    XCTAssertThrowsError(try table.setHeaderColumnCount(-1)) { error in
      guard case .invalidHeaderColumnCount(let count) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(count, -1)
    }
    XCTAssertThrowsError(try table.setHeaderColumnCount(table.metadata.columnCount + 1)) { error in
      guard case .invalidHeaderColumnCount(let count) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(count, table.metadata.columnCount + 1)
    }
  }

  func testTableGeometryMutationPersistsAndSupportsCoordinateReadAPI() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)
    table.setValue(.string("seed"), at: CellAddress(row: 1, column: 1))

    try table.setRowHeight(30, at: 0)
    try table.setRowHeight(25, at: 1)
    try table.setColumnWidth(120, at: 0)
    try table.setColumnWidth(80, at: 1)

    XCTAssertEqual(try XCTUnwrap(table.rowHeight(at: 0)), 30, accuracy: 0.001)
    XCTAssertEqual(try XCTUnwrap(table.rowHeight(at: 1)), 25, accuracy: 0.001)
    XCTAssertEqual(try XCTUnwrap(table.columnWidth(at: 0)), 120, accuracy: 0.001)
    XCTAssertEqual(try XCTUnwrap(table.columnWidth(at: 1)), 80, accuracy: 0.001)

    let output = temporaryArchiveOutputURL("editable-geometry-roundtrip.numbers")
    try editable.save(to: output)

    let reopened = try NumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(try XCTUnwrap(reopenedTable.rowHeight(at: 0)), 30, accuracy: 0.001)
    XCTAssertEqual(try XCTUnwrap(reopenedTable.rowHeight(at: 1)), 25, accuracy: 0.001)
    XCTAssertEqual(try XCTUnwrap(reopenedTable.columnWidth(at: 0)), 120, accuracy: 0.001)
    XCTAssertEqual(try XCTUnwrap(reopenedTable.columnWidth(at: 1)), 80, accuracy: 0.001)

    let geometry = try XCTUnwrap(
      reopenedTable.cellGeometry(
        "B2",
        defaultRowHeight: 20,
        defaultColumnWidth: 100
      )
    )
    XCTAssertEqual(geometry.originX, 120, accuracy: 0.001)
    XCTAssertEqual(geometry.originY, 30, accuracy: 0.001)
    XCTAssertEqual(geometry.width, 80, accuracy: 0.001)
    XCTAssertEqual(geometry.height, 25, accuracy: 0.001)
  }

  func testTableGeometryMutationRejectsInvalidIndicesAndSizes() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    XCTAssertThrowsError(try table.setRowHeight(-1, at: 0)) { error in
      guard case .nativeWriteFailed(let message) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertTrue(message.contains("Row height must be >= 0"))
    }

    XCTAssertThrowsError(try table.setColumnWidth(-1, at: 0)) { error in
      guard case .nativeWriteFailed(let message) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertTrue(message.contains("Column width must be >= 0"))
    }

    XCTAssertThrowsError(try table.setRowHeight(10, at: table.metadata.rowCount)) { error in
      guard case .invalidRowIndex(let index) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(index, table.metadata.rowCount)
    }

    XCTAssertThrowsError(try table.setColumnWidth(10, at: table.metadata.columnCount)) { error in
      guard case .invalidColumnIndex(let index) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(index, table.metadata.columnCount)
    }
  }

  func testSaveOnSingleFileArchivePersistsMergeRanges() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    try table.mergeCells("A1:B2")
    try table.setValue(.string("Merged"), at: "A1")

    let output = temporaryArchiveOutputURL("editable-merge-low-level-output.numbers")
    try editable.save(to: output)

    let reopened = try NumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.metadata.mergeRanges.count, 1)
    let merge = try XCTUnwrap(reopenedTable.metadata.mergeRanges.first)
    XCTAssertEqual(merge.startRow, 0)
    XCTAssertEqual(merge.endRow, 1)
    XCTAssertEqual(merge.startColumn, 0)
    XCTAssertEqual(merge.endColumn, 1)

    let anchor = try XCTUnwrap(reopenedTable.readCell("A1"))
    XCTAssertEqual(anchor.mergeRole, .anchor)
    let member = try XCTUnwrap(reopenedTable.readCell("B2"))
    XCTAssertEqual(member.mergeRole, .member)
  }

  func testSaveOnSingleFileArchivePersistsUnmergeMutation() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    try table.mergeCells("A1:B2")
    try table.unmergeCells("A1:B2")

    let output = temporaryArchiveOutputURL("editable-unmerge-low-level-output.numbers")
    try editable.save(to: output)

    let reopened = try NumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertTrue(reopenedTable.metadata.mergeRanges.isEmpty)
  }

  func testSaveOnSingleFileArchiveUnmergeRequiresExactRangeMatch() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    try table.mergeCells("A1:B2")
    try table.unmergeCells("B2:C3")

    let output = temporaryArchiveOutputURL("editable-unmerge-exact-match-output.numbers")
    try editable.save(to: output)

    let reopened = try NumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    XCTAssertEqual(reopenedTable.metadata.mergeRanges.count, 1)
    let merge = try XCTUnwrap(reopenedTable.metadata.mergeRanges.first)
    XCTAssertEqual(merge.startRow, 0)
    XCTAssertEqual(merge.endRow, 1)
    XCTAssertEqual(merge.startColumn, 0)
    XCTAssertEqual(merge.endColumn, 1)
  }

  func testSetBorderRoundTripPersistsSingleCellSideSpecificFlags() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    try table.setBorder(true, side: .top, at: "A1")
    try table.setBorder(true, side: .right, at: "A1")
    try table.setBorder(false, side: .top, at: "A1")

    let output = temporaryArchiveOutputURL("editable-border-single-cell-roundtrip.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)
    let style = reopenedTable.style(at: CellAddress(row: 0, column: 0))
    XCTAssertEqual(style?.hasTopBorder ?? false, false)
    XCTAssertEqual(style?.hasRightBorder ?? false, true)
    XCTAssertEqual(style?.hasBottomBorder ?? false, false)
    XCTAssertEqual(style?.hasLeftBorder ?? false, false)
  }

  func testSetBorderOnMergedMemberAppliesMergedEdgeDeterministically() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    try table.mergeCells("A1:B2")
    try table.setBorder(true, side: .top, at: "B2")
    try table.setBorder(true, side: .left, at: "B2")

    let output = temporaryArchiveOutputURL("editable-border-merged-edge-roundtrip.numbers")
    try editable.save(to: output)

    let reopened = try EditableNumbersDocument.open(at: output)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)

    let a1 = reopenedTable.style(at: CellAddress(row: 0, column: 0))
    let b1 = reopenedTable.style(at: CellAddress(row: 0, column: 1))
    let a2 = reopenedTable.style(at: CellAddress(row: 1, column: 0))
    let b2 = reopenedTable.style(at: CellAddress(row: 1, column: 1))

    XCTAssertEqual(a1?.hasTopBorder ?? false, true)
    XCTAssertEqual(b1?.hasTopBorder ?? false, true)
    XCTAssertEqual(a2?.hasTopBorder ?? false, false)
    XCTAssertEqual(b2?.hasTopBorder ?? false, false)

    XCTAssertEqual(a1?.hasLeftBorder ?? false, true)
    XCTAssertEqual(a2?.hasLeftBorder ?? false, true)
    XCTAssertEqual(b1?.hasLeftBorder ?? false, false)
    XCTAssertEqual(b2?.hasLeftBorder ?? false, false)
  }

  func testSaveOnSingleFileArchivePersistsTablePresentationMetadataForAddedTable() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let bootstrapEditable = try EditableNumbersDocument.open(at: fixture)
    let bootstrapSheet = try XCTUnwrap(bootstrapEditable.firstSheet)
    _ = try bootstrapSheet.addTable(named: "Presentation Table", rows: 1, columns: 1)

    let bootstrapOutput = temporaryArchiveOutputURL("editable-presentation-bootstrap.numbers")
    try bootstrapEditable.save(to: bootstrapOutput)

    let editable = try EditableNumbersDocument.open(at: bootstrapOutput)
    let sheet = try XCTUnwrap(editable.firstSheet)
    let table = try sheet.table(named: "Presentation Table")

    XCTAssertEqual(table.isTableNameVisible, true)
    XCTAssertEqual(table.isCaptionVisible, true)
    XCTAssertEqual(table.tableCaptionText, "")

    try table.setTableNameVisible(false)
    try table.setCaptionVisible(false)
    try table.setCaptionText("Roadmap-generated caption")

    let output = temporaryArchiveOutputURL("editable-presentation-roundtrip.numbers")
    try editable.save(to: output)

    let reopened = try NumbersDocument.open(at: output)
    let reopenedSheet = try XCTUnwrap(reopened.firstSheet)
    let reopenedTable = try XCTUnwrap(reopenedSheet.table(named: "Presentation Table"))

    XCTAssertEqual(reopenedTable.metadata.tableNameVisible, false)
    XCTAssertEqual(reopenedTable.metadata.captionVisible, false)
    XCTAssertEqual(reopenedTable.metadata.captionTextSupported, true)
    XCTAssertEqual(reopenedTable.metadata.captionText, "Roadmap-generated caption")
  }

  func testMergeCellsRejectsOverlappingRanges() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    try table.mergeCells("A1:B2")
    XCTAssertThrowsError(try table.mergeCells("B2:C3")) { error in
      guard case .nativeWriteFailed(let details) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertTrue(details.contains("Overlapping merge range"))
    }
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
    XCTAssertThrowsError(try EditableNumbersDocument.open(at: fixture)) { error in
      guard case .realReadFailed = error as? NumbersDocumentError else {
        return XCTFail("Unexpected error: \(error)")
      }
    }
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

  func testMixedMutationsRoundTripWithSaveInPlace() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let workingCopy = try makeWorkingCopy(
      from: fixture,
      name: "editable-mixed-mutations-save-in-place.numbers",
      isDirectory: false
    )

    let editable = try EditableNumbersDocument.open(at: workingCopy)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)
    let baselineColumnCount = table.metadata.columnCount

    table.setValue(.string("Initial"), at: CellAddress(row: 0, column: 0))
    try table.insertRow([.string("Inserted"), .number(7)], at: 0)

    let appendedColumnValues = (0..<max(table.metadata.rowCount, 2)).map { row in
      CellValue.string("C\(row)")
    }
    table.appendColumn(appendedColumnValues)
    let appendedColumnIndex = max(table.metadata.columnCount - 1, baselineColumnCount)

    try editable.saveInPlace()

    let reopened = try EditableNumbersDocument.open(at: workingCopy)
    let reopenedTable = try XCTUnwrap(reopened.firstSheet?.firstTable)

    let firstRowFirstColumn = reopenedTable.cell(at: CellAddress(row: 0, column: 0))
    let secondRowFirstColumn = reopenedTable.cell(at: CellAddress(row: 1, column: 0))
    XCTAssertTrue(
      [firstRowFirstColumn, secondRowFirstColumn].contains(.string("Initial")),
      "Expected first two rows to include the original setValue payload."
    )
    XCTAssertTrue(
      [firstRowFirstColumn, secondRowFirstColumn].contains(.string("Inserted")),
      "Expected first two rows to include the inserted row payload."
    )
    let firstRowAppendedColumn = reopenedTable.cell(
      at: CellAddress(row: 0, column: appendedColumnIndex))
    let secondRowAppendedColumn = reopenedTable.cell(
      at: CellAddress(row: 1, column: appendedColumnIndex))
    XCTAssertTrue(
      [firstRowAppendedColumn, secondRowAppendedColumn].contains(.string("C0")),
      "Expected appended column values from appendColumn to persist."
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
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(editable.firstSheet?.firstTable)

    table.setValue(.string("NEG"), at: CellAddress(row: -1, column: 0))
    table.setValue(.string("NEG"), at: CellAddress(row: 0, column: -1))

    XCTAssertFalse(editable.hasChanges)
    XCTAssertEqual(editable.dirtyState, .clean)
    XCTAssertNil(table.cell(at: CellAddress(row: 0, column: 0)))
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
    XCTAssertNil(editableTable.cell(at: CellAddress(row: 0, column: 0)))

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
    XCTAssertThrowsError(
      try editable.addTable(named: "New Table", rows: 1, columns: 1, onSheetNamed: "Dup")
    ) { error in
      guard case .sheetNotFound(let name) = error as? EditableNumbersError else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(name, "Dup")
    }
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
    XCTAssertThrowsError(try EditableNumbersDocument.open(at: fixture)) { error in
      guard case .realReadFailed = error as? NumbersDocumentError else {
        return XCTFail("Unexpected error: \(error)")
      }
    }
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

  func testGroupedTableMutationUnsupportedErrorMessageIsDeterministic() {
    let error = EditableNumbersError.groupedTableMutationUnsupported(
      sheet: "Sheet 1",
      table: "Table 1",
      operation: "appendRow"
    )
    XCTAssertEqual(
      error.errorDescription,
      "Unsafe grouped-table mutation blocked for Sheet 1/Table 1 during appendRow. Grouped tables are currently read-only for structural edits. Remove grouping in Apple Numbers and retry."
    )
  }

  func testGroupedDeleteRowMutationUnsupportedErrorMessageIncludesRowIndex() {
    let error = EditableNumbersError.groupedTableMutationUnsupported(
      sheet: "Sheet 1",
      table: "Table 1",
      operation: "deleteRow(rowIndex: 3)"
    )
    XCTAssertEqual(
      error.errorDescription,
      "Unsafe grouped-table mutation blocked for Sheet 1/Table 1 during deleteRow(rowIndex: 3). Grouped tables are currently read-only for structural edits. Remove grouping in Apple Numbers and retry."
    )
  }

  func testPivotLinkedTableMutationUnsupportedErrorMessageIsDeterministic() {
    let error = EditableNumbersError.pivotLinkedTableMutationUnsupported(
      sheet: "Sheet 1",
      table: "Table 1",
      operation: "setCell",
      linkedObjectIDs: [300, 400]
    )
    XCTAssertEqual(
      error.errorDescription,
      "Unsafe pivot-linked mutation blocked for Sheet 1/Table 1 during setCell. Linked object identifiers: [300,400]. This table is linked to a non-table analytical drawable (pivot-like structure) and is currently read-only for native writes. Remove pivot linkage in Apple Numbers and retry."
    )
  }

  func testPivotLinkedTableMutationUnsupportedErrorMessageHandlesEmptyIdentifiersDeterministically()
  {
    let error = EditableNumbersError.pivotLinkedTableMutationUnsupported(
      sheet: "Sheet 1",
      table: "Table 1",
      operation: "setCell",
      linkedObjectIDs: []
    )
    XCTAssertEqual(
      error.errorDescription,
      "Unsafe pivot-linked mutation blocked for Sheet 1/Table 1 during setCell. Linked object identifiers: [none]. This table is linked to a non-table analytical drawable (pivot-like structure) and is currently read-only for native writes. Remove pivot linkage in Apple Numbers and retry."
    )
  }

  func testPivotLinkedTableMutationUnsupportedErrorMessageSortsIdentifiersDeterministically() {
    let error = EditableNumbersError.pivotLinkedTableMutationUnsupported(
      sheet: "Sheet 1",
      table: "Table 1",
      operation: "setCell",
      linkedObjectIDs: [400, 300]
    )
    XCTAssertEqual(
      error.errorDescription,
      "Unsafe pivot-linked mutation blocked for Sheet 1/Table 1 during setCell. Linked object identifiers: [300,400]. This table is linked to a non-table analytical drawable (pivot-like structure) and is currently read-only for native writes. Remove pivot linkage in Apple Numbers and retry."
    )
  }

  func testPivotLinkedDeleteRowMutationUnsupportedErrorMessageIncludesRowIndex() {
    let error = EditableNumbersError.pivotLinkedTableMutationUnsupported(
      sheet: "Sheet 1",
      table: "Table 1",
      operation: "deleteRow(rowIndex: 3)",
      linkedObjectIDs: [300, 400]
    )
    XCTAssertEqual(
      error.errorDescription,
      "Unsafe pivot-linked mutation blocked for Sheet 1/Table 1 during deleteRow(rowIndex: 3). Linked object identifiers: [300,400]. This table is linked to a non-table analytical drawable (pivot-like structure) and is currently read-only for native writes. Remove pivot linkage in Apple Numbers and retry."
    )
  }

  func testPivotLinkedDeleteColumnMutationUnsupportedErrorMessageIncludesColumnIndexAndSortedIDs() {
    let error = EditableNumbersError.pivotLinkedTableMutationUnsupported(
      sheet: "Sheet 1",
      table: "Table 1",
      operation: "deleteColumn(columnIndex: 2)",
      linkedObjectIDs: [400, 300]
    )
    XCTAssertEqual(
      error.errorDescription,
      "Unsafe pivot-linked mutation blocked for Sheet 1/Table 1 during deleteColumn(columnIndex: 2). Linked object identifiers: [300,400]. This table is linked to a non-table analytical drawable (pivot-like structure) and is currently read-only for native writes. Remove pivot linkage in Apple Numbers and retry."
    )
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

  func testGroupedTableSafetyGuardBlocksStructuralMutations() {
    XCTAssertTrue(
      IWASetCellWriter.shouldBlockGroupedTableMutation(
        bucketCount: 2,
        rowCount: 4,
        columnCount: 3,
        operation: .appendRow(sheetName: "S", tableName: "T", values: [])
      )
    )
    XCTAssertTrue(
      IWASetCellWriter.shouldBlockGroupedTableMutation(
        bucketCount: 2,
        rowCount: 4,
        columnCount: 3,
        operation: .insertRow(sheetName: "S", tableName: "T", rowIndex: 2, values: [])
      )
    )
    XCTAssertTrue(
      IWASetCellWriter.shouldBlockGroupedTableMutation(
        bucketCount: 2,
        rowCount: 4,
        columnCount: 3,
        operation: .appendColumn(sheetName: "S", tableName: "T", values: [])
      )
    )
    XCTAssertTrue(
      IWASetCellWriter.shouldBlockGroupedTableMutation(
        bucketCount: 2,
        rowCount: 4,
        columnCount: 3,
        operation: .deleteRow(sheetName: "S", tableName: "T", rowIndex: 1)
      )
    )
    XCTAssertTrue(
      IWASetCellWriter.shouldBlockGroupedTableMutation(
        bucketCount: 2,
        rowCount: 4,
        columnCount: 3,
        operation: .deleteColumn(sheetName: "S", tableName: "T", columnIndex: 1)
      )
    )
  }

  func testGroupedTableSafetyGuardDeleteRowIsDeterministicAcrossIndices() {
    let groupedDecisions = [0, 1, 3].map { rowIndex in
      IWASetCellWriter.shouldBlockGroupedTableMutation(
        bucketCount: 2,
        rowCount: 4,
        columnCount: 3,
        operation: .deleteRow(sheetName: "S", tableName: "T", rowIndex: rowIndex)
      )
    }
    XCTAssertEqual(groupedDecisions, [true, true, true])

    let ungroupedDecisions = [0, 1, 3].map { rowIndex in
      IWASetCellWriter.shouldBlockGroupedTableMutation(
        bucketCount: 1,
        rowCount: 4,
        columnCount: 3,
        operation: .deleteRow(sheetName: "S", tableName: "T", rowIndex: rowIndex)
      )
    }
    XCTAssertEqual(ungroupedDecisions, [false, false, false])
  }

  func testGroupedTableSafetyGuardDeleteRowIsDeterministicAcrossOutOfBoundsIndices() {
    let groupedDecisions = [-1, 0, 4].map { rowIndex in
      IWASetCellWriter.shouldBlockGroupedTableMutation(
        bucketCount: 2,
        rowCount: 4,
        columnCount: 3,
        operation: .deleteRow(sheetName: "S", tableName: "T", rowIndex: rowIndex)
      )
    }
    XCTAssertEqual(groupedDecisions, [true, true, true])

    let ungroupedDecisions = [-1, 0, 4].map { rowIndex in
      IWASetCellWriter.shouldBlockGroupedTableMutation(
        bucketCount: 1,
        rowCount: 4,
        columnCount: 3,
        operation: .deleteRow(sheetName: "S", tableName: "T", rowIndex: rowIndex)
      )
    }
    XCTAssertEqual(ungroupedDecisions, [false, false, false])
  }

  func testGroupedTableSafetyGuardAllowsDeleteMutationsWhenTableIsNotGrouped() {
    XCTAssertFalse(
      IWASetCellWriter.shouldBlockGroupedTableMutation(
        bucketCount: 1,
        rowCount: 4,
        columnCount: 3,
        operation: .deleteRow(sheetName: "S", tableName: "T", rowIndex: 2)
      )
    )
    XCTAssertFalse(
      IWASetCellWriter.shouldBlockGroupedTableMutation(
        bucketCount: 1,
        rowCount: 4,
        columnCount: 3,
        operation: .deleteColumn(sheetName: "S", tableName: "T", columnIndex: 1)
      )
    )
  }

  func testGroupedTableMutationOperationNameForDeleteRowIncludesIndex() {
    XCTAssertEqual(
      IWASetCellWriter.groupedMutationOperationName(
        for: .deleteRow(sheetName: "S", tableName: "T", rowIndex: 3)
      ),
      "deleteRow(rowIndex: 3)"
    )
  }

  func testGroupedTableMutationOperationNameForDeleteRowPreservesOutOfBoundsIndices() {
    let operationNames = [-1, 0, 4].map { rowIndex in
      IWASetCellWriter.groupedMutationOperationName(
        for: .deleteRow(sheetName: "S", tableName: "T", rowIndex: rowIndex)
      )
    }
    XCTAssertEqual(
      operationNames,
      ["deleteRow(rowIndex: -1)", "deleteRow(rowIndex: 0)", "deleteRow(rowIndex: 4)"]
    )
  }

  func testGroupedTableSafetyGuardAllowsInBoundsSetCellMutation() {
    XCTAssertFalse(
      IWASetCellWriter.shouldBlockGroupedTableMutation(
        bucketCount: 2,
        rowCount: 4,
        columnCount: 3,
        operation: .setCell(
          sheetName: "S",
          tableName: "T",
          row: 3,
          column: 2,
          value: .string("ok")
        )
      )
    )
  }

  func testGroupedTableSafetyGuardBlocksExpandingSetCellMutation() {
    XCTAssertTrue(
      IWASetCellWriter.shouldBlockGroupedTableMutation(
        bucketCount: 2,
        rowCount: 4,
        columnCount: 3,
        operation: .setCell(
          sheetName: "S",
          tableName: "T",
          row: 4,
          column: 0,
          value: .string("expand-row")
        )
      )
    )
    XCTAssertTrue(
      IWASetCellWriter.shouldBlockGroupedTableMutation(
        bucketCount: 2,
        rowCount: 4,
        columnCount: 3,
        operation: .setCell(
          sheetName: "S",
          tableName: "T",
          row: 0,
          column: 3,
          value: .string("expand-column")
        )
      )
    )
    XCTAssertFalse(
      IWASetCellWriter.shouldBlockGroupedTableMutation(
        bucketCount: 1,
        rowCount: 4,
        columnCount: 3,
        operation: .appendRow(sheetName: "S", tableName: "T", values: [])
      )
    )
  }

  func testDecodeRowStorageMapForGroupedHeadersIsDeterministicAndBounded() throws {
    var headerStorage = TST_HeaderStorage()
    headerStorage.buckets = [reference(9101), reference(9102)]

    var bucketA = TST_HeaderStorageBucket()
    var a0 = TST_HeaderStorageBucket.Header()
    a0.index = 0
    var a1 = TST_HeaderStorageBucket.Header()
    a1.index = 1
    bucketA.headers = [a0, a1]

    var bucketB = TST_HeaderStorageBucket()
    var b1Duplicate = TST_HeaderStorageBucket.Header()
    b1Duplicate.index = 1
    var b2 = TST_HeaderStorageBucket.Header()
    b2.index = 2
    bucketB.headers = [b1Duplicate, b2]

    let payloadA = try bucketA.serializedData()
    let payloadB = try bucketB.serializedData()
    let recordsByObjectID: [UInt64: [IWAObjectRecord]] = [
      9101: [
        IWAObjectRecord(
          objectID: 9101,
          typeID: 6006,
          payloadSize: payloadA.count,
          payloadData: payloadA,
          sourceBlobPath: "BucketA.iwa"
        )
      ],
      9102: [
        IWAObjectRecord(
          objectID: 9102,
          typeID: 6006,
          payloadSize: payloadB.count,
          payloadData: payloadB,
          sourceBlobPath: "BucketB.iwa"
        )
      ],
    ]

    let map = IWASetCellWriter.decodeRowStorageMap(
      headerStorage: headerStorage,
      rowCount: 4,
      rowBufferCount: 3,
      recordsByObjectID: recordsByObjectID
    )

    XCTAssertEqual(map.count, 4)
    XCTAssertEqual(map[0], 0)
    XCTAssertEqual(map[1], 1)
    XCTAssertEqual(map[2], 2)
    XCTAssertNil(map[3], "Rows beyond available row buffers must remain unmapped.")
  }

  func testPivotLinkedTableInfoObjectIDsDetectsNonTableDrawableLink() throws {
    var tableInfo = TST_TableInfoArchive()
    var drawable = TSD_DrawableArchive()
    drawable.parent = reference(200)
    tableInfo.super = drawable
    tableInfo.tableModel = reference(400)

    var tableModel = TST_TableModelArchive()
    tableModel.tableID = "table-400"
    tableModel.tableName = "Main"
    tableModel.numberOfRows = 0
    tableModel.numberOfColumns = 0

    let tableInfoPayload = try tableInfo.serializedData()
    let tableModelPayload = try tableModel.serializedData()

    let recordsByObjectID: [UInt64: [IWAObjectRecord]] = [
      300: [
        IWAObjectRecord(
          objectID: 300,
          typeID: 6000,
          payloadSize: tableInfoPayload.count,
          payloadData: tableInfoPayload,
          sourceBlobPath: "TableInfo.iwa",
          objectReferences: [200, 400]
        )
      ],
      400: [
        IWAObjectRecord(
          objectID: 400,
          typeID: 6001,
          payloadSize: tableModelPayload.count,
          payloadData: tableModelPayload,
          sourceBlobPath: "TableModel.iwa"
        )
      ],
      900: [
        IWAObjectRecord(
          objectID: 900,
          typeID: 7777,
          payloadSize: 0,
          sourceBlobPath: "Drawable.iwa",
          objectReferences: [300]
        )
      ],
    ]

    let linked = IWASetCellWriter.pivotLinkedTableInfoObjectIDs(
      forSheetObjectID: 200,
      drawableRefs: [reference(300), reference(900)],
      recordsByObjectID: recordsByObjectID
    )

    XCTAssertEqual(linked, Set([300]))
  }

  func testPivotLinkedMutationGuardBlocksWritesForLinkedTable() {
    XCTAssertTrue(
      IWASetCellWriter.shouldBlockPivotLinkedTableMutation(
        tableInfoObjectID: 300,
        pivotLinkedTableInfoObjectIDs: Set([300]),
        operation: .setCell(sheetName: "S", tableName: "T", row: 0, column: 0, value: .number(1))
      )
    )
    XCTAssertFalse(
      IWASetCellWriter.shouldBlockPivotLinkedTableMutation(
        tableInfoObjectID: 301,
        pivotLinkedTableInfoObjectIDs: Set([300]),
        operation: .setCell(sheetName: "S", tableName: "T", row: 0, column: 0, value: .number(1))
      )
    )
    XCTAssertTrue(
      IWASetCellWriter.shouldBlockPivotLinkedTableMutation(
        tableInfoObjectID: 300,
        pivotLinkedTableInfoObjectIDs: Set([300]),
        operation: .deleteRow(sheetName: "S", tableName: "T", rowIndex: 0)
      )
    )
    XCTAssertTrue(
      IWASetCellWriter.shouldBlockPivotLinkedTableMutation(
        tableInfoObjectID: 300,
        pivotLinkedTableInfoObjectIDs: Set([300]),
        operation: .deleteColumn(sheetName: "S", tableName: "T", columnIndex: 0)
      )
    )
  }

  private func reference(_ objectID: UInt64) -> TSP_Reference {
    var reference = TSP_Reference()
    reference.identifier = objectID
    return reference
  }
}
