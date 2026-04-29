import Foundation
import Snappy
import SwiftNumbersContainer
import SwiftNumbersProto

public struct IWAObjectRecord: Sendable, Hashable {
  public let objectID: UInt64
  public let typeID: UInt32
  public let payloadSize: Int
  public let payloadData: Data
  public let sourceBlobPath: String
  public let objectReferences: [UInt64]
  public let dataReferences: [UInt64]

  public init(
    objectID: UInt64,
    typeID: UInt32,
    payloadSize: Int,
    payloadData: Data = Data(),
    sourceBlobPath: String,
    objectReferences: [UInt64] = [],
    dataReferences: [UInt64] = []
  ) {
    self.objectID = objectID
    self.typeID = typeID
    self.payloadSize = payloadSize
    self.payloadData = payloadData
    self.sourceBlobPath = sourceBlobPath
    self.objectReferences = objectReferences
    self.dataReferences = dataReferences
  }
}

public struct IWAInventory: Sendable {
  public let records: [IWAObjectRecord]
  public let unparsedBlobPaths: [String]

  public init(records: [IWAObjectRecord], unparsedBlobPaths: [String]) {
    self.records = records
    self.unparsedBlobPaths = unparsedBlobPaths
  }

  public var typeHistogram: [UInt32: Int] {
    var histogram: [UInt32: Int] = [:]
    for record in records {
      histogram[record.typeID, default: 0] += 1
    }
    return histogram
  }

  public var objectReferenceAdjacency: [UInt64: Set<UInt64>] {
    var adjacency: [UInt64: Set<UInt64>] = [:]

    for record in records {
      if !record.objectReferences.isEmpty {
        adjacency[record.objectID, default: []].formUnion(record.objectReferences)
      } else if adjacency[record.objectID] == nil {
        adjacency[record.objectID] = []
      }
    }

    return adjacency
  }

  public var objectReferenceEdgeCount: Int {
    objectReferenceAdjacency.values.reduce(0) { $0 + $1.count }
  }

  public var rootObjectIDs: [UInt64] {
    var allObjectIDs = Set(records.map(\.objectID))
    var referencedObjectIDs = Set<UInt64>()

    for references in objectReferenceAdjacency.values {
      referencedObjectIDs.formUnion(references)
    }

    allObjectIDs.subtract(referencedObjectIDs)
    return allObjectIDs.sorted()
  }

  public func reachableObjectIDs(from roots: [UInt64], maxDepth: Int? = nil) -> Set<UInt64> {
    let adjacency = objectReferenceAdjacency
    var visited = Set<UInt64>()
    var queue: [(objectID: UInt64, depth: Int)] = roots.map { ($0, 0) }
    var nextIndex = 0

    while nextIndex < queue.count {
      let current = queue[nextIndex]
      nextIndex += 1
      if visited.contains(current.objectID) {
        continue
      }
      visited.insert(current.objectID)

      if let maxDepth, current.depth >= maxDepth {
        continue
      }

      let neighbors = adjacency[current.objectID, default: []]
      for neighbor in neighbors where !visited.contains(neighbor) {
        queue.append((neighbor, current.depth + 1))
      }
    }

    return visited
  }
}

public enum IWAInventoryError: LocalizedError {
  case truncatedBlob(String)
  case malformedArchiveInfo(String)

  public var errorDescription: String? {
    switch self {
    case .truncatedBlob(let path):
      return "Malformed IWA blob at \(path): unexpected end of data"
    case .malformedArchiveInfo(let path):
      return "Malformed IWA archive info in \(path)"
    }
  }
}

public enum IWAInventoryBuilder {
  private static let magic = Data("SNIWA1\0".utf8)
  private static let sheetSummaryPayloadTypeIDs: Set<UInt32> = [
    1,  // TN.DocumentArchive
    2,  // TN.SheetArchive
    6000,  // TST.TableInfoArchive
  ]
  private static let tableSummaryPayloadTypeIDs: Set<UInt32> = [
    1,  // TN.DocumentArchive
    2,  // TN.SheetArchive
    633,  // TSWP.CaptionInfoArchive
    2001,  // TSWP.StorageArchive
    2005,  // TSWP.StorageArchive alternative
    3097,  // TSD.StandinCaptionArchive
    6000,  // TST.TableInfoArchive
    6001,  // TST.TableModelArchive
  ]
  private static let selectedValuePayloadTypeIDs: Set<UInt32> = [
    1,  // TN.DocumentArchive
    2,  // TN.SheetArchive
    6000,  // TST.TableInfoArchive
    6001,  // TST.TableModelArchive
    6002,  // TST.TileArchive
    6005,  // TST.TableDataList
    6006,  // TST.HeaderStorageBucket
    6011,  // TST.TableDataListSegment
  ]
  private static let captionPayloadTypeIDs: Set<UInt32> = [
    633,  // TSWP.CaptionInfoArchive
    2001,  // TSWP.StorageArchive
    2005,  // TSWP.StorageArchive alternative
    3097,  // TSD.StandinCaptionArchive
  ]
  private static let stylePayloadTypeIDs: Set<UInt32> = [
    2021,  // TSWP.CharacterStyleArchive
    2022,  // TSWP.ParagraphStyleArchive
    6004,  // TST.CellStyleArchive
  ]
  private static let richTextPayloadTypeIDs: Set<UInt32> = [
    2001,  // TSWP.StorageArchive
    2005,  // TSWP.StorageArchive alternative
    2032,  // TSWP.HyperlinkFieldArchive
    2039,  // TSWP.UnsupportedHyperlinkFieldArchive
    6218,  // TST.RichTextPayloadArchive
  ]
  private static let mergePayloadTypeIDs: Set<UInt32> = [
    6144  // TST.MergeRegionMapArchive
  ]

  public static func build(from blobs: [ContainerBlob]) throws -> IWAInventory {
    try build(from: blobs, includingPayloadForTypeIDs: nil)
  }

  public static func build(
    from blobs: [ContainerBlob],
    includingPayloadForTypeIDs payloadTypeIDs: Set<UInt32>?
  ) throws -> IWAInventory {
    var records: [IWAObjectRecord] = []
    var unparsed: [String] = []
    let includePayloadForType: (UInt32) -> Bool = { typeID in
      guard let payloadTypeIDs else {
        return true
      }
      return payloadTypeIDs.contains(typeID)
    }

    for blob in blobs {
      if let parsed = try parseIWAArchiveBlob(blob, includePayloadForType: includePayloadForType) {
        records.append(contentsOf: parsed)
      } else if let parsed = try parseCustomBlob(
        blob,
        includePayloadForType: includePayloadForType
      ) {
        records.append(contentsOf: parsed)
      } else {
        unparsed.append(blob.path)
      }
    }

    return IWAInventory(records: records, unparsedBlobPaths: unparsed.sorted())
  }

  public static func buildSheetSummaryInventory(
    from blobs: [ContainerBlob]
  ) throws -> IWAInventory {
    try build(from: blobs, includingPayloadForTypeIDs: sheetSummaryPayloadTypeIDs)
  }

  public static func buildTableSummaryInventory(
    from blobs: [ContainerBlob]
  ) throws -> IWAInventory {
    try build(from: blobs, includingPayloadForTypeIDs: tableSummaryPayloadTypeIDs)
  }

  public static func buildSelectedReadInventory(
    from blobs: [ContainerBlob],
    features: IWAReadFeatures
  ) throws -> IWAInventory {
    var typeIDs = selectedValuePayloadTypeIDs
    if features.contains(.captions) {
      typeIDs.formUnion(captionPayloadTypeIDs)
    }
    if features.contains(.styles) {
      typeIDs.formUnion(stylePayloadTypeIDs)
    }
    if features.contains(.richText) {
      typeIDs.formUnion(richTextPayloadTypeIDs)
    }
    if features.contains(.merges) {
      typeIDs.formUnion(mergePayloadTypeIDs)
    }
    return try build(from: blobs, includingPayloadForTypeIDs: typeIDs)
  }

  private static func parseIWAArchiveBlob(
    _ blob: ContainerBlob,
    includePayloadForType: (UInt32) -> Bool
  ) throws -> [IWAObjectRecord]? {
    guard let decompressed = try decompressIWAChunks(blob.data, blobPath: blob.path) else {
      return nil
    }

    var cursor = 0
    var records: [IWAObjectRecord] = []

    while cursor < decompressed.count {
      guard let (archiveInfoLength, varintLength) = decodeVarint(from: decompressed, cursor: cursor)
      else {
        throw IWAInventoryError.truncatedBlob(blob.path)
      }
      cursor += varintLength

      guard archiveInfoLength <= UInt64(Int.max) else {
        throw IWAInventoryError.malformedArchiveInfo(blob.path)
      }
      let archiveLength = Int(archiveInfoLength)
      guard cursor + archiveLength <= decompressed.count else {
        throw IWAInventoryError.truncatedBlob(blob.path)
      }

      let archiveInfoData = decompressed[cursor..<(cursor + archiveLength)]
      let archiveInfo: TSP_ArchiveInfo
      do {
        archiveInfo = try TSP_ArchiveInfo(serializedBytes: archiveInfoData)
      } catch {
        throw IWAInventoryError.malformedArchiveInfo(blob.path)
      }
      cursor += archiveLength

      for messageInfo in archiveInfo.messageInfos {
        let payloadLength = Int(messageInfo.length)
        guard cursor + payloadLength <= decompressed.count else {
          throw IWAInventoryError.truncatedBlob(blob.path)
        }
        let payload: Data
        if includePayloadForType(messageInfo.type) {
          payload = Data(decompressed[cursor..<(cursor + payloadLength)])
        } else {
          payload = Data()
        }

        records.append(
          IWAObjectRecord(
            objectID: archiveInfo.identifier,
            typeID: messageInfo.type,
            payloadSize: payloadLength,
            payloadData: payload,
            sourceBlobPath: blob.path,
            objectReferences: messageInfo.objectReferences,
            dataReferences: messageInfo.dataReferences
          )
        )
        cursor += payloadLength
      }
    }

    return records
  }

  private static func parseCustomBlob(
    _ blob: ContainerBlob,
    includePayloadForType: (UInt32) -> Bool
  ) throws -> [IWAObjectRecord]? {
    let data = blob.data
    guard data.count >= magic.count, data.prefix(magic.count) == magic else {
      return nil
    }

    var cursor = magic.count
    let recordCount = try readUInt32(from: data, cursor: &cursor, blobPath: blob.path)

    var records: [IWAObjectRecord] = []
    records.reserveCapacity(Int(recordCount))

    for _ in 0..<recordCount {
      let objectID = try readUInt64(from: data, cursor: &cursor, blobPath: blob.path)
      let typeID = try readUInt32(from: data, cursor: &cursor, blobPath: blob.path)
      let payloadLength = try readUInt32(from: data, cursor: &cursor, blobPath: blob.path)

      let payloadSize = Int(payloadLength)
      guard cursor + payloadSize <= data.count else {
        throw IWAInventoryError.truncatedBlob(blob.path)
      }
      let payload: Data
      if includePayloadForType(typeID) {
        payload = Data(data[cursor..<(cursor + payloadSize)])
      } else {
        payload = Data()
      }
      cursor += payloadSize

      records.append(
        IWAObjectRecord(
          objectID: objectID,
          typeID: typeID,
          payloadSize: payloadSize,
          payloadData: payload,
          sourceBlobPath: blob.path
        )
      )
    }

    return records
  }

  private static func decompressIWAChunks(_ data: Data, blobPath: String) throws -> Data? {
    guard !data.isEmpty else {
      return nil
    }

    var cursor = 0
    var decompressed = Data()

    while cursor < data.count {
      guard cursor + 4 <= data.count else {
        throw IWAInventoryError.truncatedBlob(blobPath)
      }

      let firstByte = data[cursor]
      guard firstByte == 0x00 else {
        return nil
      }

      let compressedLength =
        Int(data[cursor + 1]) | (Int(data[cursor + 2]) << 8) | (Int(data[cursor + 3]) << 16)

      let payloadStart = cursor + 4
      let payloadEnd = payloadStart + compressedLength
      guard payloadEnd <= data.count else {
        throw IWAInventoryError.truncatedBlob(blobPath)
      }

      let compressedPayload = data[payloadStart..<payloadEnd]
      if let inflated = decompressSnappy(Data(compressedPayload)) {
        decompressed.append(inflated)
      } else {
        // Some fixtures are effectively uncompressed: keep the payload as-is.
        decompressed.append(compressedPayload)
      }

      cursor = payloadEnd
    }

    return decompressed
  }

  private static func decompressSnappy(_ data: Data) -> Data? {
    try? data.uncompressedUsingSnappy()
  }

  private static func decodeVarint(from data: Data, cursor: Int) -> (UInt64, Int)? {
    var value: UInt64 = 0
    var shift: UInt64 = 0
    var index = cursor

    while index < data.count, shift <= 63 {
      let byte = data[index]
      value |= UInt64(byte & 0x7F) << shift
      index += 1

      if (byte & 0x80) == 0 {
        return (value, index - cursor)
      }
      shift += 7
    }

    return nil
  }

  private static func readUInt32(from data: Data, cursor: inout Int, blobPath: String) throws
    -> UInt32
  {
    let size = MemoryLayout<UInt32>.size
    guard cursor + size <= data.count else {
      throw IWAInventoryError.truncatedBlob(blobPath)
    }

    var value: UInt32 = 0
    _ = withUnsafeMutableBytes(of: &value) { destination in
      data.copyBytes(to: destination, from: cursor..<(cursor + size))
    }
    cursor += size
    return UInt32(littleEndian: value)
  }

  private static func readUInt64(from data: Data, cursor: inout Int, blobPath: String) throws
    -> UInt64
  {
    let size = MemoryLayout<UInt64>.size
    guard cursor + size <= data.count else {
      throw IWAInventoryError.truncatedBlob(blobPath)
    }

    var value: UInt64 = 0
    _ = withUnsafeMutableBytes(of: &value) { destination in
      data.copyBytes(to: destination, from: cursor..<(cursor + size))
    }
    cursor += size
    return UInt64(littleEndian: value)
  }
}
