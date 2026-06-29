# iosApp

iOS host for the shared Compose Multiplatform UI. The Xcode project is **generated from
`project.yml`** with [XcodeGen](https://github.com/yonsm/XcodeGen) (the `.xcodeproj` itself is not
committed). The stable, committed parts are `project.yml`, the Swift sources, and `Info.plist`.

## Generate the Xcode project

```bash
brew install xcodegen          # once
cd app/iosApp
xcodegen generate              # creates iosApp.xcodeproj
```

`project.yml` already wires everything:
- A pre-build script runs `./gradlew :composeApp:embedAndSignAppleFrameworkForXcode` to build the
  shared `ComposeApp` framework.
- `FRAMEWORK_SEARCH_PATHS` / `-framework ComposeApp` link it.
- `Info.plist` includes the ATS exception for `127.0.0.1` and the
  `CADisableMinimumFrameDurationOnPhone` key **required by Compose Multiplatform**.

## Run on a simulator

Start the 001 server (`127.0.0.1:8080`) first, then either:

- **Android Studio + Kotlin Multiplatform plugin**: after `xcodegen generate`, open `app/` — the
  `iosApp` run configuration appears; pick a simulator and Run.
- **Xcode**: open `iosApp.xcodeproj`, select a simulator, Run.
- **CLI** (full Xcode active, e.g. `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`):
  ```bash
  xcrun simctl boot "iPhone 16"
  xcodebuild -project iosApp.xcodeproj -scheme iosApp -configuration Debug \
    -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' \
    -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
  xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/iosApp.app
  xcrun simctl launch booted info.danielmartinez.sueldos
  ```

## Sources

- `iosApp/iOSApp.swift` — SwiftUI `@main` entry.
- `iosApp/ContentView.swift` — wraps `MainViewControllerKt.MainViewController()` from the
  `ComposeApp` framework in a `UIViewControllerRepresentable`.
- `iosApp/Info.plist` — bundle config, ATS exception, and the Compose-required frame-duration key.
- `project.yml` — XcodeGen spec (the source of truth for the Xcode project).
