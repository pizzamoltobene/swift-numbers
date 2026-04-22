import Foundation

enum FixtureLocator {
  static var repoRoot: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
  }

  static func fixtureURL(named name: String) -> URL {
    repoRoot.appendingPathComponent("Fixtures", isDirectory: true)
      .appendingPathComponent(name, isDirectory: true)
  }

  static func fileFixtureURL(named name: String) -> URL {
    repoRoot.appendingPathComponent("Fixtures", isDirectory: true)
      .appendingPathComponent(name, isDirectory: false)
  }
}
