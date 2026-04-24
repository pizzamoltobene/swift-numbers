import ArgumentParser
import Foundation
import SwiftNumbersCore

enum OutputFormat: String, ExpressibleByArgument {
  case text
  case json
}

@main
struct SwiftNumbersCLI: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "swiftnumbers",
    abstract: "Swift-native reader and tooling for .numbers containers.",
    subcommands: [Dump.self, ListSheets.self]
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

  mutating func run() throws {
    let url = URL(fileURLWithPath: file)
    let document = try NumbersDocument.open(at: url)
    let formulaEntries = collectFormulaEntries(from: document)

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
            let formulaID = entry.formulaID.map(String.init) ?? "-"
            let raw = entry.rawFormula ?? "<unresolved>"
            print(
              "  \(entry.sheetName)/\(entry.tableName) \(entry.cellReference) [id=\(formulaID)] result=\(entry.resultFormatted) raw=\(raw)"
            )
          }
        }
      }
    case .json:
      let payload = DumpJSONPayload(
        dump: document.dump(),
        sheets: document.sheets,
        formulas: formulas ? formulaEntries : nil
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
  let sheets: [Sheet]

  init(
    dump: DocumentDump,
    sheets: [SwiftNumbersCore.Sheet],
    formulas: [FormulaEntry]? = nil
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

private func collectFormulaEntries(from document: NumbersDocument) -> [FormulaEntry] {
  var entries: [FormulaEntry] = []

  for sheet in document.sheets {
    for table in sheet.tables {
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

private func cellValueKind(_ value: CellValue) -> String {
  switch value {
  case .empty:
    return "empty"
  case .string:
    return "string"
  case .number:
    return "number"
  case .bool:
    return "bool"
  case .date:
    return "date"
  }
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
