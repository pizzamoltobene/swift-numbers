import Foundation
import XCTest

@testable import SwiftNumbersContainer
@testable import SwiftNumbersCore
@testable import SwiftNumbersIWA

final class NumbersParserCompatibilityTests: XCTestCase {
  func testCanReadNumbersParserEmptyFixtureAsSingleFileArchive() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")

    let container = try NumbersContainer.open(at: fixture)
    let blobs = try container.loadIndexBlobs()

    XCTAssertFalse(blobs.isEmpty)
    XCTAssertTrue(blobs.allSatisfy { $0.path.lowercased().contains("index/") })
    XCTAssertTrue(blobs.allSatisfy { $0.path.lowercased().hasSuffix(".iwa") })

    let inventory = try IWAInventoryBuilder.build(from: blobs)
    XCTAssertGreaterThan(inventory.records.count, 0)
    XCTAssertTrue(inventory.unparsedBlobPaths.isEmpty)
    XCTAssertGreaterThan(inventory.objectReferenceEdgeCount, 0)
    XCTAssertGreaterThan(inventory.rootObjectIDs.count, 0)

    let reachable = inventory.reachableObjectIDs(
      from: inventory.rootObjectIDs.prefix(1).map { $0 }, maxDepth: 3)
    XCTAssertFalse(reachable.isEmpty)
  }

  func testDumpWorksWithoutSyntheticMetadataOnReferenceFile() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let document = try NumbersDocument.open(at: fixture)
    let dump = document.renderDump()

    XCTAssertGreaterThan(document.sheets.count, 0)
    XCTAssertGreaterThan(document.sheets.reduce(0) { $0 + $1.tables.count }, 0)
    XCTAssertTrue(dump.contains("Index blobs:"))
    XCTAssertTrue(dump.contains("IWA objects:"))
    XCTAssertTrue(dump.contains("Object reference edges:"))
    XCTAssertTrue(dump.contains("Root objects:"))
    XCTAssertTrue(dump.contains("Diagnostics:"))
  }

  func testSheetNamesMatchNumbersParserWhenAvailable() throws {
    guard pythonNumbersParserAvailable() else {
      throw XCTSkip("numbers-parser is not available in the local python environment.")
    }

    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let document = try NumbersDocument.open(at: fixture)
    let swiftNames = document.sheets.map(\.name)

    let pythonNames = try fetchPythonSheetNames(for: fixture)
    XCTAssertEqual(swiftNames, pythonNames)
  }

  private func pythonNumbersParserAvailable() -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["python3", "-c", "import numbers_parser"]
    process.standardOutput = Pipe()
    process.standardError = Pipe()
    do {
      try process.run()
    } catch {
      return false
    }
    process.waitUntilExit()
    return process.terminationStatus == 0
  }

  private func fetchPythonSheetNames(for url: URL) throws -> [String] {
    let snippet = """
      import json
      import sys
      from numbers_parser import Document
      doc = Document(sys.argv[1])
      sheets_attr = getattr(doc, "sheets", None)
      sheets = sheets_attr() if callable(sheets_attr) else sheets_attr
      names = [getattr(s, "name", str(s)) for s in (sheets or [])]
      print(json.dumps(names))
      """

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["python3", "-c", snippet, url.path]

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    try process.run()
    process.waitUntilExit()

    let stderr =
      String(
        data: stderrPipe.fileHandleForReading.readDataToEndOfFile(),
        encoding: .utf8
      ) ?? ""
    XCTAssertEqual(process.terminationStatus, 0, "Python numbers-parser command failed: \(stderr)")

    let stdout =
      String(
        data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(),
        encoding: .utf8
      ) ?? "[]"
    let payload = Data(stdout.utf8)
    return try JSONDecoder().decode([String].self, from: payload)
  }
}
