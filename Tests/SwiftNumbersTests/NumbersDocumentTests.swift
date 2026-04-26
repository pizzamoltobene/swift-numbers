import XCTest

@testable import SwiftNumbersCore

final class NumbersDocumentTests: XCTestCase {
  private struct SimpleRow: Decodable, Equatable {
    let name: String
    let amount: Double
  }

  private func assertMetadataOnlyFixtureRejected(_ fixtureName: String) {
    let fixture = FixtureLocator.fixtureURL(named: fixtureName)
    XCTAssertThrowsError(try NumbersDocument.open(at: fixture)) { error in
      guard case .realReadFailed = error as? NumbersDocumentError else {
        return XCTFail("Expected realReadFailed, got \(error)")
      }
    }
  }

  func testOpenSimpleFixture() throws {
    assertMetadataOnlyFixtureRejected("simple-table.numbers")
  }

  func testMergedFixtureExposesMergeRanges() throws {
    assertMetadataOnlyFixtureRejected("merged-cells.numbers")
  }

  func testDumpIncludesTypeHistogram() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let document = try NumbersDocument.open(at: fixture)
    let output = document.renderDump()

    XCTAssertTrue(output.contains("Sheets: 1"))
    XCTAssertTrue(output.contains("Object reference edges:"))
    XCTAssertTrue(output.contains("Root objects:"))
    XCTAssertTrue(output.contains("Type histogram:"))
    XCTAssertTrue(output.contains("1:"))
  }

  func testCellLookupReturnsValuesFromTypedMetadata() throws {
    assertMetadataOnlyFixtureRejected("simple-table.numbers")
  }

  func testDumpExposesFallbackReadPathForSyntheticFixture() throws {
    assertMetadataOnlyFixtureRejected("simple-table.numbers")
  }

  func testDumpExposesRealReadPathForReferenceFixture() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let document = try NumbersDocument.open(at: fixture)
    let dump = document.dump()

    XCTAssertEqual(dump.readPath, .real)
    XCTAssertNil(dump.fallbackReason)
    XCTAssertGreaterThan(document.sheets.count, 0)
  }

  func testRealReadTableMetadataIncludesStableObjectIdentifiers() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let document = try NumbersDocument.open(at: fixture)
    XCTAssertEqual(document.dump().readPath, .real)

    let table = try XCTUnwrap(document.firstSheet?.firstTable)
    let identifiers = try XCTUnwrap(table.metadata.objectIdentifiers)
    XCTAssertGreaterThan(identifiers.tableInfoObjectID ?? 0, 0)
    XCTAssertGreaterThan(identifiers.tableModelObjectID ?? 0, 0)
  }

  func testReadLookupByNameAndIndex() throws {
    assertMetadataOnlyFixtureRejected("multi-sheet.numbers")
  }

  func testTableRowsAndA1CellAndFormattedValue() throws {
    assertMetadataOnlyFixtureRejected("simple-table.numbers")
  }

  func testMergedCellHelpers() throws {
    assertMetadataOnlyFixtureRejected("merged-cells.numbers")
  }

  func testTypedValueAccessorsAndReadCellDetails() throws {
    assertMetadataOnlyFixtureRejected("simple-table.numbers")
  }

  func testRangeAndColumnExtraction() throws {
    assertMetadataOnlyFixtureRejected("simple-table.numbers")
  }

  func testUsedRangeAndPopulatedCells() throws {
    assertMetadataOnlyFixtureRejected("simple-table.numbers")
  }

  func testDocumentNameAndCountHelpers() throws {
    assertMetadataOnlyFixtureRejected("multi-sheet.numbers")
  }

  func testDumpExposesStructuredDiagnostics() throws {
    let fixture = FixtureLocator.fileFixtureURL(named: "reference-empty.numbers")
    let document = try NumbersDocument.open(at: fixture)
    let dump = document.dump()
    XCTAssertFalse(dump.structuredDiagnostics.isEmpty)
  }

  func testReadCellMergeRole() throws {
    assertMetadataOnlyFixtureRejected("merged-cells.numbers")
  }

  func testDecodeRowsToDecodableModel() throws {
    let table = Table(
      id: "t1",
      name: "Table 1",
      metadata: TableMetadata(rowCount: 3, columnCount: 2, mergeRanges: []),
      cells: [
        CellAddress(row: 0, column: 0): .string("name"),
        CellAddress(row: 0, column: 1): .string("amount"),
        CellAddress(row: 1, column: 0): .string("Alice"),
        CellAddress(row: 1, column: 1): .number(12.5),
        CellAddress(row: 2, column: 0): .string("Bob"),
        CellAddress(row: 2, column: 1): .number(3.0),
      ]
    )

    let rows = try table.decodeRows(as: SimpleRow.self, headerRow: 0)
    XCTAssertEqual(
      rows,
      [SimpleRow(name: "Alice", amount: 12.5), SimpleRow(name: "Bob", amount: 3.0)]
    )
  }

  func testFormulaReadAPI() throws {
    let formulaAddress = CellAddress(row: 1, column: 1)
    let formulaResult = FormulaResultRead(
      formulaID: 77,
      rawFormula: "=SUM(A1:A2)",
      parsedTokens: ["=", "SUM", "(", "A1", ":", "A2", ")"],
      astSummary: "Decoded TSCE AST (7 nodes)",
      computedValue: .number(7),
      computedFormatted: "7"
    )
    let table = Table(
      id: "formula-table",
      name: "Formula Table",
      metadata: TableMetadata(rowCount: 3, columnCount: 3, mergeRanges: []),
      cells: [formulaAddress: .number(7)],
      readCells: [
        formulaAddress: ReadCell(
          address: formulaAddress,
          value: .number(7),
          kind: .formula,
          readValue: .formulaResult(formulaResult),
          formulaResult: formulaResult,
          formatted: "7",
          rawCellType: 4,
          formulaID: 77
        )
      ]
    )

    let formula = try XCTUnwrap(table.formula("B2"))
    XCTAssertEqual(formula.formulaID, 77)
    XCTAssertEqual(formula.rawFormula, "=SUM(A1:A2)")
    XCTAssertEqual(formula.parsedTokens, ["=", "SUM", "(", "A1", ":", "A2", ")"])
    XCTAssertEqual(formula.resultFormatted, "7")

    let all = table.formulas()
    XCTAssertEqual(all.count, 1)
    XCTAssertEqual(all[0].reference, "B2")

    let extracted = try table.value(FormulaResultRead.self, at: "B2")
    XCTAssertEqual(extracted.rawFormula, "=SUM(A1:A2)")
    XCTAssertEqual(extracted.computedValue, .number(7))
    XCTAssertEqual(table.formulaResult("B2")?.computedFormatted, "7")
  }

  func testRichTextAndStyleReadAccessors() throws {
    let address = CellAddress(row: 0, column: 0)
    let richText = RichTextRead(
      text: "Hello",
      runs: [
        RichTextRun(
          range: 0..<5,
          text: "Hello",
          fontName: "Helvetica",
          fontSize: 12,
          isBold: true,
          textColorHex: "#336699",
          linkURL: "https://example.com"
        )
      ]
    )
    let style = ReadCellStyle(
      horizontalAlignment: .left,
      verticalAlignment: .top,
      backgroundColorHex: "#FFFFFF",
      fontName: "Helvetica Neue",
      fontSize: 12,
      isBold: true,
      isItalic: false,
      textColorHex: "#336699",
      hasTopBorder: true,
      numberFormat: ReadNumberFormat(kind: .text, formatID: 25)
    )

    let table = Table(
      id: "rich-table",
      name: "Rich Table",
      metadata: TableMetadata(rowCount: 1, columnCount: 1, mergeRanges: []),
      cells: [address: .string("Hello")],
      readCells: [
        address: ReadCell(
          address: address,
          value: .string("Hello"),
          kind: .richText,
          formatted: "Hello",
          richText: richText,
          style: style,
          rawCellType: 9,
          richTextID: 1
        )
      ]
    )

    XCTAssertEqual(table.richText("A1")?.text, "Hello")
    XCTAssertEqual(table.richText(at: address)?.runs.first?.linkURL, "https://example.com")
    XCTAssertEqual(table.style("A1")?.backgroundColorHex, "#FFFFFF")
    XCTAssertEqual(table.style("A1")?.fontName, "Helvetica Neue")
    XCTAssertEqual(table.style("A1")?.fontSize, 12)
    XCTAssertEqual(table.style("A1")?.isBold, true)
    XCTAssertEqual(table.style("A1")?.isItalic, false)
    XCTAssertEqual(table.style("A1")?.textColorHex, "#336699")
    XCTAssertEqual(table.style(at: address)?.numberFormat?.formatID, 25)
    if case .richText(let extracted)? = table.readValue("A1") {
      XCTAssertEqual(extracted.text, "Hello")
    } else {
      XCTFail("Expected rich text read value")
    }
  }

  func testFormattedValueModesAndStyleHints() throws {
    let numberAddress = CellAddress(row: 0, column: 0)
    let dateAddress = CellAddress(row: 0, column: 1)
    let durationAddress = CellAddress(row: 0, column: 2)
    let date = Date(timeIntervalSinceReferenceDate: 0)
    let currencyStyle = ReadCellStyle(numberFormat: ReadNumberFormat(kind: .currency, formatID: 1))

    let table = Table(
      id: "format-table",
      name: "Format Table",
      metadata: TableMetadata(rowCount: 1, columnCount: 3, mergeRanges: []),
      cells: [
        numberAddress: .number(42.5),
        dateAddress: .date(date),
        durationAddress: .number(3661),
      ],
      readCells: [
        numberAddress: ReadCell(
          address: numberAddress,
          value: .number(42.5),
          kind: .number,
          formatted: "42.5",
          style: currencyStyle
        ),
        dateAddress: ReadCell(
          address: dateAddress,
          value: .date(date),
          kind: .date,
          formatted: "2001-01-01T00:00:00.000Z"
        ),
        durationAddress: ReadCell(
          address: durationAddress,
          value: .number(3661),
          kind: .duration,
          readValue: .duration(3661),
          formatted: "3661"
        ),
      ]
    )

    let currency = table.formattedValue(
      "A1",
      options: ReadFormattingOptions(
        localeIdentifier: "en_US_POSIX",
        timeZoneIdentifier: "UTC",
        usesGroupingSeparator: false,
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
        includeFractionalSeconds: true,
        numberFormatMode: .decimal,
        dateFormatMode: .iso8601,
        durationFormatMode: .seconds,
        preferCellNumberFormatHints: true
      )
    )
    XCTAssertTrue(currency?.contains("$") == true)

    let percent = table.formattedValue(
      "A1",
      options: ReadFormattingOptions(
        localeIdentifier: "en_US_POSIX",
        numberFormatMode: .percent,
        preferCellNumberFormatHints: false
      )
    )
    XCTAssertTrue(percent?.contains("%") == true)

    XCTAssertEqual(
      table.formattedValue(
        "B1",
        options: ReadFormattingOptions(
          localeIdentifier: "en_US_POSIX",
          timeZoneIdentifier: "UTC",
          dateFormatMode: .pattern("yyyy-MM-dd"),
          preferCellNumberFormatHints: false
        )
      ),
      "2001-01-01"
    )

    XCTAssertEqual(
      table.formattedValue(
        "C1",
        options: ReadFormattingOptions(durationFormatMode: .hhmmss)
      ),
      "01:01:01"
    )

    XCTAssertEqual(
      table.formattedValue(
        "C1",
        options: ReadFormattingOptions(durationFormatMode: .abbreviated)
      ),
      "1h 1m 1s"
    )
  }

  func testFormattedValueISO8601FallsBackToUTCForInvalidTimeZone() {
    let address = CellAddress(row: 0, column: 0)
    let referenceDate = Date(timeIntervalSinceReferenceDate: 0)
    let table = Table(
      id: "fmt-timezone",
      name: "Formatting",
      metadata: TableMetadata(rowCount: 1, columnCount: 1, mergeRanges: []),
      cells: [address: .date(referenceDate)],
      readCells: [
        address: ReadCell(
          address: address,
          value: .date(referenceDate),
          kind: .date,
          formatted: "2001-01-01T00:00:00Z"
        )
      ]
    )

    let value = table.formattedValue(
      "A1",
      options: ReadFormattingOptions(
        localeIdentifier: "en_US_POSIX",
        timeZoneIdentifier: "Invalid/TimeZone",
        includeFractionalSeconds: false,
        dateFormatMode: .iso8601,
        preferCellNumberFormatHints: false
      )
    )
    XCTAssertEqual(value, "2001-01-01T00:00:00Z")
  }

  func testFormattedValuePatternFallsBackToUTCForInvalidTimeZone() {
    let address = CellAddress(row: 0, column: 0)
    let referenceDate = Date(timeIntervalSinceReferenceDate: 0)
    let table = Table(
      id: "fmt-pattern-timezone",
      name: "Formatting",
      metadata: TableMetadata(rowCount: 1, columnCount: 1, mergeRanges: []),
      cells: [address: .date(referenceDate)],
      readCells: [
        address: ReadCell(
          address: address,
          value: .date(referenceDate),
          kind: .date,
          formatted: "2001-01-01 00:00"
        )
      ]
    )

    let invalidTimeZoneValue = table.formattedValue(
      "A1",
      options: ReadFormattingOptions(
        localeIdentifier: "en_US_POSIX",
        timeZoneIdentifier: "Invalid/TimeZone",
        dateFormatMode: .pattern("yyyy-MM-dd HH:mm"),
        preferCellNumberFormatHints: false
      )
    )

    let utcValue = table.formattedValue(
      "A1",
      options: ReadFormattingOptions(
        localeIdentifier: "en_US_POSIX",
        timeZoneIdentifier: "UTC",
        dateFormatMode: .pattern("yyyy-MM-dd HH:mm"),
        preferCellNumberFormatHints: false
      )
    )

    XCTAssertEqual(invalidTimeZoneValue, "2001-01-01 00:00")
    XCTAssertEqual(invalidTimeZoneValue, utcValue)
  }

  func testFormattedValueStyledDateHonorsLocaleDeterministically() {
    let address = CellAddress(row: 0, column: 0)
    let referenceDate = Date(timeIntervalSinceReferenceDate: 0)
    let table = Table(
      id: "fmt-locale-date",
      name: "Formatting",
      metadata: TableMetadata(rowCount: 1, columnCount: 1, mergeRanges: []),
      cells: [address: .date(referenceDate)],
      readCells: [
        address: ReadCell(
          address: address,
          value: .date(referenceDate),
          kind: .date,
          formatted: "Monday"
        )
      ]
    )

    let enOptions = ReadFormattingOptions(
      localeIdentifier: "en_US_POSIX",
      timeZoneIdentifier: "UTC",
      dateFormatMode: .styled(date: .full, time: .none),
      preferCellNumberFormatHints: false
    )
    let frOptions = ReadFormattingOptions(
      localeIdentifier: "fr_FR",
      timeZoneIdentifier: "UTC",
      dateFormatMode: .styled(date: .full, time: .none),
      preferCellNumberFormatHints: false
    )

    let enValue = table.formattedValue("A1", options: enOptions)
    let frValue = table.formattedValue("A1", options: frOptions)

    let expectedEN = expectedStyledDateString(
      for: referenceDate,
      localeIdentifier: "en_US_POSIX",
      timeZoneIdentifier: "UTC",
      dateStyle: .full,
      timeStyle: .none
    )
    let expectedFR = expectedStyledDateString(
      for: referenceDate,
      localeIdentifier: "fr_FR",
      timeZoneIdentifier: "UTC",
      dateStyle: .full,
      timeStyle: .none
    )

    XCTAssertEqual(enValue, expectedEN)
    XCTAssertEqual(frValue, expectedFR)
    XCTAssertNotEqual(enValue, frValue)
  }

  private func expectedStyledDateString(
    for date: Date,
    localeIdentifier: String,
    timeZoneIdentifier: String,
    dateStyle: DateFormatter.Style,
    timeStyle: DateFormatter.Style
  ) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: localeIdentifier)
    formatter.timeZone = TimeZone(identifier: timeZoneIdentifier)
    formatter.dateStyle = dateStyle
    formatter.timeStyle = timeStyle
    return formatter.string(from: date)
  }
}
