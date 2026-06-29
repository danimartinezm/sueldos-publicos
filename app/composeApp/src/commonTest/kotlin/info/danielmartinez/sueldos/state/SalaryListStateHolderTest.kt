package info.danielmartinez.sueldos.state

import info.danielmartinez.sueldos.FakeApi
import info.danielmartinez.sueldos.details
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class SalaryListStateHolderTest {

    @Test
    fun firstPageLoadsIntoContent() = runTest {
        val holder = SalaryListStateHolder(FakeApi(details(5)), CoroutineScope(UnconfinedTestDispatcher(testScheduler)), pageSize = 2)
        holder.start()
        advanceUntilIdle()

        val state = holder.state.value
        assertEquals(ListStatus.Content, state.status)
        assertEquals(2, state.items.size)
        assertEquals(5, state.total)
        assertFalse(state.endReached)
    }

    @Test
    fun loadMoreAppendsUntilEndReached() = runTest {
        val holder = SalaryListStateHolder(FakeApi(details(5)), CoroutineScope(UnconfinedTestDispatcher(testScheduler)), pageSize = 2)
        holder.start()
        advanceUntilIdle()

        holder.loadMore()
        advanceUntilIdle()
        assertEquals(4, holder.state.value.items.size)
        assertFalse(holder.state.value.endReached)

        holder.loadMore()
        advanceUntilIdle()
        assertEquals(5, holder.state.value.items.size)
        assertTrue(holder.state.value.endReached)

        // Further loadMore is a no-op once the end is reached.
        holder.loadMore()
        advanceUntilIdle()
        assertEquals(5, holder.state.value.items.size)
    }

    @Test
    fun emptyDatasetYieldsEmptyState() = runTest {
        val holder =
            SalaryListStateHolder(FakeApi(details(0)), CoroutineScope(UnconfinedTestDispatcher(testScheduler)))
        holder.start()
        advanceUntilIdle()

        assertEquals(ListStatus.Empty, holder.state.value.status)
        assertTrue(holder.state.value.endReached)
    }

    @Test
    fun errorThenRetryRecovers() = runTest {
        val api = FakeApi(details(3))
        val holder = SalaryListStateHolder(api, CoroutineScope(UnconfinedTestDispatcher(testScheduler)), pageSize = 2)

        api.failList = true
        holder.start()
        advanceUntilIdle()
        assertEquals(ListStatus.Error, holder.state.value.status)

        api.failList = false
        holder.retry()
        advanceUntilIdle()
        assertEquals(ListStatus.Content, holder.state.value.status)
        assertEquals(2, holder.state.value.items.size)
    }
}
