import Fluent

/// Creates the `ingestion_runs` audit table.
struct CreateIngestionRun: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("ingestion_runs")
            .id()
            .field("source", .string, .required)
            .field("started_at", .datetime, .required)
            .field("finished_at", .datetime)
            .field("rows_read", .int, .required)
            .field("rows_imported", .int, .required)
            .field("rows_rejected", .int, .required)
            .field("status", .string, .required)
            .field("rejections", .string, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("ingestion_runs").delete()
    }
}
