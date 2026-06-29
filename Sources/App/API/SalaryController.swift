import Foundation
import SQLKit
import Vapor

/// `GET /api/v1/salaries` (paged list + filters + search) and `GET /api/v1/salaries/:id`.
struct SalaryController: RouteCollection {
    let repository: any SalaryRepository

    init(repository: any SalaryRepository = PostgresSalaryRepository()) {
        self.repository = repository
    }

    func boot(routes: any RoutesBuilder) throws {
        let salaries = routes.grouped("salaries")
        salaries.get(use: list)
        salaries.get(":id", use: get)
    }

    @Sendable
    func list(req: Request) async throws -> SalaryPageDTO {
        let page = try resolvePage(req.query[Int.self, at: "page"])
        let pageSize = try resolvePageSize(req.query[Int.self, at: "pageSize"])

        let query = SalaryListQuery(
            page: page,
            pageSize: pageSize,
            ministry: req.query[String.self, at: "ministry"],
            body: req.query[String.self, at: "body"],
            year: req.query[Int.self, at: "year"],
            q: req.query[String.self, at: "q"]
        )

        let sql = try sqlDatabase(req)
        let result = try await repository.list(query, on: sql)
        return SalaryPageDTO(
            items: result.items.map(SalaryDTO.init(stored:)),
            page: page,
            pageSize: pageSize,
            total: result.total
        )
    }

    @Sendable
    func get(req: Request) async throws -> SalaryDTO {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "The id must be a valid UUID.")
        }
        let sql = try sqlDatabase(req)
        guard let stored = try await repository.get(id: id, on: sql) else {
            throw Abort(.notFound, reason: "No salary record exists with that id.")
        }
        return SalaryDTO(stored: stored)
    }

    // MARK: helpers

    private func resolvePage(_ value: Int?) throws -> Int {
        guard let value else { return 1 }
        guard value >= 1 else { throw Abort(.badRequest, reason: "page must be 1 or greater.") }
        return value
    }

    private func resolvePageSize(_ value: Int?) throws -> Int {
        guard let value else { return 50 }
        guard (1...200).contains(value) else {
            throw Abort(.badRequest, reason: "pageSize must be between 1 and 200.")
        }
        return value
    }

    private func sqlDatabase(_ req: Request) throws -> any SQLDatabase {
        guard let sql = req.db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "A SQL database is required.")
        }
        return sql
    }
}
