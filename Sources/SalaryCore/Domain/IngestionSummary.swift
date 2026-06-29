import Foundation

/// A single rejected row, reported with its 1-based spreadsheet row number and a reason.
public struct RowRejection: Error, Codable, Sendable, Equatable {
    public var rowNumber: Int
    public var reason: String

    public init(rowNumber: Int, reason: String) {
        self.rowNumber = rowNumber
        self.reason = reason
    }
}

/// The outcome of one ingestion run.
public struct IngestionSummary: Sendable, Equatable {
    public var rowsRead: Int
    public var rowsImported: Int
    public var rejections: [RowRejection]

    public init(rowsRead: Int, rowsImported: Int, rejections: [RowRejection]) {
        self.rowsRead = rowsRead
        self.rowsImported = rowsImported
        self.rejections = rejections
    }

    public var rowsRejected: Int { rejections.count }
}
