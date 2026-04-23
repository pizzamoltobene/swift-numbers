import Foundation
import XCTest

@testable import SwiftNumbersIWA

final class RealReadPipelineUnitTests: XCTestCase {
  func testDecodeSignedInt16Array() {
    let values: [Int16] = [0, 1, -1, 320]
    var data = Data()
    for value in values {
      var little = value.littleEndian
      data.append(Data(bytes: &little, count: MemoryLayout<Int16>.size))
    }

    let decoded = IWARealDocumentReader.decodeSignedInt16Array(data)
    XCTAssertEqual(decoded, [0, 1, -1, 320])
  }

  func testSplitRowStorageBuffersWithWideOffsets() {
    let storage = Data("AAAABBBB".utf8)

    var offsets = Data()
    for value in [Int16(0), Int16(1), Int16(-1)] {
      var little = value.littleEndian
      offsets.append(Data(bytes: &little, count: MemoryLayout<Int16>.size))
    }

    let row = IWARealDocumentReader.splitRowStorageBuffers(
      storageBuffer: storage,
      offsetsBuffer: offsets,
      columnCount: 3,
      hasWideOffsets: true
    )

    XCTAssertEqual(row.count, 3)
    XCTAssertEqual(row[0], Data("AAAA".utf8))
    XCTAssertEqual(row[1], Data("BBBB".utf8))
    XCTAssertNil(row[2])
  }

  func testDecodeCellValueForStringNumberAndBool() {
    let stringBuffer = makeCellBuffer(type: 3, flags: 0x8) { data in
      appendInt32(7, to: &data)
    }
    let numberBuffer = makeCellBuffer(type: 2, flags: 0x2) { data in
      appendDouble(42.5, to: &data)
    }
    let boolBuffer = makeCellBuffer(type: 6, flags: 0x2) { data in
      appendDouble(1.0, to: &data)
    }

    let lookup: [UInt32: String] = [7: "Hello"]

    XCTAssertEqual(
      IWARealDocumentReader.decodeCellValue(buffer: stringBuffer, stringLookup: lookup),
      .string("Hello")
    )
    XCTAssertEqual(
      IWARealDocumentReader.decodeCellValue(buffer: numberBuffer, stringLookup: lookup),
      .number(42.5)
    )
    XCTAssertEqual(
      IWARealDocumentReader.decodeCellValue(buffer: boolBuffer, stringLookup: lookup),
      .bool(true)
    )
  }

  func testUnsupportedVersionDiagnostic() {
    let warning = NumbersDocumentVersion.unsupportedVersionDiagnostic(for: "99.0.1")
    XCTAssertNotNil(warning)
    XCTAssertTrue(warning?.contains("99.0.1") == true)

    XCTAssertNil(NumbersDocumentVersion.unsupportedVersionDiagnostic(for: "14.5"))
  }

  func testResolverChoosesDeterministicDocumentCandidate() {
    let records = [
      IWAObjectRecord(objectID: 20, typeID: 1, payloadSize: 0, sourceBlobPath: "A.iwa"),
      IWAObjectRecord(objectID: 10, typeID: 1, payloadSize: 0, sourceBlobPath: "B.iwa"),
    ]
    let inventory = IWAInventory(records: records, unparsedBlobPaths: [])

    let result = IWARealDocumentReader.read(from: inventory, documentVersion: nil)
    let noSheets = result.structuredDiagnostics.first { $0.code == "resolver.sheet.empty" }
    XCTAssertEqual(noSheets?.context["objectID"], "10")
  }

  func testSplitRowStorageBuffersReturnsNilCellsWhenOffsetsMissing() {
    let row = IWARealDocumentReader.splitRowStorageBuffers(
      storageBuffer: Data("AAAA".utf8),
      offsetsBuffer: Data(),
      columnCount: 3,
      hasWideOffsets: false
    )

    XCTAssertEqual(row.count, 3)
    XCTAssertEqual(row[0], nil)
    XCTAssertEqual(row[1], nil)
    XCTAssertEqual(row[2], nil)
  }

  func testUnpackDecimal128HandlesLargeMantissaWithoutOverflow() {
    var bytes = [UInt8](repeating: 0xFF, count: 16)
    // Encoded exponent for zero: 0x1820.
    bytes[14] = 0x41  // exponent low bits + mantissa low bit
    bytes[15] = 0x30  // exponent high bits, positive sign

    let value = IWARealDocumentReader.unpackDecimal128(Data(bytes))
    XCTAssertTrue(value.isFinite)
    XCTAssertFalse(value.isNaN)
  }

  private func makeCellBuffer(
    type: UInt8,
    flags: Int32,
    payloadBuilder: (inout Data) -> Void
  ) -> Data {
    var data = Data(repeating: 0, count: 12)
    data[0] = 5
    data[1] = type

    var flagsLE = flags.littleEndian
    withUnsafeBytes(of: &flagsLE) { bytes in
      data.replaceSubrange(8..<12, with: bytes)
    }
    payloadBuilder(&data)

    return data
  }

  private func appendInt32(_ value: Int32, to data: inout Data) {
    var little = value.littleEndian
    data.append(Data(bytes: &little, count: MemoryLayout<Int32>.size))
  }

  private func appendDouble(_ value: Double, to data: inout Data) {
    var bits = value.bitPattern.littleEndian
    data.append(Data(bytes: &bits, count: MemoryLayout<UInt64>.size))
  }
}
