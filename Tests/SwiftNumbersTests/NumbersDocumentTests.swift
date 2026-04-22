import XCTest

@testable import SwiftNumbersCore

final class NumbersDocumentTests: XCTestCase {
  func testOpenSimpleFixture() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let document = try NumbersDocument.open(at: fixture)

    XCTAssertEqual(document.sheets.count, 1)
    XCTAssertEqual(document.sheets.first?.name, "Sheet 1")
    XCTAssertEqual(document.sheets.first?.tables.count, 1)
    XCTAssertEqual(document.sheets.first?.tables.first?.name, "Table 1")
    XCTAssertEqual(document.sheets.first?.tables.first?.metadata.rowCount, 4)
    XCTAssertEqual(document.sheets.first?.tables.first?.metadata.columnCount, 3)
  }

  func testMergedFixtureExposesMergeRanges() throws {
    let fixture = FixtureLocator.fixtureURL(named: "merged-cells.numbers")
    let document = try NumbersDocument.open(at: fixture)

    let merges = try XCTUnwrap(document.sheets.first?.tables.first?.metadata.mergeRanges)
    XCTAssertEqual(merges.count, 1)
    XCTAssertEqual(merges[0].startRow, 0)
    XCTAssertEqual(merges[0].endRow, 1)
    XCTAssertEqual(merges[0].startColumn, 0)
    XCTAssertEqual(merges[0].endColumn, 1)
  }

  func testDumpIncludesTypeHistogram() throws {
    let fixture = FixtureLocator.fixtureURL(named: "multi-sheet.numbers")
    let document = try NumbersDocument.open(at: fixture)
    let output = document.renderDump()

    XCTAssertTrue(output.contains("Sheets: 2"))
    XCTAssertTrue(output.contains("Object reference edges: 0"))
    XCTAssertTrue(output.contains("Root objects: 5"))
    XCTAssertTrue(output.contains("Type histogram:"))
    XCTAssertTrue(output.contains("1001: 1"))
    XCTAssertTrue(output.contains("1002: 2"))
    XCTAssertTrue(output.contains("1003: 2"))
  }

  func testCellLookupReturnsValuesFromTypedMetadata() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let document = try NumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(document.sheets.first?.tables.first)

    XCTAssertEqual(table.populatedCellCount, 6)
    XCTAssertEqual(table.cell(at: CellAddress(row: 0, column: 0)), .string("Name"))
    XCTAssertEqual(table.cell(at: CellAddress(row: 1, column: 1)), .number(42))
    XCTAssertEqual(table.cell(at: CellAddress(row: 2, column: 1)), .bool(true))
    XCTAssertNil(table.cell(at: CellAddress(row: 3, column: 2)))
  }

  func testDumpExposesFallbackReadPathForSyntheticFixture() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let document = try NumbersDocument.open(at: fixture)
    let dump = document.dump()

    XCTAssertEqual(dump.readPath, .metadataFallback)
    XCTAssertNotNil(dump.fallbackReason)
    XCTAssertEqual(dump.resolvedCellCount, 6)
  }

  func testDumpExposesRealReadPathForReferenceFixture() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let document = try NumbersDocument.open(at: fixture)
    let dump = document.dump()

    XCTAssertEqual(dump.readPath, .real)
    XCTAssertNil(dump.fallbackReason)
    XCTAssertGreaterThan(document.sheets.count, 0)
  }
}
