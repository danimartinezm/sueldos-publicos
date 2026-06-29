# Sueldos Públicos

A public-transparency project for Spanish senior-official ("Altos Cargos") salaries. It ingests the
official remuneration spreadsheet, serves it through a read-only API, and presents it in a
cross-platform mobile app.

The project is built with [Spec Kit](https://github.com/github/spec-kit): each feature flows through
`constitution → specify → plan → tasks → implement`, with all artifacts under `specs/`.

## Repository layout

```text
.
├── Retribuciones.xlsx          # Source dataset (320 rows; 304 distinct records)
├── Package.swift               # Server — Swift Package (feature 001)
├── Sources/                    # Server source (SalaryCore + App)
├── Tests/                      # Server tests
├── app/                        # Cross-platform app — Kotlin Multiplatform (feature 002)
│   ├── composeApp/             # Shared logic + Compose Multiplatform UI
│   └── iosApp/                 # iOS host (Swift sources + Info.plist)
└── specs/                      # Spec Kit artifacts
    ├── 001-data-ingestion-api/ # Server: spec, plan, tasks, contracts
    └── 002-salary-browser-app/ # App: spec, plan, tasks, contracts
```

The two parts are intentionally decoupled (per the project
[constitution](.specify/memory/constitution.md)): they communicate only through the published API
contract.

## The two parts

### 1. Server — Salary Data Ingestion & Query API

Vapor (Swift 6, complete strict concurrency) server that loads `Retribuciones.xlsx` into PostgreSQL
and exposes a read-only JSON API. The XLSX reader is custom (no third-party parser): ZIP parsing +
Apple's `Compression` framework (raw DEFLATE) + Foundation `XMLParser`.

- Spec & design: [`specs/001-data-ingestion-api/`](specs/001-data-ingestion-api/)
- API contract: [`specs/001-data-ingestion-api/contracts/openapi.yaml`](specs/001-data-ingestion-api/contracts/openapi.yaml)

**Endpoints** (`/api/v1`): `GET /salaries` (paged list with `ministry`/`body`/`year` filters and
accent-insensitive `q` search), `GET /salaries/{id}`, `GET /aggregates/by-ministry`,
`GET /aggregates/by-year`.

### 2. Cross-platform app — Public Salary Browser

Kotlin Multiplatform app for **iOS and Android** with a shared **Compose Multiplatform** UI; primary
language **Spanish**. It consumes the server API to show a progressively-loaded list (position +
salary) and a detail view (all fields), with explicit loading/empty/error states. Networking via
Ktor + kotlinx.serialization; navigation, paging, state holders, strings, and currency formatting are
custom.

- Spec & design: [`specs/002-salary-browser-app/`](specs/002-salary-browser-app/)

## Prerequisites

- **Server**: Swift 6.3+ and a local **PostgreSQL 14+**. On macOS the test/run toolchain uses Xcode
  (if `xcode-select` points at CommandLineTools, prefix commands with
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`).
- **App**: JDK 21 (e.g. Android Studio's bundled JBR), the Android SDK, and Xcode for iOS. The Gradle
  wrapper (`app/gradlew`) handles Gradle itself.

## Quick start

### Run the server

```bash
# one-time
createdb sueldos_publicos

# build, migrate, ingest, serve
export DATABASE_HOST=127.0.0.1 DATABASE_NAME=sueldos_publicos
swift run App migrate --yes
swift run App ingest --file Retribuciones.xlsx     # -> Rows read: 320  Imported: 320  Rejected: 0
swift run App serve --hostname 127.0.0.1 --port 8080

# verify
curl "http://127.0.0.1:8080/api/v1/salaries?pageSize=1"   # -> { ..., "total": 304 }
```

Full guide: [`specs/001-data-ingestion-api/quickstart.md`](specs/001-data-ingestion-api/quickstart.md).

### Run the app

Start the server first (above). Android reaches it at `10.0.2.2:8080`, the iOS simulator at
`127.0.0.1:8080`.

```bash
cd app
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
./gradlew :composeApp:installDebug        # Android (running emulator)
```

For iOS, open `app/iosApp` in Xcode/Android Studio and run on a simulator. Full guide:
[`specs/002-salary-browser-app/quickstart.md`](specs/002-salary-browser-app/quickstart.md).

## Testing

```bash
# Server (Swift)
swift test

# App (Kotlin) — device-free logic tests
cd app && ./gradlew :composeApp:testDebugUnitTest
```

Test-Driven Development is mandatory (constitution Principle II): tests are written before the code
they cover.

## Principles

Development is governed by the [project constitution](.specify/memory/constitution.md): code quality,
test-first development, user-experience consistency, performance discipline, and minimal dependencies
(custom-first — third-party libraries only when necessary and well-established).
