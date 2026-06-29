import Fluent
import SQLKit

/// Creates the `salary_records` table with the natural-key unique constraint and the indexes
/// that back filtering and search (per data-model.md / Constitution Principle IV).
struct CreateSalaryRecord: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("salary_records")
            .id()
            .field("position", .string, .required)
            .field("body", .string, .required)
            .field("ministry", .string, .required)
            .field("remuneration", .custom("NUMERIC(14,2)"), .required)
            .field("year", .int, .required)
            .field("position_normalized", .string, .required)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .unique(on: "position", "body", "ministry", "year")
            .create()

        if let sql = database as? any SQLDatabase {
            try await sql.raw(
                "CREATE INDEX IF NOT EXISTS idx_salary_ministry ON salary_records (ministry)"
            ).run()
            try await sql.raw(
                "CREATE INDEX IF NOT EXISTS idx_salary_body ON salary_records (body)"
            ).run()
            try await sql.raw(
                "CREATE INDEX IF NOT EXISTS idx_salary_year ON salary_records (year)"
            ).run()
            try await sql.raw(
                "CREATE INDEX IF NOT EXISTS idx_salary_posnorm ON salary_records (position_normalized)"
            ).run()
        }
    }

    func revert(on database: any Database) async throws {
        try await database.schema("salary_records").delete()
    }
}
