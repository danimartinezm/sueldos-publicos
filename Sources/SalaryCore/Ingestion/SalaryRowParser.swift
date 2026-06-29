import Foundation

/// Pure mapping of a worksheet data row to a validated `SalaryRecord` or a `RowRejection`.
///
/// No I/O and no shared state, so it is trivially unit-testable first (Constitution Principle II)
/// and `Sendable`.
public struct SalaryRowParser: Sendable {
    public init() {}

    /// Column layout of `Retribuciones.xlsx`.
    private enum Column {
        static let position = 0  // Alto Cargo
        static let body = 1  // Organismo
        static let ministry = 2  // Ministerio
        static let remuneration = 3  // Retribución (€)
        static let year = 4  // Año
    }

    public func parse(_ row: XLSXRow) -> Result<SalaryRecord, RowRejection> {
        let position = row.cell(Column.position)
        let body = row.cell(Column.body)
        let ministry = row.cell(Column.ministry)
        let remunerationText = row.cell(Column.remuneration)
        let yearText = row.cell(Column.year)

        func reject(_ reason: String) -> Result<SalaryRecord, RowRejection> {
            .failure(RowRejection(rowNumber: row.number, reason: reason))
        }

        if position.isEmpty { return reject("missing position") }
        if body.isEmpty { return reject("missing body") }
        if ministry.isEmpty { return reject("missing ministry") }

        guard
            let remuneration = Decimal(string: remunerationText, locale: Self.posix),
            remuneration >= 0
        else { return reject("invalid remuneration") }

        guard let year = Int(yearText), (1900...2100).contains(year) else {
            return reject("invalid year")
        }

        let record = SalaryRecord(
            position: position,
            body: body,
            ministry: ministry,
            remuneration: remuneration,
            year: year,
            positionNormalized: Self.normalize(position)
        )
        return .success(record)
    }

    private static let posix = Locale(identifier: "en_US_POSIX")

    /// Lowercased, accent-stripped form for case/accent-insensitive search.
    /// Public so callers can normalize a search term the same way stored values were normalized.
    public static func normalize(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: posix)
            .lowercased()
    }
}
