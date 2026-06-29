import Foundation
import XCTest

@testable import SalaryCore

final class SalaryRowParserTests: XCTestCase {
    private let parser = SalaryRowParser()

    private func row(_ cells: [String], number: Int = 2) -> XLSXRow {
        XLSXRow(number: number, cells: cells)
    }

    func testValidRowParsesWithExactDecimalAndNormalizedPosition() throws {
        let result = parser.parse(
            row(["DIRECTORA DE ÁREA", "Organismo X", "Ministerio Y", "123456.78", "2025"])
        )
        let record = try result.get()
        XCTAssertEqual(record.position, "DIRECTORA DE ÁREA")
        XCTAssertEqual(record.body, "Organismo X")
        XCTAssertEqual(record.ministry, "Ministerio Y")
        XCTAssertEqual(record.remuneration, Decimal(string: "123456.78"))
        XCTAssertEqual(record.year, 2025)
        XCTAssertEqual(record.positionNormalized, "directora de area")
    }

    func testMissingRequiredFieldsAreRejected() {
        XCTAssertEqual(rejection(["", "B", "M", "1", "2025"])?.reason, "missing position")
        XCTAssertEqual(rejection(["P", "", "M", "1", "2025"])?.reason, "missing body")
        XCTAssertEqual(rejection(["P", "B", "", "1", "2025"])?.reason, "missing ministry")
    }

    func testBadRemunerationIsRejected() {
        XCTAssertEqual(rejection(["P", "B", "M", "n/a", "2025"])?.reason, "invalid remuneration")
        XCTAssertEqual(rejection(["P", "B", "M", "-5", "2025"])?.reason, "invalid remuneration")
        XCTAssertEqual(rejection(["P", "B", "M", "", "2025"])?.reason, "invalid remuneration")
    }

    func testBadYearIsRejected() {
        XCTAssertEqual(rejection(["P", "B", "M", "1", "abcd"])?.reason, "invalid year")
        XCTAssertEqual(rejection(["P", "B", "M", "1", "1700"])?.reason, "invalid year")
    }

    func testRowNumberPreservedInRejection() {
        let result = parser.parse(row(["", "B", "M", "1", "2025"], number: 57))
        XCTAssertEqual(rejectionValue(result)?.rowNumber, 57)
    }

    // MARK: helpers

    private func rejection(_ cells: [String]) -> RowRejection? {
        rejectionValue(parser.parse(row(cells)))
    }

    private func rejectionValue(_ result: Result<SalaryRecord, RowRejection>) -> RowRejection? {
        if case .failure(let rejection) = result { return rejection }
        return nil
    }
}
