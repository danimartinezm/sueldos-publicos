import Fluent
import FluentPostgresDriver
import Foundation
import Vapor

/// Configures database, migrations, the ingest command, middleware, and routes.
public func configure(_ app: Application) async throws {
    let port =
        Environment.get("DATABASE_PORT").flatMap(Int.init)
        ?? SQLPostgresConfiguration.ianaPortNumber
    let username =
        Environment.get("DATABASE_USERNAME")
        ?? ProcessInfo.processInfo.environment["USER"]
        ?? "postgres"

    let configuration = SQLPostgresConfiguration(
        hostname: Environment.get("DATABASE_HOST") ?? "127.0.0.1",
        port: port,
        username: username,
        password: Environment.get("DATABASE_PASSWORD"),
        database: Environment.get("DATABASE_NAME") ?? "sueldos_publicos",
        tls: .disable
    )
    app.databases.use(.postgres(configuration: configuration), as: .psql)

    app.migrations.add(CreateSalaryRecord())
    app.migrations.add(CreateIngestionRun())

    app.asyncCommands.use(IngestCommand(), as: "ingest")

    // Replace the default error handling with the consistent API envelope.
    app.middleware = Middlewares()
    app.middleware.use(APIErrorMiddleware())

    try routes(app)
}
