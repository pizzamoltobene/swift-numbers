import Foundation
import SwiftNumbersContainer
import SwiftNumbersIWA

public enum NumbersDocumentError: LocalizedError {
  case realReadFailed(String)
  case encryptedDocumentUnsupported

  public var errorDescription: String? {
    switch self {
    case .realReadFailed(let details):
      return "Swift-native read failed: \(details)"
    case .encryptedDocumentUnsupported:
      return
        "Encrypted .numbers documents are currently unsupported. Re-save without password protection and retry."
    }
  }
}

public struct NumbersDocument: Sendable {
  public let sourceURL: URL
  public let sheets: [Sheet]

  private let dumpInfo: DocumentDump
  private static let editableStringEscapePrefix = "__SWIFTNUMBERS_STRING__:"
  private static let editableDateMarkerPrefix = "__SWIFTNUMBERS_DATE__:"
  private static let editableFormulaMarkerPrefix = "__SWIFTNUMBERS_FORMULA__:"

  public static func open(at url: URL) throws -> NumbersDocument {
    let container = try NumbersContainer.open(at: url)
    if try container.isLikelyEncryptedDocument() {
      throw NumbersDocumentError.encryptedDocumentUnsupported
    }
    let documentVersion = NumbersDocumentVersion.read(from: container)
    let blobs = try container.loadIndexBlobs()
    let inventory = try IWAInventoryBuilder.build(from: blobs)

    let realRead = IWARealDocumentReader.read(from: inventory, documentVersion: documentVersion)
    guard !realRead.sheets.isEmpty else {
      let reason =
        realRead.structuredDiagnostics
        .first(where: { $0.severity == .error || $0.severity == .warning })?
        .rendered
        ?? realRead.diagnostics.first
        ?? "Real-read path returned no sheets."
      throw NumbersDocumentError.realReadFailed(reason)
    }
    let sheets = mapResolvedSheets(realRead.sheets)
    let diagnostics = realRead.diagnostics
    let structuredDiagnostics = realRead.structuredDiagnostics.map(mapReadDiagnostic)

    let resolvedCellCount =
      sheets
      .flatMap(\.tables)
      .reduce(0) { $0 + $1.populatedCellCount }

    let dump = DocumentDump(
      readPath: .real,
      sourcePath: url.path,
      documentVersion: documentVersion,
      blobCount: blobs.count,
      objectCount: inventory.records.count,
      objectReferenceEdgeCount: inventory.objectReferenceEdgeCount,
      rootObjectCount: inventory.rootObjectIDs.count,
      resolvedCellCount: resolvedCellCount,
      fallbackReason: nil,
      typeHistogram: inventory.typeHistogram,
      unparsedBlobPaths: inventory.unparsedBlobPaths,
      diagnostics: diagnostics,
      structuredDiagnostics: structuredDiagnostics
    )

    return NumbersDocument(sourceURL: url, sheets: sheets, dumpInfo: dump)
  }

  public func dump() -> DocumentDump {
    dumpInfo
  }

  public var firstSheet: Sheet? {
    sheets.first
  }

  public var sheetNames: [String] {
    sheets.map(\.name)
  }

  public var tableCount: Int {
    sheets.reduce(0) { $0 + $1.tables.count }
  }

  public var tableNames: [String] {
    sheets.flatMap { sheet in
      sheet.tables.map { "\(sheet.name)/\($0.name)" }
    }
  }

  public subscript(_ index: Int) -> Sheet? {
    sheet(at: index)
  }

  public subscript(_ name: String) -> Sheet? {
    sheet(named: name)
  }

  public func sheet(named name: String) -> Sheet? {
    sheets.first(where: { $0.name == name })
  }

  public func sheet(at index: Int) -> Sheet? {
    guard index >= 0, index < sheets.count else {
      return nil
    }
    return sheets[index]
  }

  public func renderDump() -> String {
    var lines: [String] = []
    lines.append("Source: \(dumpInfo.sourcePath)")
    if let documentVersion = dumpInfo.documentVersion {
      lines.append("Document version: \(documentVersion)")
    } else {
      lines.append("Document version: <unknown>")
    }
    lines.append("Read path: \(dumpInfo.readPath.rawValue)")
    if let fallbackReason = dumpInfo.fallbackReason {
      lines.append("Fallback reason: \(fallbackReason)")
    }
    lines.append("Sheets: \(sheets.count)")
    lines.append("Tables: \(sheets.reduce(0) { $0 + $1.tables.count })")
    lines.append("Resolved cells: \(dumpInfo.resolvedCellCount)")
    lines.append("Index blobs: \(dumpInfo.blobCount)")
    lines.append("IWA objects: \(dumpInfo.objectCount)")
    lines.append("Object reference edges: \(dumpInfo.objectReferenceEdgeCount)")
    lines.append("Root objects: \(dumpInfo.rootObjectCount)")

    let sortedTypes = dumpInfo.typeHistogram.keys.sorted()
    if sortedTypes.isEmpty {
      lines.append("Type histogram: <empty>")
    } else {
      lines.append("Type histogram:")
      for typeID in sortedTypes {
        let count = dumpInfo.typeHistogram[typeID, default: 0]
        lines.append("  \(typeID): \(count)")
      }
    }

    if dumpInfo.unparsedBlobPaths.isEmpty {
      lines.append("Unparsed blobs: 0")
    } else {
      lines.append("Unparsed blobs: \(dumpInfo.unparsedBlobPaths.count)")
      for path in dumpInfo.unparsedBlobPaths {
        lines.append("  \(path)")
      }
    }

    if dumpInfo.diagnostics.isEmpty {
      lines.append("Diagnostics: 0")
    } else {
      lines.append("Diagnostics: \(dumpInfo.diagnostics.count)")
      for diagnostic in dumpInfo.diagnostics {
        lines.append("  \(diagnostic)")
      }
    }

    return lines.joined(separator: "\n")
  }

  private static func mapResolvedSheets(_ sheets: [IWAResolvedSheet]) -> [Sheet] {
    sheets.map { sheet in
      let tables = sheet.tables.map { table in
        var cells: [CellAddress: CellValue] = [:]
        var readCells: [CellAddress: ReadCell] = [:]
        var formulas: [CellAddress: FormulaRead] = [:]
        cells.reserveCapacity(table.cells.count)
        readCells.reserveCapacity(table.cells.count)
        formulas.reserveCapacity(table.cells.count)

        for cell in table.cells {
          let address = CellAddress(row: cell.row, column: cell.column)
          let reference = CellReference(address: address).a1
          let value: CellValue
          switch cell.value {
          case .empty:
            value = .empty
          case .string(let string):
            if let escaped = decodeEscapedEditableString(string) {
              value = .string(escaped)
            } else if let date = decodeEditableDateMarker(string) {
              value = .date(date)
            } else if let formula = decodeEditableFormulaMarker(string) {
              value = .formula(formula)
            } else {
              value = .string(string)
            }
          case .number(let number):
            value = .number(number)
          case .bool(let bool):
            value = .bool(bool)
          case .date(let date):
            value = .date(date)
          case .duration(let seconds):
            value = .number(seconds)
          case .error(let message):
            value = .string(message)
          case .richText(let text):
            value = .string(cell.richText?.text ?? text)
          }

          let mappedKind: ReadCellKind
          if case .formula = value, cell.kind != .formula {
            mappedKind = .formula
          } else {
            mappedKind = mapResolvedCellKind(cell.kind)
          }
          let formattedValue = formatReadValue(value)
          let mappedRichText = mapResolvedRichText(cell.richText)
          let mappedStyle = mapResolvedCellStyle(cell.style)
          let formulaResult: FormulaResultRead?
          if mappedKind == .formula {
            let rawFormula: String?
            if let cellFormula = cell.formulaRaw {
              rawFormula = cellFormula
            } else if case .formula(let syntheticFormula) = value {
              rawFormula = syntheticFormula
            } else {
              rawFormula = nil
            }
            let tokens =
              cell.formulaTokens.isEmpty
              ? (rawFormula.map(tokenizeFormulaForDump) ?? [])
              : cell.formulaTokens
            let astSummary =
              cell.formulaASTSummary
              ?? (tokens.isEmpty ? nil : "Tokenized formula (\(tokens.count) tokens)")

            formulaResult = FormulaResultRead(
              formulaID: cell.formulaID,
              rawFormula: rawFormula,
              parsedTokens: tokens,
              astSummary: astSummary,
              computedValue: value,
              computedFormatted: formattedValue
            )

            formulas[address] = FormulaRead(
              address: address,
              reference: reference,
              formulaID: cell.formulaID,
              rawFormula: rawFormula,
              parsedTokens: tokens,
              astSummary: astSummary,
              result: value,
              resultFormatted: formattedValue
            )
          } else {
            formulaResult = nil
          }

          let readValue = mapResolvedReadValue(
            rawValue: cell.value,
            fallbackValue: value,
            richText: mappedRichText,
            formulaResult: formulaResult
          )

          cells[address] = value
          readCells[address] = ReadCell(
            address: address,
            value: value,
            kind: mappedKind,
            readValue: readValue,
            formulaResult: formulaResult,
            formatted: formattedValue,
            richText: mappedRichText,
            style: mappedStyle,
            rawCellType: cell.rawCellType,
            stringID: cell.stringID,
            richTextID: cell.richTextID,
            formulaID: cell.formulaID,
            formulaErrorID: cell.formulaErrorID
          )
        }

        let merges = table.merges.map { merge in
          MergeRange(
            startRow: merge.startRow,
            endRow: merge.endRow,
            startColumn: merge.startColumn,
            endColumn: merge.endColumn
          )
        }
        let objectIdentifiers: TableObjectIdentifiers? = {
          let tableInfoObjectID = table.tableInfoObjectID > 0 ? table.tableInfoObjectID : nil
          let tableModelObjectID = table.tableModelObjectID > 0 ? table.tableModelObjectID : nil
          guard tableInfoObjectID != nil || tableModelObjectID != nil else {
            return nil
          }
          return TableObjectIdentifiers(
            tableInfoObjectID: tableInfoObjectID,
            tableModelObjectID: tableModelObjectID
          )
        }()
        let pivotLinks = table.pivotLinks.map { link in
          PivotLinkMetadata(
            drawableObjectID: link.drawableObjectID,
            drawableTypeIDs: link.drawableTypeIDs,
            linkedTableInfoObjectIDs: link.linkedTableInfoObjectIDs,
            linkedTableModelObjectIDs: link.linkedTableModelObjectIDs
          )
        }

        return Table(
          id: table.id,
          name: table.name,
          metadata: TableMetadata(
            rowCount: table.rowCount,
            columnCount: table.columnCount,
            mergeRanges: merges,
            tableNameVisible: table.tableNameVisible,
            captionVisible: table.captionVisible,
            captionText: table.captionText,
            captionTextSupported: table.captionTextSupported,
            objectIdentifiers: objectIdentifiers,
            pivotLinks: pivotLinks
          ),
          cells: cells,
          readCells: readCells,
          formulas: formulas
        )
      }

      return Sheet(
        id: sheet.id,
        name: sheet.name,
        tables: tables
      )
    }
  }

  private static func decodeEscapedEditableString(_ raw: String) -> String? {
    guard raw.hasPrefix(editableStringEscapePrefix) else {
      return nil
    }
    return String(raw.dropFirst(editableStringEscapePrefix.count))
  }

  private static func decodeEditableDateMarker(_ raw: String) -> Date? {
    guard raw.hasPrefix(editableDateMarkerPrefix) else {
      return nil
    }

    let isoString = String(raw.dropFirst(editableDateMarkerPrefix.count))
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: isoString) {
      return date
    }

    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: isoString)
  }

  private static func decodeEditableFormulaMarker(_ raw: String) -> String? {
    guard raw.hasPrefix(editableFormulaMarkerPrefix) else {
      return nil
    }

    let encoded = String(raw.dropFirst(editableFormulaMarkerPrefix.count))
    let trimmed = encoded.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return nil
    }
    return trimmed.hasPrefix("=") ? trimmed : "=\(trimmed)"
  }

  private static func mapResolvedCellKind(_ kind: IWAResolvedCellKind) -> ReadCellKind {
    switch kind {
    case .empty:
      return .empty
    case .number:
      return .number
    case .text:
      return .text
    case .formula:
      return .formula
    case .date:
      return .date
    case .bool:
      return .bool
    case .duration:
      return .duration
    case .formulaError:
      return .formulaError
    case .richText:
      return .richText
    case .unknown(let raw):
      return .unknown(raw)
    }
  }

  private static func mapResolvedReadValue(
    rawValue: IWAResolvedCellValue,
    fallbackValue: CellValue,
    richText: RichTextRead?,
    formulaResult: FormulaResultRead?
  ) -> ReadCellValue {
    if let formulaResult {
      return .formulaResult(formulaResult)
    }

    switch rawValue {
    case .empty:
      return .empty
    case .string(let string):
      if case .date(let date) = fallbackValue {
        return .date(date)
      }
      if case .formula(let formula) = fallbackValue {
        return .string(formula)
      }
      return .string(string)
    case .number(let number):
      return .number(number)
    case .bool(let bool):
      return .bool(bool)
    case .date(let date):
      return .date(date)
    case .duration(let seconds):
      return .duration(seconds)
    case .error(let message):
      return .error(message)
    case .richText(let text):
      if let richText {
        return .richText(richText)
      }
      return .richText(RichTextRead(text: text, runs: []))
    }
  }

  private static func mapResolvedRichText(_ richText: IWAResolvedRichText?) -> RichTextRead? {
    guard let richText else {
      return nil
    }

    let runs = richText.runs.compactMap { run -> RichTextRun? in
      guard run.start >= 0, run.end >= run.start else {
        return nil
      }
      return RichTextRun(
        range: run.start..<run.end,
        text: run.text,
        fontName: run.fontName,
        fontSize: run.fontSize,
        isBold: run.isBold,
        isItalic: run.isItalic,
        textColorHex: run.textColorHex,
        linkURL: run.linkURL
      )
    }
    return RichTextRead(text: richText.text, runs: runs)
  }

  private static func mapResolvedCellStyle(_ style: IWAResolvedCellStyle?) -> ReadCellStyle? {
    guard let style else {
      return nil
    }
    return ReadCellStyle(
      horizontalAlignment: style.horizontalAlignment.map(mapResolvedHorizontalAlignment),
      verticalAlignment: style.verticalAlignment.map(mapResolvedVerticalAlignment),
      backgroundColorHex: style.backgroundColorHex,
      fontName: style.fontName,
      fontSize: style.fontSize,
      isBold: style.isBold,
      isItalic: style.isItalic,
      textColorHex: style.textColorHex,
      hasTopBorder: style.hasTopBorder,
      hasRightBorder: style.hasRightBorder,
      hasBottomBorder: style.hasBottomBorder,
      hasLeftBorder: style.hasLeftBorder,
      numberFormat: style.numberFormat.map(mapResolvedNumberFormat)
    )
  }

  private static func mapResolvedHorizontalAlignment(
    _ value: IWAResolvedHorizontalAlignment
  ) -> ReadHorizontalAlignment {
    switch value {
    case .left:
      return .left
    case .center:
      return .center
    case .right:
      return .right
    case .justified:
      return .justified
    case .natural:
      return .natural
    case .unknown(let raw):
      return .unknown(raw)
    }
  }

  private static func mapResolvedVerticalAlignment(
    _ value: IWAResolvedVerticalAlignment
  ) -> ReadVerticalAlignment {
    switch value {
    case .top:
      return .top
    case .middle:
      return .middle
    case .bottom:
      return .bottom
    case .unknown(let raw):
      return .unknown(raw)
    }
  }

  private static func mapResolvedNumberFormat(
    _ value: IWAResolvedNumberFormat
  ) -> ReadNumberFormat {
    let kind: ReadNumberFormatKind
    switch value.kind {
    case .number:
      kind = .number
    case .currency:
      kind = .currency
    case .date:
      kind = .date
    case .duration:
      kind = .duration
    case .text:
      kind = .text
    case .bool:
      kind = .bool
    }

    return ReadNumberFormat(kind: kind, formatID: value.formatID)
  }

  private static func mapReadDiagnostic(_ diagnostic: IWAReadDiagnostic) -> ReadDiagnostic {
    ReadDiagnostic(
      code: diagnostic.code,
      severity: mapReadDiagnosticSeverity(diagnostic.severity),
      message: diagnostic.message,
      objectPath: diagnostic.objectPath,
      suggestion: diagnostic.suggestion,
      context: diagnostic.context
    )
  }

  private static func mapReadDiagnosticSeverity(
    _ severity: IWAReadDiagnosticSeverity
  ) -> ReadDiagnosticSeverity {
    switch severity {
    case .info:
      return .info
    case .warning:
      return .warning
    case .error:
      return .error
    }
  }

  private static func formatReadValue(_ value: CellValue) -> String {
    switch value {
    case .empty:
      return ""
    case .string(let string):
      return string
    case .formula(let formula):
      return formula
    case .number(let number):
      let formatter = NumberFormatter()
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.numberStyle = .decimal
      formatter.usesGroupingSeparator = false
      formatter.maximumFractionDigits = 15
      formatter.minimumFractionDigits = 0
      return formatter.string(from: NSNumber(value: number)) ?? String(number)
    case .bool(let bool):
      return bool ? "TRUE" : "FALSE"
    case .date(let date):
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      return formatter.string(from: date)
    }
  }

  private static func tokenizeFormulaForDump(_ formula: String) -> [String] {
    if formula.isEmpty {
      return []
    }

    let punctuation = Set<Character>(["(", ")", ",", ":", "+", "-", "*", "/", "^", "&", "=", "<", ">"])
    var tokens: [String] = []
    var current = ""
    var inString = false

    for character in formula {
      if inString {
        current.append(character)
        if character == "\"" {
          tokens.append(current)
          current = ""
          inString = false
        }
        continue
      }

      if character == "\"" {
        if !current.isEmpty {
          tokens.append(current)
          current = ""
        }
        current.append(character)
        inString = true
        continue
      }

      if character.isWhitespace {
        if !current.isEmpty {
          tokens.append(current)
          current = ""
        }
        continue
      }

      if punctuation.contains(character) {
        if !current.isEmpty {
          tokens.append(current)
          current = ""
        }
        tokens.append(String(character))
        continue
      }

      current.append(character)
    }

    if !current.isEmpty {
      tokens.append(current)
    }

    return tokens
  }
}
