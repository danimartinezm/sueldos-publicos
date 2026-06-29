# UI Contract: Screens, States & Spanish Labels

The app's external interface is its UI. This contract fixes what each screen shows and how states
behave, so the shared Compose UI renders identically on Android and iOS (Constitution Principle III /
FR-012). Copy is Spanish (primary language).

## Screen: Salary List (`Screen.List`) — User Story 1

- **Title**: "Sueldos públicos".
- **Each row shows exactly two things** (FR-002):
  - Primary line: `position` (truncate to keep a consistent row height; full title appears in detail).
  - Secondary line: `salary`, currency-formatted es-ES euros, e.g. `95.943,96 €` (FR-004).
- Rows are virtualized (lazy list). Tapping a row opens its detail (FR-005).
- **Progressive loading** (FR-003): page size 50; the next page loads as the user nears the end; a
  footer spinner shows while a page is loading; loading stops at end-of-list.
- Scroll position is preserved when returning from detail (FR-007).

### List states

| State | When | Shown |
|-------|------|-------|
| Loading | First page in flight | Centered loading indicator ("Cargando…") |
| Content | ≥1 record | The list (+ footer spinner while appending) |
| Empty | `total == 0` | "No hay datos disponibles." |
| Error | Request failed | "No se pudieron cargar los datos." + button "Reintentar" |

## Screen: Salary Detail (`Screen.Detail(id)`) — User Story 2

- Opened from a list row; fetches the full record by `id`.
- **Shows all available fields** (FR-006) with Spanish labels, consistent ordering:
  - "Cargo": `position` (full, untruncated)
  - "Organismo": `body`
  - "Ministerio": `ministry`
  - "Retribución": `salary` (es-ES euros)
  - "Año": `year`
- Missing optional fields render gracefully (omitted or "—"), never broken/"null" (FR-011).
- Back returns to the list at its prior position (FR-007).

### Detail states

| State | When | Shown |
|-------|------|-------|
| Loading | Fetch in flight | Loading indicator ("Cargando…") |
| Content | Record found | All fields above |
| NotAvailable | `404` for the id | "Este registro ya no está disponible." |
| Error | Request failed | "No se pudo cargar el detalle." + "Reintentar" |

## Cross-cutting UI rules

- Exactly one of {Loading, Content, Empty/NotAvailable, Error} is visible per screen at any time
  (FR-008–010); never a blank screen or crash.
- The UI never blocks the main thread during network or scroll work (FR-013).
- Layout adapts to screen size/orientation without losing scroll position or selection (FR-014).
- All static copy comes from the central Spanish `Strings` object; the same labels/order are used on
  both platforms (FR-012, SC-005).

## Spanish string keys (centralized)

`appTitle`, `loading`, `empty`, `listError`, `detailError`, `retry`, `notAvailable`,
`labelPosition` ("Cargo"), `labelBody` ("Organismo"), `labelMinistry` ("Ministerio"),
`labelSalary` ("Retribución"), `labelYear` ("Año").
