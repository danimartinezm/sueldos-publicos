package info.danielmartinez.sueldos

import info.danielmartinez.sueldos.api.NotFoundException
import info.danielmartinez.sueldos.api.SalaryApiClient
import info.danielmartinez.sueldos.model.Page
import info.danielmartinez.sueldos.model.PositionDetail

/** In-memory [SalaryApiClient] for state-holder tests, with toggles to simulate failures. */
class FakeApi(private val all: List<PositionDetail>) : SalaryApiClient {
    var failList: Boolean = false
    var failDetail: Boolean = false
    var notFound: Boolean = false

    override suspend fun list(page: Int, pageSize: Int): Page<PositionDetail> {
        if (failList) throw RuntimeException("network down")
        val from = (page - 1) * pageSize
        val slice =
            if (from >= all.size) emptyList()
            else all.subList(from, minOf(from + pageSize, all.size))
        return Page(items = slice, page = page, pageSize = pageSize, total = all.size)
    }

    override suspend fun getById(id: String): PositionDetail {
        if (notFound) throw NotFoundException()
        if (failDetail) throw RuntimeException("network down")
        return all.first { it.id == id }
    }
}

fun details(count: Int): List<PositionDetail> =
    (1..count).map { i ->
        PositionDetail(
            id = "id-$i",
            position = "CARGO $i",
            body = "Organismo $i",
            ministry = "Ministerio $i",
            salary = 1000.0 * i,
            year = 2025,
        )
    }
