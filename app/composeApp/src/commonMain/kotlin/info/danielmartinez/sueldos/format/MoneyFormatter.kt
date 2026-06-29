package info.danielmartinez.sueldos.format

/**
 * Formats a euro amount for display using es-ES conventions (e.g. `95943.96` → `95.943,96 €`).
 * Implemented per platform with the native locale facilities.
 */
expect fun formatEuros(amount: Double): String
