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
}
