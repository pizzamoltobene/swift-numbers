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
