package info.danielmartinez.sueldos.api

import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class SalaryApiClientTest {

    private fun client(handler: MockEngine): HttpClient =
        HttpClient(handler) { installDefaults() }

    private val pageJson = """
        {"items":[
          {"id":"a1","position":"PRESIDENTE DEL GOBIERNO","body":"Presidencia del Gobierno",
           "ministry":"Presidencia del Gobierno","remuneration":95943.96,"year":2025}],
         "page":1,"pageSize":50,"total":304}
    """.trimIndent()

    private val jsonHeaders = headersOf(HttpHeaders.ContentType, "application/json")

    @Test
    fun listDecodesAndMapsWithTotal() = runTest {
        val engine = MockEngine { _ -> respond(pageJson, HttpStatusCode.OK, jsonHeaders) }
        val api = KtorSalaryApiClient(client(engine), "http://test/api/v1")

        val page = api.list(page = 1, pageSize = 50)

        assertEquals(304, page.total)
        assertEquals(1, page.items.size)
        assertEquals("PRESIDENTE DEL GOBIERNO", page.items[0].position)
        assertEquals(95943.96, page.items[0].salary)
        assertEquals(2025, page.items[0].year)
    }

    @Test
    fun listSendsPagingParameters() = runTest {
        val engine = MockEngine { request ->
            assertEquals("2", request.url.parameters["page"])
            assertEquals("50", request.url.parameters["pageSize"])
            respond(pageJson, HttpStatusCode.OK, jsonHeaders)
        }
        val api = KtorSalaryApiClient(client(engine), "http://test/api/v1")
        api.list(page = 2, pageSize = 50)
    }

    @Test
    fun getByIdMapsRecord() = runTest {
        val detailJson = """
            {"id":"a1","position":"PRESIDENTE DEL GOBIERNO","body":"Presidencia del Gobierno",
             "ministry":"Presidencia del Gobierno","remuneration":95943.96,"year":2025}
        """.trimIndent()
        val engine = MockEngine { _ -> respond(detailJson, HttpStatusCode.OK, jsonHeaders) }
        val api = KtorSalaryApiClient(client(engine), "http://test/api/v1")

        val detail = api.getById("a1")

        assertEquals("a1", detail.id)
        assertEquals("Presidencia del Gobierno", detail.ministry)
    }

    @Test
    fun getByIdThrowsNotFoundOn404() = runTest {
        val errorJson = """{"error":{"code":"not_found","message":"x"}}"""
        val engine = MockEngine { _ -> respond(errorJson, HttpStatusCode.NotFound, jsonHeaders) }
        val api = KtorSalaryApiClient(client(engine), "http://test/api/v1")

        assertFailsWith<NotFoundException> { api.getById("missing") }
    }

    @Test
    fun listThrowsApiExceptionOnServerError() = runTest {
        val engine = MockEngine { _ -> respond("nope", HttpStatusCode.InternalServerError) }
        val api = KtorSalaryApiClient(client(engine), "http://test/api/v1")

        val failure = assertFailsWith<ApiException> { api.list(1, 50) }
        assertTrue(failure.statusCode == 500)
    }
}
