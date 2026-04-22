import XCTest
@testable import SwiftNumbersContainer
@testable import SwiftNumbersIWA
@testable import SwiftNumbersCore

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

        let reachable = inventory.reachableObjectIDs(from: inventory.rootObjectIDs.prefix(1).map { $0 }, maxDepth: 3)
        XCTAssertFalse(reachable.isEmpty)
    }

    func testDumpWorksWithoutSyntheticMetadataOnReferenceFile() throws {
        let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
        let document = try NumbersDocument.open(at: fixture)
        let dump = document.renderDump()

        XCTAssertTrue(dump.contains("Index blobs:"))
        XCTAssertTrue(dump.contains("IWA objects:"))
        XCTAssertTrue(dump.contains("Object reference edges:"))
        XCTAssertTrue(dump.contains("Root objects:"))
    }
}
