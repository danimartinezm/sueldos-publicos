# Quickstart & Validation: Salary Data Ingestion & Query API

A runnable guide to build, deploy locally, ingest the dataset, and validate the feature end-to-end.
Implementation details (models, migrations, code) live in `tasks.md` and the implementation phase —
this is a validation/run guide.

## Prerequisites

- **Swift 6.3+** — `swift --version` (already present: 6.3.2).
- **PostgreSQL 14+** — not yet installed. Install and start (Homebrew, primary path):
  ```bash
  brew install postgresql@16
  brew services start postgresql@16
  ```
  Alternatives: Postgres.app (GUI) or a Docker container — see research.md §7.
- **Input file**: `Retribuciones.xlsx` in the repository root (already present).

## One-time database setup

```bash
createdb sueldos_publicos
# unaccent extension is enabled by a migration (CREATE EXTENSION IF NOT EXISTS unaccent)
```

Configure connection via environment (local defaults shown):

```bash
export DATABASE_HOST=127.0.0.1
export DATABASE_PORT=5432
export DATABASE_NAME=sueldos_publicos
export DATABASE_USERNAME="$(whoami)"
export DATABASE_PASSWORD=""
```

## Build

```bash
swift build -c release
```

Expected: a clean build under Swift 6 strict concurrency (no concurrency warnings/errors).

## Run migrations

```bash
swift run App migrate --yes
```

Expected: `salary_records` and `ingestion_runs` tables created; `unaccent` extension enabled.

## Ingest the dataset (admin action)

```bash
swift run App ingest --file Retribuciones.xlsx
```

Expected summary (per FR-004 / SC-001):
```
Rows read: 320  Imported: 320  Rejected: 0
```
Re-running the same command must report **0 duplicates created** (idempotency, SC-003) — the second
run imports/updates the same 320 rows without growing the table.

## Deploy locally

```bash
swift run App serve --hostname 127.0.0.1 --port 8080
```

Expected: server listening on `http://127.0.0.1:8080`.

## Validate the API (maps to spec acceptance scenarios)

```bash
# US2-1: paged list with metadata
curl -s "http://127.0.0.1:8080/api/v1/salaries?page=1&pageSize=50" | head

# US2-2: second page
curl -s "http://127.0.0.1:8080/api/v1/salaries?page=2&pageSize=50"

# US2-3/4: get by id (use an id from the list) / not-found
curl -s "http://127.0.0.1:8080/api/v1/salaries/<uuid>"
curl -s -o /dev/null -w "%{http_code}\n" "http://127.0.0.1:8080/api/v1/salaries/00000000-0000-0000-0000-000000000000"  # -> 404

# US3-1: filter by ministry + year
curl -s "http://127.0.0.1:8080/api/v1/salaries?ministry=Presidencia%20del%20Gobierno&year=2025"

# US3-2: accent/case-insensitive position search
curl -s "http://127.0.0.1:8080/api/v1/salaries?q=director"

# US3-3: aggregates
curl -s "http://127.0.0.1:8080/api/v1/aggregates/by-ministry"
curl -s "http://127.0.0.1:8080/api/v1/aggregates/by-year"

# FR-013: invalid parameter -> 400 with error envelope
curl -s "http://127.0.0.1:8080/api/v1/salaries?pageSize=9999"
```

Expected outcomes:
- List returns `{ items, page, pageSize, total: 320 }`.
- Get-by-id returns the matching record; unknown id returns `404` with `{ error: { code, message } }`.
- Filters/search return only matching records; `q=director` matches accented/case variants.
- Aggregates return `{ key, count, total, average }` per group, matching manual calculation (SC-005).
- Invalid `pageSize` returns `400` with the error envelope (no internal details, FR-015).

## Run the test suite (TDD — written first)

```bash
swift test
```

Expected: green suite covering the XLSX reader, row validation/rejection, ingestion
idempotency/atomicity, and the API contract — all authored before their implementation
(Constitution Principle II). Performance assertions check the budgets in plan.md.

## Done / acceptance

- Build is clean under strict concurrency; migrations applied.
- Full file ingests to 320 records; re-ingest creates 0 duplicates.
- All API endpoints behave per the curl checks above and `contracts/openapi.yaml`.
- `swift test` passes.
