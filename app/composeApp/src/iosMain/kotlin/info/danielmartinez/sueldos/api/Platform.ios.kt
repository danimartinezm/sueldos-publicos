package info.danielmartinez.sueldos.api

/** The iOS simulator shares the host network, so the local server is reachable at 127.0.0.1. */
actual fun platformBaseUrl(): String = "http://127.0.0.1:8080/api/v1"
