import Foundation
import SwiftNumbersContainer
import SwiftProtobuf

public enum MetadataLoaderError: LocalizedError {
  case invalidMetadataData(String)

  public var errorDescription: String? {
    switch self {
    case .invalidMetadataData(let details):
      return "Metadata decoding failed: \(details)"
    }
  }
}

public enum MetadataLoader {
  public static func loadDocumentMetadata(from container: NumbersContainer) throws
    -> Swiftnumbers_DocumentMetadata?
  {
    if let binary = try container.readMetadataFile(named: "DocumentMetadata.pb") {
      return try Swiftnumbers_DocumentMetadata(serializedBytes: binary)
    }

    if let json = try container.readMetadataFile(named: "DocumentMetadata.json") {
      do {
        return try Swiftnumbers_DocumentMetadata(jsonUTF8Data: json)
      } catch {
        throw MetadataLoaderError.invalidMetadataData(error.localizedDescription)
      }
    }

    return nil
  }
}
