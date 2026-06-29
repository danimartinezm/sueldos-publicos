# Quickstart & Validation: Public Salary Browser (Cross-Platform App)

A runnable guide to build, run on both platforms, and validate the feature end-to-end. Implementation
details live in `tasks.md` and the implementation phase — this is a validation/run guide.

## Prerequisites

- **JDK 21** — use Android Studio's bundled JBR:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home` (set `org.gradle.java.home` in
  `app/gradle.properties`, or `export JAVA_HOME=…`).
- **Android SDK** — present at `~/Library/Android/sdk` (android-36.1). Set `sdk.dir` in
  `app/local.properties` or `ANDROID_HOME`.
- **Xcode** — for the iOS simulator build.
- **The 001 server must be running locally** before launching the app:
  ```bash
  # from repo root (server feature 001)
  DEVELOPER_DIR=/Applications/Xcode-26.5.0.app/Contents/Developer \
    DATABASE_HOST=127.0.0.1 DATABASE_NAME=sueldos_publicos \
    swift run App serve --hostname 127.0.0.1 --port 8080
  ```
  Confirm data is loaded: `curl http://127.0.0.1:8080/api/v1/salaries?pageSize=1` returns `total: 304`.

## Base URL per platform

- **Android emulator** reaches the host server at `http://10.0.2.2:8080/api/v1`.
- **iOS simulator** reaches it at `http://127.0.0.1:8080/api/v1`.

These are wired via `expect/actual`; debug builds permit cleartext HTTP to the local host only (see
research.md §3).

## Build & run — Android

```bash
cd app
./gradlew :composeApp:assembleDebug      # build
./gradlew :composeApp:installDebug       # install to a running emulator
```
Or open `app/` in Android Studio and Run the `composeApp` Android configuration on an emulator.

Expected: the app launches showing "Sueldos públicos" and a scrollable list of positions with
euro-formatted salaries.

## Build & run — iOS

Open `app/iosApp/iosApp.xcodeproj` in Xcode and run on a simulator (the shared framework builds via
Gradle automatically). Ensure the 001 server is reachable at `127.0.0.1:8080`.

Expected: the same list UI and behavior as Android (shared Compose UI).

## Run the tests (TDD — written first)

```bash
cd app
./gradlew :composeApp:allTests           # common + platform unit tests
# or, Android unit tests only:
./gradlew :composeApp:testDebugUnitTest
```

Expected: green suite covering the API client (Ktor `MockEngine`), state-holder transitions
(loading/empty/error/paging), currency formatting, and Compose UI tests for list/detail/states — all
authored before their implementation (Constitution Principle II).

## Validate the experience (maps to spec acceptance scenarios)

With the server running and the app open:

- **US1 list**: the first screen of positions appears within ~3 s; each row shows a position and a
  euro-formatted salary (SC-001, SC-003).
- **US1 paging**: scroll down — more rows load with a brief footer spinner; scrolling stays smooth
  (SC-004); loading stops at the end (304 records).
- **US2 detail**: tap a row — the detail view shows Cargo, Organismo, Ministerio, Retribución, Año;
  back returns to the same scroll position (FR-006/FR-007).
- **US3 loading**: relaunch — a loading indicator (not a blank screen) shows briefly.
- **US3 error + retry**: stop the 001 server, relaunch (or pull to retry) — an error message with
  "Reintentar" appears; restart the server and tap "Reintentar" — content loads without restarting the
  app (SC-006).
- **US3 empty**: point at an empty dataset (e.g., a fresh DB) — "No hay datos disponibles." is shown.
- **Consistency**: compare Android and iOS side by side — identical fields, labels, and ordering
  (SC-005).

## Done / acceptance

- App builds and runs on both Android (emulator) and iOS (simulator) against the local 001 server.
- List shows position + salary with progressive paging; detail shows all fields; back preserves
  position.
- Loading, empty, and error(+retry) states all behave per the UI contract.
- `./gradlew :composeApp:allTests` passes; ktlint/detekt clean.
