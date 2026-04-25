import Foundation
import XCTest

final class CLIOutputFormatTests: XCTestCase {
  func testDumpSupportsJSONFormat() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: ["dump", fixture.path, "--format", "json"])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]

    XCTAssertEqual(decoded?["readPath"] as? String, "metadataFallback")
    XCTAssertEqual(decoded?["sheetCount"] as? Int, 1)
    XCTAssertEqual(decoded?["tableCount"] as? Int, 1)
    XCTAssertEqual(decoded?["resolvedCellCount"] as? Int, 6)
    XCTAssertEqual(decoded?["sheetNames"] as? [String], ["Sheet 1"])
    XCTAssertEqual(decoded?["tableNames"] as? [String], ["Sheet 1/Table 1"])

    let structured = decoded?["structuredDiagnostics"] as? [[String: Any]]
    XCTAssertNotNil(structured)
  }

  func testDumpSupportsJSONFormatWithFormulasFlag() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: ["dump", fixture.path, "--format", "json", "--formulas"])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]

    XCTAssertEqual(decoded?["formulaCount"] as? Int, 0)
    let formulas = decoded?["formulas"] as? [[String: Any]]
    XCTAssertEqual(formulas?.count, 0)
  }

  func testDumpSupportsJSONFormatWithCellsFlag() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: ["dump", fixture.path, "--format", "json", "--cells"])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]

    XCTAssertEqual(decoded?["cellCount"] as? Int, 6)
    let cells = try XCTUnwrap(decoded?["cells"] as? [[String: Any]])
    XCTAssertEqual(cells.count, 6)

    let first = try XCTUnwrap(cells.first)
    XCTAssertEqual(first["sheetName"] as? String, "Sheet 1")
    XCTAssertEqual(first["tableName"] as? String, "Table 1")
    XCTAssertEqual(first["cellReference"] as? String, "A1")
    XCTAssertEqual(first["kind"] as? String, "text")

    let readValue = try XCTUnwrap(first["readValue"] as? [String: Any])
    XCTAssertEqual(readValue["kind"] as? String, "string")
    XCTAssertEqual(readValue["string"] as? String, "Name")
  }

  func testDumpSupportsJSONFormatWithFormattingFlag() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: ["dump", fixture.path, "--format", "json", "--formatting"])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]

    XCTAssertEqual(decoded?["formattingCount"] as? Int, 6)
    let formatting = try XCTUnwrap(decoded?["formatting"] as? [[String: Any]])
    XCTAssertEqual(formatting.count, 6)

    let numberCell = try XCTUnwrap(
      formatting.first(where: { ($0["cellReference"] as? String) == "B2" })
    )
    XCTAssertEqual(numberCell["kind"] as? String, "number")
    XCTAssertNotNil(numberCell["defaultFormatted"] as? String)
    XCTAssertNotNil(numberCell["decimal"] as? String)
    XCTAssertNotNil(numberCell["currencyUSD"] as? String)
    XCTAssertNotNil(numberCell["percent"] as? String)
    XCTAssertNotNil(numberCell["scientific"] as? String)
  }

  func testDumpSupportsTextFormatWithFormulasFlag() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: ["dump", fixture.path, "--formulas"])

    XCTAssertTrue(output.contains("Formulas: 0"))
    XCTAssertTrue(output.contains("<none>"))
  }

  func testListSheetsSupportsJSONFormat() throws {
    let fixture = FixtureLocator.fixtureURL(named: "multi-sheet.numbers")
    let output = try runCLI(arguments: ["list-sheets", fixture.path, "--format", "json"])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
    let sheets = try XCTUnwrap(decoded?["sheets"] as? [[String: Any]])

    XCTAssertEqual(sheets.count, 2)
    XCTAssertEqual(sheets[0]["index"] as? Int, 1)
    XCTAssertEqual(sheets[0]["name"] as? String, "Sheet A")
    XCTAssertEqual(sheets[1]["index"] as? Int, 2)
    XCTAssertEqual(sheets[1]["name"] as? String, "Sheet B")
  }

  func testListTablesSupportsJSONFormat() throws {
    let fixture = FixtureLocator.fixtureURL(named: "multi-sheet.numbers")
    let output = try runCLI(arguments: ["list-tables", fixture.path, "--format", "json"])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
    let tableCount = decoded?["tableCount"] as? Int
    let tables = try XCTUnwrap(decoded?["tables"] as? [[String: Any]])

    XCTAssertEqual(tableCount, 3)
    XCTAssertEqual(tables.count, 3)
    XCTAssertEqual(tables[0]["sheetName"] as? String, "Sheet A")
    XCTAssertEqual(tables[0]["tableName"] as? String, "Table A1")
    XCTAssertEqual(tables[1]["sheetName"] as? String, "Sheet B")
    XCTAssertEqual(tables[1]["tableName"] as? String, "Table B1")
    XCTAssertEqual(tables[2]["sheetName"] as? String, "Sheet B")
    XCTAssertEqual(tables[2]["tableName"] as? String, "Table B2")
  }

  func testListTablesSupportsSheetFilter() throws {
    let fixture = FixtureLocator.fixtureURL(named: "multi-sheet.numbers")
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
    XCTAssertEqual(Set(tables.compactMap { $0["tableName"] as? String }), Set(["Table B1", "Table B2"]))
  }

  func testListFormulasSupportsJSONFormat() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: ["list-formulas", fixture.path, "--format", "json"])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
    let formulas = try XCTUnwrap(decoded?["formulas"] as? [[String: Any]])

    XCTAssertEqual(decoded?["formulaCount"] as? Int, 0)
    XCTAssertEqual(formulas.count, 0)
  }

  func testListFormulasSupportsSheetAndTableFilters() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
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
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-cell", fixture.path, "A1", "--sheet", "Sheet 1", "--table", "Table 1", "--format", "json",
    ])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
    let value = try XCTUnwrap(decoded?["value"] as? [String: Any])
    let readValue = try XCTUnwrap(decoded?["readValue"] as? [String: Any])
    let merge = try XCTUnwrap(decoded?["merge"] as? [String: Any])

    XCTAssertEqual(decoded?["sheetName"] as? String, "Sheet 1")
    XCTAssertEqual(decoded?["tableName"] as? String, "Table 1")
    XCTAssertEqual(decoded?["cellReference"] as? String, "A1")
    XCTAssertEqual(decoded?["row"] as? Int, 0)
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
    let fixture = FixtureLocator.fixtureURL(named: "multi-sheet.numbers")
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

  func testReadRangeSupportsJSONFormat() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-range",
      fixture.path,
      "A2:B3",
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
    XCTAssertEqual(decoded?["requestedRange"] as? String, "A2:B3")
    XCTAssertEqual(decoded?["resolvedRange"] as? String, "A2:B3")
    XCTAssertEqual(decoded?["rowCount"] as? Int, 2)
    XCTAssertEqual(decoded?["columnCount"] as? Int, 2)

    let rows = try XCTUnwrap(decoded?["cells"] as? [[Any]])
    XCTAssertEqual(rows.count, 2)
    let firstRow = try XCTUnwrap(rows.first)
    let firstCell = try XCTUnwrap(firstRow.first as? [String: Any])
    let firstReadValue = try XCTUnwrap(firstCell["readValue"] as? [String: Any])

    XCTAssertEqual(firstCell["cellReference"] as? String, "A2")
    XCTAssertEqual(firstCell["kind"] as? String, "text")
    XCTAssertEqual(firstReadValue["kind"] as? String, "string")
    XCTAssertEqual(firstReadValue["string"] as? String, "Answer")
  }

  func testReadRangeSupportsJSONLinesOutput() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-range",
      fixture.path,
      "A2:B3",
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
    XCTAssertEqual(firstJSON?["resolvedRange"] as? String, "A2:B3")
    XCTAssertEqual(firstJSON?["row"] as? Int, 1)
    XCTAssertEqual(firstJSON?["rowOffset"] as? Int, 0)
    XCTAssertEqual(firstJSON?["columnCount"] as? Int, 2)

    let firstCells = try XCTUnwrap(firstJSON?["cells"] as? [[String: Any]])
    XCTAssertEqual(firstCells.count, 2)
    let firstCell = try XCTUnwrap(firstCells.first)
    let firstReadValue = try XCTUnwrap(firstCell["readValue"] as? [String: Any])
    XCTAssertEqual(firstCell["cellReference"] as? String, "A2")
    XCTAssertEqual(firstReadValue["kind"] as? String, "string")
    XCTAssertEqual(firstReadValue["string"] as? String, "Answer")
  }

  func testReadTableSupportsJSONFormat() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-table",
      fixture.path,
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--from-row",
      "1",
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
    XCTAssertEqual(decoded?["fromRow"] as? Int, 1)
    XCTAssertEqual(decoded?["fromColumn"] as? Int, 0)
    XCTAssertEqual(decoded?["resolvedRowCount"] as? Int, 2)
    XCTAssertEqual(decoded?["resolvedColumnCount"] as? Int, 2)
    XCTAssertEqual(decoded?["truncatedRows"] as? Bool, true)
    XCTAssertEqual(decoded?["truncatedColumns"] as? Bool, true)

    let rows = try XCTUnwrap(decoded?["cells"] as? [[Any]])
    XCTAssertEqual(rows.count, 2)
    let firstRow = try XCTUnwrap(rows.first)
    let firstCell = try XCTUnwrap(firstRow.first as? [String: Any])
    let firstReadValue = try XCTUnwrap(firstCell["readValue"] as? [String: Any])
    XCTAssertEqual(firstCell["cellReference"] as? String, "A2")
    XCTAssertEqual(firstReadValue["kind"] as? String, "string")
    XCTAssertEqual(firstReadValue["string"] as? String, "Answer")
  }

  func testReadTableSupportsIndexSelectionJSONFormat() throws {
    let fixture = FixtureLocator.fixtureURL(named: "multi-sheet.numbers")
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
    XCTAssertEqual(decoded?["sheetName"] as? String, "Sheet A")
    XCTAssertEqual(decoded?["tableName"] as? String, "Table A1")

    let rows = try XCTUnwrap(decoded?["cells"] as? [[Any]])
    let firstRow = try XCTUnwrap(rows.first)
    let firstCell = try XCTUnwrap(firstRow.first as? [String: Any])
    let firstReadValue = try XCTUnwrap(firstCell["readValue"] as? [String: Any])
    XCTAssertEqual(firstCell["cellReference"] as? String, "A1")
    XCTAssertEqual(firstReadValue["kind"] as? String, "string")
    XCTAssertEqual(firstReadValue["string"] as? String, "A1")
  }

  func testReadTableSupportsJSONLinesOutput() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-table",
      fixture.path,
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--from-row",
      "1",
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
    XCTAssertEqual(firstJSON?["row"] as? Int, 1)

    let firstCells = try XCTUnwrap(firstJSON?["cells"] as? [[String: Any]])
    XCTAssertEqual(firstCells.count, 2)
    let firstCell = try XCTUnwrap(firstCells.first)
    let firstReadValue = try XCTUnwrap(firstCell["readValue"] as? [String: Any])
    XCTAssertEqual(firstCell["cellReference"] as? String, "A2")
    XCTAssertEqual(firstReadValue["kind"] as? String, "string")
    XCTAssertEqual(firstReadValue["string"] as? String, "Answer")
  }

  func testReadColumnSupportsJSONFormat() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-column",
      fixture.path,
      "0",
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--from-row",
      "1",
      "--format",
      "json",
    ])
    let payload = try XCTUnwrap(output.data(using: .utf8))
    let decoded = try JSONSerialization.jsonObject(with: payload) as? [String: Any]

    XCTAssertEqual(decoded?["sheetName"] as? String, "Sheet 1")
    XCTAssertEqual(decoded?["tableName"] as? String, "Table 1")
    XCTAssertEqual(decoded?["columnIndex"] as? Int, 0)
    XCTAssertEqual(decoded?["fromRow"] as? Int, 1)
    XCTAssertEqual(decoded?["cellCount"] as? Int, 3)

    let cells = try XCTUnwrap(decoded?["cells"] as? [[String: Any]])
    XCTAssertEqual(cells.count, 3)

    let first = try XCTUnwrap(cells.first)
    let firstReadValue = try XCTUnwrap(first["readValue"] as? [String: Any])
    XCTAssertEqual(first["cellReference"] as? String, "A2")
    XCTAssertEqual(firstReadValue["kind"] as? String, "string")
    XCTAssertEqual(firstReadValue["string"] as? String, "Answer")

    let last = try XCTUnwrap(cells.last)
    let lastReadValue = try XCTUnwrap(last["readValue"] as? [String: Any])
    XCTAssertEqual(last["cellReference"] as? String, "A4")
    XCTAssertEqual(lastReadValue["kind"] as? String, "empty")
  }

  func testReadColumnSupportsHeaderSelectionJSONFormat() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-column",
      fixture.path,
      "--header",
      "Name",
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
    XCTAssertEqual(decoded?["headerRow"] as? Int, 0)
    XCTAssertEqual(decoded?["includeHeader"] as? Bool, false)
    XCTAssertEqual(decoded?["columnIndex"] as? Int, 0)
    XCTAssertEqual(decoded?["fromRow"] as? Int, 1)
    XCTAssertEqual(decoded?["cellCount"] as? Int, 3)

    let cells = try XCTUnwrap(decoded?["cells"] as? [[String: Any]])
    XCTAssertEqual(cells.count, 3)
    XCTAssertEqual(cells.first?["cellReference"] as? String, "A2")
  }

  func testReadColumnSupportsHeaderSelectionWithIncludeHeaderJSONFormat() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-column",
      fixture.path,
      "--header",
      "Name",
      "--include-header",
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
    XCTAssertEqual(decoded?["fromRow"] as? Int, 0)
    XCTAssertEqual(decoded?["cellCount"] as? Int, 4)

    let cells = try XCTUnwrap(decoded?["cells"] as? [[String: Any]])
    XCTAssertEqual(cells.count, 4)

    let first = try XCTUnwrap(cells.first)
    let firstReadValue = try XCTUnwrap(first["readValue"] as? [String: Any])
    XCTAssertEqual(first["cellReference"] as? String, "A1")
    XCTAssertEqual(firstReadValue["kind"] as? String, "string")
    XCTAssertEqual(firstReadValue["string"] as? String, "Name")
  }

  func testReadColumnSupportsJSONLinesOutput() throws {
    let fixture = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let output = try runCLI(arguments: [
      "read-column",
      fixture.path,
      "0",
      "--sheet",
      "Sheet 1",
      "--table",
      "Table 1",
      "--from-row",
      "1",
      "--jsonl",
    ])

    let lines = output
      .split(separator: "\n")
      .map(String.init)
      .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    XCTAssertEqual(lines.count, 3)

    let firstData = try XCTUnwrap(lines.first?.data(using: .utf8))
    let firstJSON = try JSONSerialization.jsonObject(with: firstData) as? [String: Any]
    XCTAssertEqual(firstJSON?["sheetName"] as? String, "Sheet 1")
    XCTAssertEqual(firstJSON?["tableName"] as? String, "Table 1")

    let firstCell = try XCTUnwrap(firstJSON?["cell"] as? [String: Any])
    let firstReadValue = try XCTUnwrap(firstCell["readValue"] as? [String: Any])
    XCTAssertEqual(firstCell["cellReference"] as? String, "A2")
    XCTAssertEqual(firstReadValue["kind"] as? String, "string")
    XCTAssertEqual(firstReadValue["string"] as? String, "Answer")
  }

  private func runCLI(arguments: [String]) throws -> String {
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
    XCTAssertEqual(process.terminationStatus, 0, "CLI failed: \(stderr)")

    return stdout
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
