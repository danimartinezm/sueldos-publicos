package info.danielmartinez.sueldos.state

/** App-root navigation state: the two screens of the browser. */
sealed interface Screen {
    data object List : Screen

    data class Detail(val id: String) : Screen
}
