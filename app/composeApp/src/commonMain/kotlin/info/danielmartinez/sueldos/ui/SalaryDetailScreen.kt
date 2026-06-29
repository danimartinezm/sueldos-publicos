package info.danielmartinez.sueldos.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import info.danielmartinez.sueldos.api.SalaryApiClient
import info.danielmartinez.sueldos.format.formatEuros
import info.danielmartinez.sueldos.i18n.Strings
import info.danielmartinez.sueldos.model.PositionDetail
import info.danielmartinez.sueldos.state.DetailStatus
import info.danielmartinez.sueldos.state.SalaryDetailStateHolder
import info.danielmartinez.sueldos.ui.components.ErrorView
import info.danielmartinez.sueldos.ui.components.LoadingView
import info.danielmartinez.sueldos.ui.components.MessageView
import kotlinx.coroutines.CoroutineScope

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SalaryDetailScreen(
    api: SalaryApiClient,
    scope: CoroutineScope,
    id: String,
    onBack: () -> Unit,
) {
    val holder = remember(id) { SalaryDetailStateHolder(api, scope, id) }
    LaunchedEffect(id) { holder.start() }
    val state by holder.state.collectAsState()

    PlatformBackHandler(enabled = true, onBack = onBack)

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(Strings.appTitle) },
                navigationIcon = {
                    TextButton(onClick = onBack) { Text("‹ ${Strings.back}") }
                },
            )
        }
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            when (val status = state.status) {
                DetailStatus.Loading -> LoadingView()
                DetailStatus.NotAvailable -> MessageView(Strings.notAvailable)
                DetailStatus.Error -> ErrorView(Strings.detailError, onRetry = holder::retry)
                is DetailStatus.Content -> DetailContent(status.detail)
            }
        }
    }
}

@Composable
private fun DetailContent(detail: PositionDetail) {
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Field(Strings.labelPosition, detail.position)
        Field(Strings.labelBody, detail.body)
        Field(Strings.labelMinistry, detail.ministry)
        Field(Strings.labelSalary, formatEuros(detail.salary))
        Field(Strings.labelYear, detail.year.toString())
    }
}

@Composable
private fun Field(label: String, value: String) {
    Column(Modifier.fillMaxWidth()) {
        Text(label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
        Text(value.ifBlank { Strings.missingValue }, style = MaterialTheme.typography.bodyLarge)
    }
}
