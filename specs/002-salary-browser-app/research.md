# Phase 0 Research: Public Salary Browser (Cross-Platform App)

All Technical Context unknowns are resolved below (Decision / Rationale / Alternatives), consistent
with the constitution (Custom-First, Minimal Dependencies, Test-First, Performance, UX Consistency).

## 1. Platform & UI framework

- **Decision**: Kotlin Multiplatform with a single shared `composeApp` module; Compose Multiplatform
  for the UI on both Android and iOS. Targets: `androidTarget`, `iosArm64`, `iosSimulatorArm64`,
  `iosX64`. Build with the Gradle wrapper on JDK 21 (Android Studio's bundled JBR at
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`).
- **Rationale**: User-mandated. One UI + one logic layer renders identically on both platforms,
  structurally satisfying the constitution's UX-consistency principle.
- **Alternatives considered**: Native SwiftUI + Android Compose (two UIs) — rejected (duplication,
  inconsistency risk). Flutter/React Native — rejected (not Kotlin/Compose).

## 2. Networking & JSON

- **Decision**: Ktor client with platform engines — **Darwin** on iOS, **OkHttp** on Android — plus
  `ContentNegotiation` + kotlinx.serialization for JSON. A `SalaryApiClient` in `commonMain` exposes
  `list(page, pageSize)` and `getById(id)` returning typed models.
- **Rationale**: Official JetBrains, well-established, idiomatic KMP networking — the constitution
  permits well-established dependencies when necessary, and robust cross-platform HTTP is necessary.
- **Alternatives considered**: Hand-rolled `expect/actual` over NSURLSession + HttpURLConnection and
  custom JSON parsing — rejected: multiplies platform-specific bugs for no real benefit on a simple
  read-only client.

## 3. Local-server reachability per platform (key integration detail)

- **Decision**: Base URL is platform-specific via `expect/actual`:
  - Android emulator → `http://10.0.2.2:8080` (the emulator's alias for the host loopback).
  - iOS simulator → `http://127.0.0.1:8080` (shares the host network).
  - Path prefix `/api/v1`. Base URL overridable (e.g., a build constant) for physical devices.
- **Rationale**: These are the standard host-loopback addresses for each emulator/simulator; making
  the base URL an `expect/actual` keeps the difference in one obvious place.
- **Cleartext HTTP**: the local server is plain HTTP. Android **debug** builds permit cleartext to the
  local host via a `network_security_config.xml` (limited to `10.0.2.2`/localhost); iOS adds an ATS
  exception for `127.0.0.1`/`NSAllowsLocalNetworking` in the app Info.plist. Production builds would
  use HTTPS and drop these exceptions.
- **Alternatives considered**: Hard-coding one URL — rejected (breaks one platform). Disabling ATS
  globally — rejected (too broad; scope the exception to localhost).

## 4. State management & navigation

- **Decision**: Custom, coroutine-driven **state holders** in `commonMain` exposing immutable UI
  state via `StateFlow` (e.g., `SalaryListStateHolder`, `SalaryDetailStateHolder`), collected in
  Compose with `collectAsState`. Navigation between the two screens is a custom sealed `Screen` state
  (`List` / `Detail(id)`) held at the app root, with platform back handled (Android back button / iOS
  swipe-back mapped to "return to list").
- **Rationale**: Two screens and simple flows do not justify a navigation or MVVM dependency;
  custom holders are small, fully understood, and trivially testable (Custom-First, Test-First).
- **Alternatives considered**: androidx.navigation / Voyager / Decompose, moko-mvvm — rejected as
  unnecessary weight for this scope.

## 5. Progressive loading (paging)

- **Decision**: Custom incremental paging in the list state holder: fetch page 1, then request the
  next page when the user scrolls near the end (tracked from the `LazyColumn` layout info). Page size
  50; append results; stop when `loaded >= total` (from the API's paging metadata). Guard against
  duplicate concurrent page requests.
- **Rationale**: Matches FR-003 and the performance budget; no KMP-native paging library is needed.
- **Alternatives considered**: Load-all-then-display — rejected (slow first paint, unbounded memory).

## 6. Spanish localization & currency formatting

- **Decision**: All user-facing strings centralized in a single `Strings` object in `commonMain`,
  written in Spanish (es-ES). Currency formatting is an `expect MoneyFormatter` with `actual`
  implementations: Android via `java.text.NumberFormat.getCurrencyInstance(Locale("es","ES"))`, iOS
  via `NSNumberFormatter` (style currency, locale `es_ES`) → e.g., `95.943,96 €`.
- **Rationale**: Single-language v1 doesn't need a resource/i18n framework; a centralized object is
  minimal and keeps copy consistent. Correct euro formatting requires platform locale facilities, so a
  thin `expect/actual` wrapper is the right amount of custom code.
- **Alternatives considered**: Compose Resources string catalog — deferred (worth it only when a
  second language is added). Manual string formatting of euros — rejected (locale-incorrect).

## 7. Testing strategy

- **Decision**: TDD across layers. `commonTest` with kotlin.test for: `SalaryApiClient` driven by
  Ktor `MockEngine` (success, paging metadata, 404, network error); state-holder transitions
  (loading → loaded, empty, error → retry, paging append, end-of-list) using kotlinx-coroutines-test;
  the money formatter; and Compose UI tests via `runComposeUiTest` (list shows position + salary,
  detail shows all fields, loading/empty/error states render, tap navigates). Android-specific UI runs
  use the Android unit-test/instrumented path as needed.
- **Rationale**: Satisfies Principle II; `MockEngine` lets the client be fully tested without a live
  server, and Compose UI tests assert the consistent UI contract.
- **Alternatives considered**: Manual testing only — rejected (violates the constitution).

## 8. Code quality tooling

- **Decision**: ktlint (formatting) and detekt (static analysis) wired into Gradle and run in CI; a
  failing check blocks merge (Principle I).
- **Rationale**: Automated, enforced quality gate as the constitution requires.
- **Alternatives considered**: Manual review only — rejected.

## 9. Build & run (environment)

- **Decision**: Use the Gradle wrapper with `org.gradle.java.home` pointed at the Android Studio JBR.
  Android runs on an emulator (`:composeApp:installDebug` / Android Studio); iOS runs the `iosApp`
  Xcode project on a simulator. The 001 server must be running locally first
  (`swift run App serve …` on `127.0.0.1:8080`).
- **Rationale**: No standalone JDK/Gradle/Kotlin is installed, but Android Studio provides the JBR and
  the Android SDK is present (`~/Library/Android/sdk`, android-36.1); Xcode provides the iOS toolchain.
- **Alternatives considered**: Installing a separate JDK/Gradle — unnecessary given the JBR + wrapper.
