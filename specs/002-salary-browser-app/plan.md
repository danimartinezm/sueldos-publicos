# Implementation Plan: Public Salary Browser (Cross-Platform App)

**Branch**: `main` (feature dir `002-salary-browser-app`) | **Date**: 2026-06-29 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-salary-browser-app/spec.md`

## Summary

Build a Kotlin Multiplatform (KMP) app for **iOS and Android** with a **Compose Multiplatform** UI
shared across both platforms. It consumes the read-only salary API from feature
`001-data-ingestion-api` (running on the local server) to show a progressively-loaded list of
positions and salaries, a detail view with every available field, and explicit loading/empty/error
states. The app's primary (and only, for v1) language is **Spanish**. A single shared codebase for
both logic and UI guarantees the cross-platform consistency required by the constitution.

## Technical Context

**Language/Version**: Kotlin 2.x (Multiplatform), targeting Android and iOS. Build on JDK 21
(Android Studio's bundled JBR) via the Gradle wrapper.

**Primary Dependencies**: Compose Multiplatform (UI, user-mandated); Ktor client (HTTP — Darwin
engine on iOS, OkHttp engine on Android) + kotlinx.serialization (JSON) + kotlinx.coroutines.
Navigation, paging, state holders, Spanish strings, and currency formatting are **custom** (no extra
library) per the constitution's Custom-First principle.

**Storage**: None on-device for v1 (no offline cache). Data comes live from the API.

**Testing**: kotlin.test in `commonTest`; Ktor `MockEngine` for API-client tests; kotlinx-coroutines
-test for state-holder tests; Compose UI test (`runComposeUiTest`) for screen/state tests. TDD is
mandatory (Constitution Principle II).

**Target Platform**: Android (minSdk 26, compileSdk 35+) and iOS (16+). Local development targets the
Android emulator and the iOS simulator against the locally-running 001 server.

**Project Type**: Mobile (cross-platform client). The server is feature 001 and is out of scope here.

**Performance Goals** (Constitution Principle IV — explicit budgets):
- First screen of results visible within 3 s on a normal connection (SC-001).
- List scrolling sustains ~60 fps with no perceptible stall while the next page loads (SC-004).
- Page size 50; list virtualized (lazy) so memory stays bounded regardless of dataset size.

**Constraints**:
- One shared Compose UI and one shared logic layer → identical fields, labels, ordering, and behavior
  across platforms (Principle III / FR-012).
- All user-facing text in Spanish, centralized so it is consistent and translatable later.
- Local-server access differs per platform: Android emulator reaches the host at `10.0.2.2`, iOS
  simulator at `127.0.0.1`; cleartext HTTP to the local server must be permitted in debug only.
- Explicit loading / empty / error(+retry) states everywhere; never a blank screen or crash (FR-008–010).
- UI must stay responsive during network/scroll work (FR-013); all I/O off the main thread via coroutines.

**Scale/Scope**: The 001 dataset is ~304 records today (low thousands across future yearly files);
two screens (list, detail). Single Spanish locale.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**I. Code Quality** — PASS (planned). ktlint + detekt configured and enforced; small,
single-responsibility files (api / model / state / ui / format / i18n). No dead code merged.

**II. Test-First Development (NON-NEGOTIABLE)** — PASS (planned). Tests precede implementation: API
client against Ktor `MockEngine`, state-holder transitions (loading→loaded→error, paging,
end-of-list), currency formatting, and Compose UI tests for list/detail/states. `tasks.md` orders
tests first.

**III. User Experience Consistency** — PASS (planned, and structurally enforced). A single shared
Compose UI renders both platforms, so fields/labels/ordering/states are identical by construction.
Spanish strings live in one place; loading/empty/error are reused composables.

**IV. Performance Discipline** — PASS (planned). Budgets above; `LazyColumn` virtualization + custom
paging keep scrolling smooth and memory bounded; measured against the budgets.

**V. Minimal Dependencies (Custom-First)** — PASS (justified). Compose MP and KMP are user-mandated.
Ktor + kotlinx.serialization + coroutines are well-established, official JetBrains libraries and are
necessary for robust cross-platform networking/JSON/async. Navigation, paging, state management,
Spanish strings, and currency formatting are implemented custom. Justifications in Complexity Tracking.

*No gate violations. Initial Constitution Check: PASS.*

## Project Structure

### Documentation (this feature)

```text
specs/002-salary-browser-app/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── api-consumption.md   # Subset of the 001 API this app depends on
│   └── ui-contract.md       # Screen + state + Spanish-label contract
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks output (not created here)
```

### Source Code (repository root)

The KMP app lives under `app/`, kept separate from the Swift server at the repo root so the two
constitutional parts stay decoupled and independently buildable.

```text
app/
├── settings.gradle.kts
├── build.gradle.kts
├── gradle.properties               # JDK/SDK config; org.gradle.java.home → Android Studio JBR
├── gradlew / gradle/wrapper/
├── composeApp/                     # shared KMP module (logic + Compose UI)
│   ├── build.gradle.kts
│   └── src/
│       ├── commonMain/kotlin/info/danielmartinez/sueldos/
│       │   ├── api/                # SalaryApiClient, DTOs, expect Platform (baseUrl)
│       │   ├── model/              # PositionSummary, PositionDetail, Page
│       │   ├── state/              # ListStateHolder, DetailStateHolder, Screen (nav)
│       │   ├── ui/                 # App, SalaryListScreen, SalaryDetailScreen, state composables
│       │   ├── format/             # expect MoneyFormatter (es-ES euros)
│       │   └── i18n/               # Strings (Spanish)
│       ├── androidMain/kotlin/…    # actual: baseUrl 10.0.2.2, OkHttp engine, java NumberFormat, MainActivity
│       ├── androidMain/AndroidManifest.xml  # debug cleartext to local server
│       ├── iosMain/kotlin/…        # actual: baseUrl 127.0.0.1, Darwin engine, NSNumberFormatter, entrypoint
│       └── commonTest/kotlin/…     # MockEngine client, state-holder, formatter, Compose UI tests
└── iosApp/                         # Xcode project hosting the shared framework (ATS localhost exception)
```

**Structure Decision**: Single shared `composeApp` module holding both the logic and the Compose UI,
with thin `androidMain`/`iosMain` `actual` implementations only where the platform differs (HTTP
engine, base URL, currency formatting, entrypoint). This maximizes shared code → maximal UX
consistency (Principle III) and keeps the client fully decoupled from the server, which it reaches
only through the published API contract.

## Complexity Tracking

> Dependency justifications required by Constitution Principle V (Minimal Dependencies).

| Dependency / Choice | Why Needed | Simpler Alternative Rejected Because |
|---------------------|-----------|--------------------------------------|
| Compose Multiplatform | User-mandated shared UI; one UI for both platforms | Per-platform native UI (SwiftUI + Android Compose) duplicates UI and risks inconsistency the constitution forbids |
| KMP + kotlinx.coroutines | User-mandated platform; coroutines required for off-main-thread I/O | Threads/callbacks by hand are error-prone and non-idiomatic |
| Ktor client (Darwin/OkHttp) | Well-established KMP HTTP with platform engines | Hand-rolled expect/actual NSURLSession + HttpURLConnection multiplies platform-specific networking bugs |
| kotlinx.serialization | Official Kotlin JSON; type-safe DTO decoding | Hand-rolled JSON parsing is error-prone as DTOs evolve |
| Test libs (ktor-client-mock, coroutines-test, compose ui-test) | Enable test-first per Principle II | No automated alternative; test-only scope |
| Custom: navigation, paging, state holders, Spanish strings, money formatter | Small, bounded, fully understood | Adding nav/paging/MVVM/i18n libraries is unjustified for two screens and one locale |
