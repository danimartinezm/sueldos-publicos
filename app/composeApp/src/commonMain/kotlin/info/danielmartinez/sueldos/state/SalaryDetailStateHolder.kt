package info.danielmartinez.sueldos.state

import info.danielmartinez.sueldos.api.NotFoundException
import info.danielmartinez.sueldos.api.SalaryApiClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** Drives the detail screen: fetches one record by id and maps failures to explicit states. */
class SalaryDetailStateHolder(
    private val api: SalaryApiClient,
    private val scope: CoroutineScope,
    private val id: String,
) {
    private val _state = MutableStateFlow(SalaryDetailUiState())
    val state: StateFlow<SalaryDetailUiState> = _state.asStateFlow()

    fun start() = load()

    fun retry() = load()

    private fun load() {
        _state.value = SalaryDetailUiState(status = DetailStatus.Loading)
        scope.launch {
            _state.value = try {
                SalaryDetailUiState(status = DetailStatus.Content(api.getById(id)))
            } catch (e: NotFoundException) {
                SalaryDetailUiState(status = DetailStatus.NotAvailable)
            } catch (t: Throwable) {
                SalaryDetailUiState(status = DetailStatus.Error)
            }
        }
    }
}
