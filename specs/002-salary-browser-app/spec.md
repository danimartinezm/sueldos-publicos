# Feature Specification: Public Salary Browser (Cross-Platform App)

**Feature Branch**: `002-salary-browser-app`

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "Build a cross-platform application to display a list of public sector positions and their salaries. The data will be collected from an API. The item list will only show the main data: position and salary. The details view will display all available data."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse positions and their salaries (Priority: P1)

A member of the public opens the application and immediately sees a scrollable list of public-sector
positions, each showing the two pieces of information that matter at a glance: the position title and
its salary. They can scroll through the full dataset, which loads progressively so the first results
appear quickly without waiting for everything.

**Why this priority**: The list is the heart of the product and the minimum viable experience — it
delivers the transparency value on its own, even before details exist.

**Independent Test**: Launch the app with the data service available and confirm a list of items
appears, each displaying a position and a salary, and that scrolling reveals additional items beyond
the first screen.

**Acceptance Scenarios**:

1. **Given** the data service is available, **When** the user opens the app, **Then** a list of
   positions is shown, each item displaying the position title and its salary, within a few seconds.
2. **Given** the list is longer than one screen, **When** the user scrolls to the end of the loaded
   items, **Then** more items load automatically and scrolling stays smooth.
3. **Given** salary values of varying size, **When** they are displayed, **Then** each is formatted as
   a readable monetary amount (currency-formatted) consistently across every item.
4. **Given** the user has scrolled down the list and navigates away and back, **When** they return,
   **Then** their place in the list is preserved.

---

### User Story 2 - View all details for a position (Priority: P2)

From the list, the user selects a position to open a details view that presents every available piece
of information about that entry — not just the title and salary, but all fields the data service
provides (e.g., the body/organisation, the ministry, the year, and the salary).

**Why this priority**: Details turn the at-a-glance list into a useful transparency tool, but the app
is already valuable with the list alone, so this builds on P1.

**Independent Test**: From a populated list, select an item and confirm the details view shows all
available fields for that exact entry, then return to the list.

**Acceptance Scenarios**:

1. **Given** a list of positions, **When** the user selects an item, **Then** a details view opens
   showing all available fields for that entry.
2. **Given** the details view is open, **When** the user goes back, **Then** they return to the list
   in the same position they left it.
3. **Given** an entry where some optional fields are absent in the data, **When** its details are
   shown, **Then** present fields are displayed and missing ones are handled gracefully (omitted or
   clearly marked), never showing broken or placeholder values.
4. **Given** the details view, **When** it is shown on any supported platform, **Then** the same
   fields, labels, and ordering are presented consistently.

---

### User Story 3 - Reliable experience across loading, empty, and error states (Priority: P3)

Whatever the network or data conditions, the user always understands what the app is doing. While
data loads they see a loading indicator; if there is nothing to show they see a clear empty message;
if the data service cannot be reached they see an understandable error with a way to retry — never a
blank screen, a crash, or a frozen interface.

**Why this priority**: Explicit, consistent state handling is required by the project's user-experience
standard, but the happy-path list/detail (P1/P2) demonstrate core value first.

**Independent Test**: Exercise each condition — slow load, empty dataset, and unreachable service —
and confirm the app shows the appropriate loading, empty, and error states, and that retry recovers
without restarting the app.

**Acceptance Scenarios**:

1. **Given** data is being retrieved, **When** results have not yet arrived, **Then** a loading
   indicator is shown instead of a blank screen.
2. **Given** the data service returns no records, **When** the list would be empty, **Then** a clear
   empty-state message is shown.
3. **Given** the data service is unreachable or returns an error, **When** the user is on the list or
   details view, **Then** a friendly, non-technical error message with a retry action is shown.
4. **Given** an error state with retry, **When** the user taps retry after connectivity is restored,
   **Then** the content loads and the error state is replaced, without an app restart.

---

### Edge Cases

- Very long position titles: the list keeps a consistent, readable layout (e.g., truncation) while the
  details view shows the full title.
- A very large dataset: scrolling and progressive loading remain responsive and memory-stable.
- Slow or intermittent connectivity: partial loads do not corrupt the list; the user is informed.
- Selecting an item whose underlying record is no longer available: the details view shows a clear
  "not available" state rather than failing silently.
- Mid-scroll data refresh: the user's position and already-viewed items remain coherent.
- Device rotation / window resize: layout adapts without losing the user's place or selection.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The application MUST retrieve public-sector salary records from the data service rather
  than from any bundled or hard-coded data.
- **FR-002**: The application MUST present records as a scrollable list where each item shows exactly
  the position title and its salary.
- **FR-003**: The application MUST load the list progressively (in pages/batches) so initial results
  appear without retrieving the entire dataset at once, and MUST load further items as the user
  scrolls.
- **FR-004**: The application MUST format salary values as readable monetary amounts consistently
  across all items and views.
- **FR-005**: The application MUST let the user open a details view for any list item.
- **FR-006**: The details view MUST display all fields available from the data service for that entry.
- **FR-007**: The application MUST allow the user to return from the details view to the list,
  preserving the list's scroll position and selection context.
- **FR-008**: The application MUST present a loading state while data is being retrieved.
- **FR-009**: The application MUST present a clear empty state when there are no records to show.
- **FR-010**: The application MUST present a friendly, non-technical error state with a retry action
  when the data service cannot be reached or returns an error, and retry MUST recover without an app
  restart.
- **FR-011**: The application MUST gracefully handle records with missing optional fields, never
  showing broken, blank, or placeholder-looking values.
- **FR-012**: The application MUST present the same fields, labels, ordering, and interaction patterns
  consistently across all supported platforms.
- **FR-013**: The application MUST remain responsive (no frozen or blocked interface) during data
  retrieval and scrolling.
- **FR-014**: The application MUST adapt its layout to different screen sizes and orientations without
  losing the user's place or current selection.

### Key Entities *(include if feature involves data)*

- **Position Summary**: the at-a-glance list item — a position title and its salary. Used to render
  the list (FR-002).
- **Position Detail**: the full record for one entry — all fields the data service exposes (e.g.,
  position, body/organisation, ministry, salary, year). Used to render the details view (FR-006).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: From opening the app, the user sees the first screen of positions (each with a position
  and salary) within 3 seconds on a normal connection.
- **SC-002**: A user can go from the list to a position's full details and back in no more than 2
  interactions.
- **SC-003**: 100% of list items display a position and a correctly currency-formatted salary; the
  details view shows every field present in the data for the selected entry.
- **SC-004**: The list scrolls through the entire dataset smoothly, with no perceptible stalls while
  additional pages load.
- **SC-005**: On every supported platform, the list and details views present the same fields and
  labels — verified by side-by-side comparison.
- **SC-006**: In each of the loading, empty, and error conditions, the app shows the corresponding
  state (never a blank screen or crash), and retry restores content in 100% of recoverable cases.
- **SC-007**: When some optional fields are missing for an entry, the details view still renders
  correctly with zero broken or placeholder-looking values.

## Assumptions

- The app consumes the read-only salary API delivered by feature `001-data-ingestion-api` (list,
  detail-by-identifier). It does not write, modify, or delete data.
- Access is public; no user accounts or authentication are required for v1.
- "All available data" means the fields the data service exposes per record (currently position,
  body/organisation, ministry, salary, and year); the details view adapts to whatever fields are
  returned.
- Salary is displayed in euros as published by the data service; no currency conversion.
- "Cross-platform" targets the major mobile platforms (iOS and Android) sharing common core logic for
  v1; additional platforms (desktop/web) are out of scope for this specification but must not be
  precluded by the design.
- Search, filtering, and aggregate/summary views (which the data service also supports) are out of
  scope for v1 — this feature is the list-and-detail browsing experience only.
- Offline caching is out of scope for v1; without connectivity the app shows the error/retry state.

## Dependencies

- Requires the salary API from feature `001-data-ingestion-api` to be reachable and to provide paged
  list and detail-by-identifier access.
- The set of fields shown in the details view depends on the fields the data service exposes.
