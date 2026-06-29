import XCTVapor

@testable import App

private let distinctRecordCount = 304

final class AggregateAPITests: XCTestCase {
    func testAggregateByMinistry() async throws {
        try await AppTestHarness.withApp { app in
            try await app.test(
                .GET, "api/v1/aggregates/by-ministry",
                afterResponse: { res async throws in
                    XCTAssertEqual(res.status, .ok)
                    let groups = try res.content.decode([AggregateGroupDTO].self)
                    XCTAssertGreaterThan(groups.count, 0)
                    // Counts across all groups must cover every stored record.
                    XCTAssertEqual(groups.reduce(0) { $0 + $1.count }, distinctRecordCount)
                    for group in groups {
                        XCTAssertGreaterThan(group.count, 0)
                        XCTAssertGreaterThan(group.total, 0)
                        XCTAssertGreaterThan(group.average, 0)
                    }
                })
        }
    }

    func testAggregateByYear() async throws {
        try await AppTestHarness.withApp { app in
            try await app.test(
                .GET, "api/v1/aggregates/by-year",
                afterResponse: { res async throws in
                    XCTAssertEqual(res.status, .ok)
                    let groups = try res.content.decode([AggregateGroupDTO].self)
                    XCTAssertGreaterThan(groups.count, 0)
                    XCTAssertEqual(groups.reduce(0) { $0 + $1.count }, distinctRecordCount)
                    // 2025 should be present in the dataset.
                    XCTAssertTrue(groups.contains { $0.key == "2025" })
                })
        }
    }
}
