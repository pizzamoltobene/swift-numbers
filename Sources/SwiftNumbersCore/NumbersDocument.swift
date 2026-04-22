import Foundation
import SwiftNumbersContainer
import SwiftNumbersIWA
import SwiftNumbersProto

public enum NumbersDocumentError: LocalizedError {
    case metadataMissing

    public var errorDescription: String? {
        switch self {
        case .metadataMissing:
            return "Document metadata is missing (expected Metadata/DocumentMetadata.pb or .json)."
        }
    }
}

public struct NumbersDocument: Sendable {
    public let sourceURL: URL
    public let sheets: [Sheet]

    private let dumpInfo: DocumentDump

    private init(sourceURL: URL, sheets: [Sheet], dumpInfo: DocumentDump) {
        self.sourceURL = sourceURL
        self.sheets = sheets
        self.dumpInfo = dumpInfo
    }

    public static func open(at url: URL) throws -> NumbersDocument {
        let container = try NumbersContainer.open(at: url)
        let blobs = try container.loadIndexBlobs()
        let inventory = try IWAInventoryBuilder.build(from: blobs)

        let metadata = try MetadataLoader.loadDocumentMetadata(from: container)
        let sheets: [Sheet]
        if let metadata {
            sheets = metadata.sheets.map { sheet in
                let tables = sheet.tables.map { table in
                    let ranges = table.merges.map { merge in
                        MergeRange(
                            startRow: Int(merge.startRow),
                            endRow: Int(merge.endRow),
                            startColumn: Int(merge.startColumn),
                            endColumn: Int(merge.endColumn)
                        )
                    }

                    return Table(
                        id: table.tableID,
                        name: table.name,
                        metadata: TableMetadata(
                            rowCount: Int(table.rowCount),
                            columnCount: Int(table.columnCount),
                            mergeRanges: ranges
                        )
                    )
                }

                return Sheet(
                    id: sheet.sheetID,
                    name: sheet.name,
                    tables: tables
                )
            }
        } else {
            sheets = []
        }

        let dump = DocumentDump(
            sourcePath: url.path,
            blobCount: blobs.count,
            objectCount: inventory.records.count,
            typeHistogram: inventory.typeHistogram,
            unparsedBlobPaths: inventory.unparsedBlobPaths
        )

        return NumbersDocument(sourceURL: url, sheets: sheets, dumpInfo: dump)
    }

    public func dump() -> DocumentDump {
        dumpInfo
    }

    public func renderDump() -> String {
        var lines: [String] = []
        lines.append("Source: \(dumpInfo.sourcePath)")
        lines.append("Sheets: \(sheets.count)")
        lines.append("Tables: \(sheets.reduce(0) { $0 + $1.tables.count })")
        lines.append("Index blobs: \(dumpInfo.blobCount)")
        lines.append("IWA objects: \(dumpInfo.objectCount)")

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

        return lines.joined(separator: "\n")
    }
}
