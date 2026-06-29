package info.danielmartinez.sueldos.format

import java.text.NumberFormat
import java.util.Locale

private val euroFormat: NumberFormat = NumberFormat.getCurrencyInstance(Locale("es", "ES"))

actual fun formatEuros(amount: Double): String = euroFormat.format(amount)
