package info.danielmartinez.sueldos.ui

import androidx.compose.runtime.Composable

/**
 * Routes the platform's "back" gesture to [onBack] when [enabled]. On Android this is the hardware/
 * gesture back; on iOS navigation back is provided by the on-screen control, so the actual is a no-op.
 */
@Composable
expect fun PlatformBackHandler(enabled: Boolean, onBack: () -> Unit)
