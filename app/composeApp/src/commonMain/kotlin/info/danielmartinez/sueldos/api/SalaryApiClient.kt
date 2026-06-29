package info.danielmartinez.sueldos.api

import info.danielmartinez.sueldos.model.Page
import info.danielmartinez.sueldos.model.PositionDetail
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import io.ktor.http.HttpStatusCode
import io.ktor.http.isSuccess

/** Raised when a record id is not found (drives the detail "no disponible" state). */
class NotFoundException : Exception("Record not found")

/** Raised for any other non-success API response. */
class ApiException(val statusCode: Int) : Exception("API error: $statusCode")

/** Read-only access to the 001 salary API. Implementations may throw the exceptions above. */
interface SalaryApiClient {
    suspend fun list(page: Int, pageSize: Int): Page<PositionDetail>

    suspend fun getById(id: String): PositionDetail
}

/** Ktor-backed [SalaryApiClient]. The [client] and [baseUrl] are injectable for testing. */
class KtorSalaryApiClient(
    private val client: HttpClient = createHttpClient(),
    private val baseUrl: String = platformBaseUrl(),
) : SalaryApiClient {

    override suspend fun list(page: Int, pageSize: Int): Page<PositionDetail> {
        val response = client.get("$baseUrl/salaries") {
            parameter("page", page)
            parameter("pageSize", pageSize)
        }
        if (!response.status.isSuccess()) throw ApiException(response.status.value)
        return response.body<SalaryPageDto>().toModel()
    }

    override suspend fun getById(id: String): PositionDetail {
        val response = client.get("$baseUrl/salaries/$id")
        when {
            response.status == HttpStatusCode.NotFound -> throw NotFoundException()
            !response.status.isSuccess() -> throw ApiException(response.status.value)
        }
        return response.body<SalaryDto>().toModel()
    }
}
