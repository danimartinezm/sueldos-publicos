import Foundation
import XCTest

@testable import SalaryCore

final class XLSXReaderTests: XCTestCase {
    func testReadsWorkbookHeaderAnd320DataRows() throws {
        let workbook = try XLSXWorkbook(data: try TestSupport.inputData())

        XCTAssertEqual(workbook.rows.count, 321)
        XCTAssertEqual(workbook.dataRows.count, 320)

        let header = workbook.rows[0]
        XCTAssertEqual(header.cell(0), "Alto Cargo")
        XCTAssertEqual(header.cell(1), "Organismo")
        XCTAssertEqual(header.cell(2), "Ministerio")
        XCTAssertEqual(header.cell(3), "Retribución (€)")
        XCTAssertEqual(header.cell(4), "Año")
    }

    func testResolvesSharedStringsAndNumericCellsInFirstDataRow() throws {
        let workbook = try XLSXWorkbook(data: try TestSupport.inputData())
        let first = workbook.dataRows[0]

        XCTAssertEqual(first.number, 2)
        XCTAssertEqual(first.cell(0), "PRESIDENTE DEL GOBIERNO")
        XCTAssertEqual(first.cell(1), "Presidencia del Gobierno")
        XCTAssertEqual(first.cell(2), "Presidencia del Gobierno")
        XCTAssertEqual(first.cell(3), "95943.96")
        XCTAssertEqual(first.cell(4), "2025")
    }

    func testColumnReferenceParsing() {
        XCTAssertEqual(xlsxColumnIndex("A1"), 0)
        XCTAssertEqual(xlsxColumnIndex("E321"), 4)
        XCTAssertEqual(xlsxColumnIndex("AA1"), 26)
    }
}
