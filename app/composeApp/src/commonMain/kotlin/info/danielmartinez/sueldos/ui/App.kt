package info.danielmartinez.sueldos.ui

import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import info.danielmartinez.sueldos.api.KtorSalaryApiClient
import info.danielmartinez.sueldos.api.SalaryApiClient
import info.danielmartinez.sueldos.state.SalaryListStateHolder
import info.danielmartinez.sueldos.state.Screen

/** App root: owns navigation state, the shared API client, and the list's preserved scroll state. */
@Composable
fun App(api: SalaryApiClient = KtorSalaryApiClient()) {
    MaterialTheme {
        val scope = rememberCoroutineScope()
        var screen by remember { mutableStateOf<Screen>(Screen.List) }

        // Held at the root so the list (scroll position + loaded pages) survives navigation.
        val listHolder = remember { SalaryListStateHolder(api, scope) }
        val listState = rememberLazyListState()
        LaunchedEffect(Unit) { listHolder.start() }

        when (val current = screen) {
            is Screen.List ->
                SalaryListScreen(
                    holder = listHolder,
                    onItemClick = { id -> screen = Screen.Detail(id) },
                    lazyListState = listState,
                )

            is Screen.Detail ->
                SalaryDetailScreen(
                    api = api,
                    scope = scope,
                    id = current.id,
                    onBack = { screen = Screen.List },
                )
        }
    }
}
