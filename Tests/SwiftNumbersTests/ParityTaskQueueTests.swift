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

    let lines = output
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

    let lines = output
      .split(separator: "\n")
      .map(String.init)
    XCTAssertEqual(lines.first, "NEXT_TASK=SN-R71")
    XCTAssertEqual(lines.dropFirst().first, "QUEUE_SIZE=3")

    let queueTaskIDs = lines.dropFirst(2).compactMap { line -> String? in
      line.split(separator: "|", maxSplits: 1).first.map(String.init)
    }
    XCTAssertEqual(queueTaskIDs, ["SN-R71", "SN-R82", "SN-R85"])
  }

  private func runParityQueueScript(arguments: [String]) throws -> String {
    let process = Process()
    process.currentDirectoryURL = FixtureLocator.repoRoot
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = [FixtureLocator.repoRoot.appendingPathComponent("scripts/parity_task_queue.sh").path] + arguments

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
