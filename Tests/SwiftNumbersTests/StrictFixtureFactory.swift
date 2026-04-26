import Foundation

@testable import SwiftNumbersCore

enum StrictFixtureFactory {
  static let simpleTableArchiveURL: URL = {
    do {
      return try buildSimpleTableArchive()
    } catch {
      fatalError("Failed to build strict simple-table fixture: \(error)")
    }
  }()

  static let multiSheetArchiveURL: URL = {
    do {
      return try buildMultiSheetArchive()
    } catch {
      fatalError("Failed to build strict multi-sheet fixture: \(error)")
    }
  }()

  static func fixtureURL(named name: String) -> URL {
    switch name {
    case "simple-table.numbers":
      return simpleTableArchiveURL
    case "multi-sheet.numbers":
      return multiSheetArchiveURL
    default:
      return FixtureLocator.fixtureURL(named: name)
    }
  }

  private static var cacheRoot: URL {
    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent("swift-numbers-strict-fixtures", isDirectory: true)
    try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    return root
  }

  private static func buildSimpleTableArchive() throws -> URL {
    let output = cacheRoot.appendingPathComponent("simple-table-strict.numbers", isDirectory: false)
    if FileManager.default.fileExists(atPath: output.path) {
      return output
    }

    let source = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: source)
    let table = try editable.sheet(named: "Sheet 1").table(named: "Table 1")

    // Mirror legacy synthetic fixture payload expected by CLI/read tests.
    try table.setValue(.string("Name"), at: "A1")
    try table.setValue(.string("Value"), at: "B1")
    try table.setValue(.string("Answer"), at: "A2")
    try table.setValue(.number(42), at: "B2")
    try table.setValue(.string("Enabled"), at: "A3")
    try table.setValue(.bool(true), at: "B3")
    // Ensure table shape remains 4x3 with trailing empty row/column.
    table.setValue(.empty, at: CellAddress(row: 3, column: 2))

    try editable.save(to: output)
    return output
  }

  private static func buildMultiSheetArchive() throws -> URL {
    let output = cacheRoot.appendingPathComponent("multi-sheet-strict.numbers", isDirectory: false)
    if FileManager.default.fileExists(atPath: output.path) {
      return output
    }

    let source = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let editable = try EditableNumbersDocument.open(at: source)

    let firstSheet = try editable.sheet(named: "Sheet 1")
    let firstTable = try firstSheet.table(named: "Table 1")
    firstTable.setValue(.string("Metric"), at: CellAddress(row: 0, column: 0))
    firstTable.setValue(.number(10), at: CellAddress(row: 1, column: 0))

    let sheetB = editable.addSheet(named: "Sheet B")
    let sheetBDefault = try sheetB.table(named: "Table 1")
    sheetBDefault.setValue(.string("North"), at: CellAddress(row: 0, column: 0))

    let tableB2 = try editable.addTable(
      named: "Table B2",
      rows: 1,
      columns: 1,
      onSheetNamed: "Sheet B"
    )
    tableB2.setValue(.string("Flag"), at: CellAddress(row: 0, column: 0))

    try editable.save(to: output)
    return output
  }
}
