package info.danielmartinez.sueldos.state

import info.danielmartinez.sueldos.model.PositionDetail
import info.danielmartinez.sueldos.model.PositionSummary

/** Status of the list screen — exactly one is active at a time. */
sealed interface ListStatus {
    data object Loading : ListStatus

    data object Content : ListStatus

    data object Empty : ListStatus

    data object Error : ListStatus
}

/** Immutable state rendered by the list screen. */
data class SalaryListUiState(
    val status: ListStatus = ListStatus.Loading,
    val items: List<PositionSummary> = emptyList(),
    val total: Int = 0,
    val isLoadingMore: Boolean = false,
    val endReached: Boolean = false,
)

/** Status of the detail screen. */
sealed interface DetailStatus {
    data object Loading : DetailStatus

    data class Content(val detail: PositionDetail) : DetailStatus

    data object NotAvailable : DetailStatus

    data object Error : DetailStatus
}

/** Immutable state rendered by the detail screen. */
data class SalaryDetailUiState(
    val status: DetailStatus = DetailStatus.Loading,
)
