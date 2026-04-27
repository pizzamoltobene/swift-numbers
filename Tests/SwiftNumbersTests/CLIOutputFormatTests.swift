import Foundation
import XCTest

@testable import SwiftNumbersCore

final class CLIOutputFormatTests: XCTestCase {
  func testDumpSupportsJSONFormat() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: ["dump", fixture.path, "--format", "json"])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]

    XCTAssertEqual(decoded?["readPath"] as? String, "real")
    XCTAssertEqual(decoded?["sheetCount"] as? Int, 1)
    XCTAssertEqual(decoded?["tableCount"] as? Int, 1)
    XCTAssertEqual(decoded?["resolvedCellCount"] as? Int, 6)
    XCTAssertEqual(decoded?["sheetNames"] as? [String], ["Sheet 1"])
    XCTAssertEqual(decoded?["tableNames"] as? [String], ["Sheet 1/Table 1"])

    let structured = decoded?["structuredDiagnostics"] as? [[String: Any]]
    XCTAssertNotNil(structured)
  }

  func testDumpJSONIncludesPresentationMetadataInTableSummaries() throws {
    let fixture = try makeFixtureWithPresentationMetadata()
    defer {
      try? FileManager.default.removeItem(at: fixture)
    }

    let output = try runCLI(arguments: ["dump", fixture.path, "--format", "json"])
    let decoded = try decodeJSONObject(output)
    let sheets = try XCTUnwrap(decoded["sheets"] as? [[String: Any]])
    let firstSheet = try XCTUnwrap(sheets.first)
    let tables = try XCTUnwrap(firstSheet["tables"] as? [[String: Any]])
    let firstTable = try XCTUnwrap(tables.first)

    XCTAssertEqual(firstTable["tableNameVisible"] as? Bool, false)
    XCTAssertEqual(firstTable["captionVisible"] as? Bool, false)
    XCTAssertEqual(firstTable["captionTextSupported"] as? Bool, true)
    XCTAssertEqual(firstTable["captionText"] as? String, "CLI metadata caption")
  }

  func testDumpSupportsJSONFormatWithFormulasFlag() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: ["dump", fixture.path, "--format", "json", "--formulas"])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]

    XCTAssertEqual(decoded?["formulaCount"] as? Int, 0)
    let formulas = decoded?["formulas"] as? [[String: Any]]
    XCTAssertEqual(formulas?.count, 0)
  }

  func testDumpSupportsJSONFormatWithCellsFlag() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: ["dump", fixture.path, "--format", "json", "--cells"])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]

    XCTAssertEqual(decoded?["cellCount"] as? Int, 6)
    let cells = try XCTUnwrap(decoded?["cells"] as? [[String: Any]])
    XCTAssertEqual(cells.count, 6)

    let first = try XCTUnwrap(cells.first)
    XCTAssertEqual(first["sheetName"] as? String, "Sheet 1")
    XCTAssertEqual(first["tableName"] as? String, "Table 1")
    XCTAssertEqual(first["cellReference"] as? String, "A2")
    XCTAssertEqual(first["kind"] as? String, "text")

    let readValue = try XCTUnwrap(first["readValue"] as? [String: Any])
    XCTAssertEqual(readValue["kind"] as? String, "string")
    XCTAssertEqual(readValue["string"] as? String, "Name")
  }

  func testDumpSupportsJSONFormatWithFormattingFlag() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: ["dump", fixture.path, "--format", "json", "--formatting"])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]

    XCTAssertEqual(decoded?["formattingCount"] as? Int, 6)
    let formatting = try XCTUnwrap(decoded?["formatting"] as? [[String: Any]])
    XCTAssertEqual(formatting.count, 6)

    let numberCell = try XCTUnwrap(
      formatting.first(where: { ($0["cellReference"] as? String) == "B3" })
    )
    XCTAssertEqual(numberCell["kind"] as? String, "number")
    XCTAssertNotNil(numberCell["defaultFormatted"] as? String)
    XCTAssertNotNil(numberCell["decimal"] as? String)
    XCTAssertNotNil(numberCell["currencyUSD"] as? String)
    XCTAssertNotNil(numberCell["percent"] as? String)
    XCTAssertNotNil(numberCell["scientific"] as? String)
  }

  func testDumpSupportsTextFormatWithFormulasFlag() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: ["dump", fixture.path, "--formulas"])

    XCTAssertTrue(output.contains("Formulas: 0"))
    XCTAssertTrue(output.contains("<none>"))
  }

  func testListSheetsSupportsJSONFormat() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "multi-sheet.numbers")
    let output = try runCLI(arguments: ["list-sheets", fixture.path, "--format", "json"])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
    let sheets = try XCTUnwrap(decoded?["sheets"] as? [[String: Any]])

    XCTAssertEqual(sheets.count, 2)
    XCTAssertEqual(sheets[0]["index"] as? Int, 1)
    XCTAssertEqual(sheets[0]["name"] as? String, "Sheet 1")
    XCTAssertEqual(sheets[1]["index"] as? Int, 2)
    XCTAssertEqual(sheets[1]["name"] as? String, "Sheet B")
  }

  func testListTablesSupportsJSONFormat() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "multi-sheet.numbers")
    let output = try runCLI(arguments: ["list-tables", fixture.path, "--format", "json"])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
    let tableCount = decoded?["tableCount"] as? Int
    let tables = try XCTUnwrap(decoded?["tables"] as? [[String: Any]])

    XCTAssertEqual(tableCount, 3)
    XCTAssertEqual(tables.count, 3)
    XCTAssertEqual(tables[0]["sheetName"] as? String, "Sheet 1")
    XCTAssertEqual(tables[0]["tableName"] as? String, "Table 1")
    XCTAssertEqual(tables[1]["sheetName"] as? String, "Sheet B")
    XCTAssertEqual(tables[1]["tableName"] as? String, "Table 1")
    XCTAssertEqual(tables[2]["sheetName"] as? String, "Sheet B")
    XCTAssertEqual(tables[2]["tableName"] as? String, "Table B2")
  }

  func testListTablesSupportsSheetFilter() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "multi-sheet.numbers")
    let output = try runCLI(arguments: [
      "list-tables", fixture.path, "--sheet", "Sheet B", "--format", "json",
    ])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
    let tableCount = decoded?["tableCount"] as? Int
    let filter = decoded?["sheetFilter"] as? String
    let tables = try XCTUnwrap(decoded?["tables"] as? [[String: Any]])

    XCTAssertEqual(filter, "Sheet B")
    XCTAssertEqual(tableCount, 2)
    XCTAssertEqual(tables.count, 2)
    XCTAssertEqual(Set(tables.compactMap { $0["sheetName"] as? String }), Set(["Sheet B"]))
    XCTAssertEqual(Set(tables.compactMap { $0["tableName"] as? String }), Set(["Table 1", "Table B2"]))
  }

  func testListTablesJSONIncludesPresentationMetadata() throws {
    let fixture = try makeFixtureWithPresentationMetadata()
    defer {
      try? FileManager.default.removeItem(at: fixture)
    }

    let output = try runCLI(arguments: [
      "list-tables",
      fixture.path,
      "--sheet",
      "Sheet 1",
      "--format",
      "json",
    ])
    let decoded = try decodeJSONObject(output)
    let tables = try XCTUnwrap(decoded["tables"] as? [[String: Any]])
    let firstTable = try XCTUnwrap(tables.first)

    XCTAssertEqual(firstTable["tableNameVisible"] as? Bool, false)
    XCTAssertEqual(firstTable["captionVisible"] as? Bool, false)
    XCTAssertEqual(firstTable["captionTextSupported"] as? Bool, true)
    XCTAssertEqual(firstTable["captionText"] as? String, "CLI metadata caption")
  }

  func testListFormulasSupportsJSONFormat() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: ["list-formulas", fixture.path, "--format", "json"])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
    let formulas = try XCTUnwrap(decoded?["formulas"] as? [[String: Any]])

    XCTAssertEqual(decoded?["formulaCount"] as? Int, 0)
    XCTAssertEqual(formulas.count, 0)
  }

  func testListFormulasSupportsSheetAndTableFilters() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "list-formulas",
      fixture.path,
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--format",
      "json",
    ])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]

    XCTAssertEqual(decoded?["sheetFilter"] as? String, "Sheet 1")
    XCTAssertEqual(decoded?["tableFilter"] as? String, "Table 1")
    XCTAssertEqual(decoded?["formulaCount"] as? Int, 0)
  }

  func testReadCellSupportsJSONFormat() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-cell", fixture.path, "A2", "--sheet", "Sheet 1", "--table", "Table 1", "--format", "json",
    ])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
    let value = try XCTUnwrap(decoded?["value"] as? [String: Any])
    let readValue = try XCTUnwrap(decoded?["readValue"] as? [String: Any])
    let merge = try XCTUnwrap(decoded?["merge"] as? [String: Any])

    XCTAssertEqual(decoded?["sheetName"] as? String, "Sheet 1")
    XCTAssertEqual(decoded?["tableName"] as? String, "Table 1")
    XCTAssertEqual(decoded?["cellReference"] as? String, "A2")
    XCTAssertEqual(decoded?["row"] as? Int, 1)
    XCTAssertEqual(decoded?["column"] as? Int, 0)
    XCTAssertEqual(decoded?["kind"] as? String, "text")
    XCTAssertEqual(value["kind"] as? String, "string")
    XCTAssertEqual(value["string"] as? String, "Name")
    XCTAssertEqual(readValue["kind"] as? String, "string")
    XCTAssertEqual(readValue["string"] as? String, "Name")
    XCTAssertEqual(merge["isMerged"] as? Bool, false)
    XCTAssertEqual(merge["role"] as? String, "none")
  }

  func testReadCellSupportsIndexSelectionJSONFormat() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "multi-sheet.numbers")
    let output = try runCLI(arguments: [
      "read-cell",
      fixture.path,
      "A1",
      "--sheet-index",
      "1",
      "--table-index",
      "1",
      "--format",
      "json",
    ])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
    let value = try XCTUnwrap(decoded?["value"] as? [String: Any])

    XCTAssertEqual(decoded?["sheetName"] as? String, "Sheet B")
    XCTAssertEqual(decoded?["tableName"] as? String, "Table B2")
    XCTAssertEqual(decoded?["cellReference"] as? String, "A1")
    XCTAssertEqual(value["kind"] as? String, "string")
    XCTAssertEqual(value["string"] as? String, "Flag")
  }

  func testReadCellRejectsConflictingSheetSelectorsDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-cell",
      fixture.path,
      "A1",
      "--sheet",
      "Sheet 1",
      "--sheet-index",
      "0",
      "--table",
      "Table 1",
    ])

    XCTAssertTrue(result.stderr.contains("Provide either --sheet or --sheet-index"))
  }

  func testReadCellRejectsConflictingTableSelectorsDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-cell",
      fixture.path,
      "A1",
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--table-index",
      "0",
    ])

    XCTAssertTrue(result.stderr.contains("Provide either --table or --table-index"))
  }

  func testReadCellRejectsMissingSheetSelectorDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-cell",
      fixture.path,
      "A1",
      "--table",
      "Table 1",
    ])

    XCTAssertTrue(result.stderr.contains("Missing sheet selector"))
  }

  func testReadCellRejectsMissingTableSelectorDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-cell",
      fixture.path,
      "A1",
      "--sheet",
      "Sheet 1",
    ])

    XCTAssertTrue(result.stderr.contains("Missing table selector"))
  }

  func testReadCellRejectsOutOfBoundsSheetIndexDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "multi-sheet.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-cell",
      fixture.path,
      "A1",
      "--sheet-index",
      "99",
      "--table-index",
      "0",
    ])

    XCTAssertTrue(result.stderr.contains("Sheet index 99 is out of bounds"))
  }

  func testReadRangeRejectsConflictingSheetSelectorsDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-range",
      fixture.path,
      "A1:A1",
      "--sheet",
      "Sheet 1",
      "--sheet-index",
      "0",
      "--table",
      "Table 1",
    ])

    XCTAssertTrue(result.stderr.contains("Provide either --sheet or --sheet-index"))
  }

  func testReadRangeRejectsConflictingTableSelectorsDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-range",
      fixture.path,
      "A1:A1",
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--table-index",
      "0",
    ])

    XCTAssertTrue(result.stderr.contains("Provide either --table or --table-index"))
  }

  func testReadRangeRejectsMissingSheetSelectorDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-range",
      fixture.path,
      "A1:A1",
      "--table",
      "Table 1",
    ])

    XCTAssertTrue(result.stderr.contains("Missing sheet selector"))
  }

  func testReadRangeRejectsMissingTableSelectorDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-range",
      fixture.path,
      "A1:A1",
      "--sheet",
      "Sheet 1",
    ])

    XCTAssertTrue(result.stderr.contains("Missing table selector"))
  }

  func testReadTableRejectsConflictingSheetSelectorsDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-table",
      fixture.path,
      "--sheet",
      "Sheet 1",
      "--sheet-index",
      "0",
      "--table",
      "Table 1",
    ])

    XCTAssertTrue(result.stderr.contains("Provide either --sheet or --sheet-index"))
  }

  func testReadTableRejectsConflictingTableSelectorsDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-table",
      fixture.path,
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--table-index",
      "0",
    ])

    XCTAssertTrue(result.stderr.contains("Provide either --table or --table-index"))
  }

  func testReadTableRejectsMissingSheetSelectorDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-table",
      fixture.path,
      "--table",
      "Table 1",
    ])

    XCTAssertTrue(result.stderr.contains("Missing sheet selector"))
  }

  func testReadTableRejectsMissingTableSelectorDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-table",
      fixture.path,
      "--sheet",
      "Sheet 1",
    ])

    XCTAssertTrue(result.stderr.contains("Missing table selector"))
  }

  func testReadColumnRejectsConflictingSheetSelectorsDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-column",
      fixture.path,
      "0",
      "--sheet",
      "Sheet 1",
      "--sheet-index",
      "0",
      "--table",
      "Table 1",
    ])

    XCTAssertTrue(result.stderr.contains("Provide either --sheet or --sheet-index"))
  }

  func testReadColumnRejectsConflictingTableSelectorsDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-column",
      fixture.path,
      "0",
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--table-index",
      "0",
    ])

    XCTAssertTrue(result.stderr.contains("Provide either --table or --table-index"))
  }

  func testReadColumnRejectsMissingSheetSelectorDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-column",
      fixture.path,
      "0",
      "--table",
      "Table 1",
    ])

    XCTAssertTrue(result.stderr.contains("Missing sheet selector"))
  }

  func testReadColumnRejectsMissingTableSelectorDeterministically() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIExpectFailure(arguments: [
      "read-column",
      fixture.path,
      "0",
      "--sheet",
      "Sheet 1",
    ])

    XCTAssertTrue(result.stderr.contains("Missing table selector"))
  }

  func testCLIExitCodeContractReturnsZeroOnSuccess() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIRaw(arguments: ["list-sheets", fixture.path, "--format", "json"])

    XCTAssertEqual(result.terminationStatus, 0)
    XCTAssertFalse(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
  }

  func testCLIExitCodeContractReturnsNonZeroOnValidationFailure() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let result = try runCLIRaw(arguments: [
      "read-cell",
      fixture.path,
      "A1",
      "--sheet",
      "Sheet 1",
      "--sheet-index",
      "0",
      "--table",
      "Table 1",
    ])

    XCTAssertNotEqual(result.terminationStatus, 0)
    XCTAssertTrue(result.stderr.contains("Provide either --sheet or --sheet-index"))
  }

  func testCLIExitCodeContractReturnsNonZeroOnOpenFailure() throws {
    let missing = FileManager.default.temporaryDirectory
      .appendingPathComponent("swift-numbers-missing-\(UUID().uuidString).numbers")
    let result = try runCLIRaw(arguments: ["list-sheets", missing.path, "--format", "json"])

    XCTAssertNotEqual(result.terminationStatus, 0)
    XCTAssertFalse(result.stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
  }

  func testReadRangeSupportsJSONFormat() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-range",
      fixture.path,
      "A3:B4",
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--format",
      "json",
    ])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]

    XCTAssertEqual(decoded?["sheetName"] as? String, "Sheet 1")
    XCTAssertEqual(decoded?["tableName"] as? String, "Table 1")
    XCTAssertEqual(decoded?["requestedRange"] as? String, "A3:B4")
    XCTAssertEqual(decoded?["resolvedRange"] as? String, "A3:B4")
    XCTAssertEqual(decoded?["rowCount"] as? Int, 2)
    XCTAssertEqual(decoded?["columnCount"] as? Int, 2)

    let rows = try XCTUnwrap(decoded?["cells"] as? [[Any]])
    XCTAssertEqual(rows.count, 2)
    let firstRow = try XCTUnwrap(rows.first)
    let firstCell = try XCTUnwrap(firstRow.first as? [String: Any])
    let firstReadValue = try XCTUnwrap(firstCell["readValue"] as? [String: Any])

    XCTAssertEqual(firstCell["cellReference"] as? String, "A3")
    XCTAssertEqual(firstCell["kind"] as? String, "text")
    XCTAssertEqual(firstReadValue["kind"] as? String, "string")
    XCTAssertEqual(firstReadValue["string"] as? String, "Answer")
  }

  func testReadRangeSupportsJSONLinesOutput() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-range",
      fixture.path,
      "A3:B4",
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--jsonl",
    ])

    let lines = output
      .split(separator: "\n")
      .map(String.init)
      .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    XCTAssertEqual(lines.count, 2)

    let firstData = try XCTUnwrap(lines.first?.data(using: .utf8))
    let firstJSON = try JSONSerialization.jsonObject(with: firstData) as? [String: Any]
    XCTAssertEqual(firstJSON?["sheetName"] as? String, "Sheet 1")
    XCTAssertEqual(firstJSON?["tableName"] as? String, "Table 1")
    XCTAssertEqual(firstJSON?["resolvedRange"] as? String, "A3:B4")
    XCTAssertEqual(firstJSON?["row"] as? Int, 2)
    XCTAssertEqual(firstJSON?["rowOffset"] as? Int, 0)
    XCTAssertEqual(firstJSON?["columnCount"] as? Int, 2)

    let firstCells = try XCTUnwrap(firstJSON?["cells"] as? [[String: Any]])
    XCTAssertEqual(firstCells.count, 2)
    let firstCell = try XCTUnwrap(firstCells.first)
    let firstReadValue = try XCTUnwrap(firstCell["readValue"] as? [String: Any])
    XCTAssertEqual(firstCell["cellReference"] as? String, "A3")
    XCTAssertEqual(firstReadValue["kind"] as? String, "string")
    XCTAssertEqual(firstReadValue["string"] as? String, "Answer")
  }

  func testReadTableSupportsJSONFormat() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-table",
      fixture.path,
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--from-row",
      "2",
      "--from-column",
      "0",
      "--max-rows",
      "2",
      "--max-columns",
      "2",
      "--format",
      "json",
    ])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]

    XCTAssertEqual(decoded?["sheetName"] as? String, "Sheet 1")
    XCTAssertEqual(decoded?["tableName"] as? String, "Table 1")
    XCTAssertEqual(decoded?["fromRow"] as? Int, 2)
    XCTAssertEqual(decoded?["fromColumn"] as? Int, 0)
    XCTAssertEqual(decoded?["resolvedRowCount"] as? Int, 2)
    XCTAssertEqual(decoded?["resolvedColumnCount"] as? Int, 2)
    XCTAssertEqual(decoded?["truncatedRows"] as? Bool, false)
    XCTAssertEqual(decoded?["truncatedColumns"] as? Bool, true)

    let rows = try XCTUnwrap(decoded?["cells"] as? [[Any]])
    XCTAssertEqual(rows.count, 2)
    let firstRow = try XCTUnwrap(rows.first)
    let firstCell = try XCTUnwrap(firstRow.first as? [String: Any])
    let firstReadValue = try XCTUnwrap(firstCell["readValue"] as? [String: Any])
    XCTAssertEqual(firstCell["cellReference"] as? String, "A3")
    XCTAssertEqual(firstReadValue["kind"] as? String, "string")
    XCTAssertEqual(firstReadValue["string"] as? String, "Answer")
  }

  func testReadTableJSONIncludesPresentationMetadata() throws {
    let fixture = try makeFixtureWithPresentationMetadata()
    defer {
      try? FileManager.default.removeItem(at: fixture)
    }

    let output = try runCLI(arguments: [
      "read-table",
      fixture.path,
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--from-row",
      "0",
      "--from-column",
      "0",
      "--max-rows",
      "1",
      "--max-columns",
      "1",
      "--format",
      "json",
    ])
    let decoded = try decodeJSONObject(output)

    XCTAssertEqual(decoded["tableNameVisible"] as? Bool, false)
    XCTAssertEqual(decoded["captionVisible"] as? Bool, false)
    XCTAssertEqual(decoded["captionTextSupported"] as? Bool, true)
    XCTAssertEqual(decoded["captionText"] as? String, "CLI metadata caption")
  }

  func testReadTableSupportsIndexSelectionJSONFormat() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "multi-sheet.numbers")
    let output = try runCLI(arguments: [
      "read-table",
      fixture.path,
      "--sheet-index",
      "0",
      "--table-index",
      "0",
      "--from-row",
      "0",
      "--from-column",
      "0",
      "--max-rows",
      "1",
      "--max-columns",
      "2",
      "--format",
      "json",
    ])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
    XCTAssertEqual(decoded?["sheetName"] as? String, "Sheet 1")
    XCTAssertEqual(decoded?["tableName"] as? String, "Table 1")

    let rows = try XCTUnwrap(decoded?["cells"] as? [[Any]])
    let firstRow = try XCTUnwrap(rows.first)
    let firstCell = try XCTUnwrap(firstRow.first as? [String: Any])
    let firstReadValue = try XCTUnwrap(firstCell["readValue"] as? [String: Any])
    XCTAssertEqual(firstCell["cellReference"] as? String, "A1")
    XCTAssertNotNil(firstReadValue["kind"] as? String)
  }

  func testReadTableSupportsJSONLinesOutput() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-table",
      fixture.path,
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--from-row",
      "2",
      "--from-column",
      "0",
      "--max-rows",
      "2",
      "--max-columns",
      "2",
      "--jsonl",
    ])

    let lines = output
      .split(separator: "\n")
      .map(String.init)
      .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    XCTAssertEqual(lines.count, 2)

    let firstData = try XCTUnwrap(lines.first?.data(using: .utf8))
    let firstJSON = try JSONSerialization.jsonObject(with: firstData) as? [String: Any]
    XCTAssertEqual(firstJSON?["sheetName"] as? String, "Sheet 1")
    XCTAssertEqual(firstJSON?["tableName"] as? String, "Table 1")
    XCTAssertEqual(firstJSON?["row"] as? Int, 2)

    let firstCells = try XCTUnwrap(firstJSON?["cells"] as? [[String: Any]])
    XCTAssertEqual(firstCells.count, 2)
    let firstCell = try XCTUnwrap(firstCells.first)
    let firstReadValue = try XCTUnwrap(firstCell["readValue"] as? [String: Any])
    XCTAssertEqual(firstCell["cellReference"] as? String, "A3")
    XCTAssertEqual(firstReadValue["kind"] as? String, "string")
    XCTAssertEqual(firstReadValue["string"] as? String, "Answer")
  }

  func testReadTableJSONLinesIncludePresentationMetadata() throws {
    let fixture = try makeFixtureWithPresentationMetadata()
    defer {
      try? FileManager.default.removeItem(at: fixture)
    }

    let output = try runCLI(arguments: [
      "read-table",
      fixture.path,
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--from-row",
      "0",
      "--from-column",
      "0",
      "--max-rows",
      "1",
      "--max-columns",
      "1",
      "--jsonl",
    ])

    let lines = output
      .split(separator: "\n")
      .map(String.init)
      .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    let firstData = try XCTUnwrap(lines.first?.data(using: .utf8))
    let firstJSON = try JSONSerialization.jsonObject(with: firstData) as? [String: Any]

    XCTAssertEqual(firstJSON?["tableNameVisible"] as? Bool, false)
    XCTAssertEqual(firstJSON?["captionVisible"] as? Bool, false)
    XCTAssertEqual(firstJSON?["captionTextSupported"] as? Bool, true)
    XCTAssertEqual(firstJSON?["captionText"] as? String, "CLI metadata caption")
  }

  func testReadCellJSONSnapshotGolden() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    try assertCLIJSONSnapshot(
      arguments: [
        "read-cell",
        fixture.path,
        "A2",
        "--sheet",
        "Sheet 1",
        "--table",
        "Table 1",
        "--format",
        "json",
      ],
      goldenName: "read-cell-simple-table.json"
    )
  }

  func testReadRangeJSONSnapshotGolden() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    try assertCLIJSONSnapshot(
      arguments: [
        "read-range",
        fixture.path,
        "A3:B4",
        "--sheet",
        "Sheet 1",
        "--table",
        "Table 1",
        "--format",
        "json",
      ],
      goldenName: "read-range-simple-table.json"
    )
  }

  func testReadTableJSONSnapshotGolden() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    try assertCLIJSONSnapshot(
      arguments: [
        "read-table",
        fixture.path,
        "--sheet",
        "Sheet 1",
        "--table",
        "Table 1",
        "--from-row",
        "2",
        "--from-column",
        "0",
        "--max-rows",
        "2",
        "--max-columns",
        "2",
        "--format",
        "json",
      ],
      goldenName: "read-table-simple-table.json"
    )
  }

  func testReadColumnSupportsJSONFormat() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-column",
      fixture.path,
      "0",
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--from-row",
      "2",
      "--format",
      "json",
    ])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]

    XCTAssertEqual(decoded?["sheetName"] as? String, "Sheet 1")
    XCTAssertEqual(decoded?["tableName"] as? String, "Table 1")
    XCTAssertEqual(decoded?["columnIndex"] as? Int, 0)
    XCTAssertEqual(decoded?["fromRow"] as? Int, 2)
    XCTAssertEqual(decoded?["cellCount"] as? Int, 2)

    let cells = try XCTUnwrap(decoded?["cells"] as? [[String: Any]])
    XCTAssertEqual(cells.count, 2)

    let first = try XCTUnwrap(cells.first)
    let firstReadValue = try XCTUnwrap(first["readValue"] as? [String: Any])
    XCTAssertEqual(first["cellReference"] as? String, "A3")
    XCTAssertEqual(firstReadValue["kind"] as? String, "string")
    XCTAssertEqual(firstReadValue["string"] as? String, "Answer")

    let last = try XCTUnwrap(cells.last)
    let lastReadValue = try XCTUnwrap(last["readValue"] as? [String: Any])
    XCTAssertEqual(last["cellReference"] as? String, "A4")
    XCTAssertEqual(lastReadValue["kind"] as? String, "string")
    XCTAssertEqual(lastReadValue["string"] as? String, "Enabled")
  }

  func testReadColumnSupportsHeaderSelectionJSONFormat() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-column",
      fixture.path,
      "--header",
      "Name",
      "--header-row",
      "1",
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--format",
      "json",
    ])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]

    XCTAssertEqual(decoded?["selectionMode"] as? String, "header")
    XCTAssertEqual(decoded?["requestedHeader"] as? String, "Name")
    XCTAssertEqual(decoded?["headerRow"] as? Int, 1)
    XCTAssertEqual(decoded?["includeHeader"] as? Bool, false)
    XCTAssertEqual(decoded?["columnIndex"] as? Int, 0)
    XCTAssertEqual(decoded?["fromRow"] as? Int, 2)
    XCTAssertEqual(decoded?["cellCount"] as? Int, 2)

    let cells = try XCTUnwrap(decoded?["cells"] as? [[String: Any]])
    XCTAssertEqual(cells.count, 2)
    XCTAssertEqual(cells.first?["cellReference"] as? String, "A3")
  }

  func testReadColumnSupportsHeaderSelectionWithIncludeHeaderJSONFormat() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-column",
      fixture.path,
      "--header",
      "Name",
      "--include-header",
      "--header-row",
      "1",
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--format",
      "json",
    ])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]

    XCTAssertEqual(decoded?["selectionMode"] as? String, "header")
    XCTAssertEqual(decoded?["includeHeader"] as? Bool, true)
    XCTAssertEqual(decoded?["fromRow"] as? Int, 1)
    XCTAssertEqual(decoded?["cellCount"] as? Int, 3)

    let cells = try XCTUnwrap(decoded?["cells"] as? [[String: Any]])
    XCTAssertEqual(cells.count, 3)

    let first = try XCTUnwrap(cells.first)
    let firstReadValue = try XCTUnwrap(first["readValue"] as? [String: Any])
    XCTAssertEqual(first["cellReference"] as? String, "A2")
    XCTAssertEqual(firstReadValue["kind"] as? String, "string")
    XCTAssertEqual(firstReadValue["string"] as? String, "Name")
  }

  func testReadColumnSupportsJSONLinesOutput() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-column",
      fixture.path,
      "0",
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--from-row",
      "2",
      "--jsonl",
    ])

    let lines = output
      .split(separator: "\n")
      .map(String.init)
      .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    XCTAssertEqual(lines.count, 2)

    let firstData = try XCTUnwrap(lines.first?.data(using: .utf8))
    let firstJSON = try JSONSerialization.jsonObject(with: firstData) as? [String: Any]
    XCTAssertEqual(firstJSON?["sheetName"] as? String, "Sheet 1")
    XCTAssertEqual(firstJSON?["tableName"] as? String, "Table 1")

    let firstCell = try XCTUnwrap(firstJSON?["cell"] as? [String: Any])
    let firstReadValue = try XCTUnwrap(firstCell["readValue"] as? [String: Any])
    XCTAssertEqual(firstCell["cellReference"] as? String, "A3")
    XCTAssertEqual(firstReadValue["kind"] as? String, "string")
    XCTAssertEqual(firstReadValue["string"] as? String, "Answer")
  }

  func testExportCSVCommandHelpIncludesSelectorsAndMode() throws {
    let output = try runCLI(arguments: ["export-csv", "--help"])
    XCTAssertTrue(output.contains("export-csv"))
    XCTAssertTrue(output.contains("--sheet-index"))
    XCTAssertTrue(output.contains("--table-index"))
    XCTAssertTrue(output.contains("--mode"))
  }

  func testExportCSVUsesValueModeByDefault() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "export-csv",
      fixture.path,
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
    ])

    XCTAssertEqual(
      csvLines(output),
      [
        ",,",
        "Name,Value,",
        "Answer,42,",
        "Enabled,TRUE,",
      ]
    )
  }

  func testExportCSVSupportsFormattedMode() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "export-csv",
      fixture.path,
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--mode",
      "formatted",
    ])

    XCTAssertEqual(
      csvLines(output),
      [
        ",,",
        "Name,Value,",
        "Answer,42,",
        "Enabled,TRUE,",
      ]
    )
  }

  func testExportCSVSupportsFormulaModeWithFormattedFallback() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "export-csv",
      fixture.path,
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--mode",
      "formula",
    ])

    XCTAssertEqual(
      csvLines(output),
      [
        ",,",
        "Name,Value,",
        "Answer,42,",
        "Enabled,TRUE,",
      ]
    )
  }

  func testExportCSVWritesToOutputFileWhenRequested() throws {
    let fixture = StrictFixtureFactory.fixtureURL(named: "simple-table.numbers")
    let destination = FileManager.default.temporaryDirectory
      .appendingPathComponent("swift-numbers-export-\(UUID().uuidString).csv")

    defer {
      try? FileManager.default.removeItem(at: destination)
    }

    let output = try runCLI(arguments: [
      "export-csv",
      fixture.path,
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--output",
      destination.path,
    ])

    XCTAssertTrue(output.contains("Exported CSV to"))
    let written = try String(contentsOf: destination, encoding: .utf8)
    XCTAssertEqual(
      csvLines(written),
      [
        ",,",
        "Name,Value,",
        "Answer,42,",
        "Enabled,TRUE,",
      ]
    )
  }

  func testImportCSVCommandHelpIncludesHeaderAndDateOptions() throws {
    let output = try runCLI(arguments: ["import-csv", "--help"])
    XCTAssertTrue(output.contains("import-csv"))
    XCTAssertTrue(output.contains("--header"))
    XCTAssertTrue(output.contains("--parse-dates"))
    XCTAssertTrue(output.contains("--output"))
  }

  func testImportCSVWithHeaderAndDateParsingProducesTypedCells() throws {
    let sourceFixture = try copyFixtureToTemporaryPath(named: "simple-table.numbers")
    let outputFixture = FileManager.default.temporaryDirectory
      .appendingPathComponent("swift-numbers-import-output-\(UUID().uuidString).numbers")
    let csv = try writeTemporaryCSV(
      """
      Name,Value,When
      Alpha,101.5,2026-01-02
      Beta,TRUE,2026-01-03T10:00:00Z
      """
    )

    defer {
      try? FileManager.default.removeItem(at: sourceFixture)
      try? FileManager.default.removeItem(at: outputFixture)
      try? FileManager.default.removeItem(at: csv)
    }

    let output = try runCLI(arguments: [
      "import-csv",
      sourceFixture.path,
      csv.path,
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--parse-dates",
      "--output",
      outputFixture.path,
    ])
    XCTAssertFalse(output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

    let document = try NumbersDocument.open(at: outputFixture)
    let table = try XCTUnwrap(document.sheet(named: "Sheet 1")?.table(named: "Table 1"))
    let values = table.populatedCells(sorted: false).map(\.value)
    XCTAssertTrue(values.contains(.string("Name")))
    XCTAssertTrue(values.contains(.string("Value")))
    XCTAssertTrue(values.contains(.string("When")))
    XCTAssertTrue(values.contains(.string("Alpha")))
    XCTAssertTrue(values.contains(.number(101.5)))
    XCTAssertTrue(values.contains(.string("Beta")))
    XCTAssertTrue(values.contains(.bool(true)))
    XCTAssertTrue(
      values.contains { value in
        if case .date = value {
          return true
        }
        return false
      }
    )
  }

  func testImportCSVNoHeaderModeGeneratesDefaultHeaderRow() throws {
    let sourceFixture = try copyFixtureToTemporaryPath(named: "simple-table.numbers")
    let outputFixture = FileManager.default.temporaryDirectory
      .appendingPathComponent("swift-numbers-import-no-header-\(UUID().uuidString).numbers")
    let csv = try writeTemporaryCSV(
      """
      2026-01-02,42
      2026-01-03,17
      """
    )

    defer {
      try? FileManager.default.removeItem(at: sourceFixture)
      try? FileManager.default.removeItem(at: outputFixture)
      try? FileManager.default.removeItem(at: csv)
    }

    let output = try runCLI(arguments: [
      "import-csv",
      sourceFixture.path,
      csv.path,
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--header",
      "no-header",
      "--parse-dates",
      "--output",
      outputFixture.path,
    ])
    XCTAssertFalse(output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

    let document = try NumbersDocument.open(at: outputFixture)
    let table = try XCTUnwrap(document.sheet(named: "Sheet 1")?.table(named: "Table 1"))
    let values = table.populatedCells(sorted: false).map(\.value)
    XCTAssertTrue(values.contains(.string("Column 1")))
    XCTAssertTrue(values.contains(.string("Column 2")))
    XCTAssertTrue(values.contains(.number(42)))
    XCTAssertTrue(values.contains(.number(17)))
    XCTAssertTrue(
      values.contains { value in
        if case .date = value {
          return true
        }
        return false
      }
    )
  }

  private func csvLines(_ output: String) -> [String] {
    output.split(separator: "\n").map(String.init)
  }

  private func assertCLIJSONSnapshot(arguments: [String], goldenName: String) throws {
    let output = try runCLI(arguments: arguments)
    let normalizedOutput = try normalizeSnapshotJSON(output)
    let expected = try loadCLIGolden(named: goldenName)
    let normalizedExpected = try normalizeSnapshotJSON(expected)
    XCTAssertEqual(normalizedOutput, normalizedExpected)
  }

  private func normalizeSnapshotJSON(_ raw: String) throws -> String {
    let data = try XCTUnwrap(raw.data(using: .utf8))
    var object = try JSONSerialization.jsonObject(with: data)
    if var payload = object as? [String: Any], payload["sourcePath"] != nil {
      payload["sourcePath"] = "<fixture>"
      object = payload
    }

    let normalizedData = try JSONSerialization.data(
      withJSONObject: object,
      options: [.prettyPrinted, .sortedKeys]
    )
    return try XCTUnwrap(String(data: normalizedData, encoding: .utf8))
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func loadCLIGolden(named name: String) throws -> String {
    let goldenURL = FixtureLocator.repoRoot
      .appendingPathComponent("Tests", isDirectory: true)
      .appendingPathComponent("SwiftNumbersTests", isDirectory: true)
      .appendingPathComponent("Goldens", isDirectory: true)
      .appendingPathComponent(name, isDirectory: false)
    return try String(contentsOf: goldenURL, encoding: .utf8)
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func decodeJSONObject(_ output: String) throws -> [String: Any] {
    let payload = try XCTUnwrap(output.data(using: .utf8))
    return try XCTUnwrap(JSONSerialization.jsonObject(with: payload) as? [String: Any])
  }

  private func copyFixtureToTemporaryPath(named name: String) throws -> URL {
    let source = StrictFixtureFactory.fixtureURL(named: name)
    let destination = FileManager.default.temporaryDirectory
      .appendingPathComponent("swift-numbers-fixture-\(UUID().uuidString).numbers")
    try FileManager.default.copyItem(at: source, to: destination)
    return destination
  }

  private func writeTemporaryCSV(_ content: String) throws -> URL {
    let destination = FileManager.default.temporaryDirectory
      .appendingPathComponent("swift-numbers-import-\(UUID().uuidString).csv")
    try content.write(to: destination, atomically: true, encoding: .utf8)
    return destination
  }

  private func makeFixtureWithPresentationMetadata() throws -> URL {
    let fixture = try copyFixtureToTemporaryPath(named: "simple-table.numbers")
    let editable = try EditableNumbersDocument.open(at: fixture)
    let table = try editable.sheet(named: "Sheet 1").table(named: "Table 1")
    try table.setTableNameVisible(false)
    try table.setCaptionVisible(false)
    try table.setCaptionText("CLI metadata caption")
    try editable.saveInPlace()
    return fixture
  }

  private func runCLI(arguments: [String]) throws -> String {
    let result = try runCLIRaw(arguments: arguments)
    XCTAssertEqual(result.terminationStatus, 0, "CLI failed: \(result.stderr)")
    return result.stdout
  }

  private struct CLIExecutionResult {
    let stdout: String
    let stderr: String
    let terminationStatus: Int32
  }

  private func runCLIExpectFailure(arguments: [String]) throws -> CLIExecutionResult {
    let result = try runCLIRaw(arguments: arguments)
    XCTAssertNotEqual(result.terminationStatus, 0, "CLI was expected to fail.")
    return result
  }

  private func runCLIRaw(arguments: [String]) throws -> CLIExecutionResult {
    let executable = try resolveCLIExecutable()

    let process = Process()
    process.currentDirectoryURL = FixtureLocator.repoRoot
    process.executableURL = executable
    process.arguments = arguments

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    try process.run()
    process.waitUntilExit()

    let stdout =
      String(
        data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(),
        encoding: .utf8
      ) ?? ""
    let stderr =
      String(
        data: stderrPipe.fileHandleForReading.readDataToEndOfFile(),
        encoding: .utf8
      ) ?? ""
    return CLIExecutionResult(
      stdout: stdout,
      stderr: stderr,
      terminationStatus: process.terminationStatus
    )
  }

  private func resolveCLIExecutable() throws -> URL {
    let showBinPath = Process()
    showBinPath.currentDirectoryURL = FixtureLocator.repoRoot
    showBinPath.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    showBinPath.arguments = ["swift", "build", "--show-bin-path", "-c", "debug"]
    let outputPipe = Pipe()
    showBinPath.standardOutput = outputPipe
    showBinPath.standardError = Pipe()

    try showBinPath.run()
    showBinPath.waitUntilExit()
    XCTAssertEqual(showBinPath.terminationStatus, 0)

    let binPathOutput =
      String(
        data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
        encoding: .utf8
      ) ?? ""
    let binPath = URL(
      fileURLWithPath: binPathOutput.trimmingCharacters(in: .whitespacesAndNewlines))
    let executable = binPath.appendingPathComponent("swiftnumbers")

    if !FileManager.default.fileExists(atPath: executable.path) {
      let build = Process()
      build.currentDirectoryURL = FixtureLocator.repoRoot
      build.executableURL = URL(fileURLWithPath: "/usr/bin/env")
      build.arguments = ["swift", "build", "--product", "swiftnumbers", "-c", "debug"]
      build.standardOutput = Pipe()
      build.standardError = Pipe()
      try build.run()
      build.waitUntilExit()
      XCTAssertEqual(build.terminationStatus, 0)
    }

    return executable
  }
}
