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
}
