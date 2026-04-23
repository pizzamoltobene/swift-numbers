import XCTest

@testable import SwiftNumbersIWA

final class IWAWriteGraphTests: XCTestCase {
  func testIndexesAndDeterministicLookup() {
    let inventory = IWAInventory(
      records: [
        IWAObjectRecord(objectID: 42, typeID: 6001, payloadSize: 10, sourceBlobPath: "B.iwa"),
        IWAObjectRecord(objectID: 10, typeID: 2, payloadSize: 4, sourceBlobPath: "A.iwa"),
        IWAObjectRecord(objectID: 42, typeID: 1, payloadSize: 8, sourceBlobPath: "A.iwa"),
        IWAObjectRecord(objectID: 42, typeID: 6001, payloadSize: 8, sourceBlobPath: "A.iwa"),
      ],
      unparsedBlobPaths: []
    )

    let graph = IWAWriteGraph(inventory: inventory)
    let objectRecords = graph.records(forObjectID: 42)
    XCTAssertEqual(objectRecords.count, 3)
    XCTAssertEqual(objectRecords.map(\.typeID), [1, 6001, 6001])
    XCTAssertEqual(objectRecords.map(\.sourceBlobPath), ["A.iwa", "A.iwa", "B.iwa"])

    let anyRecord = graph.record(objectID: 42)
    XCTAssertEqual(anyRecord?.typeID, 1)
    XCTAssertEqual(anyRecord?.sourceBlobPath, "A.iwa")

    let typedRecord = graph.record(objectID: 42, typeID: 6001)
    XCTAssertEqual(typedRecord?.sourceBlobPath, "A.iwa")

    let typeBucket = graph.records(forTypeID: 6001)
    XCTAssertEqual(typeBucket.count, 2)
    XCTAssertEqual(typeBucket.map(\.objectID), [42, 42])
  }

  func testMarkDirtyDeduplicatesObjectAndTypePairs() {
    let inventory = IWAInventory(
      records: [
        IWAObjectRecord(objectID: 100, typeID: 6000, payloadSize: 8, sourceBlobPath: "Doc.iwa"),
        IWAObjectRecord(objectID: 101, typeID: 6001, payloadSize: 8, sourceBlobPath: "Doc.iwa"),
      ],
      unparsedBlobPaths: []
    )

    var graph = IWAWriteGraph(inventory: inventory)
    graph.markDirty(objectID: 101, typeID: 6001, reason: "cell-value-update")
    graph.markDirty(objectID: 101, typeID: 6001, reason: "duplicate-should-be-ignored")
    graph.markDirty(objectID: 100, typeID: 6000, reason: "table-structure-update")

    XCTAssertEqual(graph.dirtyObjects.count, 2)
    XCTAssertEqual(graph.dirtyObjects.map(\.objectID), [100, 101])
    XCTAssertEqual(graph.dirtyObjects.map(\.typeID), [6000, 6001])
    XCTAssertEqual(graph.dirtyObjects.map(\.sourceBlobPath), ["Doc.iwa", "Doc.iwa"])
  }
}
