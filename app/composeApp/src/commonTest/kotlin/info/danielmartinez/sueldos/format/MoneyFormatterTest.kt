package info.danielmartinez.sueldos.format

import kotlin.test.Test
import kotlin.test.assertTrue

class MoneyFormatterTest {

    @Test
    fun formatsEurosWithEsEsGroupingAndSymbol() {
        val formatted = formatEuros(95943.96)
        // es-ES uses '.' for thousands and ',' for decimals, with a '€' symbol.
        assertTrue(formatted.contains("95.943,96"), "Unexpected grouping/decimals: $formatted")
        assertTrue(formatted.contains("€"), "Missing euro symbol: $formatted")
    }

    @Test
    fun formatsWholeAmountsWithTwoDecimals() {
        val formatted = formatEuros(1000.0)
        assertTrue(formatted.contains("1.000,00"), "Unexpected formatting: $formatted")
    }
}
