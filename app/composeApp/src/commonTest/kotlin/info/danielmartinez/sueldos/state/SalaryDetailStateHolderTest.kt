package info.danielmartinez.sueldos.state

import info.danielmartinez.sueldos.FakeApi
import info.danielmartinez.sueldos.details
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs

class SalaryDetailStateHolderTest {

    @Test
    fun loadsRecordIntoContent() = runTest {
        val holder = SalaryDetailStateHolder(FakeApi(details(3)), CoroutineScope(UnconfinedTestDispatcher(testScheduler)), id = "id-2")
        holder.start()
        advanceUntilIdle()

        val status = holder.state.value.status
        assertIs<DetailStatus.Content>(status)
        assertEquals("id-2", status.detail.id)
        assertEquals("CARGO 2", status.detail.position)
    }

    @Test
    fun notFoundYieldsNotAvailable() = runTest {
        val api = FakeApi(details(3)).apply { notFound = true }
        val holder = SalaryDetailStateHolder(api, CoroutineScope(UnconfinedTestDispatcher(testScheduler)), id = "id-2")
        holder.start()
        advanceUntilIdle()

        assertEquals(DetailStatus.NotAvailable, holder.state.value.status)
    }

    @Test
    fun failureYieldsErrorThenRetryRecovers() = runTest {
        val api = FakeApi(details(3)).apply { failDetail = true }
        val holder = SalaryDetailStateHolder(api, CoroutineScope(UnconfinedTestDispatcher(testScheduler)), id = "id-1")
        holder.start()
        advanceUntilIdle()
        assertEquals(DetailStatus.Error, holder.state.value.status)

        api.failDetail = false
        holder.retry()
        advanceUntilIdle()
        assertIs<DetailStatus.Content>(holder.state.value.status)
    }
}
