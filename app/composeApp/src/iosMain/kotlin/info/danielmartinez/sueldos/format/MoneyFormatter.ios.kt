package info.danielmartinez.sueldos.format

import platform.Foundation.NSNumber
import platform.Foundation.NSNumberFormatter
import platform.Foundation.NSNumberFormatterCurrencyStyle
import platform.Foundation.NSLocale

private val euroFormatter: NSNumberFormatter = NSNumberFormatter().apply {
    numberStyle = NSNumberFormatterCurrencyStyle
    locale = NSLocale("es_ES")
}

actual fun formatEuros(amount: Double): String =
    euroFormatter.stringFromNumber(NSNumber(double = amount)) ?: amount.toString()
