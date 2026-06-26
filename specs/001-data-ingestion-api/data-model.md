# Phase 1 Data Model: Salary Data Ingestion & Query API

Derived from the spec's Key Entities and Functional Requirements, and the confirmed shape of
`Retribuciones.xlsx`. Storage is PostgreSQL via Fluent; domain types are `Sendable` value types.

## Entity: SalaryRecord

One official's remuneration entry for a given year.

| Field | Type | Source column | Rules |
|-------|------|---------------|-------|
| `id` | UUID | (generated) | Stable identifier; primary key. |
| `position` | String | Alto Cargo | Required, non-empty, trimmed. Full title preserved (incl. annotations). |
| `body` | String | Organismo | Required, non-empty, trimmed. |
| `ministry` | String | Ministerio | Required, non-empty, trimmed. |
| `remuneration` | Decimal | Retribución (€) | Required; parses to a non-negative decimal; stored as `NUMERIC(12,2)` euros (no float). |
| `year` | Int | Año | Required; 4-digit plausible year (e.g. 1900–2100). |
| `positionNormalized` | String | (derived) | Lowercased, accent-stripped `position` for case/accent-insensitive search (FR-011). |
| `createdAt` | Timestamp | (system) | Set on first insert. |
| `updatedAt` | Timestamp | (system) | Updated on upsert. |

**Natural key (uniqueness / idempotency, FR-005)**: (`position`, `body`, `ministry`, `year`).
Enforced by a unique index; ingestion upserts on this key so re-loading produces zero duplicates
(SC-003).

**Indexes** (Performance Discipline, Principle IV):
- Unique: (`position`, `body`, `ministry`, `year`).
- Filter support: `ministry`, `body`, `year`.
- Search support: `positionNormalized` (e.g. trigram/`ILIKE`-friendly index).

**Validation summary** (enforced by `SalaryRowParser`, tested first):
- Missing/blank required string → reject row with reason `"missing <field>"`.
- Non-numeric/negative remuneration → reject with reason `"invalid remuneration"`.
- Non-numeric/implausible year → reject with reason `"invalid year"`.
- Rejections never abort the run (FR-003); each is reported with its 1-based row number (FR-004).

## Entity: IngestionRun

Audit record of one load operation (spec Key Entity).

| Field | Type | Rules |
|-------|------|-------|
| `id` | UUID | Primary key. |
| `source` | String | Description of the input (e.g. `Retribuciones.xlsx`). |
| `startedAt` | Timestamp | When the run began. |
| `finishedAt` | Timestamp? | When it completed (null if aborted). |
| `rowsRead` | Int | Total data rows read from the file. |
| `rowsImported` | Int | Rows inserted or updated. |
| `rowsRejected` | Int | Rows rejected. |
| `status` | Enum | `succeeded` \| `failed`. |
| `rejections` | JSON | Array of `{ rowNumber, reason }` (FR-004). |

**Relationship**: one `IngestionRun` produces/updates many `SalaryRecord`s. The run is committed in
the same transaction as the records; a `failed` run rolls back all record changes (FR-007), so no
partial data is ever visible (SC-007).

## Derived/transport types (not persisted)

- **IngestionSummary** — value returned by the ingest command: `rowsRead`, `rowsImported`,
  `rowsRejected`, `[RowRejection]`. Mirrors `IngestionRun` for CLI output.
- **RowRejection** — `{ rowNumber: Int, reason: String }`.
- **Page<T>** — API envelope: `{ items: [T], page: Int, pageSize: Int, total: Int }`.
- **SalaryDTO** — API representation of `SalaryRecord`: `id, position, body, ministry, remuneration,
  year` (omits internal `positionNormalized`, timestamps — FR-015).
- **AggregateGroup** — `{ key: String, count: Int, total: Decimal, average: Decimal }` for
  group-by-ministry / group-by-year results (FR-012).

## State & transitions

- `SalaryRecord`: created on first ingest of its natural key; updated (remuneration/derived fields)
  on subsequent ingests of the same key. No deletes in v1 (read-only API).
- `IngestionRun`: `running` (in-transaction) → `succeeded` (commit) or `failed` (rollback).
