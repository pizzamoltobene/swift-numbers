import Foundation

enum FixtureLocator {
  static var repoRoot: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
  }

  static var fixturesRoot: URL {
    repoRoot
      .appendingPathComponent("Tests", isDirectory: true)
      .appendingPathComponent("Fixtures", isDirectory: true)
  }

  static func fixtureURL(named name: String) -> URL {
    fixturesRoot
      .appendingPathComponent(name, isDirectory: true)
  }

  static func fileFixtureURL(named name: String) -> URL {
    fixturesRoot
      .appendingPathComponent(name, isDirectory: false)
  }
}
