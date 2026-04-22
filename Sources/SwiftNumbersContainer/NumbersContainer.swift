import Foundation
import ZIPFoundation

public struct NumbersContainer: Sendable {
  public let rootURL: URL

  public init(rootURL: URL) {
    self.rootURL = rootURL
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
    let suffix = "/metadata/\(filename.lowercased())"
    guard
      let entry = archive.first(where: { candidate in
        candidate.type == .file && candidate.path.lowercased().hasSuffix(suffix)
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
}
