import Foundation
import XCTest

@testable import SwiftNumbersCore

final class PrivateCorpusIntegrationTests: XCTestCase {
  func testPrivateCorpusOpenDumpAndCellExtractionAgainstManifest() throws {
    guard let corpusURL = PrivateCorpusLocator.corpusURL else {
      throw XCTSkip(
        "Private corpus not configured. Set SWIFT_NUMBERS_PRIVATE_CORPUS or create PrivateCorpus/.")
    }

    let documents = PrivateCorpusLocator.numbersDocuments()
    guard !documents.isEmpty else {
      throw XCTSkip("No .numbers documents found in private corpus at \(corpusURL.path).")
    }

    let expectationsURL = PrivateCorpusLocator.expectationsURL
    guard FileManager.default.fileExists(atPath: expectationsURL.path) else {
      XCTFail(
        "Private corpus expectation manifest is missing at \(expectationsURL.path). "
          + "Generate it with scripts/update_private_corpus_expectations.py --write.")
      return
    }

    let manifest = try loadManifest(from: expectationsURL)
    let expectationByPath = Dictionary(
      uniqueKeysWithValues: manifest.documents.map { ($0.path, $0) })

    for documentURL in documents {
      let relativePath = PrivateCorpusLocator.relativePath(for: documentURL, corpusURL: corpusURL)
      guard let expectation = expectationByPath[relativePath] else {
        XCTFail("Missing private-corpus expectation for \(relativePath).")
        continue
      }

      let document = try NumbersDocument.open(at: documentURL)
      let dump = document.dump()

      let sheetCount = document.sheets.count
      let tableCount = document.sheets.reduce(0) { $0 + $1.tables.count }
      let populatedCells = document.sheets
        .flatMap(\.tables)
        .reduce(0) { $0 + $1.populatedCellCount }

      XCTAssertGreaterThanOrEqual(
        sheetCount,
        expectation.minSheets,
        "Sheet count regression for \(relativePath)")
      XCTAssertGreaterThanOrEqual(
        tableCount,
        expectation.minTables,
        "Table count regression for \(relativePath)")
      XCTAssertGreaterThanOrEqual(
        populatedCells,
        expectation.minPopulatedCells,
        "Populated-cell regression for \(relativePath)")

      if !expectation.allowEmptyCells {
        XCTAssertGreaterThan(
          populatedCells,
          0,
          "Expected non-empty cells for \(relativePath)")
      }

      XCTAssertFalse(
        dump.sourcePath.isEmpty,
        "Dump output must include source path for \(relativePath)")
    }
  }

  private func loadManifest(from url: URL) throws -> PrivateCorpusExpectationManifest {
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(PrivateCorpusExpectationManifest.self, from: data)
  }
}

private struct PrivateCorpusExpectationManifest: Codable {
  let version: Int
  let generatedAt: String?
  let documents: [PrivateCorpusExpectation]
}

private struct PrivateCorpusExpectation: Codable {
  let path: String
  let minSheets: Int
  let minTables: Int
  let minPopulatedCells: Int
  let allowEmptyCells: Bool
}
