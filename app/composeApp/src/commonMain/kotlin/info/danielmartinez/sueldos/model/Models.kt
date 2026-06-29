package info.danielmartinez.sueldos.model

/** Full record for one entry — drives the detail view (all available fields). */
data class PositionDetail(
    val id: String,
    val position: String,
    val body: String,
    val ministry: String,
    val salary: Double,
    val year: Int,
)

/** At-a-glance list item — only what the list shows, plus the id needed to open detail. */
data class PositionSummary(
    val id: String,
    val position: String,
    val salary: Double,
)

/** A page of results plus the total matching count, mirroring the API paging envelope. */
data class Page<T>(
    val items: List<T>,
    val page: Int,
    val pageSize: Int,
    val total: Int,
)

/** Projects a full detail into the lighter list summary. */
fun PositionDetail.toSummary(): PositionSummary =
    PositionSummary(id = id, position = position, salary = salary)
