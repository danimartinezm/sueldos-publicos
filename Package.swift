// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "sueldos-publicos",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.106.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.11.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.9.0"),
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.0.0"),
    ],
    targets: [
        // Pure-Swift core: domain model + custom XLSX reader + row parsing.
        // No Vapor / no database dependency, so it builds and tests fast and in isolation
        // (Constitution: Custom-First, decoupling, Test-First).
        .target(
            name: "SalaryCore",
            path: "Sources/SalaryCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // Vapor application: persistence (Fluent/Postgres), HTTP API, and the ingest command.
        .executableTarget(
            name: "App",
            dependencies: [
                "SalaryCore",
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "SQLKit", package: "sql-kit"),
            ],
            path: "Sources/App",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "SalaryCoreTests",
            dependencies: ["SalaryCore"],
            path: "Tests/SalaryCoreTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                "App",
                .product(name: "XCTVapor", package: "vapor"),
            ],
            path: "Tests/AppTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
