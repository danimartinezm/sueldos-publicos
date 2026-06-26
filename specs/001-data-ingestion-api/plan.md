# Implementation Plan: Salary Data Ingestion & Query API

**Branch**: `main` (feature dir `001-data-ingestion-api`) | **Date**: 2026-06-26 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-data-ingestion-api/spec.md`

## Summary

Build a Vapor (Swift) server that ingests the senior-officials public-salary spreadsheet
(`Retribuciones.xlsx`, in the project root), parses and persists each record into a local
PostgreSQL database, and exposes a read-only, versioned HTTP/JSON API for listing, retrieving,
filtering, searching, and aggregating salary records. The build runs under Swift 6 strict
concurrency, and the server is deployed locally on `http://127.0.0.1:8080` after the build.

## Technical Context

**Language/Version**: Swift 6.3.2 (Swift 6 language mode, complete strict concurrency)

**Primary Dependencies**: Vapor 4 (web framework, user-mandated), Fluent + FluentPostgresDriver
(data layer / migrations within the Vapor ecosystem). XLSX parsing uses **no third-party
dependency** — a custom reader built on Foundation `XMLParser` + Apple's `Compression` framework
(raw DEFLATE) per the constitution's Custom-First principle.

**Storage**: Local PostgreSQL (target 14+), database `sueldos_publicos`, accessed via Fluent.

**Testing**: Swift Testing (bundled with the toolchain) for unit/parser/repository tests;
`VaporTesting` for HTTP endpoint/contract tests. TDD is mandatory (Constitution Principle II).

**Target Platform**: macOS (development/local deploy), Linux-compatible (Vapor/SwiftNIO). Local
deployment runs the server process bound to `127.0.0.1:8080`.

**Project Type**: Web service (server application). The cross-platform client is a separate,
future feature and out of scope here.

**Performance Goals** (Constitution Principle IV — explicit budgets):
- Full-file ingestion (320 data rows) completes in < 2 s on a developer machine.
- API read endpoints (list/get/filter/search) respond p95 < 100 ms locally at current data scale.
- Aggregation endpoints respond p95 < 150 ms locally.

**Constraints**:
- Strict concurrency: all shared types crossing concurrency boundaries are `Sendable`; no data races.
- Ingestion is transactional/atomic: a failed load leaves no partial or corrupt visible data (FR-007).
- Ingestion is idempotent via a natural-key uniqueness rule (FR-005).
- API never leaks storage/implementation details; consistent JSON error envelope (FR-015).
- Memory-bounded ingestion (stream/parse without loading unbounded structures).

**Scale/Scope**: ~320 records in the provided 2025 file; designed to absorb additional yearly files
of the same shape (low thousands of rows). Single API consumer family (the cross-platform app) plus
ad-hoc public consumers.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**I. Code Quality** — PASS (planned). A `swift-format` configuration is committed and enforced;
modules are small and single-responsibility (parser, repository, services, controllers). No dead
code merged.

**II. Test-First Development (NON-NEGOTIABLE)** — PASS (planned). Every behavior is driven by a
failing test written first: XLSX parser tests, validation tests, repository/idempotency tests,
and `VaporTesting` endpoint/contract tests. `tasks.md` will order tests before implementation.

**III. User Experience Consistency** — PASS (planned). The "interface" here is the API contract:
a single consistent JSON response/error envelope, stable field names mirroring the domain
(position/body/ministry/remuneration/year), consistent paging metadata, and actionable validation
messages across all endpoints. Captured in `contracts/openapi.yaml`.

**IV. Performance Discipline** — PASS (planned). Per-feature budgets defined above and asserted via
tests/measurements; regressions beyond budget block release.

**V. Minimal Dependencies (Custom-First)** — PASS (justified). XLSX parsing is custom (Foundation +
Apple Compression), no third-party parser. Vapor is the user-mandated framework; Fluent +
FluentPostgresDriver are well-established within that ecosystem and necessary for PostgreSQL access
and migrations. Justifications recorded in Complexity Tracking.

*No gate violations. Initial Constitution Check: PASS.*

## Project Structure

### Documentation (this feature)

```text
specs/001-data-ingestion-api/
├── plan.md              # This file (/speckit-plan output)
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── openapi.yaml
├── checklists/
│   └── requirements.md  # From /speckit-specify
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created here)
```

### Source Code (repository root)

```text
Package.swift                       # SwiftPM manifest (Swift 6 mode, strict concurrency)
Retribuciones.xlsx                  # Input file (project root)
.swift-format                       # Code-quality config (Principle I)
Sources/
└── App/
    ├── Domain/
    │   ├── SalaryRecord.swift       # Domain entity (Sendable)
    │   └── IngestionSummary.swift   # Ingestion result/report value type
    ├── XLSX/
    │   ├── ZipArchiveReader.swift   # Custom ZIP entry reader (Apple Compression)
    │   └── XLSXWorkbook.swift       # Sheet + sharedStrings parsing (XMLParser)
    ├── Ingestion/
    │   ├── SalaryRowParser.swift    # Row → validated SalaryRecord (or rejection)
    │   └── IngestionService.swift   # Orchestrates load → validate → persist (atomic)
    ├── Persistence/
    │   ├── Models/                  # Fluent models
    │   ├── Migrations/              # Fluent migrations
    │   └── SalaryRepository.swift   # Query/upsert abstraction over Fluent
    ├── API/
    │   ├── DTOs/                    # Request/response + error envelope (Codable, Sendable)
    │   ├── SalaryController.swift   # list / get / filter / search
    │   └── AggregateController.swift# group-by ministry / year
    ├── configure.swift              # DB config, migrations, routes, strict-concurrency setup
    ├── routes.swift
    └── entrypoint.swift             # Binds 127.0.0.1:8080 for local deploy

Tests/
└── AppTests/
    ├── XLSXReaderTests.swift        # ZIP/XML parsing (unit)
    ├── SalaryRowParserTests.swift   # validation + rejection reporting (unit)
    ├── IngestionServiceTests.swift  # idempotency + atomicity (integration)
    ├── SalaryAPITests.swift         # list/get/filter/search contract (VaporTesting)
    └── AggregateAPITests.swift      # aggregates (VaporTesting)
```

**Structure Decision**: Single Vapor server package at the repository root (Project Type =
web service). Layers are separated by directory — `XLSX` (custom reader), `Ingestion`,
`Persistence` (Fluent isolated behind `SalaryRepository`), and `API` — so persistence and the
HTTP contract stay decoupled and independently testable, satisfying Principles I, II, and the
constitution's server/cross-platform decoupling. The cross-platform client is not part of this
package.

## Complexity Tracking

> Dependency justifications required by Constitution Principle V (Minimal Dependencies).

| Dependency / Choice | Why Needed | Simpler Alternative Rejected Because |
|---------------------|-----------|--------------------------------------|
| Vapor 4 | User-mandated web framework; mature, widely adopted, maintained | Hand-rolling an HTTP server on SwiftNIO duplicates a well-established framework for no benefit |
| Fluent + FluentPostgresDriver | Well-established, idiomatic PostgreSQL access + migrations within the mandated Vapor stack | Raw PostgresNIO + hand-written SQL increases correctness risk on the data layer; Fluent is isolated behind `SalaryRepository` so it can be swapped |
| Custom XLSX reader (Foundation + Apple Compression) | Honors Custom-First; file is a single simple sheet | CoreXLSX/ZIPFoundation are third-party deps the constitution tells us to avoid when a bounded custom implementation suffices |
| swift-format (dev-only) | Enforces Principle I code-quality gate in CI | Manual style review is not automatable and fails the constitution's enforced-gate requirement |
