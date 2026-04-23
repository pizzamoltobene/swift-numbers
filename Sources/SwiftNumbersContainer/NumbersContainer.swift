import Foundation
import ZIPFoundation

public struct NumbersContainer: Sendable {
  public let rootURL: URL

  public init(rootURL: URL) {
    self.rootURL = rootURL
  }

  public static func copyContainer(
    from sourceURL: URL,
    to destinationURL: URL,
    replacingMetadataFiles metadataFiles: [String: Data] = [:],
    replacingIndexBlobs indexBlobs: [String: Data] = [:]
  ) throws {
    let source = sourceURL.standardizedFileURL
    let destination = destinationURL.standardizedFileURL

    guard FileManager.default.fileExists(atPath: source.path) else {
      throw NumbersContainerError.pathDoesNotExist(source)
    }

    let parent = destination.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)

    if isDirectory(at: source) {
      if FileManager.default.fileExists(atPath: destination.path) {
        try FileManager.default.removeItem(at: destination)
      }
      try FileManager.default.copyItem(at: source, to: destination)

      if !metadataFiles.isEmpty {
        let metadataURL = destination.appendingPathComponent("Metadata", isDirectory: true)
        try FileManager.default.createDirectory(at: metadataURL, withIntermediateDirectories: true)
        for filename in metadataFiles.keys.sorted() {
          let target = metadataURL.appendingPathComponent(filename, isDirectory: false)
          try metadataFiles[filename]?.write(to: target)
        }
      }

      if !indexBlobs.isEmpty {
        try replaceIndexBlobsInPackage(packageURL: destination, blobs: indexBlobs)
      }
      return
    }

    try rewriteArchiveContainer(
      source: source,
      destination: destination,
      replacingMetadataFiles: metadataFiles,
      replacingIndexBlobs: indexBlobs
    )
  }

  public static func open(at url: URL) throws -> NumbersContainer {
    let normalizedURL = url.standardizedFileURL
    guard FileManager.default.fileExists(atPath: normalizedURL.path) else {
      throw NumbersContainerError.pathDoesNotExist(normalizedURL)
    }
    return NumbersContainer(rootURL: normalizedURL)
  }

  public func loadIndexBlobs() throws -> [ContainerBlob] {
    if isDirectory {
      return try loadIndexBlobsFromPackage()
    }
    return try loadIndexBlobsFromSingleFile()
  }

  public func readMetadataFile(named filename: String) throws -> Data? {
    if isDirectory {
      let metadataURL = rootURL.appendingPathComponent("Metadata", isDirectory: true)
      guard FileManager.default.fileExists(atPath: metadataURL.path) else {
        throw NumbersContainerError.metadataNotFound(rootURL)
      }

      let target = metadataURL.appendingPathComponent(filename, isDirectory: false)
      guard FileManager.default.fileExists(atPath: target.path) else {
        return nil
      }
      return try Data(contentsOf: target)
    }

    let archive = try openArchive(at: rootURL)
    let lowercasedFilename = filename.lowercased()
    let directPath = "metadata/\(lowercasedFilename)"
    let nestedSuffix = "/metadata/\(lowercasedFilename)"
    guard
      let entry = archive.first(where: { candidate in
        guard candidate.type == .file else {
          return false
        }
        let path = candidate.path.lowercased()
        return path == directPath || path.hasSuffix(nestedSuffix)
      })
    else {
      return nil
    }
    return try extract(entry: entry, from: archive)
  }

  public func listMetadataFiles() throws -> [String] {
    if isDirectory {
      let metadataURL = rootURL.appendingPathComponent("Metadata", isDirectory: true)
      guard FileManager.default.fileExists(atPath: metadataURL.path) else {
        return []
      }

      let files = try FileManager.default.contentsOfDirectory(atPath: metadataURL.path)
      return files.sorted()
    }

    let archive = try openArchive(at: rootURL)
    let metadataFiles = archive.compactMap { entry -> String? in
      guard entry.type == .file else {
        return nil
      }
      let parts = entry.path.split(separator: "/")
      guard parts.count >= 2 else {
        return nil
      }
      let metadataFolder = parts[parts.count - 2]
      guard metadataFolder.lowercased() == "metadata" else {
        return nil
      }
      return String(parts.last!)
    }

    return Array(Set(metadataFiles)).sorted()
  }

  private var isDirectory: Bool {
    var isDirectory: ObjCBool = false
    _ = FileManager.default.fileExists(atPath: rootURL.path, isDirectory: &isDirectory)
    return isDirectory.boolValue
  }

  private func loadIndexBlobsFromPackage() throws -> [ContainerBlob] {
    let indexZipURL = rootURL.appendingPathComponent("Index.zip", isDirectory: false)
    if FileManager.default.fileExists(atPath: indexZipURL.path) {
      let indexArchive = try openArchive(at: indexZipURL)
      return try extractBlobs(from: indexArchive, filter: { $0.type == .file })
    }

    let indexFolderURL = rootURL.appendingPathComponent("Index", isDirectory: true)
    var isIndexFolder: ObjCBool = false
    guard FileManager.default.fileExists(atPath: indexFolderURL.path, isDirectory: &isIndexFolder),
      isIndexFolder.boolValue
    else {
      throw NumbersContainerError.indexZipMissing(rootURL)
    }

    let enumerator = FileManager.default.enumerator(
      at: indexFolderURL, includingPropertiesForKeys: nil)
    var blobs: [ContainerBlob] = []
    while let fileURL = enumerator?.nextObject() as? URL {
      var isFileDirectory: ObjCBool = false
      guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isFileDirectory),
        !isFileDirectory.boolValue
      else {
        continue
      }
      let data = try Data(contentsOf: fileURL)
      let relativePath = fileURL.path.replacingOccurrences(of: rootURL.path + "/", with: "")
      blobs.append(ContainerBlob(path: relativePath, data: data))
    }
    return blobs.sorted { $0.path < $1.path }
  }

  private func loadIndexBlobsFromSingleFile() throws -> [ContainerBlob] {
    let archive = try openArchive(at: rootURL)
    let topLevelIndexBlobs = try extractBlobs(
      from: archive,
      filter: { entry in
        guard entry.type == .file else {
          return false
        }
        let lowercasedPath = entry.path.lowercased()
        let inIndexFolder = lowercasedPath.hasPrefix("index/") || lowercasedPath.contains("/index/")
        return inIndexFolder && lowercasedPath.hasSuffix(".iwa")
      })

    if !topLevelIndexBlobs.isEmpty {
      return topLevelIndexBlobs
    }

    guard
      let nestedIndexEntry = archive.first(where: { entry in
        entry.type == .file && entry.path.lowercased().hasSuffix("index.zip")
      })
    else {
      throw NumbersContainerError.indexEntriesMissing(rootURL)
    }

    let nestedIndexData = try extract(entry: nestedIndexEntry, from: archive)
    let nestedArchive: Archive
    do {
      nestedArchive = try Archive(data: nestedIndexData, accessMode: .read)
    } catch {
      throw NumbersContainerError.invalidZipArchive(rootURL)
    }

    return try extractBlobs(from: nestedArchive, filter: { $0.type == .file })
  }

  private func openArchive(at url: URL) throws -> Archive {
    do {
      return try Archive(url: url, accessMode: .read)
    } catch {
      throw NumbersContainerError.invalidZipArchive(url)
    }
  }

  private func extractBlobs(from archive: Archive, filter: (Entry) -> Bool) throws
    -> [ContainerBlob]
  {
    var blobs: [ContainerBlob] = []
    for entry in archive where filter(entry) {
      let data = try extract(entry: entry, from: archive)
      blobs.append(ContainerBlob(path: entry.path, data: data))
    }
    return blobs.sorted { $0.path < $1.path }
  }

  private func extract(entry: Entry, from archive: Archive) throws -> Data {
    var data = Data()
    _ = try archive.extract(entry) { chunk in
      data.append(chunk)
    }
    return data
  }

  private static func isDirectory(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    _ = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
    return isDirectory.boolValue
  }

  private static func rewriteArchiveContainer(
    source: URL,
    destination: URL,
    replacingMetadataFiles metadataFiles: [String: Data],
    replacingIndexBlobs indexBlobs: [String: Data]
  ) throws {
    let sourceArchive: Archive
    do {
      sourceArchive = try Archive(url: source, accessMode: .read)
    } catch {
      throw NumbersContainerError.invalidZipArchive(source)
    }

    if FileManager.default.fileExists(atPath: destination.path) {
      try FileManager.default.removeItem(at: destination)
    }

    let destinationArchive: Archive
    do {
      destinationArchive = try Archive(url: destination, accessMode: .create)
    } catch {
      throw NumbersContainerError.invalidZipArchive(destination)
    }

    let replacedMetadataNames = Set(metadataFiles.keys.map { $0.lowercased() })
    let replacedIndexBlobsByLowerPath = Dictionary(
      uniqueKeysWithValues: indexBlobs.map { ($0.key.lowercased(), (path: $0.key, data: $0.value)) }
    )
    var fileEntries: [(path: String, data: Data)] = []
    fileEntries.reserveCapacity(64)

    for entry in sourceArchive where entry.type == .file {
      let lowercasedPath = entry.path.lowercased()
      if isReplacedMetadataEntry(
        pathLowercased: lowercasedPath, metadataNames: replacedMetadataNames)
      {
        continue
      }
      if replacedIndexBlobsByLowerPath[lowercasedPath] != nil {
        continue
      }
      let data = try extract(entry: entry, from: sourceArchive)
      fileEntries.append((path: entry.path, data: data))
    }

    for filename in metadataFiles.keys.sorted() {
      guard let data = metadataFiles[filename] else {
        continue
      }
      fileEntries.append((path: "Metadata/\(filename)", data: data))
    }

    for key in indexBlobs.keys.sorted() {
      guard let data = indexBlobs[key] else {
        continue
      }
      fileEntries.append((path: key, data: data))
    }

    for entry in fileEntries.sorted(by: { $0.path < $1.path }) {
      let payload = entry.data
      try destinationArchive.addEntry(
        with: entry.path,
        type: .file,
        uncompressedSize: Int64(payload.count),
        compressionMethod: .deflate,
        provider: { position, size in
          let start = Int(position)
          let end = min(start + size, payload.count)
          guard start >= 0, end >= start else {
            return Data()
          }
          return payload.subdata(in: start..<end)
        }
      )
    }
  }

  private static func isReplacedMetadataEntry(
    pathLowercased: String,
    metadataNames: Set<String>
  ) -> Bool {
    guard !metadataNames.isEmpty else {
      return false
    }
    for name in metadataNames {
      let direct = "metadata/\(name)"
      if pathLowercased == direct || pathLowercased.hasSuffix("/\(direct)") {
        return true
      }
    }
    return false
  }

  private static func extract(entry: Entry, from archive: Archive) throws -> Data {
    var data = Data()
    _ = try archive.extract(entry) { chunk in
      data.append(chunk)
    }
    return data
  }

  private static func replaceIndexBlobsInPackage(packageURL: URL, blobs: [String: Data]) throws {
    let indexZipURL = packageURL.appendingPathComponent("Index.zip", isDirectory: false)
    if FileManager.default.fileExists(atPath: indexZipURL.path) {
      try rewriteZipFile(
        at: indexZipURL,
        replacingEntries: blobs
      )
      return
    }

    let indexDirectoryURL = packageURL.appendingPathComponent("Index", isDirectory: true)
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: indexDirectoryURL.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      throw NumbersContainerError.indexZipMissing(packageURL)
    }

    for key in blobs.keys.sorted() {
      guard let data = blobs[key] else {
        continue
      }
      let target = packageURL.appendingPathComponent(key, isDirectory: false)
      try FileManager.default.createDirectory(
        at: target.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try data.write(to: target)
    }
  }

  private static func rewriteZipFile(
    at zipURL: URL,
    replacingEntries replacements: [String: Data]
  ) throws {
    let sourceArchive: Archive
    do {
      sourceArchive = try Archive(url: zipURL, accessMode: .read)
    } catch {
      throw NumbersContainerError.invalidZipArchive(zipURL)
    }

    let tempURL = zipURL.deletingLastPathComponent().appendingPathComponent(
      ".\(UUID().uuidString)-\(zipURL.lastPathComponent)"
    )
    if FileManager.default.fileExists(atPath: tempURL.path) {
      try FileManager.default.removeItem(at: tempURL)
    }

    let replacementByLowerPath = Dictionary(
      uniqueKeysWithValues: replacements.map {
        ($0.key.lowercased(), (path: $0.key, data: $0.value))
      })

    let destinationArchive: Archive
    do {
      destinationArchive = try Archive(url: tempURL, accessMode: .create)
    } catch {
      throw NumbersContainerError.invalidZipArchive(tempURL)
    }

    var entries: [(path: String, data: Data)] = []
    for entry in sourceArchive where entry.type == .file {
      if replacementByLowerPath[entry.path.lowercased()] != nil {
        continue
      }
      let data = try extract(entry: entry, from: sourceArchive)
      entries.append((path: entry.path, data: data))
    }

    for key in replacements.keys.sorted() {
      guard let data = replacements[key] else {
        continue
      }
      entries.append((path: key, data: data))
    }

    for entry in entries.sorted(by: { $0.path < $1.path }) {
      let payload = entry.data
      try destinationArchive.addEntry(
        with: entry.path,
        type: .file,
        uncompressedSize: Int64(payload.count),
        compressionMethod: .deflate,
        provider: { position, size in
          let start = Int(position)
          let end = min(start + size, payload.count)
          guard start >= 0, end >= start else {
            return Data()
          }
          return payload.subdata(in: start..<end)
        }
      )
    }

    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: zipURL.path) {
      _ = try fileManager.replaceItemAt(
        zipURL,
        withItemAt: tempURL,
        backupItemName: nil,
        options: [.usingNewMetadataOnly]
      )
    } else {
      try fileManager.moveItem(at: tempURL, to: zipURL)
    }
  }
}
