# Phase 0 Research: Salary Data Ingestion & Query API

All Technical Context unknowns are resolved below. Each item records the Decision, Rationale, and
Alternatives considered, consistent with the constitution (Custom-First, Minimal Dependencies,
Test-First, Performance Discipline).

## 1. XLSX parsing strategy (Custom-First)

- **Decision**: Implement a custom, read-only XLSX reader. An `.xlsx` is a ZIP container of XML
  parts. The reader (a) parses ZIP local file headers / central directory to locate
  `xl/sharedStrings.xml` and `xl/worksheets/sheet1.xml`, (b) inflates each entry with Apple's
  `Compression` framework using `COMPRESSION_ZLIB` (raw DEFLATE, RFC 1951 — exactly what ZIP uses),
  and (c) parses the XML with Foundation's `XMLParser`, resolving shared-string indices to cell text.
- **Rationale**: Constitution Principle V mandates custom implementations over third-party deps when
  feasible. The input is a single sheet with 5 columns and ~320 rows — a bounded, well-understood
  format. No external dependency, smaller attack/supply-chain surface, full control.
- **Format facts confirmed from `Retribuciones.xlsx`**: sheet `HOJA1`; header row 1 =
  `Alto Cargo | Organismo | Ministerio | Retribución (€) | Año`; 320 data rows (rows 2–321);
  remuneration cells are numeric (`t="n"`, e.g. `95943.96`); year cells are shared strings (`"2025"`).
- **Alternatives considered**: CoreXLSX (pulls ZIPFoundation + XMLCoder) and ZIPFoundation directly —
  rejected as third-party dependencies the constitution tells us to avoid for a bounded custom case.

## 2. Web framework & concurrency

- **Decision**: Vapor 4 on Swift 6 language mode with **complete** strict concurrency. Enable in
  `Package.swift` via `swiftLanguageModes: [.v6]` and `.enableExperimentalFeature`/
  `.enableUpcomingFeature("StrictConcurrency")` as needed; all types crossing concurrency boundaries
  (DTOs, domain entities, config) conform to `Sendable`.
- **Rationale**: User-mandated framework; Vapor 4 (current SwiftNIO-based releases) supports Swift 6
  and strict concurrency. Async/await request handling fits the read-heavy API.
- **Alternatives considered**: Hummingbird — rejected (user specified Vapor). Disabling strict
  concurrency — rejected (explicitly required).

## 3. Persistence & migrations

- **Decision**: Fluent ORM + `FluentPostgresDriver` against local PostgreSQL. Schema created via
  Fluent migrations. All Fluent usage is isolated behind a `SalaryRepository` abstraction so domain
  and API layers never import Fluent directly.
- **Rationale**: Well-established within the mandated Vapor stack; provides migrations, parameterized
  queries, and connection pooling, reducing correctness risk on the data layer (which holds the
  salary figures that must be exact). Isolation keeps Principle V's swap-ability intact.
- **Alternatives considered**: Raw PostgresNIO + hand-written SQL — more custom but higher risk of
  query/escaping bugs on the correctness-critical layer; not justified given Fluent's maturity.

## 4. Idempotent ingestion & atomicity

- **Decision**: Define a **natural key** = (position, body, ministry, year). A unique constraint on
  this key plus an upsert (`ON CONFLICT ... DO UPDATE`/Fluent equivalent) makes re-ingestion
  idempotent (FR-005). The whole ingestion runs inside a single database transaction; on any fatal
  error it rolls back, leaving no partial data visible (FR-007).
- **Rationale**: Directly satisfies SC-003 (zero duplicates) and SC-007/FR-007 (no partial/corrupt
  data). The natural key matches how the source identifies a distinct salary line per year.
- **Alternatives considered**: Truncate-and-reload — simpler but loses historical multi-file data and
  causes a visibility gap mid-load; rejected. Hash-of-row key — opaque; natural key is clearer.

## 5. Row validation & rejection reporting

- **Decision**: A pure `SalaryRowParser` maps a raw row to either a validated `SalaryRecord` or a
  `RowRejection(rowNumber, reason)`. Required: non-empty position/body/ministry, remuneration parses
  to a non-negative decimal, year parses to a plausible 4-digit year. Invalid rows are collected, not
  fatal (FR-003, FR-004). Remuneration stored as exact decimal (no float drift).
- **Rationale**: Pure function → trivially unit-testable first (Principle II); satisfies SC-002
  (every bad row individually reported, no neighbour lost).
- **Alternatives considered**: Fail-fast on first bad row — rejected (violates FR-003).

## 6. API shape, paging, search, aggregation, error envelope

- **Decision**: REST/JSON under `/api/v1`. Endpoints: `GET /salaries` (paged list + filters
  `ministry`, `body`, `year`, search `q`), `GET /salaries/{id}`, `GET /aggregates/by-ministry`,
  `GET /aggregates/by-year`. Paging via `page` (1-based) + `pageSize` (default 50, max 200) returning
  `{ items, page, pageSize, total }`. Search `q` matches position case- and accent-insensitively
  (PostgreSQL `unaccent` + `ILIKE`, or normalized lowercase column). Single consistent error envelope
  `{ error: { code, message } }` with actionable messages and no internal details (FR-013, FR-015).
- **Rationale**: One consistent contract across endpoints satisfies Principle III; versioned path
  satisfies FR-014. Defined once in `contracts/openapi.yaml`.
- **Alternatives considered**: GraphQL — overkill for a small read-only dataset. Offset paging chosen
  over cursor paging given the small, stable dataset.

## 7. Local PostgreSQL provisioning (environment gap)

- **Decision**: PostgreSQL is **not currently installed**. Document Homebrew as the primary path:
  `brew install postgresql@16 && brew services start postgresql@16`, then create role/db
  `sueldos_publicos`. Connection configured via environment variables
  (`DATABASE_HOST/PORT/USERNAME/PASSWORD/NAME`) with local defaults. The `unaccent` extension is
  enabled by a migration (`CREATE EXTENSION IF NOT EXISTS unaccent`).
- **Rationale**: Homebrew is the standard macOS path and avoids Docker (also not installed). Env-var
  config keeps secrets out of source and matches Vapor conventions.
- **Alternatives considered**: Docker Postgres (Docker not installed) and Postgres.app (GUI, fine as a
  documented alternative) — both noted in quickstart as options.

## 8. Build & local deployment

- **Decision**: `swift build -c release` then run the server bound to `127.0.0.1:8080`
  (`swift run App serve --hostname 127.0.0.1 --port 8080`). Migrations run via
  `swift run App migrate`. Ingestion triggered by an admin command
  (`swift run App ingest --file Retribuciones.xlsx`) reading the root file.
- **Rationale**: Satisfies "deploy the server locally". A CLI ingest command keeps loading an
  administrator action (spec Assumption) rather than a public upload endpoint.
- **Alternatives considered**: HTTP upload endpoint — rejected for v1 (spec scopes ingestion as an
  admin action, not internet-facing upload).

## 9. Tooling: code quality & testing

- **Decision**: `swift-format` with a committed `.swift-format` config, enforced in CI. Tests use
  Swift Testing (`import Testing`) for units and `VaporTesting` for HTTP-level contract tests.
- **Rationale**: Principle I needs an automated, enforced formatter; Principle II needs a first-class
  test path. Both ship with the toolchain / Vapor — no extra runtime dependency.
- **Alternatives considered**: SwiftLint (additional dep) — `swift-format` suffices; XCTest — Swift
  Testing is the modern, bundled choice and integrates with VaporTesting.
