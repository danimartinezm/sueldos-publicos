import Foundation
import SalaryCore
import Vapor

/// `swift run App ingest --file Retribuciones.xlsx` — administrator action that loads the
/// salary spreadsheet into the database and prints a summary.
struct IngestCommand: AsyncCommand {
    struct Signature: CommandSignature {
        @Option(name: "file", short: "f", help: "Path to the XLSX file to ingest.")
        var file: String?

        init() {}
    }

    var help: String { "Ingest a salary XLSX file into the database." }

    func run(using context: CommandContext, signature: Signature) async throws {
        let path = signature.file ?? "Retribuciones.xlsx"
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw Abort(.badRequest, reason: "Input file not found at \(path)")
        }

        let data = try Data(contentsOf: url)
        let service = IngestionService()
        let summary = try await service.ingest(
            data: data, source: url.lastPathComponent, on: context.application.db)

        context.console.print(
            "Rows read: \(summary.rowsRead)  "
                + "Imported: \(summary.rowsImported)  "
                + "Rejected: \(summary.rowsRejected)")
        for rejection in summary.rejections.prefix(50) {
            context.console.print("  row \(rejection.rowNumber): \(rejection.reason)")
        }
        if summary.rejections.count > 50 {
            context.console.print("  … and \(summary.rejections.count - 50) more")
        }
    }
}
