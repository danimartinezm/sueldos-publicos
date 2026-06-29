import Foundation
import SQLKit
import SalaryCore

/// SQL-based `SalaryRepository`. Stateless (hence `Sendable`); every method runs on the SQL
/// database/transaction passed in, so it composes inside Fluent transactions for atomicity.
struct PostgresSalaryRepository: SalaryRepository {
    func upsert(_ records: [SalaryRecord], on db: any SQLDatabase) async throws {
        let now = Date()
        for record in records {
            let query: SQLQueryString = """
                INSERT INTO salary_records
                    (id, position, body, ministry, remuneration, year, position_normalized,
                     created_at, updated_at)
                VALUES
                    (\(bind: record.id), \(bind: record.position), \(bind: record.body),
                     \(bind: record.ministry), \(bind: record.remuneration), \(bind: record.year),
                     \(bind: record.positionNormalized), \(bind: now), \(bind: now))
                ON CONFLICT (position, body, ministry, year)
                DO UPDATE SET
                    remuneration = EXCLUDED.remuneration,
                    position_normalized = EXCLUDED.position_normalized,
                    updated_at = EXCLUDED.updated_at
                """
            try await db.raw(query).run()
        }
    }

    func recordRun(
        summary: IngestionSummary, source: String, startedAt: Date, on db: any SQLDatabase
    ) async throws {
        let rejectionsJSON = String(
            decoding: try JSONEncoder().encode(summary.rejections), as: UTF8.self)
        let query: SQLQueryString = """
            INSERT INTO ingestion_runs
                (id, source, started_at, finished_at, rows_read, rows_imported, rows_rejected,
                 status, rejections)
            VALUES
                (\(bind: UUID()), \(bind: source), \(bind: startedAt), \(bind: Date()),
                 \(bind: summary.rowsRead), \(bind: summary.rowsImported),
                 \(bind: summary.rowsRejected), \(bind: "succeeded"), \(bind: rejectionsJSON))
            """
        try await db.raw(query).run()
    }

    func list(_ query: SalaryListQuery, on db: any SQLDatabase) async throws
        -> PagedResult<StoredSalary>
    {
        var items = db.select()
            .columns("id", "position", "body", "ministry", "remuneration", "year")
            .from("salary_records")
        items = applyFilters(query, to: items)
        items =
            items
            .orderBy("ministry")
            .orderBy("position")
            .limit(query.pageSize)
            .offset(query.offset)
        let rows = try await items.all(decoding: StoredSalary.self)

        var counter = db.select()
            .column(SQLFunction("COUNT", args: SQLLiteral.all), as: "count")
            .from("salary_records")
        counter = applyFilters(query, to: counter)
        let total = try await counter.first(decoding: CountRow.self)?.count ?? 0

        return PagedResult(items: rows, total: total)
    }

    func get(id: UUID, on db: any SQLDatabase) async throws -> StoredSalary? {
        try await db.select()
            .columns("id", "position", "body", "ministry", "remuneration", "year")
            .from("salary_records")
            .where("id", .equal, id)
            .first(decoding: StoredSalary.self)
    }

    func aggregate(by dimension: AggregateDimension, year: Int?, on db: any SQLDatabase)
        async throws
        -> [AggregateGroupResult]
    {
        let keyExpression: any SQLExpression
        let groupColumn: String
        switch dimension {
        case .ministry:
            keyExpression = SQLColumn("ministry")
            groupColumn = "ministry"
        case .year:
            keyExpression = SQLRaw("CAST(year AS TEXT)")
            groupColumn = "year"
        }

        var builder = db.select()
            .column(keyExpression, as: "key")
            .column(SQLFunction("COUNT", args: SQLLiteral.all), as: "count")
            .column(SQLFunction("SUM", args: SQLColumn("remuneration")), as: "total")
            .column(SQLFunction("AVG", args: SQLColumn("remuneration")), as: "average")
            .from("salary_records")
        if let year {
            builder = builder.where("year", .equal, year)
        }
        return
            try await builder
            .groupBy(groupColumn)
            .orderBy(groupColumn)
            .all(decoding: AggregateGroupResult.self)
    }

    // MARK: helpers

    private func applyFilters(_ query: SalaryListQuery, to builder: SQLSelectBuilder)
        -> SQLSelectBuilder
    {
        var builder = builder
        if let ministry = query.ministry {
            builder = builder.where("ministry", .equal, ministry)
        }
        if let body = query.body {
            builder = builder.where("body", .equal, body)
        }
        if let year = query.year {
            builder = builder.where("year", .equal, year)
        }
        if let q = query.q, !q.isEmpty {
            let term = "%\(SalaryRowParser.normalize(q))%"
            builder = builder.where("position_normalized", .like, term)
        }
        return builder
    }
}

private struct CountRow: Codable {
    var count: Int
}
