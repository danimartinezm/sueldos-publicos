import Foundation
import Vapor

/// Public representation of a salary record (omits internal fields per FR-015).
struct SalaryDTO: Content {
    let id: UUID
    let position: String
    let body: String
    let ministry: String
    let remuneration: Decimal
    let year: Int

    init(stored: StoredSalary) {
        self.id = stored.id
        self.position = stored.position
        self.body = stored.body
        self.ministry = stored.ministry
        self.remuneration = stored.remuneration
        self.year = stored.year
    }
}

/// A page of salary records with paging metadata.
struct SalaryPageDTO: Content {
    let items: [SalaryDTO]
    let page: Int
    let pageSize: Int
    let total: Int
}

/// One aggregate group in an aggregates response.
struct AggregateGroupDTO: Content {
    let key: String
    let count: Int
    let total: Decimal
    let average: Decimal

    init(result: AggregateGroupResult) {
        self.key = result.key
        self.count = result.count
        self.total = result.total
        self.average = result.average
    }
}
