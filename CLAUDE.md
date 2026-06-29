<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan at
`specs/002-salary-browser-app/plan.md`.

Active feature: **002-salary-browser-app** — Kotlin Multiplatform (iOS + Android) client with a
shared **Compose Multiplatform** UI, primary language **Spanish**. It consumes the local 001 API
(`/api/v1/salaries`) to show a paged list (position + salary) and a detail view (all fields), with
explicit loading/empty/error states. Networking via Ktor + kotlinx.serialization; navigation,
paging, state holders, strings, and currency formatting are custom (Custom-First). The KMP app
lives under `app/`. See `research.md`, `data-model.md`, `contracts/`, and `quickstart.md` in the
same spec directory.

Previous feature: **001-data-ingestion-api** — Vapor (Swift 6) server at the repo root serving the
salary API this app consumes; see `specs/001-data-ingestion-api/`.
<!-- SPECKIT END -->
