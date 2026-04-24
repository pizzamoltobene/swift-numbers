import XCTest

@testable import SwiftNumbersCore

final class NumbersDocumentTests: XCTestCase {
  private struct SimpleRow: Decodable, Equatable {
    let name: String
    let amount: Double
  }

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

  func testReadLookupByNameAndIndex() throws {
    let fixture = FixtureLocator.fixtureURL(named: "multi-sheet.numbers")
    let document = try NumbersDocument.open(at: fixture)

    XCTAssertEqual(document.sheet(at: 0)?.name, "Sheet A")
    XCTAssertEqual(document.sheet(at: 1)?.name, "Sheet B")
    XCTAssertNil(document.sheet(at: 99))
    XCTAssertEqual(document[0]?.name, "Sheet A")
    XCTAssertEqual(document[1]?.name, "Sheet B")
    XCTAssertNil(document[99])

    XCTAssertEqual(document.sheet(named: "Sheet A")?.name, "Sheet A")
    XCTAssertNil(document.sheet(named: "Missing"))
    XCTAssertEqual(document["Sheet A"]?.name, "Sheet A")
    XCTAssertNil(document["Missing"])

    let sheetA = try XCTUnwrap(document.sheet(named: "Sheet A"))
    XCTAssertEqual(sheetA.table(at: 0)?.name, "Table A1")
    XCTAssertNil(sheetA.table(at: 42))
    XCTAssertEqual(sheetA.table(named: "Table A1")?.name, "Table A1")
    XCTAssertNil(sheetA.table(named: "Unknown"))
    XCTAssertEqual(sheetA[0]?.name, "Table A1")
    XCTAssertNil(sheetA[42])
    XCTAssertEqual(sheetA["Table A1"]?.name, "Table A1")
    XCTAssertNil(sheetA["Unknown"])
  }

  func testTableRowsAndA1CellAndFormattedValue() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let document = try NumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(document.firstSheet?.firstTable)

    let rows = table.rows()
    XCTAssertEqual(rows.count, 4)
    XCTAssertEqual(rows[0].count, 3)
    XCTAssertEqual(rows[0][0], .string("Name"))
    XCTAssertEqual(rows[3][2], .empty)

    XCTAssertEqual(table.cell(row: 1, column: 1), .number(42))
    XCTAssertNil(table.cell(row: 99, column: 99))
    XCTAssertEqual(table.cell("B2"), .number(42))
    XCTAssertNil(table.cell("ZZZ"))

    XCTAssertEqual(table.formattedValue(at: CellAddress(row: 1, column: 1)), "42")
    XCTAssertEqual(table.formattedValue("B3"), "TRUE")
    XCTAssertEqual(table.formattedValue("C4"), "")
    XCTAssertNil(table.formattedValue("ZZZ"))
  }

  func testMergedCellHelpers() throws {
    let fixture = FixtureLocator.fixtureURL(named: "merged-cells.numbers")
    let document = try NumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(document.firstSheet?.firstTable)

    XCTAssertTrue(table.isMergedCell("A1"))
    XCTAssertTrue(table.isMergedCell(at: CellAddress(row: 1, column: 1)))
    XCTAssertFalse(table.isMergedCell("C3"))

    let mergeA1 = try XCTUnwrap(table.mergeRange(containing: "A1"))
    XCTAssertEqual(mergeA1.startRow, 0)
    XCTAssertEqual(mergeA1.endRow, 1)
    XCTAssertEqual(mergeA1.startColumn, 0)
    XCTAssertEqual(mergeA1.endColumn, 1)

    XCTAssertNil(table.mergeRange(containing: "C3"))
  }

  func testTypedValueAccessorsAndReadCellDetails() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let document = try NumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(document.firstSheet?.firstTable)

    XCTAssertEqual(try table.value(Double.self, at: "B2"), 42)
    XCTAssertEqual(try table.value(String.self, at: "A2"), "Answer")
    XCTAssertEqual(try table.value(Bool.self, at: "B3"), true)
    XCTAssertNil(try table.optionalValue(String.self, at: "C4"))

    XCTAssertThrowsError(try table.value(Double.self, at: "A2"))

    let read = try XCTUnwrap(table.readCell("B2"))
    XCTAssertEqual(read.kind, .number)
    XCTAssertEqual(read.formatted, "42")
    XCTAssertFalse(read.isMerged)
  }

  func testRangeAndColumnExtraction() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let document = try NumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(document.firstSheet?.firstTable)

    let range = try table.values(in: "A2:B3")
    XCTAssertEqual(range.count, 2)
    XCTAssertEqual(range[0].count, 2)
    XCTAssertEqual(range[0][0], .string("Answer"))
    XCTAssertEqual(range[0][1], .number(42))
    XCTAssertEqual(range[1][0], .string("Enabled"))
    XCTAssertEqual(range[1][1], .bool(true))

    let nameColumn = try table.column(named: "Name")
    XCTAssertEqual(nameColumn.count, 3)
    XCTAssertEqual(nameColumn[0], .string("Answer"))
    XCTAssertEqual(nameColumn[1], .string("Enabled"))
    XCTAssertEqual(nameColumn[2], .empty)

    let firstColumn = try table.column(at: 0, from: 1)
    XCTAssertEqual(firstColumn, [.string("Answer"), .string("Enabled"), .empty])

    let firstReadColumn = try table.readColumn(at: 0, from: 1)
    XCTAssertEqual(firstReadColumn.count, 3)
    XCTAssertEqual(firstReadColumn[0].formatted, "Answer")

    let lazyRows = Array(table.rows(lazy: true))
    XCTAssertEqual(lazyRows.count, table.metadata.rowCount)
  }

  func testUsedRangeAndPopulatedCells() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let document = try NumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(document.firstSheet?.firstTable)

    let usedRange = try XCTUnwrap(table.usedRange)
    XCTAssertEqual(usedRange.a1, "A1:B3")
    XCTAssertEqual(usedRange.rowCount, 3)
    XCTAssertEqual(usedRange.columnCount, 2)
    XCTAssertTrue(usedRange.contains(CellAddress(row: 1, column: 1)))
    XCTAssertFalse(usedRange.contains(CellAddress(row: 3, column: 2)))

    let populated = table.populatedCells()
    XCTAssertEqual(populated.count, 6)
    XCTAssertEqual(populated.first?.address, CellAddress(row: 0, column: 0))
    XCTAssertEqual(populated.last?.address, CellAddress(row: 2, column: 1))
  }

  func testDocumentNameAndCountHelpers() throws {
    let fixture = FixtureLocator.fixtureURL(named: "multi-sheet.numbers")
    let document = try NumbersDocument.open(at: fixture)

    XCTAssertEqual(document.sheetNames, ["Sheet A", "Sheet B"])
    XCTAssertEqual(document.tableCount, 3)
    XCTAssertEqual(document.tableNames, ["Sheet A/Table A1", "Sheet B/Table B1", "Sheet B/Table B2"])

    let sheetA = try XCTUnwrap(document.sheet(named: "Sheet A"))
    XCTAssertEqual(sheetA.tableNames, ["Table A1"])
  }

  func testDumpExposesStructuredDiagnostics() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let document = try NumbersDocument.open(at: fixture)
    let dump = document.dump()

    XCTAssertFalse(dump.structuredDiagnostics.isEmpty)
    XCTAssertTrue(
      dump.structuredDiagnostics.contains { diagnostic in
        diagnostic.code == "read-path.fallback" || diagnostic.code == "read-path.editable-overlay"
      })
  }

  func testReadCellMergeRole() throws {
    let fixture = FixtureLocator.fixtureURL(named: "merged-cells.numbers")
    let document = try NumbersDocument.open(at: fixture)
    let table = try XCTUnwrap(document.firstSheet?.firstTable)

    let anchor = try XCTUnwrap(table.readCell("A1"))
    XCTAssertEqual(anchor.mergeRole, .anchor)
    XCTAssertTrue(anchor.isMerged)

    let member = try XCTUnwrap(table.readCell("B2"))
    XCTAssertEqual(member.mergeRole, .member)
    XCTAssertTrue(member.isMerged)
  }

  func testDecodeRowsToDecodableModel() throws {
    let table = Table(
      id: "t1",
      name: "Table 1",
      metadata: TableMetadata(rowCount: 3, columnCount: 2, mergeRanges: []),
      cells: [
        CellAddress(row: 0, column: 0): .string("name"),
        CellAddress(row: 0, column: 1): .string("amount"),
        CellAddress(row: 1, column: 0): .string("Alice"),
        CellAddress(row: 1, column: 1): .number(12.5),
        CellAddress(row: 2, column: 0): .string("Bob"),
        CellAddress(row: 2, column: 1): .number(3.0),
      ]
    )

    let rows = try table.decodeRows(as: SimpleRow.self, headerRow: 0)
    XCTAssertEqual(
      rows,
      [SimpleRow(name: "Alice", amount: 12.5), SimpleRow(name: "Bob", amount: 3.0)]
    )
  }

  func testFormulaReadAPI() throws {
    let formulaAddress = CellAddress(row: 1, column: 1)
    let table = Table(
      id: "formula-table",
      name: "Formula Table",
      metadata: TableMetadata(rowCount: 3, columnCount: 3, mergeRanges: []),
      cells: [formulaAddress: .string("=SUM(A1:A2)")],
      readCells: [
        formulaAddress: ReadCell(
          address: formulaAddress,
          value: .string("=SUM(A1:A2)"),
          kind: .formula,
          formatted: "7",
          rawCellType: 4,
          formulaID: 77
        )
      ]
    )

    let formula = try XCTUnwrap(table.formula("B2"))
    XCTAssertEqual(formula.formulaID, 77)
    XCTAssertEqual(formula.rawFormula, "=SUM(A1:A2)")
    XCTAssertEqual(formula.parsedTokens, ["=", "SUM", "(", "A1", ":", "A2", ")"])
    XCTAssertEqual(formula.resultFormatted, "7")

    let all = table.formulas()
    XCTAssertEqual(all.count, 1)
    XCTAssertEqual(all[0].reference, "B2")
  }
}
