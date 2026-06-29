import SQLKit
import Vapor

/// `GET /api/v1/aggregates/by-ministry` and `GET /api/v1/aggregates/by-year`.
struct AggregateController: RouteCollection {
    let repository: any SalaryRepository

    init(repository: any SalaryRepository = PostgresSalaryRepository()) {
        self.repository = repository
    }

    func boot(routes: any RoutesBuilder) throws {
        let aggregates = routes.grouped("aggregates")
        aggregates.get("by-ministry", use: byMinistry)
        aggregates.get("by-year", use: byYear)
    }

    @Sendable
    func byMinistry(req: Request) async throws -> [AggregateGroupDTO] {
        let sql = try sqlDatabase(req)
        let year = req.query[Int.self, at: "year"]
        let groups = try await repository.aggregate(by: .ministry, year: year, on: sql)
        return groups.map(AggregateGroupDTO.init(result:))
    }

    @Sendable
    func byYear(req: Request) async throws -> [AggregateGroupDTO] {
        let sql = try sqlDatabase(req)
        let groups = try await repository.aggregate(by: .year, year: nil, on: sql)
        return groups.map(AggregateGroupDTO.init(result:))
    }

    private func sqlDatabase(_ req: Request) throws -> any SQLDatabase {
        guard let sql = req.db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "A SQL database is required.")
        }
        return sql
    }
}
