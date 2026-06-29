package info.danielmartinez.sueldos

import androidx.compose.ui.window.ComposeUIViewController
import info.danielmartinez.sueldos.ui.App
import platform.UIKit.UIViewController

/** Entry point consumed by the iOS app (`iosApp`) to host the shared Compose UI. */
fun MainViewController(): UIViewController = ComposeUIViewController { App() }
