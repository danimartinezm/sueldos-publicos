import Foundation
import SQLKit
import SalaryCore

/// A salary record as read back from storage for API responses.
struct StoredSalary: Codable, Sendable {
    var id: UUID
    var position: String
    var body: String
    var ministry: String
    var remuneration: Decimal
    var year: Int
}

/// A page of results plus the total matching count.
struct PagedResult<Item: Sendable>: Sendable {
    var items: [Item]
    var total: Int
}

/// Validated list/filter/search parameters.
struct SalaryListQuery: Sendable {
    var page: Int
    var pageSize: Int
    var ministry: String?
    var body: String?
    var year: Int?
    var q: String?

    var offset: Int { (page - 1) * pageSize }
}

/// The dimension to group aggregates by.
enum AggregateDimension: Sendable {
    case ministry
    case year
}

/// One aggregate group (count / total / average remuneration).
struct AggregateGroupResult: Codable, Sendable {
    var key: String
    var count: Int
    var total: Decimal
    var average: Decimal
}

/// Persistence boundary for salary data. Kept abstract so the storage engine stays swappable
/// (Constitution Principle V). Methods take the SQL database/transaction to run on.
protocol SalaryRepository: Sendable {
    /// Idempotently insert or update records by their natural key.
    func upsert(_ records: [SalaryRecord], on db: any SQLDatabase) async throws

    /// Record one ingestion run for audit.
    func recordRun(
        summary: IngestionSummary, source: String, startedAt: Date, on db: any SQLDatabase
    ) async throws

    func list(_ query: SalaryListQuery, on db: any SQLDatabase) async throws
        -> PagedResult<StoredSalary>

    func get(id: UUID, on db: any SQLDatabase) async throws -> StoredSalary?

    func aggregate(by dimension: AggregateDimension, year: Int?, on db: any SQLDatabase)
        async throws
        -> [AggregateGroupResult]
}
