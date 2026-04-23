import Foundation

public struct IWAWriteGraph: Sendable {
  public struct DirtyObject: Hashable, Sendable {
    public let objectID: UInt64
    public let typeID: UInt32
    public let sourceBlobPath: String
    public let reason: String

    public init(objectID: UInt64, typeID: UInt32, sourceBlobPath: String, reason: String) {
      self.objectID = objectID
      self.typeID = typeID
      self.sourceBlobPath = sourceBlobPath
      self.reason = reason
    }
  }

  public let recordsByObjectID: [UInt64: [IWAObjectRecord]]
  public let recordsByTypeID: [UInt32: [IWAObjectRecord]]
  public let recordsByBlobPath: [String: [IWAObjectRecord]]

  public private(set) var dirtyObjects: [DirtyObject] = []

  private var dirtyKeySet: Set<DirtyKey> = []

  public init(inventory: IWAInventory) {
    var byObjectID: [UInt64: [IWAObjectRecord]] = [:]
    var byTypeID: [UInt32: [IWAObjectRecord]] = [:]
    var byBlobPath: [String: [IWAObjectRecord]] = [:]

    for record in inventory.records {
      byObjectID[record.objectID, default: []].append(record)
      byTypeID[record.typeID, default: []].append(record)
      byBlobPath[record.sourceBlobPath, default: []].append(record)
    }

    self.recordsByObjectID = Self.normalizeBuckets(byObjectID)
    self.recordsByTypeID = Self.normalizeBuckets(byTypeID)
    self.recordsByBlobPath = Self.normalizeBuckets(byBlobPath)
  }

  public func records(forObjectID objectID: UInt64) -> [IWAObjectRecord] {
    recordsByObjectID[objectID] ?? []
  }

  public func records(forTypeID typeID: UInt32) -> [IWAObjectRecord] {
    recordsByTypeID[typeID] ?? []
  }

  public func records(forBlobPath blobPath: String) -> [IWAObjectRecord] {
    recordsByBlobPath[blobPath] ?? []
  }

  public func record(objectID: UInt64, typeID: UInt32? = nil) -> IWAObjectRecord? {
    let candidates = records(forObjectID: objectID)
    guard !candidates.isEmpty else {
      return nil
    }
    if let typeID {
      return candidates.first(where: { $0.typeID == typeID })
    }
    return candidates.first
  }

  public mutating func markDirty(objectID: UInt64, typeID: UInt32, reason: String) {
    guard let record = record(objectID: objectID, typeID: typeID) else {
      return
    }

    let key = DirtyKey(objectID: record.objectID, typeID: record.typeID)
    if dirtyKeySet.contains(key) {
      return
    }

    dirtyKeySet.insert(key)
    dirtyObjects.append(
      DirtyObject(
        objectID: record.objectID,
        typeID: record.typeID,
        sourceBlobPath: record.sourceBlobPath,
        reason: reason
      ))
    dirtyObjects.sort {
      if $0.sourceBlobPath == $1.sourceBlobPath {
        if $0.objectID == $1.objectID {
          return $0.typeID < $1.typeID
        }
        return $0.objectID < $1.objectID
      }
      return $0.sourceBlobPath < $1.sourceBlobPath
    }
  }

  private struct DirtyKey: Hashable, Sendable {
    let objectID: UInt64
    let typeID: UInt32
  }

  private static func normalizeBuckets<Key: Hashable>(
    _ buckets: [Key: [IWAObjectRecord]]
  ) -> [Key: [IWAObjectRecord]] {
    var normalized: [Key: [IWAObjectRecord]] = [:]
    normalized.reserveCapacity(buckets.count)

    for (key, value) in buckets {
      normalized[key] = value.sorted(by: { lhs, rhs in
        recordSortOrder(lhs: lhs, rhs: rhs)
      })
    }
    return normalized
  }

  private static func recordSortOrder(lhs: IWAObjectRecord, rhs: IWAObjectRecord) -> Bool {
    if lhs.objectID == rhs.objectID {
      if lhs.typeID == rhs.typeID {
        if lhs.sourceBlobPath == rhs.sourceBlobPath {
          return lhs.payloadSize < rhs.payloadSize
        }
        return lhs.sourceBlobPath < rhs.sourceBlobPath
      }
      return lhs.typeID < rhs.typeID
    }
    return lhs.objectID < rhs.objectID
  }
}
