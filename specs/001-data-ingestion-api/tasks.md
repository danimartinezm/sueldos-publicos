---
description: "Task list for Salary Data Ingestion & Query API"
---

# Tasks: Salary Data Ingestion & Query API

**Input**: Design documents from `/specs/001-data-ingestion-api/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/openapi.yaml, quickstart.md

**Tests**: MANDATORY per Constitution Principle II (Test-First Development, NON-NEGOTIABLE). Every
behavior task is preceded by a test task that MUST be written first and MUST fail before
implementation.

**Organization**: Tasks are grouped by user story (US1 ingest → US2 query → US3 filter/search/aggregate)
so each story is independently implementable and testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1, US2, US3 (Setup/Foundational/Polish have no story label)
- Paths follow the Vapor package layout in plan.md (`Sources/App/...`, `Tests/AppTests/...`)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize the Vapor Swift package under strict concurrency with quality tooling.

- [x] T001 Create the SwiftPM Vapor package skeleton at repo root: `Package.swift` declaring Swift 6 language mode (`swiftLanguageModes: [.v6]`), complete strict concurrency, and dependencies Vapor 4, Fluent, FluentPostgresDriver, plus the `App` executable target and `AppTests` test target (with `VaporTesting`)
- [x] T002 [P] Create the source directory tree per plan.md under `Sources/App/` (`Domain/`, `XLSX/`, `Ingestion/`, `Persistence/Models/`, `Persistence/Migrations/`, `API/DTOs/`) and `Tests/AppTests/`
- [x] T003 [P] Add `.swift-format` configuration at repo root and document the format/lint gate (Constitution Principle I) in `specs/001-data-ingestion-api/quickstart.md` if missing
- [x] T004 [P] Add `.gitignore` entries for `.build/`, `.swiftpm/`, and local env files; keep `Retribuciones.xlsx` tracked

**Checkpoint**: `swift build` compiles an empty app cleanly under strict concurrency.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure required by every user story — DB config, base entities, repository
seam, API error envelope, and the locally-deployable app entrypoint.

**⚠️ CRITICAL**: No user story work begins until this phase is complete.

- [x] T005 Implement `configure.swift` in `Sources/App/configure.swift`: read `DATABASE_HOST/PORT/NAME/USERNAME/PASSWORD` env vars (local defaults), register FluentPostgresDriver, register migrations, and apply strict-concurrency-safe setup
- [x] T006 Implement `entrypoint.swift` in `Sources/App/entrypoint.swift` and `routes.swift` in `Sources/App/routes.swift` binding the server to `127.0.0.1:8080` and mounting an empty `/api/v1` route group
- [x] T007 [P] Define the domain entity `SalaryRecord` (Sendable value type) in `Sources/App/Domain/SalaryRecord.swift` per data-model.md (id, position, body, ministry, remuneration as Decimal, year, positionNormalized)
- [x] T008 [P] Define `IngestionSummary` and `RowRejection` value types in `Sources/App/Domain/IngestionSummary.swift`
- [x] T009 [P] Define the consistent API error envelope + a `Sendable` `APIError` (code, message) and abort mapping in `Sources/App/API/DTOs/APIError.swift` (FR-013, FR-015)
- [x] T010 Create Fluent model `SalaryRecordModel` in `Sources/App/Persistence/Models/SalaryRecordModel.swift` and `IngestionRunModel` in `Sources/App/Persistence/Models/IngestionRunModel.swift` per data-model.md
- [x] T011 Create Fluent migrations in `Sources/App/Persistence/Migrations/`: `CreateSalaryRecord.swift` (with unique index on position+body+ministry+year and filter/search indexes), `CreateIngestionRun.swift`, and `EnableUnaccent.swift` (`CREATE EXTENSION IF NOT EXISTS unaccent`)
- [x] T012 Define the `SalaryRepository` protocol (Sendable) in `Sources/App/Persistence/SalaryRepository.swift` with methods for upsert-by-natural-key, paged query with filters/search, fetch-by-id, and aggregates — keeping Fluent isolated behind it

**Checkpoint**: `swift run App migrate` creates the schema; server starts on `127.0.0.1:8080` with an empty API.

---

## Phase 3: User Story 1 - Ingest the salary dataset (Priority: P1) 🎯 MVP

**Goal**: Read `Retribuciones.xlsx`, validate/parse rows, and persist records idempotently and
atomically, reporting an import summary.

**Independent Test**: Run `swift run App ingest --file Retribuciones.xlsx`; confirm 320 rows read /
320 imported / 0 rejected, field values match the source, and a second run creates 0 duplicates.

### Tests for User Story 1 (MANDATORY — write before implementation) ⚠️

> **Write these tests FIRST, ensure they FAIL before implementation (Constitution Principle II)**

- [x] T013 [P] [US1] Unit tests for the custom ZIP/DEFLATE reader in `Tests/AppTests/XLSXReaderTests.swift`: locate and inflate `xl/sharedStrings.xml` and `xl/worksheets/sheet1.xml` from `Retribuciones.xlsx`, asserting known cell values (e.g. A1="Alto Cargo", D2=95943.96)
- [x] T014 [P] [US1] Unit tests for `SalaryRowParser` in `Tests/AppTests/SalaryRowParserTests.swift`: valid row → SalaryRecord; missing field / non-numeric or negative remuneration / bad year → RowRejection with row number and reason; one bad row does not abort others (FR-003, FR-004, SC-002)
- [x] T015 [P] [US1] Integration tests for `IngestionService` in `Tests/AppTests/IngestionServiceTests.swift`: full-file load yields 320 records; re-run yields 0 duplicates (SC-003); a forced mid-load failure leaves zero visible records (atomicity, FR-007/SC-007)
- [x] T016 [P] [US1] Performance test in `Tests/AppTests/IngestionPerformanceTests.swift` asserting full-file ingestion completes within the 2 s budget (Constitution Principle IV)

### Implementation for User Story 1

- [x] T017 [P] [US1] Implement `ZipArchiveReader` in `Sources/App/XLSX/ZipArchiveReader.swift`: parse ZIP entries and inflate with Apple `Compression` (`COMPRESSION_ZLIB`, raw DEFLATE) per research.md §1
- [x] T018 [US1] Implement `XLSXWorkbook` in `Sources/App/XLSX/XLSXWorkbook.swift`: parse sheet + sharedStrings via Foundation `XMLParser`, resolving shared-string indices into typed rows (depends on T017)
- [x] T019 [P] [US1] Implement `SalaryRowParser` in `Sources/App/Ingestion/SalaryRowParser.swift`: pure row→`SalaryRecord` or `RowRejection`, including `positionNormalized` (lowercased, accent-stripped) and exact Decimal remuneration
- [x] T020 [US1] Implement Fluent-backed upsert (`ON CONFLICT` on natural key) in `Sources/App/Persistence/FluentSalaryRepository.swift` conforming to `SalaryRepository`
- [x] T021 [US1] Implement `IngestionService` in `Sources/App/Ingestion/IngestionService.swift`: orchestrate read→parse→validate→transactional upsert, record an `IngestionRun`, and return `IngestionSummary` (depends on T018, T019, T020)
- [x] T022 [US1] Implement the `ingest` CLI command in `Sources/App/Commands/IngestCommand.swift` (registered in `configure.swift`) reading `--file` (default `Retribuciones.xlsx`) and printing the summary

**Checkpoint**: US1 is fully functional — `ingest` loads the dataset idempotently; all US1 tests pass.

---

## Phase 4: User Story 2 - Query salary records through the API (Priority: P2)

**Goal**: Serve ingested data via `GET /api/v1/salaries` (paged list) and `GET /api/v1/salaries/{id}`.

**Independent Test**: With data ingested, list returns `{ items, page, pageSize, total: 320 }`;
get-by-id returns the matching record; an unknown id returns 404 with the error envelope.

### Tests for User Story 2 (MANDATORY — write before implementation) ⚠️

- [x] T023 [P] [US2] Contract test for `GET /salaries` in `Tests/AppTests/SalaryListAPITests.swift` (VaporTesting): response matches `contracts/openapi.yaml` `SalaryPage`; paging metadata correct across pages
- [x] T024 [P] [US2] Contract test for `GET /salaries/{id}` in `Tests/AppTests/SalaryGetAPITests.swift`: existing id returns the record; unknown id returns 404 + `Error` envelope; malformed id returns 400

### Implementation for User Story 2

- [x] T025 [P] [US2] Implement `SalaryDTO` and `Page<T>` response types in `Sources/App/API/DTOs/SalaryDTO.swift` (Codable, Sendable) mapping `SalaryRecord` → public fields only (FR-015)
- [x] T026 [US2] Implement paged list + fetch-by-id in `FluentSalaryRepository` (extend T020) with validated paging (`page>=1`, `pageSize 1..200`)
- [x] T027 [US2] Implement `SalaryController` in `Sources/App/API/SalaryController.swift` with `list` and `get` routes, registered under `/api/v1` in `routes.swift` (FR-008, FR-009)
- [x] T028 [US2] Add paging parameter validation returning the 400 error envelope in `SalaryController` (FR-013)

**Checkpoint**: US1 + US2 both work — data is ingestable and queryable; US2 tests pass.

---

## Phase 5: User Story 3 - Filter, search, and aggregate (Priority: P3)

**Goal**: Filter by ministry/body/year, accent/case-insensitive position search, and aggregate
(count/total/average) by ministry and by year.

**Independent Test**: Filter by ministry+year, search `q=director` (matches accented/case variants),
and request aggregates; results match manual calculation over the dataset (SC-005).

### Tests for User Story 3 (MANDATORY — write before implementation) ⚠️

- [x] T029 [P] [US3] Contract/behavior tests for filtering & search in `Tests/AppTests/SalaryFilterSearchAPITests.swift`: `ministry`/`body`/`year` filters combine (AND); `q` is case- and accent-insensitive (FR-010, FR-011); empty match returns empty page (US3-4)
- [x] T030 [P] [US3] Contract tests for aggregates in `Tests/AppTests/AggregateAPITests.swift`: `by-ministry` and `by-year` return `{ key, count, total, average }` matching manual calculation (FR-012, SC-005)

### Implementation for User Story 3

- [x] T031 [US3] Extend `FluentSalaryRepository` query to apply `ministry`/`body`/`year` filters and accent-insensitive `q` search (using `unaccent` + `ILIKE` on `positionNormalized`)
- [x] T032 [US3] Wire filter/search query parameters into `SalaryController.list` with validation (FR-013)
- [x] T033 [P] [US3] Implement aggregate queries (group-by ministry, group-by year) in `FluentSalaryRepository` returning `AggregateGroup`
- [x] T034 [US3] Implement `AggregateController` in `Sources/App/API/AggregateController.swift` with `by-ministry` and `by-year` routes registered under `/api/v1`

**Checkpoint**: All user stories independently functional; full suite green.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Quality, performance, and end-to-end validation across stories.

- [x] T035 [P] Add API read-path performance tests in `Tests/AppTests/APIPerformanceTests.swift` asserting list/get/filter p95 < 100 ms and aggregates p95 < 150 ms at current scale (Constitution Principle IV)
- [x] T036 [P] Run `swift-format` across `Sources/` and `Tests/` and resolve all findings (Constitution Principle I)
- [x] T037 Execute `specs/001-data-ingestion-api/quickstart.md` end-to-end (migrate → ingest → serve → curl checks) and confirm every expected outcome
- [x] T038 [P] Verify the running API matches `contracts/openapi.yaml` (field names, envelope, status codes) and update whichever is wrong

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories.
- **User Stories (Phases 3–5)**: All depend on Foundational. US2 and US3 build on the repository and
  controllers seeded by US1/US2 but each remains independently testable.
- **Polish (Phase 6)**: Depends on the targeted user stories being complete.

### User Story Dependencies

- **US1 (P1)**: Depends only on Foundational. Delivers the MVP (ingested, queryable data).
- **US2 (P2)**: Depends on Foundational; consumes data produced by US1 for meaningful results but its
  endpoints/tests are independent.
- **US3 (P3)**: Depends on Foundational; extends US2's list endpoint and repository.

### Within Each User Story

- Tests (T013–T016, T023–T024, T029–T030) MUST be written and FAIL before implementation.
- Reader → workbook → parser → repository → service → controller/command order is enforced by the
  `depends on` notes above.

### Parallel Opportunities

- Setup: T002, T003, T004 in parallel after T001.
- Foundational: T007, T008, T009 in parallel; T010/T011/T012 after entities exist.
- US1 tests T013–T016 all [P]; implementation T017 and T019 [P], then T018/T020/T021/T022 in order.
- US2 tests T023–T024 [P]; US3 tests T029–T030 [P].
- Polish: T035, T036, T038 [P].

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Complete Phase 1 (Setup) and Phase 2 (Foundational).
2. Complete Phase 3 (US1): custom XLSX reader → parser → idempotent/atomic ingestion → CLI.
3. **STOP and VALIDATE**: ingest the file, confirm 320/320/0 and zero duplicates on re-run.
4. This is a deployable MVP: data is in PostgreSQL and verifiable.

### Incremental Delivery

1. Setup + Foundational → foundation ready.
2. Add US1 → validate ingestion → MVP.
3. Add US2 → serve list/get locally on `127.0.0.1:8080`.
4. Add US3 → filtering, search, aggregates.
5. Polish → performance + quickstart validation.

---

## Notes

- [P] = different files, no incomplete dependencies.
- Verify each test fails before implementing (Principle II).
- Keep Fluent behind `SalaryRepository`; domain/API layers never import Fluent (plan.md decoupling).
- Commit after each task or logical group.
- Remuneration is exact Decimal end-to-end — never floating-point — to protect correctness.

---

## Implementation Notes & Deviations (completed 2026-06-26)

All tasks above are implemented and verified. **18/18 automated tests pass**; the server builds
clean under Swift 6 strict concurrency and was deployed locally on `127.0.0.1:8080` with the full
dataset loaded and all endpoints validated. Deviations from the original plan, each a deliberate
improvement or environmental necessity:

- **Pure core split into a `SalaryCore` target** (domain + custom XLSX reader + parser), with the
  Vapor `App` target depending on it. Improves testability/decoupling and lets the custom-parser
  tests run without compiling Vapor. (Refines the single-target layout in plan.md.)
- **Persistence uses the SQL layer (SQLKit) instead of Fluent `Model` classes** (T010). Fluent is
  still used for migrations and transactions; queries/upserts decode into `Sendable` Codable structs.
  This sidesteps non-`Sendable` Fluent models under Swift 6 strict concurrency while keeping the
  `SalaryRepository` abstraction and atomic, idempotent `INSERT … ON CONFLICT`.
- **No PostgreSQL `unaccent` extension** (dropped from T011). Accent/case-insensitive search is
  achieved by precomputing `position_normalized` in Swift at ingest and matching with `LIKE` — more
  Custom-First and one fewer DB dependency.
- **Tests use XCTest/XCTVapor**, not Swift Testing (research.md preference). The `Testing` module was
  not available in the active toolchain configuration; XCTest is bundled and keeps the stack uniform
  with XCTVapor. All tests are still authored test-first.
- **Toolchain**: the active `xcode-select` points at CommandLineTools (no XCTest); builds/tests are
  run with `DEVELOPER_DIR=/Applications/Xcode-26.5.0.app/Contents/Developer` (documented in
  quickstart.md).
- **Distinct record count is 304, not 320**: the source file contains 16 exact-duplicate rows
  (identical position/body/ministry/year AND remuneration). Idempotent upsert correctly collapses
  them; the ingestion summary still reports 320 rows read/processed. Re-ingesting keeps the count at
  304 (idempotency verified).
