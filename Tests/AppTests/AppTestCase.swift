import Fluent
import Foundation
import SalaryCore
import XCTVapor

@testable import App

/// Mutable reference cell for moving a value out of a `@Sendable` response closure.
final class Box<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

/// Shared harness: boots the app against a dedicated test database, runs migrations, ingests the
/// real `Retribuciones.xlsx`, runs the test body, then reverts and shuts down.
enum AppTestHarness {
    static var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // AppTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // root
    }

    static func withApp(
        ingest: Bool = true,
        _ body: (Application) async throws -> Void
    ) async throws {
        let testDB =
            ProcessInfo.processInfo.environment["TEST_DATABASE_NAME"] ?? "sueldos_publicos_test"
        setenv("DATABASE_NAME", testDB, 1)

        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoRevert()
            try await app.autoMigrate()
            if ingest {
                let data = try Data(
                    contentsOf: repoRoot.appendingPathComponent("Retribuciones.xlsx"))
                _ = try await IngestionService().ingest(
                    data: data, source: "Retribuciones.xlsx", on: app.db)
            }
            try await body(app)
            try await app.autoRevert()
        } catch {
            try? await app.autoRevert()
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
}
