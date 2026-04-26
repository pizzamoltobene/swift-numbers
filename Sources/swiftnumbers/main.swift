import ArgumentParser
import Foundation
import SwiftNumbersCore

enum OutputFormat: String, ExpressibleByArgument {
  case text
  case json
}

enum ExportCSVMode: String, ExpressibleByArgument {
  case value
  case formatted
  case formula
}

enum ImportCSVHeaderMode: String, ExpressibleByArgument {
  case withHeader = "with-header"
  case noHeader = "no-header"
}

@main
struct SwiftNumbersCLI: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "swiftnumbers",
    abstract: "Swift-native reader and tooling for .numbers containers.",
    subcommands: [
      Dump.self,
      ListSheets.self,
      ListTables.self,
      ListFormulas.self,
      ReadColumnCommand.self,
      ReadCellCommand.self,
      ReadTableCommand.self,
      ReadRangeCommand.self,
      ExportCSVCommand.self,
      ImportCSVCommand.self,
    ]
  )
}

struct Dump: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Prints structural information for a .numbers document."
  )

  @Argument(help: "Path to a .numbers package")
  var file: String

  @Option(name: .long, help: "Output format: text or json")
  var format: OutputFormat = .text

  @Flag(name: .long, help: "Include formula read details when available")
  var formulas: Bool = false

  @Flag(name: .long, help: "Include populated-cell read snapshots")
  var cells: Bool = false

  @Flag(name: .long, help: "Include deterministic formatting snapshots for populated cells")
  var formatting: Bool = false

  mutating func run() throws {
    let url = URL(fileURLWithPath: file)
    let document = try NumbersDocument.open(at: url)
    let formulaEntries = collectFormulaEntries(from: document)
    let cellEntries = cells ? collectCellEntries(from: document) : []
    let formattingEntries = formatting ? collectFormattingEntries(from: document) : []

    switch format {
    case .text:
      print(document.renderDump())
      if formulas {
        print("")
        print("Formulas: \(formulaEntries.count)")
        if formulaEntries.isEmpty {
          print("  <none>")
        } else {
          for entry in formulaEntries {
            let formulaID = entry.formulaID.map { String($0) } ?? "-"
            let raw = entry.rawFormula ?? "<unresolved>"
            print(
              "  \(entry.sheetName)/\(entry.tableName) \(entry.cellReference) [id=\(formulaID)] result=\(entry.resultFormatted) raw=\(raw)"
            )
          }
        }
      }
      if cells {
        print("")
        print("Cells: \(cellEntries.count)")
        if cellEntries.isEmpty {
          print("  <none>")
        } else {
          for entry in cellEntries {
            print(
              "  \(entry.sheetName)/\(entry.tableName) \(entry.cellReference) kind=\(entry.kind) value=\(describeTypedValue(entry.readValue)) formatted=\(entry.formatted)"
            )
          }
        }
      }
      if formatting {
        print("")
        print("Formatting: \(formattingEntries.count)")
        if formattingEntries.isEmpty {
          print("  <none>")
        } else {
          for entry in formattingEntries {
            print(
              "  \(entry.sheetName)/\(entry.tableName) \(entry.cellReference) default=\(entry.defaultFormatted) decimal=\(entry.decimal) currency=\(entry.currencyUSD) percent=\(entry.percent) scientific=\(entry.scientific)"
            )
          }
        }
      }
    case .json:
      let payload = DumpJSONPayload(
        dump: document.dump(),
        sheets: document.sheets,
        formulas: formulas ? formulaEntries : nil,
        cells: cells ? cellEntries : nil,
        formatting: formatting ? formattingEntries : nil
      )
      print(try renderJSON(payload))
    }
  }
}

struct ListSheets: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-sheets",
    abstract: "Prints all sheet names."
  )

  @Argument(help: "Path to a .numbers package")
  var file: String

  @Option(name: .long, help: "Output format: text or json")
  var format: OutputFormat = .text

  mutating func run() throws {
    let url = URL(fileURLWithPath: file)
    let document = try NumbersDocument.open(at: url)

    switch format {
    case .text:
      for (index, sheet) in document.sheets.enumerated() {
        print("\(index + 1). \(sheet.name)")
      }
    case .json:
      let payload = ListSheetsJSONPayload(
        sheets: document.sheets.enumerated().map { offset, sheet in
          ListSheetsJSONPayload.Sheet(
            index: offset + 1,
            id: sheet.id,
            name: sheet.name,
            tableCount: sheet.tables.count
          )
        }
      )
      print(try renderJSON(payload))
    }
  }
}

struct ListTables: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-tables",
    abstract: "Prints all tables, grouped by sheet."
  )

  @Argument(help: "Path to a .numbers package")
  var file: String

  @Option(name: .long, help: "Optional exact sheet name filter")
  var sheet: String?

  @Option(name: .long, help: "Output format: text or json")
  var format: OutputFormat = .text

  mutating func run() throws {
    let url = URL(fileURLWithPath: file)
    let document = try NumbersDocument.open(at: url)
    let entries = collectTableEntries(from: document, sheetFilter: sheet)

    switch format {
    case .text:
      if entries.isEmpty {
        print("<none>")
        return
      }
      for (offset, entry) in entries.enumerated() {
        let usedRange = entry.usedRange ?? "-"
        print(
          "\(offset + 1). \(entry.sheetName)/\(entry.tableName) rows=\(entry.rowCount) cols=\(entry.columnCount) populated=\(entry.populatedCellCount) formulas=\(entry.formulaCount) merges=\(entry.mergeRangeCount) used=\(usedRange)"
        )
      }
    case .json:
      let payload = ListTablesJSONPayload(
        sheetFilter: sheet,
        tables: entries.enumerated().map { offset, entry in
          ListTablesJSONPayload.Table(
            index: offset + 1,
            sheetIndex: entry.sheetIndex,
            sheetID: entry.sheetID,
            sheetName: entry.sheetName,
            tableIndexInSheet: entry.tableIndexInSheet,
            tableID: entry.tableID,
            tableName: entry.tableName,
            rowCount: entry.rowCount,
            columnCount: entry.columnCount,
            mergeRangeCount: entry.mergeRangeCount,
            populatedCellCount: entry.populatedCellCount,
            formulaCount: entry.formulaCount,
            usedRange: entry.usedRange
          )
        }
      )
      print(try renderJSON(payload))
    }
  }
}

struct ListFormulas: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-formulas",
    abstract: "Prints formula cells with raw/tokenized details when available."
  )

  @Argument(help: "Path to a .numbers package")
  var file: String

  @Option(name: .long, help: "Optional exact sheet name filter")
  var sheet: String?

  @Option(name: .long, help: "Optional exact table name filter")
  var table: String?

  @Option(name: .long, help: "Output format: text or json")
  var format: OutputFormat = .text

  mutating func run() throws {
    let url = URL(fileURLWithPath: file)
    let document = try NumbersDocument.open(at: url)
    let formulas = collectFormulaEntries(
      from: document,
      sheetFilter: sheet,
      tableFilter: table
    )

    switch format {
    case .text:
      if formulas.isEmpty {
        print("<none>")
        return
      }
      for (offset, entry) in formulas.enumerated() {
        let formulaID = entry.formulaID.map { String($0) } ?? "-"
        let raw = entry.rawFormula ?? "<unresolved>"
        print(
          "\(offset + 1). \(entry.sheetName)/\(entry.tableName) \(entry.cellReference) [id=\(formulaID)] result=\(entry.resultFormatted) raw=\(raw)"
        )
      }
    case .json:
      let payload = ListFormulasJSONPayload(
        sheetFilter: sheet,
        tableFilter: table,
        formulas: formulas
      )
      print(try renderJSON(payload))
    }
  }
}

struct ReadCellCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "read-cell",
    abstract: "Prints a full read snapshot for one cell."
  )

  @Argument(help: "Path to a .numbers package")
  var file: String

  @Argument(help: "Cell reference in A1 notation (for example: B2)")
  var cell: String

  @Option(name: .long, help: "Exact sheet name")
  var sheet: String?

  @Option(name: .long, help: "Zero-based sheet index (alternative to --sheet)")
  var sheetIndex: Int?

  @Option(name: .long, help: "Exact table name")
  var table: String?

  @Option(name: .long, help: "Zero-based table index within the selected sheet (alternative to --table)")
  var tableIndex: Int?

  @Option(name: .long, help: "Output format: text or json")
  var format: OutputFormat = .text

  mutating func run() throws {
    let url = URL(fileURLWithPath: file)
    let document = try NumbersDocument.open(at: url)

    let sheetModel = try resolveSheet(in: document, sheetName: sheet, sheetIndex: sheetIndex)
    let tableModel = try resolveTable(in: sheetModel, tableName: table, tableIndex: tableIndex)

    let reference: CellReference
    do {
      reference = try CellReference(cell)
    } catch {
      throw ValidationError("Invalid cell reference: \(cell)")
    }

    guard let readCell = tableModel.readCell(at: reference.address) else {
      throw ValidationError(
        "Cell \(reference.a1) is out of bounds for table '\(tableModel.name)' (\(tableModel.rowCount)x\(tableModel.columnCount))."
      )
    }

    let payload = ReadCellJSONPayload(
      sourcePath: url.path,
      sheet: sheetModel,
      table: tableModel,
      reference: reference,
      readCell: readCell,
      formula: tableModel.formula(at: reference.address)
    )

    switch format {
    case .text:
      print(renderReadCellText(payload))
    case .json:
      print(try renderJSON(payload))
    }
  }
}

struct ReadColumnCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "read-column",
    abstract: "Prints typed read snapshots for one column (by index or header)."
  )

  @Argument(help: "Path to a .numbers package")
  var file: String

  @Argument(help: "Zero-based column index (for example: 0 for column A)")
  var columnIndex: Int?

  @Option(name: .long, help: "Column header label (case-insensitive) used instead of column index")
  var header: String?

  @Option(name: .long, help: "Header row index (zero-based) used with --header")
  var headerRow: Int = 0

  @Flag(name: .long, help: "Include header row in output when using --header")
  var includeHeader: Bool = false

  @Option(name: .long, help: "Exact sheet name")
  var sheet: String?

  @Option(name: .long, help: "Zero-based sheet index (alternative to --sheet)")
  var sheetIndex: Int?

  @Option(name: .long, help: "Exact table name")
  var table: String?

  @Option(name: .long, help: "Zero-based table index within the selected sheet (alternative to --table)")
  var tableIndex: Int?

  @Option(name: .long, help: "Start row index (zero-based)")
  var fromRow: Int = 0

  @Option(name: .long, help: "Output format: text or json")
  var format: OutputFormat = .text

  @Flag(name: .long, help: "Emit newline-delimited JSON (one cell per line)")
  var jsonl: Bool = false

  mutating func run() throws {
    let url = URL(fileURLWithPath: file)
    let document = try NumbersDocument.open(at: url)

    let sheetModel = try resolveSheet(in: document, sheetName: sheet, sheetIndex: sheetIndex)
    let tableModel = try resolveTable(in: sheetModel, tableName: table, tableIndex: tableIndex)

    let resolvedColumnIndex: Int
    let resolvedFromRow: Int
    let values: [CellValue]

    if let header {
      if let columnIndex {
        throw ValidationError(
          "Provide either <column-index> or --header, not both (received index \(columnIndex) and header '\(header)')."
        )
      }
      if fromRow != 0 {
        throw ValidationError(
          "--from-row is only valid with index mode. For --header mode, use --header-row and optional --include-header."
        )
      }

      let normalizedHeader = header.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !normalizedHeader.isEmpty else {
        throw ValidationError("Header cannot be empty.")
      }

      do {
        values = try tableModel.column(
          named: normalizedHeader,
          headerRow: headerRow,
          includeHeader: includeHeader
        )
        resolvedColumnIndex = try resolveColumnIndex(
          in: tableModel,
          header: normalizedHeader,
          headerRow: headerRow
        )
        resolvedFromRow = includeHeader ? headerRow : headerRow + 1
      } catch {
        throw ValidationError(
          "Header '\(normalizedHeader)' with headerRow=\(headerRow) is invalid for table '\(tableModel.name)' (\(tableModel.rowCount)x\(tableModel.columnCount))."
        )
      }
    } else {
      guard let columnIndex else {
        throw ValidationError(
          "Missing column selector. Provide <column-index> or use --header \"<Column Name>\"."
        )
      }

      do {
        values = try tableModel.column(at: columnIndex, from: fromRow)
        resolvedColumnIndex = columnIndex
        resolvedFromRow = fromRow
      } catch {
        throw ValidationError(
          "Column index \(columnIndex) with fromRow=\(fromRow) is invalid for table '\(tableModel.name)' (\(tableModel.rowCount)x\(tableModel.columnCount))."
        )
      }
    }

    let payload = ReadColumnJSONPayload(
      sourcePath: url.path,
      sheet: sheetModel,
      table: tableModel,
      selectionMode: header == nil ? "index" : "header",
      requestedColumnIndex: columnIndex,
      requestedHeader: header,
      headerRow: header == nil ? nil : headerRow,
      includeHeader: header == nil ? nil : includeHeader,
      columnIndex: resolvedColumnIndex,
      fromRow: resolvedFromRow,
      values: values
    )

    if jsonl {
      print(try renderReadColumnJSONLines(payload))
      return
    }

    switch format {
    case .text:
      print(renderReadColumnText(payload))
    case .json:
      print(try renderJSON(payload))
    }
  }
}

struct ReadTableCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "read-table",
    abstract: "Prints typed read snapshots for a table window (rows x columns)."
  )

  @Argument(help: "Path to a .numbers package")
  var file: String

  @Option(name: .long, help: "Exact sheet name")
  var sheet: String?

  @Option(name: .long, help: "Zero-based sheet index (alternative to --sheet)")
  var sheetIndex: Int?

  @Option(name: .long, help: "Exact table name")
  var table: String?

  @Option(name: .long, help: "Zero-based table index within the selected sheet (alternative to --table)")
  var tableIndex: Int?

  @Option(name: .long, help: "Start row index (zero-based)")
  var fromRow: Int = 0

  @Option(name: .long, help: "Start column index (zero-based)")
  var fromColumn: Int = 0

  @Option(name: .long, help: "Maximum number of rows to return")
  var maxRows: Int = 100

  @Option(name: .long, help: "Maximum number of columns to return")
  var maxColumns: Int = 50

  @Option(name: .long, help: "Output format: text or json")
  var format: OutputFormat = .text

  @Flag(name: .long, help: "Emit newline-delimited JSON (one row per line)")
  var jsonl: Bool = false

  mutating func run() throws {
    let url = URL(fileURLWithPath: file)
    let document = try NumbersDocument.open(at: url)

    let sheetModel = try resolveSheet(in: document, sheetName: sheet, sheetIndex: sheetIndex)
    let tableModel = try resolveTable(in: sheetModel, tableName: table, tableIndex: tableIndex)

    guard fromRow >= 0, fromRow <= tableModel.rowCount else {
      throw ValidationError("Invalid fromRow=\(fromRow) for table rowCount=\(tableModel.rowCount).")
    }
    guard fromColumn >= 0, fromColumn <= tableModel.columnCount else {
      throw ValidationError(
        "Invalid fromColumn=\(fromColumn) for table columnCount=\(tableModel.columnCount).")
    }
    guard maxRows > 0 else {
      throw ValidationError("--max-rows must be greater than 0.")
    }
    guard maxColumns > 0 else {
      throw ValidationError("--max-columns must be greater than 0.")
    }

    let resolvedRowCount = min(maxRows, max(0, tableModel.rowCount - fromRow))
    let resolvedColumnCount = min(maxColumns, max(0, tableModel.columnCount - fromColumn))
    let truncatedRows = fromRow + resolvedRowCount < tableModel.rowCount
    let truncatedColumns = fromColumn + resolvedColumnCount < tableModel.columnCount

    let payload = ReadTableJSONPayload(
      sourcePath: url.path,
      sheet: sheetModel,
      table: tableModel,
      fromRow: fromRow,
      fromColumn: fromColumn,
      maxRows: maxRows,
      maxColumns: maxColumns,
      resolvedRowCount: resolvedRowCount,
      resolvedColumnCount: resolvedColumnCount,
      truncatedRows: truncatedRows,
      truncatedColumns: truncatedColumns
    )

    if jsonl {
      print(try renderReadTableJSONLines(payload))
      return
    }

    switch format {
    case .text:
      print(renderReadTableText(payload))
    case .json:
      print(try renderJSON(payload))
    }
  }
}

struct ReadRangeCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "read-range",
    abstract: "Prints read snapshots for a cell range."
  )

  @Argument(help: "Path to a .numbers package")
  var file: String

  @Argument(help: "Range reference in A1 notation (for example: A1:D10)")
  var range: String

  @Option(name: .long, help: "Exact sheet name")
  var sheet: String?

  @Option(name: .long, help: "Zero-based sheet index (alternative to --sheet)")
  var sheetIndex: Int?

  @Option(name: .long, help: "Exact table name")
  var table: String?

  @Option(name: .long, help: "Zero-based table index within the selected sheet (alternative to --table)")
  var tableIndex: Int?

  @Option(name: .long, help: "Output format: text or json")
  var format: OutputFormat = .text

  @Flag(name: .long, help: "Emit newline-delimited JSON (one row per line)")
  var jsonl: Bool = false

  mutating func run() throws {
    let url = URL(fileURLWithPath: file)
    let document = try NumbersDocument.open(at: url)

    let sheetModel = try resolveSheet(in: document, sheetName: sheet, sheetIndex: sheetIndex)
    let tableModel = try resolveTable(in: sheetModel, tableName: table, tableIndex: tableIndex)

    let parsedRange: CLIParsedRange
    do {
      parsedRange = try parseCLIRangeReference(range)
    } catch {
      throw ValidationError("Invalid range reference: \(range)")
    }

    let rows: [[ReadCell]]
    do {
      rows = try tableModel.readCells(in: range)
    } catch {
      throw ValidationError(
        "Range \(range) is invalid for table '\(tableModel.name)' (\(tableModel.rowCount)x\(tableModel.columnCount))."
      )
    }

    let payload = ReadRangeJSONPayload(
      sourcePath: url.path,
      sheet: sheetModel,
      table: tableModel,
      requestedRange: range,
      resolvedRange: parsedRange,
      rows: rows
    )

    if jsonl {
      print(try renderReadRangeJSONLines(payload))
      return
    }

    switch format {
    case .text:
      print(renderReadRangeText(payload))
    case .json:
      print(try renderJSON(payload))
    }
  }
}

struct ExportCSVCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "export-csv",
    abstract: "Exports table data to CSV."
  )

  @Argument(help: "Path to a .numbers package")
  var file: String

  @Option(name: .long, help: "Exact sheet name")
  var sheet: String?

  @Option(name: .long, help: "Zero-based sheet index (alternative to --sheet)")
  var sheetIndex: Int?

  @Option(name: .long, help: "Exact table name")
  var table: String?

  @Option(name: .long, help: "Zero-based table index within the selected sheet (alternative to --table)")
  var tableIndex: Int?

  @Option(name: .long, help: "CSV output mode: value, formatted, or formula")
  var mode: ExportCSVMode = .value

  @Option(name: .long, help: "Write CSV to this file path instead of stdout")
  var output: String?

  mutating func run() throws {
    let url = URL(fileURLWithPath: file)
    let document = try NumbersDocument.open(at: url)

    let sheetModel = try resolveSheet(in: document, sheetName: sheet, sheetIndex: sheetIndex)
    let tableModel = try resolveTable(in: sheetModel, tableName: table, tableIndex: tableIndex)
    let csv = renderCSV(table: tableModel, mode: mode)

    if let output {
      let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else {
        throw ValidationError("--output cannot be empty.")
      }

      let outputURL = URL(fileURLWithPath: trimmed)
      try Data(csv.utf8).write(to: outputURL, options: .atomic)
      print("Exported CSV to \(outputURL.path)")
      return
    }

    FileHandle.standardOutput.write(Data(csv.utf8))
  }
}

struct ImportCSVCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "import-csv",
    abstract: "Imports CSV data into a selected table."
  )

  @Argument(help: "Path to a .numbers package")
  var file: String

  @Argument(help: "Path to a CSV file")
  var csvFile: String

  @Option(name: .long, help: "Exact sheet name")
  var sheet: String?

  @Option(name: .long, help: "Zero-based sheet index (alternative to --sheet)")
  var sheetIndex: Int?

  @Option(name: .long, help: "Exact table name")
  var table: String?

  @Option(name: .long, help: "Zero-based table index within the selected sheet (alternative to --table)")
  var tableIndex: Int?

  @Option(name: .long, help: "Header handling: with-header or no-header")
  var header: ImportCSVHeaderMode = .withHeader

  @Flag(name: .long, help: "Parse date-like values into typed date cells")
  var parseDates: Bool = false

  @Option(name: .long, help: "Write updated .numbers document to this path instead of saving in place")
  var output: String?

  mutating func run() throws {
    let sourceURL = URL(fileURLWithPath: file)
    let csvURL = URL(fileURLWithPath: csvFile)
    let csvContent = try String(contentsOf: csvURL, encoding: .utf8)
    let parsedRows = try parseCSVRows(csvContent)
    let importRows = normalizeImportRows(parsedRows, headerMode: header)

    guard !importRows.isEmpty else {
      throw ValidationError("CSV file '\(csvURL.path)' is empty.")
    }

    let maxColumnCount = importRows.map(\.count).max() ?? 0
    guard maxColumnCount > 0 else {
      throw ValidationError("CSV file '\(csvURL.path)' does not contain columns.")
    }

    let readDocument = try NumbersDocument.open(at: sourceURL)
    let selectedSheet = try resolveSheet(in: readDocument, sheetName: sheet, sheetIndex: sheetIndex)
    let selectedTable = try resolveTable(
      in: selectedSheet,
      tableName: table,
      tableIndex: tableIndex
    )

    let editableDocument = try EditableNumbersDocument.open(at: sourceURL)
    let editableSheet = try editableDocument.sheet(named: selectedSheet.name)
    let editableTable = try editableSheet.table(named: selectedTable.name)

    for rowIndex in 0..<importRows.count {
      let row = importRows[rowIndex]
      for columnIndex in 0..<maxColumnCount {
        let raw = columnIndex < row.count ? row[columnIndex] : ""
        let isHeaderRow = header == .withHeader && rowIndex == 0
        let value = importedCellValue(
          raw: raw,
          parseDates: parseDates,
          forceString: isHeaderRow
        )
        editableTable.setValue(value, at: CellAddress(row: rowIndex, column: columnIndex))
      }
    }

    if let output {
      let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else {
        throw ValidationError("--output cannot be empty.")
      }
      let outputURL = URL(fileURLWithPath: trimmed)
      try editableDocument.save(to: outputURL)
      print("Imported CSV into \(outputURL.path)")
      return
    }

    try editableDocument.saveInPlace()
    print("Imported CSV into \(sourceURL.path)")
  }
}

private struct DumpJSONPayload: Encodable {
  struct Diagnostic: Encodable {
    let code: String
    let severity: String
    let message: String
    let objectPath: String?
    let suggestion: String?
    let context: [String: String]
    let rendered: String
  }

  struct Formula: Encodable {
    let sheetName: String
    let tableName: String
    let cellReference: String
    let formulaID: Int32?
    let rawFormula: String?
    let parsedTokens: [String]
    let astSummary: String?
    let resultKind: String
    let resultFormatted: String
  }

  struct Cell: Encodable {
    let sheetName: String
    let tableName: String
    let cellReference: String
    let row: Int
    let column: Int
    let kind: String
    let value: TypedValuePayload
    let readValue: TypedValuePayload
    let formatted: String
    let formulaID: Int32?
    let rawFormula: String?
  }

  struct Formatting: Encodable {
    let sheetName: String
    let tableName: String
    let cellReference: String
    let row: Int
    let column: Int
    let kind: String
    let defaultFormatted: String
    let styleHinted: String
    let decimal: String
    let currencyUSD: String
    let percent: String
    let scientific: String
    let dateISO8601: String
    let dateShort: String
    let durationSeconds: String
    let durationHHMMSS: String
    let durationAbbreviated: String
  }

  struct Sheet: Encodable {
    struct Table: Encodable {
      let id: String
      let name: String
      let rowCount: Int
      let columnCount: Int
      let mergeRangeCount: Int
      let populatedCellCount: Int
      let usedRange: String?
    }

    let id: String
    let name: String
    let tableCount: Int
    let tables: [Table]
  }

  let sourcePath: String
  let documentVersion: String?
  let readPath: String
  let fallbackReason: String?
  let sheetCount: Int
  let sheetNames: [String]
  let tableCount: Int
  let tableNames: [String]
  let resolvedCellCount: Int
  let blobCount: Int
  let objectCount: Int
  let objectReferenceEdgeCount: Int
  let rootObjectCount: Int
  let typeHistogram: [String: Int]
  let unparsedBlobPaths: [String]
  let diagnostics: [String]
  let structuredDiagnostics: [Diagnostic]
  let formulaCount: Int?
  let formulas: [Formula]?
  let cellCount: Int?
  let cells: [Cell]?
  let formattingCount: Int?
  let formatting: [Formatting]?
  let sheets: [Sheet]

  init(
    dump: DocumentDump,
    sheets: [SwiftNumbersCore.Sheet],
    formulas: [FormulaEntry]? = nil,
    cells: [CellEntry]? = nil,
    formatting: [FormattingEntry]? = nil
  ) {
    self.sourcePath = dump.sourcePath
    self.documentVersion = dump.documentVersion
    self.readPath = dump.readPath.rawValue
    self.fallbackReason = dump.fallbackReason
    self.sheetCount = sheets.count
    self.sheetNames = sheets.map(\.name)
    self.tableCount = sheets.reduce(0) { $0 + $1.tables.count }
    self.tableNames = sheets.flatMap { sheet in
      sheet.tables.map { "\(sheet.name)/\($0.name)" }
    }
    self.resolvedCellCount = dump.resolvedCellCount
    self.blobCount = dump.blobCount
    self.objectCount = dump.objectCount
    self.objectReferenceEdgeCount = dump.objectReferenceEdgeCount
    self.rootObjectCount = dump.rootObjectCount
    self.typeHistogram = Dictionary(
      uniqueKeysWithValues: dump.typeHistogram.map { (String($0.key), $0.value) })
    self.unparsedBlobPaths = dump.unparsedBlobPaths
    self.diagnostics = dump.diagnostics
    self.structuredDiagnostics = dump.structuredDiagnostics.map { diagnostic in
      Diagnostic(
        code: diagnostic.code,
        severity: diagnostic.severity.rawValue,
        message: diagnostic.message,
        objectPath: diagnostic.objectPath,
        suggestion: diagnostic.suggestion,
        context: diagnostic.context,
        rendered: diagnostic.rendered
      )
    }
    if let formulas {
      self.formulaCount = formulas.count
      self.formulas = formulas.map { formula in
        Formula(
          sheetName: formula.sheetName,
          tableName: formula.tableName,
          cellReference: formula.cellReference,
          formulaID: formula.formulaID,
          rawFormula: formula.rawFormula,
          parsedTokens: formula.parsedTokens,
          astSummary: formula.astSummary,
          resultKind: formula.resultKind,
          resultFormatted: formula.resultFormatted
        )
      }
    } else {
      self.formulaCount = nil
      self.formulas = nil
    }
    if let cells {
      self.cellCount = cells.count
      self.cells = cells.map { entry in
        Cell(
          sheetName: entry.sheetName,
          tableName: entry.tableName,
          cellReference: entry.cellReference,
          row: entry.row,
          column: entry.column,
          kind: entry.kind,
          value: entry.value,
          readValue: entry.readValue,
          formatted: entry.formatted,
          formulaID: entry.formulaID,
          rawFormula: entry.rawFormula
        )
      }
    } else {
      self.cellCount = nil
      self.cells = nil
    }
    if let formatting {
      self.formattingCount = formatting.count
      self.formatting = formatting.map { entry in
        Formatting(
          sheetName: entry.sheetName,
          tableName: entry.tableName,
          cellReference: entry.cellReference,
          row: entry.row,
          column: entry.column,
          kind: entry.kind,
          defaultFormatted: entry.defaultFormatted,
          styleHinted: entry.styleHinted,
          decimal: entry.decimal,
          currencyUSD: entry.currencyUSD,
          percent: entry.percent,
          scientific: entry.scientific,
          dateISO8601: entry.dateISO8601,
          dateShort: entry.dateShort,
          durationSeconds: entry.durationSeconds,
          durationHHMMSS: entry.durationHHMMSS,
          durationAbbreviated: entry.durationAbbreviated
        )
      }
    } else {
      self.formattingCount = nil
      self.formatting = nil
    }
    self.sheets = sheets.map { sheet in
      Sheet(
        id: sheet.id,
        name: sheet.name,
        tableCount: sheet.tables.count,
        tables: sheet.tables.map { table in
          Sheet.Table(
            id: table.id,
            name: table.name,
            rowCount: table.metadata.rowCount,
            columnCount: table.metadata.columnCount,
            mergeRangeCount: table.metadata.mergeRanges.count,
            populatedCellCount: table.populatedCellCount,
            usedRange: table.usedRange?.a1
          )
        }
      )
    }
  }
}

private struct ListSheetsJSONPayload: Encodable {
  struct Sheet: Encodable {
    let index: Int
    let id: String
    let name: String
    let tableCount: Int
  }

  let sheets: [Sheet]
}

private struct ListTablesJSONPayload: Encodable {
  struct Table: Encodable {
    let index: Int
    let sheetIndex: Int
    let sheetID: String
    let sheetName: String
    let tableIndexInSheet: Int
    let tableID: String
    let tableName: String
    let rowCount: Int
    let columnCount: Int
    let mergeRangeCount: Int
    let populatedCellCount: Int
    let formulaCount: Int
    let usedRange: String?
  }

  let sheetFilter: String?
  let tableCount: Int
  let tables: [Table]

  init(sheetFilter: String?, tables: [Table]) {
    self.sheetFilter = sheetFilter
    self.tableCount = tables.count
    self.tables = tables
  }
}

private struct ListFormulasJSONPayload: Encodable {
  struct Formula: Encodable {
    let index: Int
    let sheetName: String
    let tableName: String
    let cellReference: String
    let formulaID: Int32?
    let rawFormula: String?
    let parsedTokens: [String]
    let astSummary: String?
    let resultKind: String
    let resultFormatted: String
  }

  let sheetFilter: String?
  let tableFilter: String?
  let formulaCount: Int
  let formulas: [Formula]

  init(sheetFilter: String?, tableFilter: String?, formulas: [FormulaEntry]) {
    self.sheetFilter = sheetFilter
    self.tableFilter = tableFilter
    self.formulaCount = formulas.count
    self.formulas = formulas.enumerated().map { offset, formula in
      Formula(
        index: offset + 1,
        sheetName: formula.sheetName,
        tableName: formula.tableName,
        cellReference: formula.cellReference,
        formulaID: formula.formulaID,
        rawFormula: formula.rawFormula,
        parsedTokens: formula.parsedTokens,
        astSummary: formula.astSummary,
        resultKind: formula.resultKind,
        resultFormatted: formula.resultFormatted
      )
    }
  }
}

private struct TypedValuePayload: Encodable {
  let kind: String
  let string: String?
  let number: Double?
  let bool: Bool?
  let dateISO8601: String?
  let durationSeconds: Double?
  let error: String?
  let richText: RichTextPayload?
  let formulaResultSummary: FormulaResultSummaryPayload?
}

private struct RichTextPayload: Encodable {
  struct Run: Encodable {
    let start: Int
    let end: Int
    let text: String
    let fontName: String?
    let fontSize: Double?
    let isBold: Bool?
    let isItalic: Bool?
    let textColorHex: String?
    let linkURL: String?
  }

  let text: String
  let runs: [Run]
}

private struct FormulaResultSummaryPayload: Encodable {
  let formulaID: Int32?
  let rawFormula: String?
  let parsedTokens: [String]
  let astSummary: String?
  let computedKind: String
  let computedValue: String
  let computedFormatted: String
}

private struct FormulaPayload: Encodable {
  let formulaID: Int32?
  let rawFormula: String?
  let parsedTokens: [String]
  let astSummary: String?
  let result: TypedValuePayload
  let resultFormatted: String
}

private struct StylePayload: Encodable {
  struct NumberFormatPayload: Encodable {
    let kind: String
    let formatID: Int32
  }

  let horizontalAlignment: String?
  let verticalAlignment: String?
  let backgroundColorHex: String?
  let hasTopBorder: Bool
  let hasRightBorder: Bool
  let hasBottomBorder: Bool
  let hasLeftBorder: Bool
  let numberFormat: NumberFormatPayload?
}

private struct MergePayload: Encodable {
  let isMerged: Bool
  let role: String
  let range: String?
}

private struct ReadCellJSONPayload: Encodable {
  let sourcePath: String
  let sheetID: String
  let sheetName: String
  let tableID: String
  let tableName: String
  let tableRowCount: Int
  let tableColumnCount: Int
  let cellReference: String
  let row: Int
  let column: Int
  let kind: String
  let value: TypedValuePayload
  let readValue: TypedValuePayload
  let formatted: String
  let richText: RichTextPayload?
  let style: StylePayload?
  let formula: FormulaPayload?
  let merge: MergePayload
  let rawCellType: UInt8?
  let stringID: Int32?
  let richTextID: Int32?
  let formulaID: Int32?
  let formulaErrorID: Int32?

  init(
    sourcePath: String,
    sheet: SwiftNumbersCore.Sheet,
    table: SwiftNumbersCore.Table,
    reference: CellReference,
    readCell: SwiftNumbersCore.ReadCell,
    formula: SwiftNumbersCore.FormulaRead?
  ) {
    self.sourcePath = sourcePath
    self.sheetID = sheet.id
    self.sheetName = sheet.name
    self.tableID = table.id
    self.tableName = table.name
    self.tableRowCount = table.rowCount
    self.tableColumnCount = table.columnCount
    self.cellReference = reference.a1
    self.row = reference.address.row
    self.column = reference.address.column
    self.kind = readCellKindString(readCell.kind)
    self.value = typedValuePayload(from: readCell.value)
    self.readValue = typedValuePayload(from: readCell.readValue)
    self.formatted = readCell.formatted
    self.richText = richTextPayload(from: readCell.richText)
    self.style = stylePayload(from: readCell.style)
    self.formula = formulaPayload(from: formula, readCell: readCell)
    self.merge = MergePayload(
      isMerged: readCell.isMerged,
      role: mergeRoleString(readCell.mergeRole),
      range: readCell.mergeRange.map(mergeRangeA1)
    )
    self.rawCellType = readCell.rawCellType
    self.stringID = readCell.stringID
    self.richTextID = readCell.richTextID
    self.formulaID = readCell.formulaID
    self.formulaErrorID = readCell.formulaErrorID
  }
}

private struct ReadRangeJSONPayload: Encodable {
  struct Cell: Encodable {
    let cellReference: String
    let row: Int
    let column: Int
    let kind: String
    let value: TypedValuePayload
    let readValue: TypedValuePayload
    let formatted: String
    let richText: RichTextPayload?
    let style: StylePayload?
    let formula: FormulaPayload?
    let isMerged: Bool
    let mergeRole: String
    let mergeRange: String?
    let rawCellType: UInt8?
    let stringID: Int32?
    let richTextID: Int32?
    let formulaID: Int32?
    let formulaErrorID: Int32?
  }

  let sourcePath: String
  let sheetID: String
  let sheetName: String
  let tableID: String
  let tableName: String
  let tableRowCount: Int
  let tableColumnCount: Int
  let requestedRange: String
  let resolvedRange: String
  let rowCount: Int
  let columnCount: Int
  let cells: [[Cell]]

  init(
    sourcePath: String,
    sheet: SwiftNumbersCore.Sheet,
    table: SwiftNumbersCore.Table,
    requestedRange: String,
    resolvedRange: CLIParsedRange,
    rows: [[SwiftNumbersCore.ReadCell]]
  ) {
    self.sourcePath = sourcePath
    self.sheetID = sheet.id
    self.sheetName = sheet.name
    self.tableID = table.id
    self.tableName = table.name
    self.tableRowCount = table.rowCount
    self.tableColumnCount = table.columnCount
    self.requestedRange = requestedRange
    self.resolvedRange = resolvedRange.a1
    self.rowCount = rows.count
    self.columnCount = rows.first?.count ?? 0
    self.cells = rows.enumerated().map { rowOffset, row in
      row.enumerated().map { columnOffset, readCell in
        let address = CellAddress(
          row: resolvedRange.start.row + rowOffset,
          column: resolvedRange.start.column + columnOffset
        )
        let formula = table.formula(at: address)
        return Cell(
          cellReference: CellReference(address: address).a1,
          row: address.row,
          column: address.column,
          kind: readCellKindString(readCell.kind),
          value: typedValuePayload(from: readCell.value),
          readValue: typedValuePayload(from: readCell.readValue),
          formatted: readCell.formatted,
          richText: richTextPayload(from: readCell.richText),
          style: stylePayload(from: readCell.style),
          formula: formulaPayload(from: formula, readCell: readCell),
          isMerged: readCell.isMerged,
          mergeRole: mergeRoleString(readCell.mergeRole),
          mergeRange: readCell.mergeRange.map(mergeRangeA1),
          rawCellType: readCell.rawCellType,
          stringID: readCell.stringID,
          richTextID: readCell.richTextID,
          formulaID: readCell.formulaID,
          formulaErrorID: readCell.formulaErrorID
        )
      }
    }
  }
}

private struct ReadColumnJSONPayload: Encodable {
  struct Cell: Encodable {
    let cellReference: String
    let row: Int
    let column: Int
    let kind: String
    let value: TypedValuePayload
    let readValue: TypedValuePayload
    let formatted: String
    let richText: RichTextPayload?
    let style: StylePayload?
    let formula: FormulaPayload?
    let isMerged: Bool
    let mergeRole: String
    let mergeRange: String?
    let rawCellType: UInt8?
    let stringID: Int32?
    let richTextID: Int32?
    let formulaID: Int32?
    let formulaErrorID: Int32?
  }

  let sourcePath: String
  let sheetID: String
  let sheetName: String
  let tableID: String
  let tableName: String
  let tableRowCount: Int
  let tableColumnCount: Int
  let selectionMode: String
  let requestedColumnIndex: Int?
  let requestedHeader: String?
  let headerRow: Int?
  let includeHeader: Bool?
  let columnIndex: Int
  let fromRow: Int
  let cellCount: Int
  let cells: [Cell]

  init(
    sourcePath: String,
    sheet: SwiftNumbersCore.Sheet,
    table: SwiftNumbersCore.Table,
    selectionMode: String,
    requestedColumnIndex: Int?,
    requestedHeader: String?,
    headerRow: Int?,
    includeHeader: Bool?,
    columnIndex: Int,
    fromRow: Int,
    values: [CellValue]
  ) {
    self.sourcePath = sourcePath
    self.sheetID = sheet.id
    self.sheetName = sheet.name
    self.tableID = table.id
    self.tableName = table.name
    self.tableRowCount = table.rowCount
    self.tableColumnCount = table.columnCount
    self.selectionMode = selectionMode
    self.requestedColumnIndex = requestedColumnIndex
    self.requestedHeader = requestedHeader
    self.headerRow = headerRow
    self.includeHeader = includeHeader
    self.columnIndex = columnIndex
    self.fromRow = fromRow
    self.cellCount = values.count
    self.cells = values.enumerated().map { offset, value in
      let row = fromRow + offset
      let address = CellAddress(row: row, column: columnIndex)
      let readCell =
        table.readCell(at: address)
        ?? ReadCell(address: address, value: .empty, kind: .empty, formatted: "")
      let formula = table.formula(at: address)
      return Cell(
        cellReference: CellReference(address: address).a1,
        row: row,
        column: columnIndex,
        kind: readCellKindString(readCell.kind),
        value: typedValuePayload(from: value),
        readValue: typedValuePayload(from: readCell.readValue),
        formatted: readCell.formatted,
        richText: richTextPayload(from: readCell.richText),
        style: stylePayload(from: readCell.style),
        formula: formulaPayload(from: formula, readCell: readCell),
        isMerged: readCell.isMerged,
        mergeRole: mergeRoleString(readCell.mergeRole),
        mergeRange: readCell.mergeRange.map(mergeRangeA1),
        rawCellType: readCell.rawCellType,
        stringID: readCell.stringID,
        richTextID: readCell.richTextID,
        formulaID: readCell.formulaID,
        formulaErrorID: readCell.formulaErrorID
      )
    }
  }
}

private struct ReadTableJSONPayload: Encodable {
  struct Cell: Encodable {
    let cellReference: String
    let row: Int
    let column: Int
    let kind: String
    let value: TypedValuePayload
    let readValue: TypedValuePayload
    let formatted: String
    let richText: RichTextPayload?
    let style: StylePayload?
    let formula: FormulaPayload?
    let isMerged: Bool
    let mergeRole: String
    let mergeRange: String?
    let rawCellType: UInt8?
    let stringID: Int32?
    let richTextID: Int32?
    let formulaID: Int32?
    let formulaErrorID: Int32?
  }

  let sourcePath: String
  let sheetID: String
  let sheetName: String
  let tableID: String
  let tableName: String
  let tableRowCount: Int
  let tableColumnCount: Int
  let fromRow: Int
  let fromColumn: Int
  let maxRows: Int
  let maxColumns: Int
  let resolvedRowCount: Int
  let resolvedColumnCount: Int
  let truncatedRows: Bool
  let truncatedColumns: Bool
  let cells: [[Cell]]

  init(
    sourcePath: String,
    sheet: SwiftNumbersCore.Sheet,
    table: SwiftNumbersCore.Table,
    fromRow: Int,
    fromColumn: Int,
    maxRows: Int,
    maxColumns: Int,
    resolvedRowCount: Int,
    resolvedColumnCount: Int,
    truncatedRows: Bool,
    truncatedColumns: Bool
  ) {
    self.sourcePath = sourcePath
    self.sheetID = sheet.id
    self.sheetName = sheet.name
    self.tableID = table.id
    self.tableName = table.name
    self.tableRowCount = table.rowCount
    self.tableColumnCount = table.columnCount
    self.fromRow = fromRow
    self.fromColumn = fromColumn
    self.maxRows = maxRows
    self.maxColumns = maxColumns
    self.resolvedRowCount = resolvedRowCount
    self.resolvedColumnCount = resolvedColumnCount
    self.truncatedRows = truncatedRows
    self.truncatedColumns = truncatedColumns
    self.cells = (0..<resolvedRowCount).map { rowOffset in
      let row = fromRow + rowOffset
      return (0..<resolvedColumnCount).map { columnOffset in
        let column = fromColumn + columnOffset
        let address = CellAddress(row: row, column: column)
        let readCell = table.readCell(at: address)
          ?? ReadCell(address: address, value: .empty, kind: .empty, formatted: "")
        let formula = table.formula(at: address)
        return Cell(
          cellReference: CellReference(address: address).a1,
          row: row,
          column: column,
          kind: readCellKindString(readCell.kind),
          value: typedValuePayload(from: readCell.value),
          readValue: typedValuePayload(from: readCell.readValue),
          formatted: readCell.formatted,
          richText: richTextPayload(from: readCell.richText),
          style: stylePayload(from: readCell.style),
          formula: formulaPayload(from: formula, readCell: readCell),
          isMerged: readCell.isMerged,
          mergeRole: mergeRoleString(readCell.mergeRole),
          mergeRange: readCell.mergeRange.map(mergeRangeA1),
          rawCellType: readCell.rawCellType,
          stringID: readCell.stringID,
          richTextID: readCell.richTextID,
          formulaID: readCell.formulaID,
          formulaErrorID: readCell.formulaErrorID
        )
      }
    }
  }
}

private struct FormulaEntry {
  let sheetName: String
  let tableName: String
  let cellReference: String
  let formulaID: Int32?
  let rawFormula: String?
  let parsedTokens: [String]
  let astSummary: String?
  let resultKind: String
  let resultFormatted: String
}

private struct CellEntry {
  let sheetName: String
  let tableName: String
  let cellReference: String
  let row: Int
  let column: Int
  let kind: String
  let value: TypedValuePayload
  let readValue: TypedValuePayload
  let formatted: String
  let formulaID: Int32?
  let rawFormula: String?
}

private struct FormattingEntry {
  let sheetName: String
  let tableName: String
  let cellReference: String
  let row: Int
  let column: Int
  let kind: String
  let defaultFormatted: String
  let styleHinted: String
  let decimal: String
  let currencyUSD: String
  let percent: String
  let scientific: String
  let dateISO8601: String
  let dateShort: String
  let durationSeconds: String
  let durationHHMMSS: String
  let durationAbbreviated: String
}

private struct TableEntry {
  let sheetIndex: Int
  let sheetID: String
  let sheetName: String
  let tableIndexInSheet: Int
  let tableID: String
  let tableName: String
  let rowCount: Int
  let columnCount: Int
  let mergeRangeCount: Int
  let populatedCellCount: Int
  let formulaCount: Int
  let usedRange: String?
}

private func collectFormulaEntries(
  from document: NumbersDocument,
  sheetFilter: String? = nil,
  tableFilter: String? = nil
) -> [FormulaEntry] {
  var entries: [FormulaEntry] = []

  for sheet in document.sheets {
    if let sheetFilter, sheet.name != sheetFilter {
      continue
    }

    for table in sheet.tables {
      if let tableFilter, table.name != tableFilter {
        continue
      }

      for formula in table.formulas() {
        entries.append(
          FormulaEntry(
            sheetName: sheet.name,
            tableName: table.name,
            cellReference: formula.reference,
            formulaID: formula.formulaID,
            rawFormula: formula.rawFormula,
            parsedTokens: formula.parsedTokens,
            astSummary: formula.astSummary,
            resultKind: cellValueKind(formula.result),
            resultFormatted: formula.resultFormatted
          )
        )
      }
    }
  }

  return entries
}

private func collectCellEntries(from document: NumbersDocument) -> [CellEntry] {
  var entries: [CellEntry] = []

  for sheet in document.sheets {
    for table in sheet.tables {
      for cell in table.populatedCells(sorted: true) {
        let reference = CellReference(address: cell.address).a1
        let formula = table.formula(at: cell.address)
        entries.append(
          CellEntry(
            sheetName: sheet.name,
            tableName: table.name,
            cellReference: reference,
            row: cell.address.row,
            column: cell.address.column,
            kind: readCellKindString(cell.kind),
            value: typedValuePayload(from: cell.value),
            readValue: typedValuePayload(from: cell.readValue),
            formatted: cell.formatted,
            formulaID: cell.formulaID,
            rawFormula: formula?.rawFormula
          )
        )
      }
    }
  }

  return entries
}

private func collectFormattingEntries(from document: NumbersDocument) -> [FormattingEntry] {
  let styleHintedOptions = ReadFormattingOptions.default
  let decimalOptions = ReadFormattingOptions(
    localeIdentifier: "en_US_POSIX",
    timeZoneIdentifier: "UTC",
    usesGroupingSeparator: false,
    minimumFractionDigits: 0,
    maximumFractionDigits: 15,
    includeFractionalSeconds: true,
    numberFormatMode: .decimal,
    dateFormatMode: .iso8601,
    durationFormatMode: .seconds,
    preferCellNumberFormatHints: false
  )
  let currencyOptions = ReadFormattingOptions(
    localeIdentifier: "en_US_POSIX",
    timeZoneIdentifier: "UTC",
    usesGroupingSeparator: false,
    minimumFractionDigits: 0,
    maximumFractionDigits: 15,
    includeFractionalSeconds: true,
    numberFormatMode: .currency(code: "USD"),
    dateFormatMode: .iso8601,
    durationFormatMode: .seconds,
    preferCellNumberFormatHints: false
  )
  let percentOptions = ReadFormattingOptions(
    localeIdentifier: "en_US_POSIX",
    timeZoneIdentifier: "UTC",
    usesGroupingSeparator: false,
    minimumFractionDigits: 0,
    maximumFractionDigits: 15,
    includeFractionalSeconds: true,
    numberFormatMode: .percent,
    dateFormatMode: .iso8601,
    durationFormatMode: .seconds,
    preferCellNumberFormatHints: false
  )
  let scientificOptions = ReadFormattingOptions(
    localeIdentifier: "en_US_POSIX",
    timeZoneIdentifier: "UTC",
    usesGroupingSeparator: false,
    minimumFractionDigits: 0,
    maximumFractionDigits: 15,
    includeFractionalSeconds: true,
    numberFormatMode: .scientific,
    dateFormatMode: .iso8601,
    durationFormatMode: .seconds,
    preferCellNumberFormatHints: false
  )
  let dateISOOptions = ReadFormattingOptions(
    localeIdentifier: "en_US_POSIX",
    timeZoneIdentifier: "UTC",
    usesGroupingSeparator: false,
    minimumFractionDigits: 0,
    maximumFractionDigits: 15,
    includeFractionalSeconds: true,
    numberFormatMode: .decimal,
    dateFormatMode: .iso8601,
    durationFormatMode: .seconds,
    preferCellNumberFormatHints: false
  )
  let dateShortOptions = ReadFormattingOptions(
    localeIdentifier: "en_US_POSIX",
    timeZoneIdentifier: "UTC",
    usesGroupingSeparator: false,
    minimumFractionDigits: 0,
    maximumFractionDigits: 15,
    includeFractionalSeconds: false,
    numberFormatMode: .decimal,
    dateFormatMode: .styled(date: .short, time: .short),
    durationFormatMode: .seconds,
    preferCellNumberFormatHints: false
  )
  let durationSecondsOptions = ReadFormattingOptions(
    localeIdentifier: "en_US_POSIX",
    timeZoneIdentifier: "UTC",
    usesGroupingSeparator: false,
    minimumFractionDigits: 0,
    maximumFractionDigits: 15,
    includeFractionalSeconds: false,
    numberFormatMode: .decimal,
    dateFormatMode: .iso8601,
    durationFormatMode: .seconds,
    preferCellNumberFormatHints: false
  )
  let durationHHMMSSOptions = ReadFormattingOptions(
    localeIdentifier: "en_US_POSIX",
    timeZoneIdentifier: "UTC",
    usesGroupingSeparator: false,
    minimumFractionDigits: 0,
    maximumFractionDigits: 15,
    includeFractionalSeconds: false,
    numberFormatMode: .decimal,
    dateFormatMode: .iso8601,
    durationFormatMode: .hhmmss,
    preferCellNumberFormatHints: false
  )
  let durationAbbrevOptions = ReadFormattingOptions(
    localeIdentifier: "en_US_POSIX",
    timeZoneIdentifier: "UTC",
    usesGroupingSeparator: false,
    minimumFractionDigits: 0,
    maximumFractionDigits: 15,
    includeFractionalSeconds: false,
    numberFormatMode: .decimal,
    dateFormatMode: .iso8601,
    durationFormatMode: .abbreviated,
    preferCellNumberFormatHints: false
  )

  var entries: [FormattingEntry] = []

  for sheet in document.sheets {
    for table in sheet.tables {
      for cell in table.populatedCells(sorted: true) {
        let reference = CellReference(address: cell.address).a1
        let fallback = cell.formatted
        let formatted: (ReadFormattingOptions) -> String = { options in
          table.formattedValue(at: cell.address, options: options) ?? fallback
        }

        entries.append(
          FormattingEntry(
            sheetName: sheet.name,
            tableName: table.name,
            cellReference: reference,
            row: cell.address.row,
            column: cell.address.column,
            kind: readCellKindString(cell.kind),
            defaultFormatted: fallback,
            styleHinted: formatted(styleHintedOptions),
            decimal: formatted(decimalOptions),
            currencyUSD: formatted(currencyOptions),
            percent: formatted(percentOptions),
            scientific: formatted(scientificOptions),
            dateISO8601: formatted(dateISOOptions),
            dateShort: formatted(dateShortOptions),
            durationSeconds: formatted(durationSecondsOptions),
            durationHHMMSS: formatted(durationHHMMSSOptions),
            durationAbbreviated: formatted(durationAbbrevOptions)
          )
        )
      }
    }
  }

  return entries
}

private func collectTableEntries(
  from document: NumbersDocument,
  sheetFilter: String?
) -> [TableEntry] {
  var entries: [TableEntry] = []

  for (sheetOffset, sheetModel) in document.sheets.enumerated() {
    if let sheetFilter, sheetModel.name != sheetFilter {
      continue
    }

    for (tableOffset, tableModel) in sheetModel.tables.enumerated() {
      entries.append(
        TableEntry(
          sheetIndex: sheetOffset + 1,
          sheetID: sheetModel.id,
          sheetName: sheetModel.name,
          tableIndexInSheet: tableOffset + 1,
          tableID: tableModel.id,
          tableName: tableModel.name,
          rowCount: tableModel.metadata.rowCount,
          columnCount: tableModel.metadata.columnCount,
          mergeRangeCount: tableModel.metadata.mergeRanges.count,
          populatedCellCount: tableModel.populatedCellCount,
          formulaCount: tableModel.formulas().count,
          usedRange: tableModel.usedRange?.a1
        )
      )
    }
  }

  return entries
}

private func cellValueKind(_ value: CellValue) -> String {
  switch value {
  case .empty:
    return "empty"
  case .string:
    return "string"
  case .formula:
    return "formula"
  case .number:
    return "number"
  case .bool:
    return "bool"
  case .date:
    return "date"
  }
}

private func readCellKindString(_ kind: ReadCellKind) -> String {
  switch kind {
  case .empty:
    return "empty"
  case .text:
    return "text"
  case .number:
    return "number"
  case .bool:
    return "bool"
  case .date:
    return "date"
  case .duration:
    return "duration"
  case .formula:
    return "formula"
  case .formulaError:
    return "formulaError"
  case .richText:
    return "richText"
  case .unknown(let rawType):
    return "unknown(\(rawType))"
  }
}

private func mergeRoleString(_ role: MergeRole) -> String {
  switch role {
  case .none:
    return "none"
  case .anchor:
    return "anchor"
  case .member:
    return "member"
  }
}

private func horizontalAlignmentString(_ alignment: ReadHorizontalAlignment) -> String {
  switch alignment {
  case .left:
    return "left"
  case .center:
    return "center"
  case .right:
    return "right"
  case .justified:
    return "justified"
  case .natural:
    return "natural"
  case .unknown(let raw):
    return "unknown(\(raw))"
  }
}

private func verticalAlignmentString(_ alignment: ReadVerticalAlignment) -> String {
  switch alignment {
  case .top:
    return "top"
  case .middle:
    return "middle"
  case .bottom:
    return "bottom"
  case .unknown(let raw):
    return "unknown(\(raw))"
  }
}

private func mergeRangeA1(_ range: MergeRange) -> String {
  let start = CellReference(
    address: CellAddress(row: range.startRow, column: range.startColumn)
  ).a1
  let end = CellReference(
    address: CellAddress(row: range.endRow, column: range.endColumn)
  ).a1
  return start == end ? start : "\(start):\(end)"
}

private func iso8601String(_ date: Date) -> String {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  return formatter.string(from: date)
}

private func richTextPayload(from richText: RichTextRead?) -> RichTextPayload? {
  guard let richText else {
    return nil
  }

  return RichTextPayload(
    text: richText.text,
    runs: richText.runs.map { run in
      RichTextPayload.Run(
        start: run.range.lowerBound,
        end: run.range.upperBound,
        text: run.text,
        fontName: run.fontName,
        fontSize: run.fontSize,
        isBold: run.isBold,
        isItalic: run.isItalic,
        textColorHex: run.textColorHex,
        linkURL: run.linkURL
      )
    }
  )
}

private func formulaResultSummaryPayload(from result: FormulaResultRead) -> FormulaResultSummaryPayload {
  FormulaResultSummaryPayload(
    formulaID: result.formulaID,
    rawFormula: result.rawFormula,
    parsedTokens: result.parsedTokens,
    astSummary: result.astSummary,
    computedKind: cellValueKind(result.computedValue),
    computedValue: describeTypedValue(typedValuePayload(from: result.computedValue)),
    computedFormatted: result.computedFormatted
  )
}

private func formulaPayload(
  from formula: FormulaRead?,
  readCell: ReadCell
) -> FormulaPayload? {
  if let formula {
    return FormulaPayload(
      formulaID: formula.formulaID,
      rawFormula: formula.rawFormula,
      parsedTokens: formula.parsedTokens,
      astSummary: formula.astSummary,
      result: typedValuePayload(from: formula.result),
      resultFormatted: formula.resultFormatted
    )
  }

  guard let fallback = readCell.formulaResult else {
    return nil
  }

  return FormulaPayload(
    formulaID: fallback.formulaID ?? readCell.formulaID,
    rawFormula: fallback.rawFormula,
    parsedTokens: fallback.parsedTokens,
    astSummary: fallback.astSummary,
    result: typedValuePayload(from: fallback.computedValue),
    resultFormatted: fallback.computedFormatted
  )
}

private func typedValuePayload(from value: CellValue) -> TypedValuePayload {
  switch value {
  case .empty:
    return TypedValuePayload(
      kind: "empty",
      string: nil,
      number: nil,
      bool: nil,
      dateISO8601: nil,
      durationSeconds: nil,
      error: nil,
      richText: nil,
      formulaResultSummary: nil
    )
  case .string(let string):
    return TypedValuePayload(
      kind: "string",
      string: string,
      number: nil,
      bool: nil,
      dateISO8601: nil,
      durationSeconds: nil,
      error: nil,
      richText: nil,
      formulaResultSummary: nil
    )
  case .formula(let formula):
    return TypedValuePayload(
      kind: "formula",
      string: formula,
      number: nil,
      bool: nil,
      dateISO8601: nil,
      durationSeconds: nil,
      error: nil,
      richText: nil,
      formulaResultSummary: nil
    )
  case .number(let number):
    return TypedValuePayload(
      kind: "number",
      string: nil,
      number: number,
      bool: nil,
      dateISO8601: nil,
      durationSeconds: nil,
      error: nil,
      richText: nil,
      formulaResultSummary: nil
    )
  case .bool(let bool):
    return TypedValuePayload(
      kind: "bool",
      string: nil,
      number: nil,
      bool: bool,
      dateISO8601: nil,
      durationSeconds: nil,
      error: nil,
      richText: nil,
      formulaResultSummary: nil
    )
  case .date(let date):
    return TypedValuePayload(
      kind: "date",
      string: nil,
      number: nil,
      bool: nil,
      dateISO8601: iso8601String(date),
      durationSeconds: nil,
      error: nil,
      richText: nil,
      formulaResultSummary: nil
    )
  }
}

private func typedValuePayload(from value: ReadCellValue) -> TypedValuePayload {
  switch value {
  case .empty:
    return typedValuePayload(from: CellValue.empty)
  case .string(let string):
    return typedValuePayload(from: CellValue.string(string))
  case .number(let number):
    return typedValuePayload(from: CellValue.number(number))
  case .bool(let bool):
    return typedValuePayload(from: CellValue.bool(bool))
  case .date(let date):
    return typedValuePayload(from: CellValue.date(date))
  case .duration(let seconds):
    return TypedValuePayload(
      kind: "duration",
      string: nil,
      number: nil,
      bool: nil,
      dateISO8601: nil,
      durationSeconds: seconds,
      error: nil,
      richText: nil,
      formulaResultSummary: nil
    )
  case .error(let message):
    return TypedValuePayload(
      kind: "error",
      string: nil,
      number: nil,
      bool: nil,
      dateISO8601: nil,
      durationSeconds: nil,
      error: message,
      richText: nil,
      formulaResultSummary: nil
    )
  case .richText(let richText):
    return TypedValuePayload(
      kind: "richText",
      string: nil,
      number: nil,
      bool: nil,
      dateISO8601: nil,
      durationSeconds: nil,
      error: nil,
      richText: richTextPayload(from: richText),
      formulaResultSummary: nil
    )
  case .formulaResult(let result):
    return TypedValuePayload(
      kind: "formulaResult",
      string: nil,
      number: nil,
      bool: nil,
      dateISO8601: nil,
      durationSeconds: nil,
      error: nil,
      richText: nil,
      formulaResultSummary: formulaResultSummaryPayload(from: result)
    )
  }
}

private func stylePayload(from style: ReadCellStyle?) -> StylePayload? {
  guard let style else {
    return nil
  }

  return StylePayload(
    horizontalAlignment: style.horizontalAlignment.map(horizontalAlignmentString),
    verticalAlignment: style.verticalAlignment.map(verticalAlignmentString),
    backgroundColorHex: style.backgroundColorHex,
    hasTopBorder: style.hasTopBorder,
    hasRightBorder: style.hasRightBorder,
    hasBottomBorder: style.hasBottomBorder,
    hasLeftBorder: style.hasLeftBorder,
    numberFormat: style.numberFormat.map { format in
      StylePayload.NumberFormatPayload(kind: format.kind.rawValue, formatID: format.formatID)
    }
  )
}

private func describeTypedValue(_ payload: TypedValuePayload) -> String {
  switch payload.kind {
  case "empty":
    return "empty"
  case "string":
    return payload.string ?? ""
  case "number":
    return payload.number.map { String($0) } ?? ""
  case "bool":
    return payload.bool.map { String($0) } ?? ""
  case "date":
    return payload.dateISO8601 ?? ""
  case "duration":
    return payload.durationSeconds.map { "\($0)s" } ?? ""
  case "error":
    return payload.error ?? ""
  case "richText":
    if let richText = payload.richText {
      return "richText(text=\"\(richText.text)\", runs=\(richText.runs.count))"
    }
    return "richText"
  case "formulaResult":
    if let result = payload.formulaResultSummary {
      return
        "formulaResult(formulaID=\(result.formulaID.map { String($0) } ?? "-"), value=\(result.computedValue))"
    }
    return "formulaResult"
  default:
    return payload.kind
  }
}

private func renderReadCellText(_ payload: ReadCellJSONPayload) -> String {
  var lines: [String] = []
  lines.append("Source: \(payload.sourcePath)")
  lines.append("Sheet: \(payload.sheetName) [id=\(payload.sheetID)]")
  lines.append(
    "Table: \(payload.tableName) [id=\(payload.tableID)] rows=\(payload.tableRowCount) cols=\(payload.tableColumnCount)"
  )
  lines.append("Cell: \(payload.cellReference) (row=\(payload.row), col=\(payload.column))")
  lines.append("Kind: \(payload.kind)")
  lines.append("Value: \(describeTypedValue(payload.value))")
  lines.append("ReadValue: \(describeTypedValue(payload.readValue))")
  lines.append("Formatted: \(payload.formatted)")

  if let formula = payload.formula {
    lines.append("Formula:")
    lines.append("  ID: \(formula.formulaID.map { String($0) } ?? "-")")
    lines.append("  Raw: \(formula.rawFormula ?? "<none>")")
    lines.append("  Tokens: \(formula.parsedTokens.isEmpty ? "<none>" : formula.parsedTokens.joined(separator: " "))")
    lines.append("  AST: \(formula.astSummary ?? "<none>")")
    lines.append("  Result: \(describeTypedValue(formula.result))")
    lines.append("  Result formatted: \(formula.resultFormatted)")
  }

  if let style = payload.style {
    lines.append("Style:")
    lines.append(
      "  align(h=\(style.horizontalAlignment ?? "-"), v=\(style.verticalAlignment ?? "-"))"
    )
    lines.append(
      "  bg=\(style.backgroundColorHex ?? "-") borders[top=\(style.hasTopBorder), right=\(style.hasRightBorder), bottom=\(style.hasBottomBorder), left=\(style.hasLeftBorder)]"
    )
    if let numberFormat = style.numberFormat {
      lines.append("  numberFormat=\(numberFormat.kind)#\(numberFormat.formatID)")
    }
  }

  lines.append(
    "Merge: isMerged=\(payload.merge.isMerged) role=\(payload.merge.role) range=\(payload.merge.range ?? "-")"
  )

  lines.append(
    "Raw IDs: rawCellType=\(payload.rawCellType.map { String($0) } ?? "-") stringID=\(payload.stringID.map { String($0) } ?? "-") richTextID=\(payload.richTextID.map { String($0) } ?? "-") formulaID=\(payload.formulaID.map { String($0) } ?? "-") formulaErrorID=\(payload.formulaErrorID.map { String($0) } ?? "-")"
  )
  return lines.joined(separator: "\n")
}

private func renderReadRangeText(_ payload: ReadRangeJSONPayload) -> String {
  var lines: [String] = []
  lines.append("Source: \(payload.sourcePath)")
  lines.append("Sheet: \(payload.sheetName) [id=\(payload.sheetID)]")
  lines.append(
    "Table: \(payload.tableName) [id=\(payload.tableID)] rows=\(payload.tableRowCount) cols=\(payload.tableColumnCount)"
  )
  lines.append(
    "Range: requested=\(payload.requestedRange) resolved=\(payload.resolvedRange) rows=\(payload.rowCount) cols=\(payload.columnCount)"
  )
  lines.append("Cells:")
  if payload.cells.isEmpty {
    lines.append("  <none>")
  } else {
    for row in payload.cells {
      let parts = row.map { cell in
        "\(cell.cellReference)=\(cell.formatted)"
      }
      lines.append("  " + parts.joined(separator: " | "))
    }
  }
  return lines.joined(separator: "\n")
}

private func renderReadColumnText(_ payload: ReadColumnJSONPayload) -> String {
  var lines: [String] = []
  lines.append("Source: \(payload.sourcePath)")
  lines.append("Sheet: \(payload.sheetName) [id=\(payload.sheetID)]")
  lines.append(
    "Table: \(payload.tableName) [id=\(payload.tableID)] rows=\(payload.tableRowCount) cols=\(payload.tableColumnCount)"
  )
  var selectorLine =
    "Column: mode=\(payload.selectionMode) index=\(payload.columnIndex) fromRow=\(payload.fromRow) cells=\(payload.cellCount)"
  if let requestedHeader = payload.requestedHeader {
    selectorLine += " header=\"\(requestedHeader)\""
  }
  if let headerRow = payload.headerRow {
    selectorLine += " headerRow=\(headerRow)"
  }
  if let includeHeader = payload.includeHeader {
    selectorLine += " includeHeader=\(includeHeader)"
  }
  lines.append(selectorLine)
  lines.append("Cells:")
  if payload.cells.isEmpty {
    lines.append("  <none>")
  } else {
    for cell in payload.cells {
      lines.append("  \(cell.cellReference)=\(cell.formatted)")
    }
  }
  return lines.joined(separator: "\n")
}

private struct ReadColumnJSONLinePayload: Encodable {
  let sourcePath: String
  let sheetID: String
  let sheetName: String
  let tableID: String
  let tableName: String
  let selectionMode: String
  let columnIndex: Int
  let fromRow: Int
  let cell: ReadColumnJSONPayload.Cell
}

private func renderReadColumnJSONLines(_ payload: ReadColumnJSONPayload) throws -> String {
  var lines: [String] = []
  lines.reserveCapacity(payload.cells.count)

  for cell in payload.cells {
    lines.append(
      try renderJSONLine(
        ReadColumnJSONLinePayload(
          sourcePath: payload.sourcePath,
          sheetID: payload.sheetID,
          sheetName: payload.sheetName,
          tableID: payload.tableID,
          tableName: payload.tableName,
          selectionMode: payload.selectionMode,
          columnIndex: payload.columnIndex,
          fromRow: payload.fromRow,
          cell: cell
        )
      )
    )
  }

  return lines.joined(separator: "\n")
}

private func renderReadTableText(_ payload: ReadTableJSONPayload) -> String {
  var lines: [String] = []
  lines.append("Source: \(payload.sourcePath)")
  lines.append("Sheet: \(payload.sheetName) [id=\(payload.sheetID)]")
  lines.append(
    "Table: \(payload.tableName) [id=\(payload.tableID)] rows=\(payload.tableRowCount) cols=\(payload.tableColumnCount)"
  )
  lines.append(
    "Window: fromRow=\(payload.fromRow) fromColumn=\(payload.fromColumn) maxRows=\(payload.maxRows) maxColumns=\(payload.maxColumns) resolvedRows=\(payload.resolvedRowCount) resolvedColumns=\(payload.resolvedColumnCount) truncatedRows=\(payload.truncatedRows) truncatedColumns=\(payload.truncatedColumns)"
  )
  lines.append("Cells:")
  if payload.cells.isEmpty {
    lines.append("  <none>")
  } else {
    for row in payload.cells {
      let parts = row.map { cell in
        "\(cell.cellReference)=\(cell.formatted)"
      }
      lines.append("  " + parts.joined(separator: " | "))
    }
  }
  return lines.joined(separator: "\n")
}

private struct ReadTableJSONLinePayload: Encodable {
  let sourcePath: String
  let sheetID: String
  let sheetName: String
  let tableID: String
  let tableName: String
  let fromRow: Int
  let fromColumn: Int
  let row: Int
  let rowOffset: Int
  let resolvedColumnCount: Int
  let cells: [ReadTableJSONPayload.Cell]
}

private func renderReadTableJSONLines(_ payload: ReadTableJSONPayload) throws -> String {
  var lines: [String] = []
  lines.reserveCapacity(payload.cells.count)

  for (rowOffset, rowCells) in payload.cells.enumerated() {
    lines.append(
      try renderJSONLine(
        ReadTableJSONLinePayload(
          sourcePath: payload.sourcePath,
          sheetID: payload.sheetID,
          sheetName: payload.sheetName,
          tableID: payload.tableID,
          tableName: payload.tableName,
          fromRow: payload.fromRow,
          fromColumn: payload.fromColumn,
          row: payload.fromRow + rowOffset,
          rowOffset: rowOffset,
          resolvedColumnCount: payload.resolvedColumnCount,
          cells: rowCells
        )
      )
    )
  }

  return lines.joined(separator: "\n")
}

private struct ReadRangeJSONLinePayload: Encodable {
  let sourcePath: String
  let sheetID: String
  let sheetName: String
  let tableID: String
  let tableName: String
  let requestedRange: String
  let resolvedRange: String
  let row: Int
  let rowOffset: Int
  let columnCount: Int
  let cells: [ReadRangeJSONPayload.Cell]
}

private func renderReadRangeJSONLines(_ payload: ReadRangeJSONPayload) throws -> String {
  var lines: [String] = []
  lines.reserveCapacity(payload.cells.count)

  for (rowOffset, rowCells) in payload.cells.enumerated() {
    let row = rowCells.first?.row ?? rowOffset
    lines.append(
      try renderJSONLine(
        ReadRangeJSONLinePayload(
          sourcePath: payload.sourcePath,
          sheetID: payload.sheetID,
          sheetName: payload.sheetName,
          tableID: payload.tableID,
          tableName: payload.tableName,
          requestedRange: payload.requestedRange,
          resolvedRange: payload.resolvedRange,
          row: row,
          rowOffset: rowOffset,
          columnCount: payload.columnCount,
          cells: rowCells
        )
      )
    )
  }

  return lines.joined(separator: "\n")
}

private func renderCSV(
  table: SwiftNumbersCore.Table,
  mode: ExportCSVMode
) -> String {
  guard table.rowCount > 0, table.columnCount > 0 else {
    return ""
  }

  var lines: [String] = []
  lines.reserveCapacity(table.rowCount)

  for row in 0..<table.rowCount {
    var fields: [String] = []
    fields.reserveCapacity(table.columnCount)

    for column in 0..<table.columnCount {
      let address = CellAddress(row: row, column: column)
      let value = csvCellString(table: table, address: address, mode: mode)
      fields.append(escapeCSVField(value))
    }

    lines.append(fields.joined(separator: ","))
  }

  return lines.joined(separator: "\n") + "\n"
}

private func csvCellString(
  table: SwiftNumbersCore.Table,
  address: CellAddress,
  mode: ExportCSVMode
) -> String {
  switch mode {
  case .value:
    guard let readCell = table.readCell(at: address) else {
      return ""
    }
    return csvCellString(from: readCell.readValue)
  case .formatted:
    return table.formattedValue(at: address, options: .default) ?? ""
  case .formula:
    if let raw = table.formula(at: address)?.rawFormula, !raw.isEmpty {
      return raw
    }
    return table.formattedValue(at: address, options: .default) ?? ""
  }
}

private func csvCellString(from value: ReadCellValue) -> String {
  switch value {
  case .empty:
    return ""
  case .string(let text):
    return text
  case .number(let number):
    return csvNumberString(number)
  case .bool(let bool):
    return bool ? "TRUE" : "FALSE"
  case .date(let date):
    return iso8601String(date)
  case .duration(let seconds):
    return csvNumberString(seconds)
  case .error(let message):
    return message
  case .richText(let richText):
    return richText.text
  case .formulaResult(let formulaResult):
    return csvCellString(from: formulaResult.computedValue)
  }
}

private func csvCellString(from value: CellValue) -> String {
  switch value {
  case .empty:
    return ""
  case .string(let text):
    return text
  case .formula(let formula):
    return formula
  case .number(let number):
    return csvNumberString(number)
  case .bool(let bool):
    return bool ? "TRUE" : "FALSE"
  case .date(let date):
    return iso8601String(date)
  }
}

private func csvNumberString(_ value: Double) -> String {
  let formatter = NumberFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.numberStyle = .decimal
  formatter.usesGroupingSeparator = false
  formatter.minimumFractionDigits = 0
  formatter.maximumFractionDigits = 15
  return formatter.string(from: NSNumber(value: value)) ?? String(value)
}

private func escapeCSVField(_ value: String) -> String {
  let requiresQuotes =
    value.contains(",")
    || value.contains("\"")
    || value.contains("\n")
    || value.contains("\r")

  guard requiresQuotes else {
    return value
  }

  return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
}

private func parseCSVRows(_ content: String) throws -> [[String]] {
  var rows: [[String]] = []
  var currentRow: [String] = []
  var currentField = ""
  var inQuotes = false

  var index = content.startIndex
  while index < content.endIndex {
    let character = content[index]

    if inQuotes {
      if character == "\"" {
        let nextIndex = content.index(after: index)
        if nextIndex < content.endIndex, content[nextIndex] == "\"" {
          currentField.append("\"")
          index = nextIndex
        } else {
          inQuotes = false
        }
      } else {
        currentField.append(character)
      }
      index = content.index(after: index)
      continue
    }

    switch character {
    case "\"":
      inQuotes = true
    case ",":
      currentRow.append(currentField)
      currentField = ""
    case "\n":
      currentRow.append(currentField)
      rows.append(currentRow)
      currentRow = []
      currentField = ""
    case "\r":
      currentRow.append(currentField)
      rows.append(currentRow)
      currentRow = []
      currentField = ""

      let nextIndex = content.index(after: index)
      if nextIndex < content.endIndex, content[nextIndex] == "\n" {
        index = nextIndex
      }
    default:
      currentField.append(character)
    }

    index = content.index(after: index)
  }

  if inQuotes {
    throw ValidationError("CSV parse failed: unclosed quoted field.")
  }

  if !currentField.isEmpty || !currentRow.isEmpty {
    currentRow.append(currentField)
    rows.append(currentRow)
  }

  if let last = rows.last, last.count == 1, (last.first?.isEmpty ?? false) {
    rows.removeLast()
  }

  return rows
}

private func normalizeImportRows(
  _ rows: [[String]],
  headerMode: ImportCSVHeaderMode
) -> [[String]] {
  guard !rows.isEmpty else {
    return []
  }

  switch headerMode {
  case .withHeader:
    return rows
  case .noHeader:
    let maxColumns = rows.map(\.count).max() ?? 0
    guard maxColumns > 0 else {
      return rows
    }
    let generatedHeader = (0..<maxColumns).map { "Column \($0 + 1)" }
    return [generatedHeader] + rows
  }
}

private func importedCellValue(
  raw: String,
  parseDates: Bool,
  forceString: Bool
) -> CellValue {
  if forceString {
    return raw.isEmpty ? .empty : .string(raw)
  }

  let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
  if trimmed.isEmpty {
    return .empty
  }

  if parseDates, let date = parseCSVDate(trimmed) {
    return .date(date)
  }

  let lower = trimmed.lowercased()
  if lower == "true" {
    return .bool(true)
  }
  if lower == "false" {
    return .bool(false)
  }

  if let number = parseCSVNumber(trimmed) {
    return .number(number)
  }

  return .string(raw)
}

private func parseCSVDate(_ raw: String) -> Date? {
  let iso8601 = ISO8601DateFormatter()
  iso8601.timeZone = TimeZone(secondsFromGMT: 0)

  if let value = iso8601.date(from: raw) {
    return value
  }

  let iso8601Fractional = ISO8601DateFormatter()
  iso8601Fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  iso8601Fractional.timeZone = TimeZone(secondsFromGMT: 0)
  if let value = iso8601Fractional.date(from: raw) {
    return value
  }

  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  formatter.dateFormat = "yyyy-MM-dd"
  return formatter.date(from: raw)
}

private func parseCSVNumber(_ raw: String) -> Double? {
  if let number = Double(raw) {
    return number
  }

  let formatter = NumberFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.numberStyle = .decimal
  formatter.usesGroupingSeparator = false
  return formatter.number(from: raw)?.doubleValue
}

private func resolveSheet(
  in document: NumbersDocument,
  sheetName: String?,
  sheetIndex: Int?
) throws -> SwiftNumbersCore.Sheet {
  if let sheetName, let sheetIndex {
    throw ValidationError(
      "Provide either --sheet or --sheet-index, not both (received name '\(sheetName)' and index \(sheetIndex))."
    )
  }

  if let sheetName {
    guard let sheet = document.sheet(named: sheetName) else {
      throw ValidationError("Sheet '\(sheetName)' not found.")
    }
    return sheet
  }

  if let sheetIndex {
    guard sheetIndex >= 0, sheetIndex < document.sheets.count else {
      throw ValidationError(
        "Sheet index \(sheetIndex) is out of bounds (document has \(document.sheets.count) sheets)."
      )
    }
    return document.sheets[sheetIndex]
  }

  throw ValidationError("Missing sheet selector. Provide --sheet or --sheet-index.")
}

private func resolveTable(
  in sheet: SwiftNumbersCore.Sheet,
  tableName: String?,
  tableIndex: Int?
) throws -> SwiftNumbersCore.Table {
  if let tableName, let tableIndex {
    throw ValidationError(
      "Provide either --table or --table-index, not both (received name '\(tableName)' and index \(tableIndex))."
    )
  }

  if let tableName {
    guard let table = sheet.table(named: tableName) else {
      throw ValidationError("Table '\(tableName)' not found in sheet '\(sheet.name)'.")
    }
    return table
  }

  if let tableIndex {
    guard tableIndex >= 0, tableIndex < sheet.tables.count else {
      throw ValidationError(
        "Table index \(tableIndex) is out of bounds for sheet '\(sheet.name)' (sheet has \(sheet.tables.count) tables)."
      )
    }
    return sheet.tables[tableIndex]
  }

  throw ValidationError("Missing table selector. Provide --table or --table-index.")
}

private func resolveColumnIndex(
  in table: SwiftNumbersCore.Table,
  header: String,
  headerRow: Int
) throws -> Int {
  guard headerRow >= 0, headerRow < table.rowCount else {
    throw ValidationError("Header row \(headerRow) is out of bounds.")
  }

  let normalizedHeader = header.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  for columnIndex in 0..<table.columnCount {
    let address = CellAddress(row: headerRow, column: columnIndex)
    let candidate = table.formattedValue(at: address, options: .default) ?? ""
    let normalizedCandidate = candidate.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if normalizedCandidate == normalizedHeader {
      return columnIndex
    }
  }
  throw ValidationError("Header '\(header)' not found.")
}

private func renderJSONLine<T: Encodable>(_ payload: T) throws -> String {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.sortedKeys]
  let data = try encoder.encode(payload)
  guard let string = String(data: data, encoding: .utf8) else {
    throw ValidationError("Failed to render JSON line output.")
  }
  return string
}

private struct CLIParsedRange {
  let start: CellAddress
  let end: CellAddress

  var a1: String {
    let startRef = CellReference(address: start).a1
    let endRef = CellReference(address: end).a1
    return startRef == endRef ? startRef : "\(startRef):\(endRef)"
  }
}

private func parseCLIRangeReference(_ raw: String) throws -> CLIParsedRange {
  let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !trimmed.isEmpty else {
    throw ValidationError("Invalid range reference: \(raw)")
  }

  let parts = trimmed.split(separator: ":", maxSplits: 1).map(String.init)
  guard parts.count == 1 || parts.count == 2 else {
    throw ValidationError("Invalid range reference: \(raw)")
  }

  let startRef = try CellReference(parts[0])
  let endRef = try (parts.count == 2 ? CellReference(parts[1]) : startRef)

  return CLIParsedRange(
    start: CellAddress(
      row: min(startRef.address.row, endRef.address.row),
      column: min(startRef.address.column, endRef.address.column)
    ),
    end: CellAddress(
      row: max(startRef.address.row, endRef.address.row),
      column: max(startRef.address.column, endRef.address.column)
    )
  )
}

private func renderJSON<T: Encodable>(_ payload: T) throws -> String {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  let data = try encoder.encode(payload)
  guard let string = String(data: data, encoding: .utf8) else {
    throw ValidationError("Failed to render JSON output.")
  }
  return string
}
