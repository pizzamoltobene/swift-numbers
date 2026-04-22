import ArgumentParser
import Foundation
import SwiftNumbersCore

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

    mutating func run() throws {
        let url = URL(fileURLWithPath: file)
        let document = try NumbersDocument.open(at: url)
        print(document.renderDump())
    }
}

struct ListSheets: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-sheets",
        abstract: "Prints all sheet names."
    )

    @Argument(help: "Path to a .numbers package")
    var file: String

    mutating func run() throws {
        let url = URL(fileURLWithPath: file)
        let document = try NumbersDocument.open(at: url)
        for (index, sheet) in document.sheets.enumerated() {
            print("\(index + 1). \(sheet.name)")
        }
    }
}
