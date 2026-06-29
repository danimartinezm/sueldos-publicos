package info.danielmartinez.sueldos.ui

import androidx.compose.runtime.Composable

/** iOS navigation back is provided by the on-screen control in the detail screen, so this is a no-op. */
@Composable
actual fun PlatformBackHandler(enabled: Boolean, onBack: () -> Unit) {
    // No system back gesture to intercept here.
}
