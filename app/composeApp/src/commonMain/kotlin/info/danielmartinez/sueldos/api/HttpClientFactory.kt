package info.danielmartinez.sueldos.api

import io.ktor.client.HttpClient
import io.ktor.client.HttpClientConfig
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json

/** Shared client configuration (JSON + timeouts) applied by every platform engine. */
internal fun HttpClientConfig<*>.installDefaults() {
    install(ContentNegotiation) {
        json(
            Json {
                ignoreUnknownKeys = true
                isLenient = true
            }
        )
    }
    install(HttpTimeout) {
        requestTimeoutMillis = 15_000
        connectTimeoutMillis = 10_000
    }
}

/** Creates an HTTP client backed by the platform's engine (OkHttp on Android, Darwin on iOS). */
expect fun createHttpClient(): HttpClient
