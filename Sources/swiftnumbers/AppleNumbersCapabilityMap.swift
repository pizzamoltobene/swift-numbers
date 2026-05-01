import ArgumentParser
import Foundation

struct RefreshAppleNumbersMapCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "refresh-apple-numbers-map",
    abstract: "Refresh the Apple Numbers AppleScript capability map."
  )

  @Option(name: .long, help: "Markdown output path.")
  var output: String = "docs/apple-numbers-applescript-capability-map.md"

  @Flag(name: .long, help: "Print the generated map instead of writing it.")
  var dryRun: Bool = false

  @Flag(
    name: .long,
    help: "Emit deterministic skipped oracle metadata without probing Numbers.app."
  )
  var skipOracle: Bool = false

  mutating func run() throws {
    let markdown = AppleNumbersCapabilityMapRefresher().refresh(skipOracle: skipOracle)

    if dryRun {
      print(markdown)
      return
    }

    let outputURL = URL(fileURLWithPath: output)
    let parent = outputURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
    try Data(markdown.utf8).write(to: outputURL, options: .atomic)
    print("Refreshed \(outputURL.path)")
  }
}

private struct AppleNumbersCapabilityMapRefresher {
  func refresh(skipOracle: Bool) -> String {
    if skipOracle {
      return renderSkippedMap(
        reason: "Skipped by --skip-oracle for deterministic CI/offline validation.",
        discoveryMethod: "skipped by --skip-oracle"
      )
    }

    guard let discovery = discoverNumbersApplication() else {
      return renderSkippedMap(
        reason:
          "Numbers.app was not discoverable through LaunchServices/AppleScript, or Automation permissions denied access.",
        discoveryMethod:
          "AppleScript LaunchServices: path to application id \"com.apple.Numbers\", then path to application \"Numbers\""
      )
    }

    let sdef = runAppleTool("/usr/bin/sdef", [discovery.path])
    let trimmedSDEF = sdef.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    guard sdef.terminationStatus == 0, !trimmedSDEF.isEmpty else {
      return renderSkippedMap(
        reason:
          "Numbers.app was discovered, but its scripting dictionary could not be read through sdef.",
        discoveryMethod: discovery.method,
        numbersPath: discovery.path
      )
    }

    let dictionary = SDEFDictionaryParser.parse(sdef.stdout)
    return renderAvailableMap(discovery: discovery, sdefXML: sdef.stdout, dictionary: dictionary)
  }

  private func discoverNumbersApplication() -> AppleNumbersDiscovery? {
    let probes = [
      (
        "AppleScript LaunchServices: path to application id \"com.apple.Numbers\"",
        "POSIX path of (path to application id \"com.apple.Numbers\")"
      ),
      (
        "AppleScript LaunchServices: path to application \"Numbers\"",
        "POSIX path of (path to application \"Numbers\")"
      ),
    ]

    for probe in probes {
      let result = runAppleTool("/usr/bin/osascript", ["-e", probe.1])
      let path = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
      if result.terminationStatus == 0, !path.isEmpty {
        return AppleNumbersDiscovery(method: probe.0, path: path)
      }
    }

    return nil
  }

  private func runAppleTool(_ executable: String, _ arguments: [String]) -> AppleToolResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    do {
      try process.run()
      process.waitUntilExit()
    } catch {
      return AppleToolResult(stdout: "", stderr: "\(error)", terminationStatus: 127)
    }

    let stdout =
      String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let stderr =
      String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

    return AppleToolResult(
      stdout: stdout,
      stderr: stderr,
      terminationStatus: process.terminationStatus
    )
  }

  private func renderSkippedMap(
    reason: String,
    discoveryMethod: String,
    numbersPath: String = "<unavailable>"
  ) -> String {
    renderMap(
      oracleStatus: "skipped",
      reason: reason,
      discoveryMethod: discoveryMethod,
      numbersPath: numbersPath,
      sdefStatus: "not-run",
      sdefByteCount: 0,
      dictionary: .empty
    )
  }

  private func renderAvailableMap(
    discovery: AppleNumbersDiscovery,
    sdefXML: String,
    dictionary: AppleNumbersSDEFDictionary
  ) -> String {
    renderMap(
      oracleStatus: "available",
      reason: "Numbers.app discovered through LaunchServices/AppleScript and sdef parsed.",
      discoveryMethod: discovery.method,
      numbersPath: normalizedApplicationLabel(discovery.path),
      sdefStatus: dictionary.parseSucceeded ? "parsed" : "read-unparsed",
      sdefByteCount: sdefXML.utf8.count,
      dictionary: dictionary
    )
  }

  private func renderMap(
    oracleStatus: String,
    reason: String,
    discoveryMethod: String,
    numbersPath: String,
    sdefStatus: String,
    sdefByteCount: Int,
    dictionary: AppleNumbersSDEFDictionary
  ) -> String {
    var lines: [String] = []
    lines.append("# Apple Numbers AppleScript Capability Map")
    lines.append("")
    lines.append("This file is generated by `swift run swiftnumbers refresh-apple-numbers-map`.")
    lines.append(
      "It is a planning oracle only; shipped SwiftNumbers library code does not depend on Numbers.app."
    )
    lines.append("")
    lines.append("## Snapshot Metadata")
    lines.append("")
    lines.append("- Oracle status: \(oracleStatus)")
    lines.append("- Reason: \(reason)")
    lines.append("- Discovery method: \(discoveryMethod)")
    lines.append("- Numbers application: \(numbersPath)")
    lines.append("- sdef status: \(sdefStatus)")
    lines.append("- sdef byte count: \(sdefByteCount)")
    lines.append("- Timestamp policy: omitted for deterministic diffs")
    lines.append("")
    lines.append("## Capability Summary")
    lines.append("")
    lines.append("| Area | AppleScript status | Evidence | SwiftNumbers planning target |")
    lines.append("|---|---|---|---|")

    for row in capabilityRows(from: dictionary, oracleStatus: oracleStatus) {
      lines.append(
        "| \(row.area) | \(row.status) | \(row.evidence) | \(row.planningTarget) |")
    }

    lines.append("")
    lines.append("## Read Semantics Probe Rows")
    lines.append("")
    lines.append(
      "These rows keep AppleScript/OSAScript read semantics visible to the roadmap conveyor."
    )
    lines.append(
      "They are generated from the local Numbers scripting dictionary or deterministic skipped metadata."
    )
    lines.append("")
    lines.append("| Probe | AppleScript status | Evidence | SwiftNumbers public surface |")
    lines.append("|---|---|---|---|")

    for row in readProbeRows(from: dictionary, oracleStatus: oracleStatus) {
      lines.append("| \(row.probe) | \(row.status) | \(row.evidence) | \(row.swiftSurface) |")
    }

    lines.append("")
    lines.append("## Mutation Semantics Probe Rows")
    lines.append("")
    lines.append(
      "These rows keep AppleScript/OSAScript document, sheet, table, row, and column mutation semantics visible to the roadmap conveyor."
    )
    lines.append(
      "They map Apple-visible write operations to SwiftNumbers supported APIs or safe-write backlog gaps."
    )
    lines.append("")
    lines.append("| Probe | AppleScript status | Evidence | SwiftNumbers parity target |")
    lines.append("|---|---|---|---|")

    for row in mutationProbeRows(from: dictionary, oracleStatus: oracleStatus) {
      lines.append("| \(row.probe) | \(row.status) | \(row.evidence) | \(row.swiftTarget) |")
    }

    lines.append("")
    lines.append("## Formula Semantics Probe Rows")
    lines.append("")
    lines.append(
      "These rows keep AppleScript/OSAScript formula text, result, range-reference, function-call, and write semantics visible to the roadmap conveyor."
    )
    lines.append(
      "They map Apple-visible formula operations to SwiftNumbers formula read APIs and guarded formula-write behavior."
    )
    lines.append("")
    lines.append("| Probe | AppleScript status | Evidence | SwiftNumbers parity target |")
    lines.append("|---|---|---|---|")

    for row in formulaProbeRows(from: dictionary, oracleStatus: oracleStatus) {
      lines.append("| \(row.probe) | \(row.status) | \(row.evidence) | \(row.swiftTarget) |")
    }

    lines.append("")
    lines.append("## Advanced Object Discovery Probe Rows")
    lines.append("")
    lines.append(
      "These rows keep AppleScript/OSAScript chart, pivot, style, media, shape, and text-object surfaces visible to the roadmap conveyor."
    )
    lines.append(
      "Each row classifies the current SwiftNumbers stance as supported, safe-read-only, safe-write-blocked, or unsupported."
    )
    lines.append("")
    lines.append(
      "| Probe | AppleScript status | Evidence | SwiftNumbers classification | SwiftNumbers parity target |"
    )
    lines.append("|---|---|---|---|---|")

    for row in advancedObjectProbeRows(from: dictionary, oracleStatus: oracleStatus) {
      lines.append(
        "| \(row.probe) | \(row.status) | \(row.evidence) | \(row.classification) | \(row.swiftTarget) |"
      )
    }

    lines.append("")
    lines.append("## Scripting Dictionary Inventory")
    lines.append("")
    lines.append("- Suites: \(dictionary.suites.count)")
    lines.append("- Commands: \(dictionary.commands.count)")
    lines.append("- Classes: \(dictionary.classes.count)")
    lines.append("- Enumerations: \(dictionary.enumerations.count)")
    lines.append("")
    lines.append("### Suites")
    lines.append("")
    appendList(dictionary.suites, to: &lines)
    lines.append("")
    lines.append("### Commands")
    lines.append("")
    appendList(dictionary.commands, to: &lines)
    lines.append("")
    lines.append("### Classes")
    lines.append("")

    if dictionary.classes.isEmpty {
      lines.append("- <none>")
    } else {
      for item in dictionary.classes {
        let properties = item.properties.isEmpty ? "-" : item.properties.joined(separator: ", ")
        let elements = item.elements.isEmpty ? "-" : item.elements.joined(separator: ", ")
        lines.append("- `\(item.name)` (suite: \(item.suite))")
        lines.append("  - properties: \(properties)")
        lines.append("  - elements: \(elements)")
      }
    }

    lines.append("")
    lines.append("## Refresh Commands")
    lines.append("")
    lines.append("```sh")
    lines.append("swift run swiftnumbers refresh-apple-numbers-map")
    lines.append("swift run swiftnumbers refresh-apple-numbers-map --dry-run")
    lines.append("swift run swiftnumbers refresh-apple-numbers-map --skip-oracle --dry-run")
    lines.append("```")
    lines.append("")

    return lines.joined(separator: "\n")
  }

  private func appendList(_ values: [String], to lines: inout [String]) {
    if values.isEmpty {
      lines.append("- <none>")
      return
    }
    for value in values {
      lines.append("- `\(value)`")
    }
  }

  private func normalizedApplicationLabel(_ path: String) -> String {
    let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return "<available>"
    }

    return "com.apple.Numbers (LaunchServices-discovered path redacted for deterministic diffs)"
  }

  private func capabilityRows(
    from dictionary: AppleNumbersSDEFDictionary,
    oracleStatus: String
  ) -> [AppleNumbersCapabilityRow] {
    let definitions = [
      AppleNumbersCapabilityDefinition(
        area: "document-lifecycle",
        terms: ["document", "open", "close", "save", "export", "print"],
        planningTarget: "Open/save/export parity and deterministic document metadata."
      ),
      AppleNumbersCapabilityDefinition(
        area: "sheet-read",
        terms: ["sheet", "sheets"],
        planningTarget: "Sheet names, IDs, ordering, and lookup behavior."
      ),
      AppleNumbersCapabilityDefinition(
        area: "table-read",
        terms: ["table", "tables"],
        planningTarget: "Table names, IDs, dimensions, summaries, and selection semantics."
      ),
      AppleNumbersCapabilityDefinition(
        area: "cell-range-read",
        terms: ["cell", "range", "row", "column", "value"],
        planningTarget: "Cell/range/row/column read semantics and typed value parity."
      ),
      AppleNumbersCapabilityDefinition(
        area: "mutation",
        terms: ["make", "delete", "duplicate", "move", "row", "column", "table"],
        planningTarget: "Safe sheet/table/row/column mutation behavior."
      ),
      AppleNumbersCapabilityDefinition(
        area: "formula",
        terms: ["formula", "formula result", "function"],
        planningTarget: "Formula text/result read behavior and guarded formula writes."
      ),
      AppleNumbersCapabilityDefinition(
        area: "formatting-style",
        terms: ["format", "style", "font", "alignment", "color", "background"],
        planningTarget: "Formatting, style, rich text, and display-value parity."
      ),
      AppleNumbersCapabilityDefinition(
        area: "chart",
        terms: ["chart", "series"],
        planningTarget: "Chart object discovery and safe read-only diagnostics."
      ),
      AppleNumbersCapabilityDefinition(
        area: "pivot",
        terms: ["pivot"],
        planningTarget: "Pivot object discovery, diagnostics, and safe write blocking."
      ),
      AppleNumbersCapabilityDefinition(
        area: "media-shape",
        terms: ["image", "movie", "audio", "shape", "graphic", "line"],
        planningTarget: "Media/shape object inventory and unsupported-object diagnostics."
      ),
    ]

    let terms = dictionary.normalizedTerms
    return definitions.map { definition in
      guard oracleStatus != "skipped" else {
        return AppleNumbersCapabilityRow(
          area: definition.area,
          status: "skipped",
          evidence: "<not-probed>",
          planningTarget: definition.planningTarget
        )
      }

      let evidence = definition.terms.filter { term in
        terms.contains { candidate in candidate.contains(term) }
      }
      return AppleNumbersCapabilityRow(
        area: definition.area,
        status: evidence.isEmpty ? "missing" : "available",
        evidence: evidence.isEmpty ? "<none>" : evidence.map { "`\($0)`" }.joined(separator: ", "),
        planningTarget: definition.planningTarget
      )
    }
  }

  private func readProbeRows(
    from dictionary: AppleNumbersSDEFDictionary,
    oracleStatus: String
  ) -> [AppleNumbersReadProbeRow] {
    let definitions = [
      AppleNumbersReadProbeDefinition(
        probe: "sheet-list-read",
        requirements: [
          .class("sheet"),
          .property(className: "sheet", property: "name"),
        ],
        swiftSurface: "`NumbersDocument.sheetSummaries(at:)`, `swiftnumbers list-sheets`"
      ),
      AppleNumbersReadProbeDefinition(
        probe: "table-list-read",
        requirements: [
          .class("table"),
          .property(className: "table", property: "name"),
          .property(className: "table", property: "row count"),
          .property(className: "table", property: "column count"),
        ],
        swiftSurface: "`NumbersDocument.tableSummaries(at:)`, `swiftnumbers list-tables`"
      ),
      AppleNumbersReadProbeDefinition(
        probe: "range-read",
        requirements: [
          .class("range"),
          .element(className: "range", element: "cell"),
          .element(className: "range", element: "row"),
          .element(className: "range", element: "column"),
        ],
        swiftSurface: "`NumbersDocument.readRange(...)`, `swiftnumbers read-range`"
      ),
      AppleNumbersReadProbeDefinition(
        probe: "row-read",
        requirements: [
          .class("row"),
          .property(className: "row", property: "address"),
          .property(className: "row", property: "height"),
        ],
        swiftSurface: "`TableModel.readCells(in:)`, `swiftnumbers read-range` row slices"
      ),
      AppleNumbersReadProbeDefinition(
        probe: "column-read",
        requirements: [
          .class("column"),
          .property(className: "column", property: "address"),
          .property(className: "column", property: "width"),
        ],
        swiftSurface: "`TableModel.readCells(in:)`, `swiftnumbers read-column`"
      ),
      AppleNumbersReadProbeDefinition(
        probe: "cell-value-read",
        requirements: [
          .class("cell"),
          .property(className: "cell", property: "value"),
          .property(className: "cell", property: "formatted value"),
        ],
        swiftSurface: "`NumbersDocument.readCell(...)`, `swiftnumbers read-cell`"
      ),
      AppleNumbersReadProbeDefinition(
        probe: "table-selection-range-read",
        requirements: [
          .class("table"),
          .property(className: "table", property: "selection range"),
          .property(className: "table", property: "cell range"),
        ],
        swiftSurface: "`TableModel.usedRange`, table/range diagnostics"
      ),
    ]

    return definitions.map { definition in
      guard oracleStatus != "skipped" else {
        return AppleNumbersReadProbeRow(
          probe: definition.probe,
          status: "skipped",
          evidence: "<not-probed>",
          swiftSurface: definition.swiftSurface
        )
      }

      let missing = definition.requirements.filter { !dictionary.satisfies($0) }
      return AppleNumbersReadProbeRow(
        probe: definition.probe,
        status: missing.isEmpty ? "available" : "missing",
        evidence: missing.isEmpty
          ? definition.requirements.map { "`\($0.evidence)`" }.joined(separator: ", ")
          : missing.map { "missing `\($0.evidence)`" }.joined(separator: ", "),
        swiftSurface: definition.swiftSurface
      )
    }
  }

  private func mutationProbeRows(
    from dictionary: AppleNumbersSDEFDictionary,
    oracleStatus: String
  ) -> [AppleNumbersMutationProbeRow] {
    let definitions = [
      AppleNumbersMutationProbeDefinition(
        probe: "document-export-operation",
        requirements: [
          .command("export")
        ],
        swiftTarget:
          "safe export is CLI-level (`export-csv`); native document export remains a roadmap gap"
      ),
      AppleNumbersMutationProbeDefinition(
        probe: "sheet-create-delete-operation",
        requirements: [
          .command("make"),
          .command("delete"),
          .class("sheet"),
        ],
        swiftTarget:
          "`EditableNumbersDocument.addSheet`; sheet delete/rename parity remains a backlog gap"
      ),
      AppleNumbersMutationProbeDefinition(
        probe: "table-create-delete-operation",
        requirements: [
          .command("make"),
          .command("delete"),
          .class("table"),
        ],
        swiftTarget: "`EditableSheet.addTable`; table delete/duplicate parity remains a backlog gap"
      ),
      AppleNumbersMutationProbeDefinition(
        probe: "row-mutation-operation",
        requirements: [
          .command("add row above"),
          .command("add row below"),
          .command("delete"),
          .class("row"),
        ],
        swiftTarget: "`appendRow`, `insertRow`, `deleteRow` with grouped/pivot-linked safety guards"
      ),
      AppleNumbersMutationProbeDefinition(
        probe: "column-mutation-operation",
        requirements: [
          .command("add column before"),
          .command("add column after"),
          .command("delete"),
          .class("column"),
        ],
        swiftTarget: "`appendColumn`, `deleteColumn`; "
          + "`insertColumn` has a deterministic unsupported guard until native column shifting lands"
      ),
      AppleNumbersMutationProbeDefinition(
        probe: "cell-range-clear-set-operation",
        requirements: [
          .command("clear"),
          .command("set"),
          .class("cell"),
          .class("range"),
        ],
        swiftTarget: "`setValue`, `clearValue`, `clearValues`; "
          + "range fill parity remains a safe-write backlog gap"
      ),
      AppleNumbersMutationProbeDefinition(
        probe: "table-structure-transform-operation",
        requirements: [
          .command("merge"),
          .command("unmerge"),
          .command("sort"),
          .command("transpose"),
        ],
        swiftTarget: "`mergeCells`, `unmergeCells`; sort/transpose parity remains a backlog gap"
      ),
    ]

    return definitions.map { definition in
      guard oracleStatus != "skipped" else {
        return AppleNumbersMutationProbeRow(
          probe: definition.probe,
          status: "skipped",
          evidence: "<not-probed>",
          swiftTarget: definition.swiftTarget
        )
      }

      let missing = definition.requirements.filter { !dictionary.satisfies($0) }
      return AppleNumbersMutationProbeRow(
        probe: definition.probe,
        status: missing.isEmpty ? "available" : "missing",
        evidence: missing.isEmpty
          ? definition.requirements.map { "`\($0.evidence)`" }.joined(separator: ", ")
          : missing.map { "missing `\($0.evidence)`" }.joined(separator: ", "),
        swiftTarget: definition.swiftTarget
      )
    }
  }

  private func formulaProbeRows(
    from dictionary: AppleNumbersSDEFDictionary,
    oracleStatus: String
  ) -> [AppleNumbersFormulaProbeRow] {
    let definitions = [
      AppleNumbersFormulaProbeDefinition(
        probe: "formula-text-read",
        requirements: [
          .class("cell"),
          .property(className: "cell", property: "formula"),
        ],
        swiftTarget:
          "`TableModel.formula(...)`, `TableModel.formulas()`, `swiftnumbers list-formulas`"
      ),
      AppleNumbersFormulaProbeDefinition(
        probe: "formula-result-read",
        requirements: [
          .class("cell"),
          .property(className: "cell", property: "formula"),
          .property(className: "cell", property: "value"),
          .property(className: "cell", property: "formatted value"),
        ],
        swiftTarget:
          "`TableModel.formulaResult(...)`, `NumbersDocument.readCell(...)` formula result payloads"
      ),
      AppleNumbersFormulaProbeDefinition(
        probe: "formula-range-reference-read",
        requirements: [
          .property(className: "cell", property: "formula"),
          .class("range"),
          .element(className: "range", element: "cell"),
        ],
        swiftTarget: "formula AST/range-reference rendering and `--formulas` parity output"
      ),
      AppleNumbersFormulaProbeDefinition(
        probe: "formula-function-call-read",
        requirements: [
          .property(className: "cell", property: "formula"),
          .class("table"),
          .element(className: "table", element: "cell"),
        ],
        swiftTarget: "formula AST function-call rendering with deterministic fallback summaries"
      ),
      AppleNumbersFormulaProbeDefinition(
        probe: "formula-set-operation",
        requirements: [
          .command("set"),
          .class("cell"),
          .property(className: "cell", property: "formula"),
        ],
        swiftTarget: "`EditableTable.setValue(.formula(...))` with strict unsafe-reference guards"
      ),
      AppleNumbersFormulaProbeDefinition(
        probe: "formula-clear-operation",
        requirements: [
          .command("clear"),
          .class("cell"),
          .property(className: "cell", property: "formula"),
        ],
        swiftTarget:
          "formula clear is covered by `clearValue`/`clearValues`; richer formula write parity remains a backlog gap"
      ),
    ]

    return definitions.map { definition in
      guard oracleStatus != "skipped" else {
        return AppleNumbersFormulaProbeRow(
          probe: definition.probe,
          status: "skipped",
          evidence: "<not-probed>",
          swiftTarget: definition.swiftTarget
        )
      }

      let missing = definition.requirements.filter { !dictionary.satisfies($0) }
      return AppleNumbersFormulaProbeRow(
        probe: definition.probe,
        status: missing.isEmpty ? "available" : "missing",
        evidence: missing.isEmpty
          ? definition.requirements.map { "`\($0.evidence)`" }.joined(separator: ", ")
          : missing.map { "missing `\($0.evidence)`" }.joined(separator: ", "),
        swiftTarget: definition.swiftTarget
      )
    }
  }

  private func advancedObjectProbeRows(
    from dictionary: AppleNumbersSDEFDictionary,
    oracleStatus: String
  ) -> [AppleNumbersAdvancedObjectProbeRow] {
    let definitions = [
      AppleNumbersAdvancedObjectProbeDefinition(
        probe: "chart-object-discovery",
        requirements: [
          .class("chart")
        ],
        classification: "safe-read-only",
        swiftTarget:
          "chart inventory and read-only diagnostics; native chart writes remain unsupported"
      ),
      AppleNumbersAdvancedObjectProbeDefinition(
        probe: "pivot-object-discovery",
        requirements: [
          .class("pivot")
        ],
        classification: "safe-write-blocked",
        swiftTarget:
          "pivot-like object diagnostics and write blocking for linked analytical drawables"
      ),
      AppleNumbersAdvancedObjectProbeDefinition(
        probe: "range-formatting-style-discovery",
        requirements: [
          .class("range"),
          .property(className: "range", property: "format"),
          .property(className: "range", property: "font name"),
          .property(className: "range", property: "font size"),
          .property(className: "range", property: "background color"),
          .property(className: "range", property: "text color"),
          .property(className: "range", property: "alignment"),
          .property(className: "range", property: "vertical alignment"),
        ],
        classification: "safe-read-only",
        swiftTarget: "`ReadCell.style`, `ReadCell.formatted`, `formattedValue(...)`, "
          + "CLI `--formatting`; richer write parity remains guarded"
      ),
      AppleNumbersAdvancedObjectProbeDefinition(
        probe: "media-object-discovery",
        requirements: [
          .class("image"),
          .class("movie"),
          .class("audio clip"),
        ],
        classification: "safe-read-only",
        swiftTarget: "media object inventory with unsupported-object diagnostics"
      ),
      AppleNumbersAdvancedObjectProbeDefinition(
        probe: "shape-line-text-object-discovery",
        requirements: [
          .class("shape"),
          .class("line"),
          .class("text item"),
        ],
        classification: "safe-read-only",
        swiftTarget: "shape/line/text object inventory and no unsafe native mutation support"
      ),
      AppleNumbersAdvancedObjectProbeDefinition(
        probe: "rich-text-style-discovery",
        requirements: [
          .class("rich text"),
          .property(className: "rich text", property: "color"),
          .property(className: "rich text", property: "font"),
          .property(className: "rich text", property: "size"),
        ],
        classification: "safe-read-only",
        swiftTarget: "`ReadCell.richText`, `ReadCell.style`, `formattedValue(...)`; "
          + "richer rich-text writes remain a backlog gap"
      ),
    ]

    return definitions.map { definition in
      guard oracleStatus != "skipped" else {
        return AppleNumbersAdvancedObjectProbeRow(
          probe: definition.probe,
          status: "skipped",
          evidence: "<not-probed>",
          classification: definition.classification,
          swiftTarget: definition.swiftTarget
        )
      }

      let missing = definition.requirements.filter { !dictionary.satisfies($0) }
      return AppleNumbersAdvancedObjectProbeRow(
        probe: definition.probe,
        status: missing.isEmpty ? "available" : "missing",
        evidence: missing.isEmpty
          ? definition.requirements.map { "`\($0.evidence)`" }.joined(separator: ", ")
          : missing.map { "missing `\($0.evidence)`" }.joined(separator: ", "),
        classification: definition.classification,
        swiftTarget: definition.swiftTarget
      )
    }
  }
}

private struct AppleToolResult {
  let stdout: String
  let stderr: String
  let terminationStatus: Int32
}

private struct AppleNumbersDiscovery {
  let method: String
  let path: String
}

private struct AppleNumbersCapabilityDefinition {
  let area: String
  let terms: [String]
  let planningTarget: String
}

private struct AppleNumbersCapabilityRow {
  let area: String
  let status: String
  let evidence: String
  let planningTarget: String
}

private struct AppleNumbersReadProbeDefinition {
  let probe: String
  let requirements: [AppleNumbersSDEFRequirement]
  let swiftSurface: String
}

private struct AppleNumbersMutationProbeDefinition {
  let probe: String
  let requirements: [AppleNumbersSDEFRequirement]
  let swiftTarget: String
}

private struct AppleNumbersFormulaProbeDefinition {
  let probe: String
  let requirements: [AppleNumbersSDEFRequirement]
  let swiftTarget: String
}

private struct AppleNumbersAdvancedObjectProbeDefinition {
  let probe: String
  let requirements: [AppleNumbersSDEFRequirement]
  let classification: String
  let swiftTarget: String
}

private enum AppleNumbersSDEFRequirement {
  case command(String)
  case `class`(String)
  case property(className: String, property: String)
  case element(className: String, element: String)

  var evidence: String {
    switch self {
    case .command(let name):
      return name
    case .class(let name):
      return name
    case .property(let className, let property):
      return "\(className).\(property)"
    case .element(let className, let element):
      return "\(className).\(element)"
    }
  }
}

private struct AppleNumbersReadProbeRow {
  let probe: String
  let status: String
  let evidence: String
  let swiftSurface: String
}

private struct AppleNumbersMutationProbeRow {
  let probe: String
  let status: String
  let evidence: String
  let swiftTarget: String
}

private struct AppleNumbersFormulaProbeRow {
  let probe: String
  let status: String
  let evidence: String
  let swiftTarget: String
}

private struct AppleNumbersAdvancedObjectProbeRow {
  let probe: String
  let status: String
  let evidence: String
  let classification: String
  let swiftTarget: String
}

private struct AppleNumbersSDEFDictionary {
  var parseSucceeded: Bool
  var suites: [String]
  var commands: [String]
  var classes: [AppleNumbersSDEFClass]
  var enumerations: [String]

  static let empty = AppleNumbersSDEFDictionary(
    parseSucceeded: false,
    suites: [],
    commands: [],
    classes: [],
    enumerations: []
  )

  var normalizedTerms: [String] {
    var terms = Set<String>()
    for suite in suites {
      terms.insert(suite.lowercased())
    }
    for command in commands {
      terms.insert(command.lowercased())
    }
    for item in classes {
      terms.insert(item.name.lowercased())
      for property in item.properties {
        terms.insert(property.lowercased())
      }
      for element in item.elements {
        terms.insert(element.lowercased())
      }
    }
    for enumeration in enumerations {
      terms.insert(enumeration.lowercased())
    }
    return terms.sorted()
  }

  func satisfies(_ requirement: AppleNumbersSDEFRequirement) -> Bool {
    switch requirement {
    case .command(let name):
      return commands.contains(name)
    case .class(let name):
      return classNamed(name) != nil
    case .property(let className, let property):
      return classNamed(className)?.properties.contains(property) == true
    case .element(let className, let element):
      return classNamed(className)?.elements.contains(element) == true
    }
  }

  private func classNamed(_ name: String) -> AppleNumbersSDEFClass? {
    classes.first { $0.name == name }
  }
}

private struct AppleNumbersSDEFClass {
  var suite: String
  var name: String
  var properties: [String]
  var elements: [String]
}

private final class SDEFDictionaryParser: NSObject, XMLParserDelegate {
  private var currentSuite: String?
  private var classStack: [Int] = []
  private var dictionary = AppleNumbersSDEFDictionary.empty

  static func parse(_ xml: String) -> AppleNumbersSDEFDictionary {
    guard let data = xml.data(using: .utf8) else {
      return .empty
    }

    let delegate = SDEFDictionaryParser()
    let parser = XMLParser(data: data)
    parser.delegate = delegate
    let succeeded = parser.parse()
    var dictionary = delegate.dictionary
    dictionary.parseSucceeded = succeeded
    dictionary.suites = sortedUnique(dictionary.suites)
    dictionary.commands = sortedUnique(dictionary.commands)
    dictionary.enumerations = sortedUnique(dictionary.enumerations)
    dictionary.classes = dictionary.classes
      .map { item in
        AppleNumbersSDEFClass(
          suite: item.suite,
          name: item.name,
          properties: sortedUnique(item.properties),
          elements: sortedUnique(item.elements)
        )
      }
      .sorted {
        if $0.suite != $1.suite {
          return $0.suite < $1.suite
        }
        return $0.name < $1.name
      }
    return dictionary
  }

  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
    attributes attributeDict: [String: String] = [:]
  ) {
    switch elementName {
    case "suite":
      currentSuite = attributeDict["name"] ?? "<unknown>"
      if let currentSuite {
        dictionary.suites.append(currentSuite)
      }
    case "command":
      if let name = attributeDict["name"] {
        dictionary.commands.append(name)
      }
    case "class":
      let item = AppleNumbersSDEFClass(
        suite: currentSuite ?? "<unknown>",
        name: attributeDict["name"] ?? "<anonymous>",
        properties: [],
        elements: []
      )
      dictionary.classes.append(item)
      classStack.append(dictionary.classes.count - 1)
    case "property":
      guard let index = classStack.last, let name = attributeDict["name"] else {
        return
      }
      dictionary.classes[index].properties.append(name)
    case "element":
      guard let index = classStack.last, let type = attributeDict["type"] else {
        return
      }
      dictionary.classes[index].elements.append(type)
    case "enumeration":
      if let name = attributeDict["name"] {
        dictionary.enumerations.append(name)
      }
    default:
      break
    }
  }

  func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    if elementName == "class" {
      _ = classStack.popLast()
    } else if elementName == "suite" {
      currentSuite = nil
    }
  }
}

private func sortedUnique(_ values: [String]) -> [String] {
  Array(Set(values)).sorted()
}
