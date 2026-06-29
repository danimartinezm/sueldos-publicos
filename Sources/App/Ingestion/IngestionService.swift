import Fluent
import Foundation
import SQLKit
import SalaryCore
import Vapor

/// Orchestrates a full ingestion: read the workbook, validate/parse every row, then persist
/// records and the audit run inside a single transaction so a failure leaves no partial data
/// visible (FR-007 / SC-007), and re-runs stay idempotent (FR-005 / SC-003).
struct IngestionService: Sendable {
    let repository: any SalaryRepository

    init(repository: any SalaryRepository = PostgresSalaryRepository()) {
        self.repository = repository
    }

    func ingest(data: Data, source: String, on database: any Database) async throws
        -> IngestionSummary
    {
        let startedAt = Date()
        let workbook = try XLSXWorkbook(data: data)
        let parser = SalaryRowParser()

        var records: [SalaryRecord] = []
        var rejections: [RowRejection] = []
        for row in workbook.dataRows {
            switch parser.parse(row) {
            case .success(let record):
                records.append(record)
            case .failure(let rejection):
                rejections.append(rejection)
            }
        }

        let summary = IngestionSummary(
            rowsRead: workbook.dataRows.count,
            rowsImported: records.count,
            rejections: rejections
        )

        // Bind to immutable values so the @Sendable transaction closure can capture them.
        let recordsToInsert = records
        let runSummary = summary
        let repository = self.repository

        try await database.transaction { transaction in
            guard let sql = transaction as? any SQLDatabase else {
                throw Abort(
                    .internalServerError, reason: "A SQL database is required for ingestion.")
            }
            try await repository.upsert(recordsToInsert, on: sql)
            try await repository.recordRun(
                summary: runSummary, source: source, startedAt: startedAt, on: sql)
        }

        return summary
    }
}
