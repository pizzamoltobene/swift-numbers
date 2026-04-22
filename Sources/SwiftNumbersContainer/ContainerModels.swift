import Foundation

public struct ContainerBlob: Sendable, Hashable {
  public let path: String
  public let data: Data

  public init(path: String, data: Data) {
    self.path = path
    self.data = data
  }
}

public enum NumbersContainerError: LocalizedError {
  case pathDoesNotExist(URL)
  case indexZipMissing(URL)
  case indexEntriesMissing(URL)
  case metadataNotFound(URL)
  case cannotReadEntry(String)
  case invalidZipArchive(URL)

  public var errorDescription: String? {
    switch self {
    case .pathDoesNotExist(let url):
      return "Path does not exist: \(url.path)"
    case .indexZipMissing(let url):
      return "Missing Index.zip in container: \(url.path)"
    case .indexEntriesMissing(let url):
      return "Missing Index entries in container: \(url.path)"
    case .metadataNotFound(let url):
      return "Metadata folder not found in container: \(url.path)"
    case .cannotReadEntry(let path):
      return "Cannot read archive entry: \(path)"
    case .invalidZipArchive(let url):
      return "Cannot open zip archive: \(url.path)"
    }
  }
}
