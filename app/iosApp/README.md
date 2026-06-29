# iosApp

Thin iOS host for the shared Compose Multiplatform UI. The `.xcodeproj` is generated locally (it is
machine-specific and not committed); the Swift sources and `Info.plist` here are the stable parts.

## Generating / opening the Xcode project

1. Open the `app/` project in Android Studio (with the Kotlin Multiplatform plugin) — it will create
   and manage `iosApp.xcodeproj` wired to the `:composeApp` shared framework, **or** create a new
   Xcode "App" target in `iosApp/` and add these sources.
2. Add a "Run Script" build phase that builds the shared framework before compiling:
   ```sh
   cd "$SRCROOT/.."
   ./gradlew :composeApp:embedAndSignAppleFrameworkForXcode
   ```
   and add `$(SRCROOT)/../composeApp/build/xcode-frameworks/...` to the Framework Search Paths
   (Android Studio's KMP integration configures this automatically).
3. Set the target's Info.plist to `iosApp/iosApp/Info.plist` (it includes the ATS localhost exception
   needed to reach the local 001 server during development).

## Sources

- `iosApp/iOSApp.swift` — SwiftUI `@main` entry.
- `iosApp/ContentView.swift` — wraps `MainViewControllerKt.MainViewController()` from the
  `ComposeApp` framework in a `UIViewControllerRepresentable`.
- `iosApp/Info.plist` — bundle config + ATS exception for `127.0.0.1`.

## Running

Start the 001 server (`127.0.0.1:8080`), then run the iosApp target on an iOS simulator. The shared
Compose UI is identical to Android.
