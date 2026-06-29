package info.danielmartinez.sueldos.state

import info.danielmartinez.sueldos.api.SalaryApiClient
import info.danielmartinez.sueldos.model.toSummary
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Drives the list screen: loads the first page, appends subsequent pages on demand, and exposes a
 * single immutable [SalaryListUiState] via [state]. Progressive paging stops at end-of-list.
 *
 * A [loading] flag is set synchronously before launching so a single request is in flight at a time,
 * independent of the dispatcher's eagerness.
 */
class SalaryListStateHolder(
    private val api: SalaryApiClient,
    private val scope: CoroutineScope,
    private val pageSize: Int = 50,
) {
    private val _state = MutableStateFlow(SalaryListUiState())
    val state: StateFlow<SalaryListUiState> = _state.asStateFlow()

    private var nextPage = 1
    private var loading = false
    private var currentJob: Job? = null

    /** Loads the first page if nothing has been loaded yet. Safe to call repeatedly. */
    fun start() {
        if (_state.value.items.isEmpty() && !loading) {
            loadFirstPage()
        }
    }

    /** Reloads from the first page (used by the error-state retry). */
    fun retry() = loadFirstPage()

    private fun loadFirstPage() {
        currentJob?.cancel()
        loading = true
        nextPage = 1
        _state.value = SalaryListUiState(status = ListStatus.Loading)
        currentJob = scope.launch {
            try {
                val page = api.list(page = 1, pageSize = pageSize)
                val summaries = page.items.map { it.toSummary() }
                _state.value =
                    if (summaries.isEmpty() && page.total == 0) {
                        SalaryListUiState(status = ListStatus.Empty, total = 0, endReached = true)
                    } else {
                        nextPage = 2
                        SalaryListUiState(
                            status = ListStatus.Content,
                            items = summaries,
                            total = page.total,
                            endReached = summaries.size >= page.total,
                        )
                    }
            } catch (t: Throwable) {
                _state.value = SalaryListUiState(status = ListStatus.Error)
            } finally {
                loading = false
            }
        }
    }

    /** Requests the next page when the user nears the end of the list. */
    fun loadMore() {
        val current = _state.value
        if (current.status != ListStatus.Content) return
        if (current.isLoadingMore || current.endReached || loading) return

        loading = true
        _state.value = current.copy(isLoadingMore = true)
        currentJob = scope.launch {
            try {
                val page = api.list(page = nextPage, pageSize = pageSize)
                val merged = _state.value.items + page.items.map { it.toSummary() }
                nextPage += 1
                _state.value = _state.value.copy(
                    status = ListStatus.Content,
                    items = merged,
                    total = page.total,
                    isLoadingMore = false,
                    endReached = merged.size >= page.total,
                )
            } catch (t: Throwable) {
                // A failed page append keeps existing content; just stop the spinner.
                _state.value = _state.value.copy(isLoadingMore = false)
            } finally {
                loading = false
            }
        }
    }
}
