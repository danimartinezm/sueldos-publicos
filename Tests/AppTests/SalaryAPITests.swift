import XCTVapor

@testable import App

/// The provided file has 320 data rows; 16 are exact duplicates (same position/body/ministry/year
/// AND remuneration), so 304 distinct records are stored after idempotent upsert.
private let distinctRecordCount = 304

final class SalaryAPITests: XCTestCase {
    func testListReturnsPagedRecordsWithMetadata() async throws {
        try await AppTestHarness.withApp { app in
            try await app.test(
                .GET, "api/v1/salaries?page=1&pageSize=50",
                afterResponse: { res async throws in
                    XCTAssertEqual(res.status, .ok)
                    let page = try res.content.decode(SalaryPageDTO.self)
                    XCTAssertEqual(page.total, distinctRecordCount)
                    XCTAssertEqual(page.page, 1)
                    XCTAssertEqual(page.pageSize, 50)
                    XCTAssertEqual(page.items.count, 50)
                })
        }
    }

    func testSecondPageReturnsDifferentRecords() async throws {
        try await AppTestHarness.withApp { app in
            let firstPageIDs = Box<Set<String>>([])
            try await app.test(
                .GET, "api/v1/salaries?page=1&pageSize=50",
                afterResponse: { res async throws in
                    let page = try res.content.decode(SalaryPageDTO.self)
                    firstPageIDs.value = Set(page.items.map { $0.id.uuidString })
                })
            try await app.test(
                .GET, "api/v1/salaries?page=2&pageSize=50",
                afterResponse: { res async throws in
                    let page = try res.content.decode(SalaryPageDTO.self)
                    let secondIDs = Set(page.items.map { $0.id.uuidString })
                    XCTAssertTrue(firstPageIDs.value.isDisjoint(with: secondIDs))
                })
        }
    }

    func testGetByIdReturnsRecord() async throws {
        try await AppTestHarness.withApp { app in
            let sampleID = Box("")
            try await app.test(
                .GET, "api/v1/salaries?pageSize=1",
                afterResponse: { res async throws in
                    let page = try res.content.decode(SalaryPageDTO.self)
                    sampleID.value = page.items[0].id.uuidString
                })
            try await app.test(
                .GET, "api/v1/salaries/\(sampleID.value)",
                afterResponse: { res async throws in
                    XCTAssertEqual(res.status, .ok)
                    let dto = try res.content.decode(SalaryDTO.self)
                    XCTAssertEqual(dto.id.uuidString, sampleID.value)
                })
        }
    }

    func testUnknownIdReturns404Envelope() async throws {
        try await AppTestHarness.withApp { app in
            try await app.test(
                .GET, "api/v1/salaries/00000000-0000-0000-0000-000000000000",
                afterResponse: { res async throws in
                    XCTAssertEqual(res.status, .notFound)
                    let envelope = try res.content.decode(APIErrorEnvelope.self)
                    XCTAssertEqual(envelope.error.code, "not_found")
                })
        }
    }

    func testMalformedIdReturns400() async throws {
        try await AppTestHarness.withApp(ingest: false) { app in
            try await app.test(
                .GET, "api/v1/salaries/not-a-uuid",
                afterResponse: { res async throws in
                    XCTAssertEqual(res.status, .badRequest)
                    let envelope = try res.content.decode(APIErrorEnvelope.self)
                    XCTAssertEqual(envelope.error.code, "invalid_parameter")
                })
        }
    }

    func testInvalidPageSizeReturns400() async throws {
        try await AppTestHarness.withApp(ingest: false) { app in
            try await app.test(
                .GET, "api/v1/salaries?pageSize=9999",
                afterResponse: { res async throws in
                    XCTAssertEqual(res.status, .badRequest)
                    let envelope = try res.content.decode(APIErrorEnvelope.self)
                    XCTAssertEqual(envelope.error.code, "invalid_parameter")
                })
        }
    }

    func testFilterByMinistryAndYear() async throws {
        try await AppTestHarness.withApp { app in
            try await app.test(
                .GET,
                "api/v1/salaries?ministry=Presidencia%20del%20Gobierno&year=2025&pageSize=200",
                afterResponse: { res async throws in
                    XCTAssertEqual(res.status, .ok)
                    let page = try res.content.decode(SalaryPageDTO.self)
                    XCTAssertGreaterThan(page.total, 0)
                    for item in page.items {
                        XCTAssertEqual(item.ministry, "Presidencia del Gobierno")
                        XCTAssertEqual(item.year, 2025)
                    }
                })
        }
    }

    func testAccentAndCaseInsensitiveSearch() async throws {
        try await AppTestHarness.withApp { app in
            try await app.test(
                .GET, "api/v1/salaries?q=director&pageSize=200",
                afterResponse: { res async throws in
                    XCTAssertEqual(res.status, .ok)
                    let page = try res.content.decode(SalaryPageDTO.self)
                    XCTAssertGreaterThan(page.total, 0)
                    for item in page.items {
                        XCTAssertTrue(item.position.lowercased().contains("direc"))
                    }
                })
            try await app.test(
                .GET, "api/v1/salaries?q=zz-no-such-position",
                afterResponse: { res async throws in
                    let page = try res.content.decode(SalaryPageDTO.self)
                    XCTAssertEqual(page.total, 0)
                    XCTAssertTrue(page.items.isEmpty)
                })
        }
    }
}
