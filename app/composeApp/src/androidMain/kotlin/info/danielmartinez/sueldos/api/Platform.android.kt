package info.danielmartinez.sueldos.api

/** Android emulator reaches the host machine's loopback via the alias 10.0.2.2. */
actual fun platformBaseUrl(): String = "http://10.0.2.2:8080/api/v1"
