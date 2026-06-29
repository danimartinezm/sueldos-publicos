package info.danielmartinez.sueldos.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import info.danielmartinez.sueldos.format.formatEuros
import info.danielmartinez.sueldos.i18n.Strings
import info.danielmartinez.sueldos.model.PositionSummary
import info.danielmartinez.sueldos.state.ListStatus
import info.danielmartinez.sueldos.state.SalaryListStateHolder
import info.danielmartinez.sueldos.ui.components.ErrorView
import info.danielmartinez.sueldos.ui.components.LoadingView
import info.danielmartinez.sueldos.ui.components.MessageView

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SalaryListScreen(
    holder: SalaryListStateHolder,
    onItemClick: (String) -> Unit,
    lazyListState: LazyListState = rememberLazyListState(),
) {
    val state by holder.state.collectAsState()

    Scaffold(
        topBar = { TopAppBar(title = { Text(Strings.appTitle) }) }
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            when (state.status) {
                ListStatus.Loading -> LoadingView()
                ListStatus.Empty -> MessageView(Strings.empty)
                ListStatus.Error -> ErrorView(Strings.listError, onRetry = holder::retry)
                ListStatus.Content -> {
                    LazyColumn(state = lazyListState, modifier = Modifier.fillMaxSize()) {
                        items(state.items, key = { it.id }) { item ->
                            SalaryRow(item, onClick = { onItemClick(item.id) })
                            HorizontalDivider()
                        }
                        if (state.isLoadingMore) {
                            item {
                                Box(
                                    Modifier.fillMaxWidth().padding(16.dp),
                                    contentAlignment = Alignment.Center,
                                ) { CircularProgressIndicator() }
                            }
                        }
                    }

                    // Progressive loading: request the next page as the end approaches.
                    LaunchedEffect(lazyListState, state.items.size) {
                        snapshotFlow {
                            lazyListState.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: 0
                        }.collect { lastVisible ->
                            if (lastVisible >= state.items.size - 5) holder.loadMore()
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SalaryRow(item: PositionSummary, onClick: () -> Unit) {
    Column(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Text(
            text = item.position,
            style = MaterialTheme.typography.bodyLarge,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            text = formatEuros(item.salary),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.primary,
        )
    }
}
