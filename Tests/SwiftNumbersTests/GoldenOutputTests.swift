import Foundation
import XCTest

@testable import SwiftNumbersCore

final class GoldenOutputTests: XCTestCase {
  func testDumpGoldenSimpleTable() throws {
    try assertDumpGolden(
      fixtureName: "simple-table.numbers",
      goldenName: "dump-simple-table.txt"
    )
  }

  func testDumpGoldenMultiSheet() throws {
    try assertDumpGolden(
      fixtureName: "multi-sheet.numbers",
      goldenName: "dump-multi-sheet.txt"
    )
  }

  func testListSheetsGoldenSimpleTable() throws {
    try assertListSheetsGolden(
      fixtureName: "simple-table.numbers",
      goldenName: "list-sheets-simple-table.txt"
    )
  }

  func testListSheetsGoldenMultiSheet() throws {
    try assertListSheetsGolden(
      fixtureName: "multi-sheet.numbers",
      goldenName: "list-sheets-multi-sheet.txt"
    )
  }

  private func assertDumpGolden(fixtureName: String, goldenName: String) throws {
    let fixtureURL = StrictFixtureFactory.fixtureURL(named: fixtureName)
    let document = try NumbersDocument.open(at: fixtureURL)
    let output = normalizeDump(document.renderDump()).trimmingCharacters(
      in: .whitespacesAndNewlines)
    let expected = try loadGolden(named: goldenName)

    XCTAssertEqual(output, expected)
  }

  private func assertListSheetsGolden(fixtureName: String, goldenName: String) throws {
    let fixtureURL = StrictFixtureFactory.fixtureURL(named: fixtureName)
    let document = try NumbersDocument.open(at: fixtureURL)

    let output = document.sheets.enumerated()
      .map { "\($0.offset + 1). \($0.element.name)" }
      .joined(separator: "\n")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let expected = try loadGolden(named: goldenName)

    XCTAssertEqual(output, expected)
  }

  private func normalizeDump(_ dump: String) -> String {
    var lines = dump.components(separatedBy: "\n")
    if !lines.isEmpty, lines[0].hasPrefix("Source: ") {
      lines[0] = "Source: <fixture>"
    }
    return lines.joined(separator: "\n")
  }

  private func loadGolden(named name: String) throws -> String {
    let goldenURL = FixtureLocator.repoRoot
      .appendingPathComponent("Tests", isDirectory: true)
      .appendingPathComponent("SwiftNumbersTests", isDirectory: true)
      .appendingPathComponent("Goldens", isDirectory: true)
      .appendingPathComponent(name, isDirectory: false)

    let payload = try String(contentsOf: goldenURL, encoding: .utf8)
    return payload.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
