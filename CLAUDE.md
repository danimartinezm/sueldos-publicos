<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan at
`specs/001-data-ingestion-api/plan.md`.

Active feature: **001-data-ingestion-api** — Vapor (Swift 6, strict concurrency) server that
ingests `Retribuciones.xlsx` into local PostgreSQL (via Fluent) and serves a read-only
`/api/v1` JSON API. XLSX parsing is custom (Foundation + Apple Compression) per the
constitution's Custom-First principle. See also `research.md`, `data-model.md`,
`contracts/openapi.yaml`, and `quickstart.md` in the same directory.
<!-- SPECKIT END -->
