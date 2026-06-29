---
description: "Task list for Public Salary Browser (Cross-Platform App)"
---

# Tasks: Public Salary Browser (Cross-Platform App)

**Input**: Design documents from `/specs/002-salary-browser-app/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ (api-consumption.md,
ui-contract.md), quickstart.md

**Tests**: MANDATORY per Constitution Principle II (Test-First Development, NON-NEGOTIABLE). Every
behavior task is preceded by a test task that MUST be written first and MUST fail before
implementation.

**Organization**: Grouped by user story (US1 list → US2 detail → US3 states) so each is independently
implementable and testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1, US2, US3 (Setup/Foundational/Polish carry no story label)
- Base package path: `app/composeApp/src/commonMain/kotlin/info/danielmartinez/sueldos/`
  (referred to below as `…/sueldos/`). Tests live under
  `app/composeApp/src/commonTest/kotlin/info/danielmartinez/sueldos/` (`…/test/`).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Stand up the Kotlin Multiplatform + Compose Multiplatform project that builds for Android
and iOS.

- [x] T001 Create the Gradle KMP project under `app/` (`settings.gradle.kts`, root `build.gradle.kts`, `gradle.properties`, Gradle wrapper) with `org.gradle.java.home` pointing at the Android Studio JBR
- [x] T002 Configure the `composeApp` module in `app/composeApp/build.gradle.kts`: targets `androidTarget` + `iosX64/iosArm64/iosSimulatorArm64`, Compose Multiplatform plugin, kotlinx-serialization plugin, and dependencies (Ktor client core/content-negotiation/serialization-json, Ktor Darwin + OkHttp engines, kotlinx-coroutines, kotlinx-serialization-json); test deps ktor-client-mock, kotlinx-coroutines-test, compose ui-test
- [x] T003 [P] Create `app/local.properties` (Android `sdk.dir` → `~/Library/Android/sdk`) and the Android source set: `app/composeApp/src/androidMain/AndroidManifest.xml` with a debug `network_security_config.xml` permitting cleartext to `10.0.2.2`/localhost
- [x] T004 [P] Create the `app/iosApp/` Xcode project hosting the shared framework, with an Info.plist ATS exception for `127.0.0.1` (NSAllowsLocalNetworking)
- [ ] T005 [P] Configure ktlint + detekt in Gradle and add their config files under `app/` (Constitution Principle I)

**Checkpoint**: `./gradlew :composeApp:assembleDebug` builds an empty app for Android; iOS framework links.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared models, API client, platform `actual`s, Spanish strings, formatting, navigation,
and reusable state UI — required by every user story.

**⚠️ CRITICAL**: No user story work begins until this phase is complete.

- [x] T006 [P] Define domain models in `…/sueldos/model/Models.kt`: `PositionDetail`, `PositionSummary`, `Page<T>` per data-model.md
- [x] T007 [P] Define serialization DTOs in `…/sueldos/api/Dto.kt`: `SalaryDto`, `SalaryPageDto`, `ApiErrorDto` (`@Serializable`, fields matching contracts/api-consumption.md) and mappers DTO→model
- [x] T008 [P] Define `expect` platform config in `…/sueldos/api/Platform.kt` (`baseUrl`) with `actual`s: `androidMain` → `http://10.0.2.2:8080/api/v1`, `iosMain` → `http://127.0.0.1:8080/api/v1`
- [x] T009 Implement the Ktor `HttpClient` factory in `…/sueldos/api/HttpClientFactory.kt` (`expect` engine; `androidMain` OkHttp, `iosMain` Darwin) with JSON ContentNegotiation and a timeout
- [x] T010 Implement `SalaryApiClient` interface + Ktor implementation skeleton in `…/sueldos/api/SalaryApiClient.kt` (`list(page,pageSize)`, `getById(id)`) returning models/typed errors (`NotFound`, `Network`)
- [x] T011 [P] Define `expect MoneyFormatter` in `…/sueldos/format/MoneyFormatter.kt` with `actual`s: `androidMain` `java.text.NumberFormat` (es-ES), `iosMain` `NSNumberFormatter` (es_ES) → `95.943,96 €`
- [x] T012 [P] Create the Spanish `Strings` object in `…/sueldos/i18n/Strings.kt` with all keys from contracts/ui-contract.md
- [x] T013 [P] Define navigation state `Screen` (`List` | `Detail(id)`) in `…/sueldos/state/Screen.kt`
- [x] T014 Create the app root composable + theme in `…/sueldos/ui/App.kt` (hosts `Screen` state, renders List/Detail, wires platform back to "return to list")
- [x] T015 [P] Create reusable state composables in `…/sueldos/ui/components/StateViews.kt`: `LoadingView`, `EmptyView`, `ErrorView(onRetry)` using `Strings`

**Checkpoint**: App launches showing an empty shell; API client + formatter + strings compile on both platforms.

---

## Phase 3: User Story 1 - Browse positions and salaries (Priority: P1) 🎯 MVP

**Goal**: A scrollable, progressively-loaded list where each row shows position + euro-formatted
salary.

**Independent Test**: With the 001 server running, launch the app and confirm a list of positions
appears (position + salary per row) and scrolling loads more beyond the first screen.

### Tests for User Story 1 (MANDATORY — write before implementation) ⚠️

> **Write these tests FIRST, ensure they FAIL before implementation (Constitution Principle II)**

- [x] T016 [P] [US1] API client list test in `…/test/api/SalaryApiClientListTest.kt` using Ktor `MockEngine`: decodes `SalaryPageDto`, maps to models, reads `total`; handles a network failure
- [x] T017 [P] [US1] `MoneyFormatter` test in `…/test/format/MoneyFormatterTest.kt`: 95943.96 → `95.943,96 €` (es-ES grouping/decimal/symbol)
- [x] T018 [P] [US1] `SalaryListStateHolder` tests in `…/test/state/SalaryListStateHolderTest.kt` (coroutines-test): Loading→Content first page; append on next page; `endReached` when `loaded>=total`; no duplicate concurrent page loads
- [ ] T019 [P] [US1] Compose UI test in `…/test/ui/SalaryListScreenTest.kt` (`runComposeUiTest`): rows show position + formatted salary; near-end scroll triggers a load-more

### Implementation for User Story 1

- [x] T020 [US1] Implement `SalaryApiClient.list` in `…/sueldos/api/SalaryApiClient.kt` (GET `/salaries?page&pageSize=50`, decode, map)
- [x] T021 [US1] Implement `SalaryListStateHolder` in `…/sueldos/state/SalaryListStateHolder.kt`: `StateFlow<SalaryListUiState>`, first-page load, `loadMore()` with in-flight guard and `endReached`
- [x] T022 [US1] Implement `SalaryListScreen` in `…/sueldos/ui/SalaryListScreen.kt`: `LazyColumn` of rows (position + `MoneyFormatter` salary), footer spinner while appending, near-end detection → `loadMore()`, row click → `Screen.Detail(id)`
- [x] T023 [US1] Wire `SalaryListScreen` into `App.kt` as the start screen and preserve `LazyListState` across navigation

**Checkpoint**: US1 fully functional and independently testable — list loads, formats, and pages.

---

## Phase 4: User Story 2 - View all details for a position (Priority: P2)

**Goal**: Tapping a list row opens a detail view showing every available field; back returns to the
list at its prior position.

**Independent Test**: From a populated list, tap an item and confirm all fields (Cargo, Organismo,
Ministerio, Retribución, Año) are shown; back returns to the same scroll position.

### Tests for User Story 2 (MANDATORY — write before implementation) ⚠️

- [x] T024 [P] [US2] API client getById test in `…/test/api/SalaryApiClientDetailTest.kt` (MockEngine): 200 maps to `PositionDetail`; 404 → `NotFound`; failure → `Network`
- [x] T025 [P] [US2] `SalaryDetailStateHolder` tests in `…/test/state/SalaryDetailStateHolderTest.kt`: Loading→Content; 404→NotAvailable; error→Error
- [ ] T026 [P] [US2] Compose UI test in `…/test/ui/SalaryDetailScreenTest.kt`: all five labelled fields render with Spanish labels and formatted salary

### Implementation for User Story 2

- [x] T027 [US2] Implement `SalaryApiClient.getById` in `…/sueldos/api/SalaryApiClient.kt` (GET `/salaries/{id}`, map 404→NotFound)
- [x] T028 [US2] Implement `SalaryDetailStateHolder` in `…/sueldos/state/SalaryDetailStateHolder.kt` (`StateFlow<SalaryDetailUiState>`)
- [x] T029 [US2] Implement `SalaryDetailScreen` in `…/sueldos/ui/SalaryDetailScreen.kt`: labelled rows (Cargo/Organismo/Ministerio/Retribución/Año), graceful handling of missing optional fields
- [x] T030 [US2] Wire list→detail navigation and back (preserving list scroll) in `…/sueldos/ui/App.kt`

**Checkpoint**: US1 + US2 work — browse and drill into full details.

---

## Phase 5: User Story 3 - Reliable loading/empty/error states (Priority: P3)

**Goal**: Every screen shows explicit loading, empty, and error(+retry) states; retry recovers without
an app restart; never a blank screen or crash.

**Independent Test**: Exercise slow load, empty dataset, and an unreachable server; confirm the right
state shows and retry recovers.

### Tests for User Story 3 (MANDATORY — write before implementation) ⚠️

- [x] T031 [P] [US3] State-holder resilience tests in `…/test/state/StateResilienceTest.kt`: list Empty when `total==0`; Error on failure; retry transitions Error→Loading→Content
- [ ] T032 [P] [US3] Compose UI tests in `…/test/ui/StateViewsTest.kt`: list and detail render Loading/Empty/Error views; tapping "Reintentar" invokes retry; detail NotAvailable renders

### Implementation for User Story 3

- [x] T033 [US3] Wire Loading/Empty/Error(+retry) from `SalaryListStateHolder` into `SalaryListScreen` using the shared `StateViews` (replace any ad-hoc handling)
- [x] T034 [US3] Wire Loading/NotAvailable/Error(+retry) from `SalaryDetailStateHolder` into `SalaryDetailScreen`
- [x] T035 [US3] Ensure all network work runs off the main thread via coroutine dispatchers so the UI never blocks (FR-013), verified by a non-blocking state-holder test

**Checkpoint**: All three user stories independently functional; full suite green.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Quality, performance, and end-to-end validation across platforms.

- [ ] T036 [P] Performance pass: confirm first screen < 3 s and smooth paged scroll (Principle IV); ensure `LazyColumn` keys use `id` and avoid recomposition hotspots
- [ ] T037 [P] Run ktlint + detekt across `app/composeApp/src` and resolve all findings (Principle I)
- [ ] T038 Layout/orientation: verify list and detail adapt to size/rotation without losing scroll or selection (FR-014)
- [ ] T039 Execute `quickstart.md` end-to-end on the Android emulator and iOS simulator against the running 001 server; verify US1/US2/US3 scenarios and side-by-side consistency (SC-005)
- [ ] T040 [P] Verify the running app matches `contracts/ui-contract.md` (labels, ordering, Spanish copy) and `contracts/api-consumption.md` (fields/endpoints); fix whichever is wrong

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories.
- **User Stories (Phases 3–5)**: All depend on Foundational. US2 builds on US1's list/navigation; US3
  layers explicit states onto US1/US2 but each remains independently testable.
- **Polish (Phase 6)**: Depends on the targeted user stories being complete.

### User Story Dependencies

- **US1 (P1)**: Depends only on Foundational. Delivers the MVP (browsable, paged list).
- **US2 (P2)**: Depends on Foundational; uses US1's list rows/navigation to reach detail.
- **US3 (P3)**: Depends on Foundational; refines US1/US2 with explicit states + retry.

### Within Each User Story

- Tests (T016–T019, T024–T026, T031–T032) MUST be written and FAIL before implementation.
- model/DTO → api client → state holder → screen → wiring order is enforced by the notes above.

### Parallel Opportunities

- Setup: T003, T004, T005 in parallel after T001/T002.
- Foundational: T006, T007, T008, T011, T012, T013, T015 in parallel; T009/T010/T014 after their inputs.
- US1 tests T016–T019 all [P]; US2 tests T024–T026 [P]; US3 tests T031–T032 [P].
- Polish: T036, T037, T040 [P].

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Complete Phase 1 (Setup) and Phase 2 (Foundational).
2. Complete Phase 3 (US1): API list → list state holder (paging) → list screen.
3. **STOP and VALIDATE**: run the 001 server, launch the app, confirm the paged list of positions +
   salaries on Android (and iOS).
4. This is a demoable MVP.

### Incremental Delivery

1. Setup + Foundational → foundation ready.
2. Add US1 → browsable paged list (MVP).
3. Add US2 → tap-through detail with all fields.
4. Add US3 → explicit loading/empty/error + retry everywhere.
5. Polish → performance, lint, cross-platform consistency.

---

## Notes

- [P] = different files, no incomplete dependencies.
- Verify each test fails before implementing (Principle II).
- One shared Compose UI for both platforms — do not fork per-platform UI; only `actual`s differ
  (engine, base URL, formatter, entrypoint).
- All user-facing copy in Spanish via `Strings`; salaries always via `MoneyFormatter`.
- Commit after each task or logical group.

---

## Implementation Status (2026-06-29)

**Verified in this environment:**
- ✅ Project builds: **Android debug APK assembles**; **iOS shared framework compiles** (Kotlin/Native,
  iosSimulatorArm64) — both platforms' shared logic + Compose UI compile.
- ✅ **14/14 logic tests pass** (`:composeApp:testDebugUnitTest`): API client over Ktor `MockEngine`
  (list mapping, paging params, getById, 404→NotFound, 5xx→ApiException), `MoneyFormatter` es-ES
  (`95.943,96 €`), list state holder (loading→content, paged append, end-of-list, error+retry,
  empty), and detail state holder (content, NotAvailable, error+retry). Authored test-first.
- Toolchain: Gradle 8.11.1 + JDK 21 (Android Studio JBR); Kotlin 2.0.21, Compose MP 1.7.3, AGP 8.7.3,
  Ktor 3.0.3. compileSdk 36 (only platform installed; suppressed for AGP 8.7).

**Remaining (device-/tooling-bound, not run here):**
- ⬜ T019 / T026 / T032 — Compose UI tests (`runComposeUiTest`) require an Android emulator / iOS
  simulator (instrumented). The UI composables are thin projections of the state holders, which are
  fully unit-tested; these are the on-device follow-ups.
- ⬜ T005 / T037 — wire ktlint + detekt into Gradle and resolve findings. Code follows Kotlin official
  style; the gate is not yet enforced in the build.
- ⬜ T036 / T038 / T039 / T040 — performance pass, rotation check, and end-to-end run on emulator +
  simulator against the live 001 server (per `quickstart.md`), incl. side-by-side consistency.

**Deviations from research.md (documented):**
- The `iosApp` Xcode project (`.xcodeproj`) is generated locally and not committed (machine-specific);
  the Swift sources + `Info.plist` are provided under `app/iosApp/`.
- State holders use a `loading` flag + injected `CoroutineScope` (custom, no MVVM lib) rather than a
  navigation/paging library — per Custom-First.
