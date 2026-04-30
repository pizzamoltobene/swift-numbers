import Foundation
import XCTest

final class ParityTaskQueueTests: XCTestCase {
  func testParityQueueSimulationProducesDeterministicOrder() throws {
    let output = try runParityQueueScript(arguments: [
      "--roadmap",
      FixtureLocator.fileFixtureURL(named: "autopilot-parity-roadmap-sim.md").path,
      "--code-map",
      FixtureLocator.fileFixtureURL(named: "autopilot-parity-map-sim.md").path,
      "--max",
      "10",
    ])

    let lines =
      output
      .split(separator: "\n")
      .map(String.init)
    XCTAssertEqual(lines.first, "NEXT_TASK=SN-R71")
    XCTAssertEqual(lines.dropFirst().first, "QUEUE_SIZE=4")

    let queueTaskIDs = lines.dropFirst(2).compactMap { line -> String? in
      line.split(separator: "|", maxSplits: 1).first.map(String.init)
    }
    XCTAssertEqual(queueTaskIDs, ["SN-R71", "SN-R72", "SN-R82", "SN-R85"])
  }

  func testParityQueueExcludeInProgressFiltersInProgressTasks() throws {
    let output = try runParityQueueScript(arguments: [
      "--roadmap",
      FixtureLocator.fileFixtureURL(named: "autopilot-parity-roadmap-sim.md").path,
      "--code-map",
      FixtureLocator.fileFixtureURL(named: "autopilot-parity-map-sim.md").path,
      "--exclude-in-progress",
      "--max",
      "10",
    ])

    let lines =
      output
      .split(separator: "\n")
      .map(String.init)
    XCTAssertEqual(lines.first, "NEXT_TASK=SN-R71")
    XCTAssertEqual(lines.dropFirst().first, "QUEUE_SIZE=3")

    let queueTaskIDs = lines.dropFirst(2).compactMap { line -> String? in
      line.split(separator: "|", maxSplits: 1).first.map(String.init)
    }
    XCTAssertEqual(queueTaskIDs, ["SN-R71", "SN-R82", "SN-R85"])
  }

  func testParityQueuePrefersAppleScriptCapabilityGapsOverHistoricalCodeMap() throws {
    let output = try runParityQueueScript(arguments: [
      "--roadmap",
      FixtureLocator.fileFixtureURL(named: "autopilot-apple-parity-roadmap-sim.md").path,
      "--code-map",
      FixtureLocator.fileFixtureURL(named: "autopilot-parity-map-sim.md").path,
      "--apple-map",
      FixtureLocator.fileFixtureURL(named: "autopilot-apple-parity-map-sim.md").path,
      "--max",
      "10",
    ])

    let lines =
      output
      .split(separator: "\n")
      .map(String.init)
    XCTAssertEqual(lines.first, "NEXT_TASK=SN-OSA05")
    XCTAssertEqual(lines.dropFirst().first, "QUEUE_SIZE=3")

    let queueTaskIDs = lines.dropFirst(2).compactMap { line -> String? in
      line.split(separator: "|", maxSplits: 1).first.map(String.init)
    }
    XCTAssertEqual(queueTaskIDs, ["SN-OSA05", "SN-OSA04", "SN-R71"])

    let firstFields = lines[2].split(separator: "|").map(String.init)
    XCTAssertEqual(firstFields[8], "apple")
    XCTAssertEqual(firstFields[9], "missing")
  }

  func testParityQueueUsesAppleScriptMutationProbeRowsForMutationTasks() throws {
    let output = try runParityQueueScript(arguments: [
      "--roadmap",
      FixtureLocator.fileFixtureURL(named: "autopilot-apple-parity-roadmap-sim.md").path,
      "--code-map",
      FixtureLocator.fileFixtureURL(named: "autopilot-parity-map-sim.md").path,
      "--apple-map",
      FixtureLocator.fileFixtureURL(named: "autopilot-apple-mutation-probe-map-sim.md").path,
      "--max",
      "10",
    ])

    let lines =
      output
      .split(separator: "\n")
      .map(String.init)
    XCTAssertEqual(lines.first, "NEXT_TASK=SN-OSA04")

    let firstFields = lines[2].split(separator: "|").map(String.init)
    XCTAssertEqual(firstFields[0], "SN-OSA04")
    XCTAssertEqual(firstFields[3], "write")
    XCTAssertEqual(firstFields[4], "row-mutation-operation")
    XCTAssertEqual(firstFields[8], "apple")
    XCTAssertEqual(firstFields[9], "missing")
  }

  func testParityQueueUsesAppleScriptReadProbeRowsForReadTasks() throws {
    let output = try runParityQueueScript(arguments: [
      "--roadmap",
      FixtureLocator.fileFixtureURL(named: "autopilot-apple-read-probe-roadmap-sim.md").path,
      "--code-map",
      FixtureLocator.fileFixtureURL(named: "autopilot-parity-map-sim.md").path,
      "--apple-map",
      FixtureLocator.fileFixtureURL(named: "autopilot-apple-read-probe-map-sim.md").path,
      "--max",
      "10",
    ])

    let lines =
      output
      .split(separator: "\n")
      .map(String.init)
    XCTAssertEqual(lines.first, "NEXT_TASK=SN-AUTO-20260430-01")

    let firstFields = lines[2].split(separator: "|").map(String.init)
    XCTAssertEqual(firstFields[0], "SN-AUTO-20260430-01")
    XCTAssertEqual(firstFields[3], "read")
    XCTAssertEqual(firstFields[4], "cell-read-surface")
    XCTAssertEqual(firstFields[8], "apple")
    XCTAssertEqual(firstFields[9], "missing")
  }

  func testParityQueueUsesAppleScriptDocumentAndTableMutationRowsForRenewalTasks() throws {
    let output = try runParityQueueScript(arguments: [
      "--roadmap",
      FixtureLocator.fileFixtureURL(named: "autopilot-apple-mutation-renewal-roadmap-sim.md").path,
      "--code-map",
      FixtureLocator.fileFixtureURL(named: "autopilot-parity-map-sim.md").path,
      "--apple-map",
      FixtureLocator.fileFixtureURL(named: "autopilot-apple-mutation-renewal-map-sim.md").path,
      "--max",
      "10",
    ])

    let lines =
      output
      .split(separator: "\n")
      .map(String.init)
    XCTAssertEqual(lines.first, "NEXT_TASK=SN-AUTO-20260430-02")

    let firstFields = lines[2].split(separator: "|").map(String.init)
    XCTAssertEqual(firstFields[0], "SN-AUTO-20260430-02")
    XCTAssertEqual(firstFields[3], "write")
    XCTAssertEqual(firstFields[4], "table-mutation-operation")
    XCTAssertEqual(firstFields[8], "apple")
    XCTAssertEqual(firstFields[9], "missing")
  }

  func testParityQueueUsesAppleScriptFormulaRowsForFormulaRenewalTasks() throws {
    let output = try runParityQueueScript(arguments: [
      "--roadmap",
      FixtureLocator.fileFixtureURL(named: "autopilot-apple-formula-renewal-roadmap-sim.md").path,
      "--code-map",
      FixtureLocator.fileFixtureURL(named: "autopilot-parity-map-sim.md").path,
      "--apple-map",
      FixtureLocator.fileFixtureURL(named: "autopilot-apple-formula-renewal-map-sim.md").path,
      "--max",
      "10",
    ])

    let lines =
      output
      .split(separator: "\n")
      .map(String.init)
    XCTAssertEqual(lines.first, "NEXT_TASK=SN-AUTO-20260430-03")

    let firstFields = lines[2].split(separator: "|").map(String.init)
    XCTAssertEqual(firstFields[0], "SN-AUTO-20260430-03")
    XCTAssertEqual(firstFields[3], "formula")
    XCTAssertEqual(firstFields[4], "formula-write-operation")
    XCTAssertEqual(firstFields[8], "apple")
    XCTAssertEqual(firstFields[9], "missing")
  }

  private func runParityQueueScript(arguments: [String]) throws -> String {
    let environment = ProcessInfo.processInfo.environment
    guard let scriptPath = environment["SWIFT_NUMBERS_PARITY_QUEUE_SCRIPT"],
      FileManager.default.isExecutableFile(atPath: scriptPath)
    else {
      throw XCTSkip("External parity task queue script is not configured for package tests.")
    }

    let process = Process()
    process.currentDirectoryURL = FixtureLocator.repoRoot
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = [scriptPath] + arguments

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe
    try process.run()
    process.waitUntilExit()

    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
    let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
    let stderr = String(data: stderrData, encoding: .utf8) ?? ""

    XCTAssertEqual(process.terminationStatus, 0, "parity_task_queue.sh failed: \(stderr)")
    return stdout
  }
}
