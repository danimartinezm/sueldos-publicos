import Foundation

/// A single official's remuneration entry for a given year.
///
/// Pure value type with no persistence or transport concerns. `remuneration` is an exact
/// `Decimal` (never floating point) to protect monetary correctness.
public struct SalaryRecord: Sendable, Equatable {
    public var id: UUID
    public var position: String
    public var body: String
    public var ministry: String
    public var remuneration: Decimal
    public var year: Int
    /// Lowercased, accent-stripped `position` for case/accent-insensitive search.
    public var positionNormalized: String

    public init(
        id: UUID = UUID(),
        position: String,
        body: String,
        ministry: String,
        remuneration: Decimal,
        year: Int,
        positionNormalized: String
    ) {
        self.id = id
        self.position = position
        self.body = body
        self.ministry = ministry
        self.remuneration = remuneration
        self.year = year
        self.positionNormalized = positionNormalized
    }

    /// The natural key that uniquely identifies a salary line (used for idempotent ingestion).
    public var naturalKey: String { "\(position)|\(body)|\(ministry)|\(year)" }
}
