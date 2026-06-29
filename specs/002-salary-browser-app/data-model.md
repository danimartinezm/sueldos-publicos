# Phase 1 Data Model: Public Salary Browser (Cross-Platform App)

Client-side models derived from the spec's Key Entities and the 001 API contract
(`Salary` / `SalaryPage`). All types live in `commonMain` and are immutable.

## Domain models

### PositionDetail

The full record for one entry (drives the detail view, FR-006). Maps 1:1 from the API `Salary`.

| Field | Type | Source (API) | Notes |
|-------|------|--------------|-------|
| `id` | String (UUID) | `id` | Stable identifier; used to fetch detail and as list key. |
| `position` | String | `position` | "Alto Cargo" title. |
| `body` | String | `body` | Organismo. |
| `ministry` | String | `ministry` | Ministerio. |
| `salary` | Double | `remuneration` | Euros; formatted for display via `MoneyFormatter`. |
| `year` | Int | `year` | Reporting year. |

### PositionSummary

The at-a-glance list item (drives the list, FR-002) — only what the list shows plus the id needed to
open detail.

| Field | Type | Notes |
|-------|------|-------|
| `id` | String (UUID) | Navigation key. |
| `position` | String | Shown as the primary line. |
| `salary` | Double | Shown as the secondary line, currency-formatted. |

> The list endpoint returns full `Salary` objects; the client projects each to a `PositionSummary`
> for rendering and keeps the `id` to request `PositionDetail` on tap. (A future API "summary"
> projection could reduce payload, but is not required at current scale.)

### Page<T>

Mirrors the API paging envelope for incremental loading.

| Field | Type | Notes |
|-------|------|-------|
| `items` | List<T> | This page's records. |
| `page` | Int | 1-based page number. |
| `pageSize` | Int | Items per page (50). |
| `total` | Int | Total matching records; `loaded >= total` ⇒ end of list. |

## UI state models

### SalaryListUiState

Single immutable state for the list screen, emitted by `SalaryListStateHolder` via `StateFlow`.

- `status`: `Loading` | `Content` | `Empty` | `Error(message)` — exactly one at a time (FR-008–010).
- `items`: `List<PositionSummary>` accumulated across loaded pages.
- `total`: `Int` — from paging metadata.
- `isLoadingMore`: `Bool` — a page append is in flight (footer spinner, not full-screen).
- `endReached`: `Bool` — `items.size >= total`.

Transitions: `Loading → Content` (first page) / `Empty` (total 0) / `Error`; `Content → Content`
(append page); `Error → Loading` on retry; near-end scroll triggers append unless `isLoadingMore` or
`endReached`.

### SalaryDetailUiState

State for the detail screen, emitted by `SalaryDetailStateHolder`.

- `status`: `Loading` | `Content(PositionDetail)` | `NotAvailable` | `Error(message)`.
- `NotAvailable` covers a record that 404s between list and detail (edge case in spec).

### Screen (navigation)

Sealed app-root state: `Screen.List` | `Screen.Detail(id: String)`. Back from `Detail` returns to
`List` preserving the list's scroll position and accumulated items (FR-007).

## Validation & formatting rules

- `salary` is rendered through `MoneyFormatter` (es-ES euros, e.g. `95.943,96 €`) everywhere it
  appears — never raw (FR-004, SC-003).
- Missing/blank optional string fields render as a graceful placeholder or are omitted — never broken
  or "null"-looking text (FR-011, SC-007).
- All labels and static copy come from the Spanish `Strings` object (consistency, FR-012).

## Mapping summary

`API Salary` → `PositionDetail` (direct) and → `PositionSummary` (id, position, remuneration→salary).
`API SalaryPage` → `Page<PositionDetail>`; the list state holder appends `PositionSummary`
projections and reads `total` to decide when paging ends.
