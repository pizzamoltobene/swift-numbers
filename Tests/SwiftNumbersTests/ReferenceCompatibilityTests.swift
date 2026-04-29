import Foundation
import XCTest

@testable import SwiftNumbersContainer
@testable import SwiftNumbersCore
@testable import SwiftNumbersIWA

final class ReferenceCompatibilityTests: XCTestCase {
  func testCanReadReferenceFixtureAsSingleFileArchive() throws {
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

  func testReachableObjectIDsTraversesLargeLinearGraph() {
    let nodeCount = 10_000
    var records: [IWAObjectRecord] = []
    records.reserveCapacity(nodeCount)

    for index in 1...nodeCount {
      let objectID = UInt64(index)
      let next = index < nodeCount ? [UInt64(index + 1)] : []
      records.append(
        IWAObjectRecord(
          objectID: objectID,
          typeID: 6000,
          payloadSize: 0,
          sourceBlobPath: "Index/\(index).iwa",
          objectReferences: next
        ))
    }

    let inventory = IWAInventory(records: records, unparsedBlobPaths: [])
    let reachable = inventory.reachableObjectIDs(from: [1])
    XCTAssertEqual(reachable.count, nodeCount)
    XCTAssertTrue(reachable.contains(1))
    XCTAssertTrue(reachable.contains(UInt64(nodeCount)))
  }

  func testSheetNamesAreStableForReferenceFixture() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let document = try NumbersDocument.open(at: fixture)

    XCTAssertEqual(document.sheets.count, 1)
    XCTAssertEqual(document.sheets.first?.name, "Sheet 1")
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

  func testContainerDetectsEncryptionMarkers() throws {
    let fixture = try makeTemporaryNumbersDirectory(encrypted: true)
    defer { try? FileManager.default.removeItem(at: fixture) }

    let container = try NumbersContainer.open(at: fixture)
    XCTAssertTrue(try container.isLikelyEncryptedDocument())
  }

  func testOpenThrowsUnsupportedForEncryptedDocument() throws {
    let fixture = try makeTemporaryNumbersDirectory(encrypted: true)
    defer { try? FileManager.default.removeItem(at: fixture) }

    XCTAssertThrowsError(try NumbersDocument.open(at: fixture)) { error in
      guard case NumbersDocumentError.encryptedDocumentUnsupported = error else {
        XCTFail("Expected encryptedDocumentUnsupported, got \(error)")
        return
      }
    }
  }

  func testReadMetadataFileReturnsNilWhenPackageHasNoMetadataDirectory() throws {
    let source = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let workingCopy = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent(
        "swift-numbers-no-metadata-\(UUID().uuidString).numbers",
        isDirectory: true
      )
    defer { try? FileManager.default.removeItem(at: workingCopy) }

    try FileManager.default.copyItem(at: source, to: workingCopy)
    try FileManager.default.removeItem(
      at: workingCopy.appendingPathComponent("Metadata", isDirectory: true)
    )

    let container = try NumbersContainer.open(at: workingCopy)
    XCTAssertNil(try container.readMetadataFile(named: "DocumentMetadata.json"))
    XCTAssertNil(try container.readMetadataFile(named: "DocumentMetadata.pb"))
  }

  func testCopyContainerRejectsMetadataTraversalReplacementFilename() throws {
    let source = FixtureLocator.fixtureURL(named: "simple-table.numbers")
    let output = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent("swift-numbers-invalid-metadata-\(UUID().uuidString).numbers")
    defer { try? FileManager.default.removeItem(at: output) }

    XCTAssertThrowsError(
      try NumbersContainer.copyContainer(
        from: source,
        to: output,
        replacingMetadataFiles: ["../escape.json": Data("{}".utf8)]
      )
    ) { error in
      guard case NumbersContainerError.invalidReplacementPath(let path) = error else {
        return XCTFail("Expected invalidReplacementPath, got \(error)")
      }
      XCTAssertEqual(path, "../escape.json")
    }
  }

  func testCopyContainerRejectsIndexBlobTraversalReplacementPath() throws {
    let archiveFixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let source = try makePackageFixture(fromSingleFileArchive: archiveFixture)
    let output = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent("swift-numbers-invalid-index-\(UUID().uuidString).numbers")
    defer {
      try? FileManager.default.removeItem(at: source)
      try? FileManager.default.removeItem(at: output)
    }

    XCTAssertThrowsError(
      try NumbersContainer.copyContainer(
        from: source,
        to: output,
        replacingIndexBlobs: ["Index/../escape.iwa": Data([0x00])]
      )
    ) { error in
      guard case NumbersContainerError.invalidReplacementPath(let path) = error else {
        return XCTFail("Expected invalidReplacementPath, got \(error)")
      }
      XCTAssertEqual(path, "Index/../escape.iwa")
    }
  }

  func testReadAPIsAreConsistentBetweenPackageAndSingleFileArchive() throws {
    let archiveFixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let packageFixture = try makePackageFixture(fromSingleFileArchive: archiveFixture)
    defer { try? FileManager.default.removeItem(at: packageFixture) }

    let packageDocument = try NumbersDocument.open(at: packageFixture)
    let archiveDocument = try NumbersDocument.open(at: archiveFixture)

    XCTAssertEqual(packageDocument.sheetNames, archiveDocument.sheetNames)
    XCTAssertEqual(packageDocument.tableCount, archiveDocument.tableCount)
    XCTAssertEqual(packageDocument.tableNames, archiveDocument.tableNames)

    let packageSheet = try XCTUnwrap(packageDocument.sheets.first)
    let archiveSheet = try XCTUnwrap(archiveDocument.sheets.first)
    let packageTable = try XCTUnwrap(packageSheet.tables.first)
    let archiveTable = try XCTUnwrap(archiveSheet.tables.first)

    XCTAssertEqual(packageTable.metadata.rowCount, archiveTable.metadata.rowCount)
    XCTAssertEqual(packageTable.metadata.columnCount, archiveTable.metadata.columnCount)
    XCTAssertEqual(packageTable.rows(), archiveTable.rows())

    let addresses = [
      CellAddress(row: 0, column: 0),  // A1
      CellAddress(row: 1, column: 1),  // B2
      CellAddress(row: 2, column: 1),  // B3
      CellAddress(row: 3, column: 2),  // C4
    ]
    for address in addresses {
      XCTAssertEqual(
        packageTable.cell(at: address),
        archiveTable.cell(at: address),
        "Mismatch at row=\(address.row), column=\(address.column)"
      )
      XCTAssertEqual(
        packageTable.readCell(at: address)?.kind,
        archiveTable.readCell(at: address)?.kind,
        "ReadCell kind mismatch at row=\(address.row), column=\(address.column)"
      )
    }
  }

  private func makeTemporaryNumbersDirectory(encrypted: Bool) throws -> URL {
    let fixture = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent("swift-numbers-\(UUID().uuidString).numbers", isDirectory: true)

    try FileManager.default.createDirectory(at: fixture, withIntermediateDirectories: true)

    guard encrypted else {
      return fixture
    }

    try Data([0x01]).write(to: fixture.appendingPathComponent(".iwpv2", isDirectory: false))
    try Data([0x01]).write(to: fixture.appendingPathComponent(".iwph", isDirectory: false))
    return fixture
  }

  private func makePackageFixture(fromSingleFileArchive archiveURL: URL) throws -> URL {
    let packageURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent("swift-numbers-\(UUID().uuidString).numbers", isDirectory: true)
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
    process.arguments = [
      "-x",
      "-k",
      archiveURL.path,
      packageURL.path,
    ]

    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      throw NSError(
        domain: "ReferenceCompatibilityTests",
        code: Int(process.terminationStatus),
        userInfo: [
          NSLocalizedDescriptionKey:
            "ditto package conversion failed with status \(process.terminationStatus)"
        ]
      )
    }

    return packageURL
  }
}
