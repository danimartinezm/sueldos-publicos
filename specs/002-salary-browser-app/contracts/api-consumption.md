# Consumer Contract: 001 Salary API

The subset of the feature `001-data-ingestion-api` HTTP API that this client depends on. The
authoritative definition is `specs/001-data-ingestion-api/contracts/openapi.yaml`; this file records
exactly what the app relies on, so a breaking change there is caught here.

**Base URL**: `http://<host>:8080/api/v1` where `<host>` is `10.0.2.2` (Android emulator) or
`127.0.0.1` (iOS simulator).

## Endpoints used

### GET /salaries — paged list (User Story 1)

Query params used: `page` (1-based, default 1), `pageSize` (50).

Response `200` (`SalaryPage`):

```json
{
  "items": [
    {
      "id": "67490F33-9561-4842-98F8-182DC07D1ED8",
      "position": "PRESIDENTE DEL GOBIERNO",
      "body": "Presidencia del Gobierno",
      "ministry": "Presidencia del Gobierno",
      "remuneration": 95943.96,
      "year": 2025
    }
  ],
  "page": 1,
  "pageSize": 50,
  "total": 304
}
```

The client reads `items` (projected to list rows), and `total` to know when paging ends
(`loaded >= total`).

### GET /salaries/{id} — single record (User Story 2)

Response `200` (`Salary`): the object shown above (one element).

Response `404` (`Error` envelope) when the id does not exist — drives the detail "no disponible"
(NotAvailable) state:

```json
{ "error": { "code": "not_found", "message": "No salary record exists with that id." } }
```

## Fields consumed

`id`, `position`, `body`, `ministry`, `remuneration` (euros, shown as "salary"), `year`. The detail
view shows **all** of these (FR-006); the list shows `position` + `remuneration` only (FR-002).

## Error handling expectations

- Any non-2xx or transport failure → the app's error state with retry (FR-010). The `Error` envelope's
  `message` may inform the displayed (Spanish) copy, but the app never surfaces raw technical detail.
- `404` on detail specifically → NotAvailable state, not a generic error.

## Out of scope for this client (v1)

`GET /aggregates/by-ministry`, `GET /aggregates/by-year`, and the `ministry`/`body`/`year`/`q` filter
and search params exist in the API but are **not** used by this feature (search/filter/aggregates are
out of scope per the spec).
