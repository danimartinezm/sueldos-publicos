# Feature Specification: Salary Data Ingestion & Query API

**Feature Branch**: `001-data-ingestion-api`

**Created**: 2026-06-26

**Status**: Draft

**Input**: User description: "Build an server app. It will load an input file, parse it to the database and implement an API to be consumed."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ingest the salary dataset from the input file (Priority: P1)

A data administrator provides the official public-salary spreadsheet (senior officials and their
remuneration) to the server. The server reads the file, validates and parses each record, and
stores it so the data becomes available for querying. This is the foundation: without ingested
data, there is nothing to serve.

**Why this priority**: No other capability has value until the dataset exists in the system. This
is the minimum viable slice — a single successful load produces queryable data.

**Independent Test**: Provide the sample input file, trigger ingestion, and confirm that the number
of stored records equals the number of valid rows in the file and that field values
(position, body, ministry, remuneration, year) match the source rows.

**Acceptance Scenarios**:

1. **Given** a valid input file with N data rows, **When** the administrator triggers ingestion,
   **Then** N salary records are stored and a summary reports N rows read, N imported, 0 rejected.
2. **Given** an input file containing some rows with missing or malformed required fields, **When**
   ingestion runs, **Then** valid rows are imported, invalid rows are rejected and reported with
   their row number and reason, and the import does not abort on a single bad row.
3. **Given** a dataset that has already been ingested, **When** the same dataset is ingested again,
   **Then** the result is idempotent — records are not silently duplicated, and the summary reflects
   how many were added versus already present.
4. **Given** a file that cannot be read or is not in the expected format, **When** ingestion is
   triggered, **Then** the operation fails fast with a clear error identifying the problem and no
   partial/corrupt data is left behind.

---

### User Story 2 - Query salary records through the API (Priority: P2)

A consuming application (the cross-platform client) or any authorized consumer requests salary data
through the API to display and explore it: listing records, retrieving a single record, and paging
through large result sets.

**Why this priority**: Ingested data has no external value until it can be consumed. This story
turns stored data into a usable service, but depends on US1 being complete.

**Independent Test**: With a known set of ingested records, call the API to list records and retrieve
one by identifier, and confirm the returned data matches what was ingested, with correct paging
metadata.

**Acceptance Scenarios**:

1. **Given** ingested data, **When** a consumer requests the list of records, **Then** the API
   returns records with position, body, ministry, remuneration, and year, plus paging information
   (current page, page size, total count).
2. **Given** a dataset larger than one page, **When** a consumer requests a specific page, **Then**
   only that page of records is returned and paging metadata lets the consumer fetch the next page.
3. **Given** an identifier for an existing record, **When** a consumer requests that record, **Then**
   the single matching record is returned.
4. **Given** an identifier that does not exist, **When** a consumer requests it, **Then** the API
   responds with a clear "not found" result rather than an error or empty success.

---

### User Story 3 - Filter, search, and aggregate salary data (Priority: P3)

A consumer narrows the dataset to answer real questions: salaries for a given ministry or body,
records for a specific year, positions matching a search term, and summary figures such as totals
and averages by ministry or year.

**Why this priority**: Filtering, search, and aggregation are what make the data genuinely useful for
transparency, but the service is already viable for an MVP with plain listing (US2).

**Independent Test**: With a known dataset, request records filtered by ministry and by year, search
by a position keyword, and request an aggregate (e.g., average remuneration per ministry); confirm
results match manual calculation over the known data.

**Acceptance Scenarios**:

1. **Given** ingested data, **When** a consumer filters by ministry and/or year, **Then** only
   records matching all supplied filters are returned, with paging applied.
2. **Given** ingested data, **When** a consumer searches by a position keyword, **Then** records
   whose position contains the term (case- and accent-insensitive) are returned.
3. **Given** ingested data, **When** a consumer requests aggregate figures grouped by ministry or by
   year, **Then** the API returns the count, total, and average remuneration per group.
4. **Given** filters that match no records, **When** the query runs, **Then** an empty result set
   with valid paging metadata is returned (not an error).

---

### Edge Cases

- A remuneration value that is blank, non-numeric, negative, or contains currency/thousands
  formatting: the row is rejected with a reason, or the value is normalized per documented rules.
- A position title that carries qualifying notes (e.g., partial-year service annotations): the
  record is stored with its full title; partial-period semantics are out of scope for v1.
- Duplicate logical records within a single file (same position, body, ministry, year): handled
  consistently with the idempotency rule rather than producing silent duplicates.
- A very large input file: ingestion completes within the performance budget and reports progress or
  a final summary without exhausting memory.
- Concurrent API reads during an ingestion run: consumers never see partial/corrupt data from an
  in-progress import.
- Requests with invalid paging or filter parameters (e.g., negative page, page size over the limit):
  rejected with a clear, actionable validation message.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST accept an input file containing public-salary records and ingest it on
  demand via an administrative action.
- **FR-002**: System MUST parse each data row into a salary record with the fields: position
  ("Alto Cargo"), body ("Organismo"), ministry ("Ministerio"), remuneration in euros
  ("Retribución"), and year ("Año").
- **FR-003**: System MUST validate each row, importing valid rows and rejecting invalid ones without
  aborting the whole import on a single bad row.
- **FR-004**: System MUST produce an ingestion summary reporting rows read, imported, rejected, and
  the row number plus reason for each rejection.
- **FR-005**: System MUST make ingestion idempotent for an already-loaded dataset so that re-running
  it does not create silent duplicate records.
- **FR-006**: System MUST persist ingested records durably so they remain available across restarts.
- **FR-007**: System MUST guarantee that a failed or partial ingestion leaves no corrupt or
  partially-loaded data visible to consumers.
- **FR-008**: System MUST expose an API that returns a paged list of salary records including all
  parsed fields and paging metadata (current page, page size, total count).
- **FR-009**: System MUST expose an API to retrieve a single salary record by its identifier and
  return a clear "not found" result when it does not exist.
- **FR-010**: System MUST allow API consumers to filter records by ministry, by body, and by year.
- **FR-011**: System MUST allow API consumers to search records by position title using
  case-insensitive and accent-insensitive matching.
- **FR-012**: System MUST provide aggregate figures (count, total, and average remuneration) grouped
  by ministry and by year.
- **FR-013**: System MUST validate API request parameters and reject invalid paging or filter values
  with clear, actionable error messages.
- **FR-014**: System MUST return data through a stable, versioned API contract so the consuming
  application can depend on it without breaking on internal changes.
- **FR-015**: System MUST handle and report errors with user-facing, non-technical messages and
  never expose internal storage or implementation details to consumers.

### Key Entities *(include if feature involves data)*

- **Salary Record**: A single official's remuneration entry. Key attributes: position title, body,
  ministry, remuneration amount (euros), reporting year, and a stable identifier. Relationships:
  belongs to one ministry and one body for a given year.
- **Ingestion Run**: A record of one load operation. Key attributes: source description, timestamp,
  counts (read, imported, rejected), and the list of rejection reasons. Relationship: produces or
  updates many Salary Records.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A data administrator can load the full provided dataset in a single operation and see a
  summary confirming every valid row was imported, with 100% of stored field values matching the
  source rows.
- **SC-002**: 100% of rows with missing or malformed required fields are rejected and individually
  reported, and no valid row is lost because of a neighbouring bad row.
- **SC-003**: Re-loading an already-ingested dataset results in zero duplicate records.
- **SC-004**: A consumer can retrieve any page of the dataset and a single record by identifier, with
  returned values matching the ingested data 100% of the time.
- **SC-005**: Filter, search, and aggregate results match an independent manual calculation over a
  known dataset 100% of the time.
- **SC-006**: Listing and query requests return results quickly enough for an interactive client
  experience under the expected dataset size and concurrent load (specific latency budget set in the
  implementation plan per the constitution's Performance Discipline principle).
- **SC-007**: During an ingestion run, no consumer ever receives partial or corrupted data.

## Assumptions

- The input file is the provided senior-officials salary spreadsheet (`Retribuciones.xlsx`) with
  columns Alto Cargo, Organismo, Ministerio, Retribución (€), and Año; additional yearly files of the
  same shape may be loaded later.
- Ingestion is an administrator-triggered operation (not a public, internet-facing upload) — for
  example a server-side/admin action — rather than an automated external feed in v1.
- The query API is read-only for consumers; consumers do not create, modify, or delete salary data.
- Because this is a public-transparency dataset, read access through the API is treated as public by
  default; if access restrictions are later required they will be specified separately.
- Remuneration is stored and reported in euros as published; currency conversion is out of scope.
- Partial-period service annotations embedded in some position titles are preserved as text but are
  not modeled as structured periods in v1.
- "Cross-platform application" is the primary intended consumer of this API but is specified and built
  separately; this feature only delivers the server and its API contract.

## Dependencies

- Requires the source salary dataset file to be available to the server for ingestion.
- The downstream cross-platform application depends on the stable API contract delivered here but is
  out of scope for this specification.
