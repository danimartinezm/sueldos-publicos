import Vapor

/// Mounts the read-only API under `/api/v1`.
func routes(_ app: Application) throws {
    let api = app.grouped("api", "v1")
    try api.register(collection: SalaryController())
    try api.register(collection: AggregateController())
}
