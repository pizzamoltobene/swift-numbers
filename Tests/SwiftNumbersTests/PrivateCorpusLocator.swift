import Foundation

enum PrivateCorpusLocator {
  private static let envKey = "SWIFT_NUMBERS_PRIVATE_CORPUS"
  private static let expectationsEnvKey = "SWIFT_NUMBERS_PRIVATE_EXPECTATIONS"

  static var corpusURL: URL? {
    let environment = ProcessInfo.processInfo.environment
    if let configuredPath = environment[envKey], !configuredPath.isEmpty {
      let url = URL(fileURLWithPath: configuredPath, isDirectory: true).standardizedFileURL
      return directoryExists(at: url) ? url : nil
    }

    let defaultURL = FixtureLocator.repoRoot
      .appendingPathComponent("PrivateCorpus", isDirectory: true)
      .standardizedFileURL
    return directoryExists(at: defaultURL) ? defaultURL : nil
  }

  static func numbersDocuments() -> [URL] {
    guard let corpusURL else {
      return []
    }

    let fm = FileManager.default
    guard
      let enumerator = fm.enumerator(
        at: corpusURL,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
      )
    else {
      return []
    }

    var documents: [URL] = []
    while let item = enumerator.nextObject() as? URL {
      if item.pathExtension.lowercased() != "numbers" {
        continue
      }

      let values = try? item.resourceValues(forKeys: [.isDirectoryKey])
      if values?.isDirectory == true {
        enumerator.skipDescendants()
      }
      documents.append(item.standardizedFileURL)
    }

    return documents.sorted { $0.path < $1.path }
  }

  static var expectationsURL: URL {
    let environment = ProcessInfo.processInfo.environment
    if let configuredPath = environment[expectationsEnvKey], !configuredPath.isEmpty {
      return URL(fileURLWithPath: configuredPath, isDirectory: false).standardizedFileURL
    }

    return FixtureLocator.repoRoot
      .appendingPathComponent(".private-corpus", isDirectory: true)
      .appendingPathComponent("expectations.json", isDirectory: false)
      .standardizedFileURL
  }

  static func relativePath(for documentURL: URL, corpusURL: URL) -> String {
    let basePath = corpusURL.standardizedFileURL.path
    let documentPath = documentURL.standardizedFileURL.path
    guard documentPath.hasPrefix(basePath) else {
      return documentURL.lastPathComponent
    }

    var relative = String(documentPath.dropFirst(basePath.count))
    if relative.hasPrefix("/") {
      relative.removeFirst()
    }
    return relative
  }

  private static func directoryExists(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
    return exists && isDirectory.boolValue
  }
}
