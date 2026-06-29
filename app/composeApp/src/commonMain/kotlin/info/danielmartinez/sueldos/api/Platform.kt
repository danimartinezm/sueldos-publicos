package info.danielmartinez.sueldos.api

/**
 * Base URL of the 001 salary API, which differs per platform:
 * - Android emulator reaches the host loopback at `10.0.2.2`.
 * - iOS simulator shares the host network at `127.0.0.1`.
 */
expect fun platformBaseUrl(): String
