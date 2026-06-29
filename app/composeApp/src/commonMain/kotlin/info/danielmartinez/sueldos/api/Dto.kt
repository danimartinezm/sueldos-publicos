package info.danielmartinez.sueldos.api

import info.danielmartinez.sueldos.model.Page
import info.danielmartinez.sueldos.model.PositionDetail
import kotlinx.serialization.Serializable

/** Wire representation of an API `Salary` object. */
@Serializable
data class SalaryDto(
    val id: String,
    val position: String,
    val body: String,
    val ministry: String,
    val remuneration: Double,
    val year: Int,
)

/** Wire representation of an API `SalaryPage`. */
@Serializable
data class SalaryPageDto(
    val items: List<SalaryDto>,
    val page: Int,
    val pageSize: Int,
    val total: Int,
)

/** Wire representation of the API error envelope `{ error: { code, message } }`. */
@Serializable
data class ApiErrorDto(val error: ApiErrorBody)

@Serializable
data class ApiErrorBody(val code: String, val message: String)

fun SalaryDto.toModel(): PositionDetail =
    PositionDetail(
        id = id,
        position = position,
        body = body,
        ministry = ministry,
        salary = remuneration,
        year = year,
    )

fun SalaryPageDto.toModel(): Page<PositionDetail> =
    Page(items = items.map { it.toModel() }, page = page, pageSize = pageSize, total = total)
