<!--
SYNC IMPACT REPORT
Version change: (uninitialized template) → 1.0.0
Bump rationale: Initial ratification — first concrete constitution replacing the template.

Modified principles: N/A (initial definition)
Added principles:
  - I. Code Quality
  - II. Test-First Development (NON-NEGOTIABLE)
  - III. User Experience Consistency
  - IV. Performance Discipline
  - V. Minimal Dependencies (Custom-First)
Added sections:
  - Architecture & Technology Constraints
  - Development Workflow & Quality Gates
Removed sections: None

Templates requiring updates:
  - ✅ .specify/templates/tasks-template.md (tests promoted from OPTIONAL to MANDATORY to match Principle II)
  - ✅ .specify/templates/plan-template.md (Constitution Check is generic; no edit required, verified aligned)
  - ✅ .specify/templates/spec-template.md (no principle conflicts; verified aligned)
  - ✅ .specify/templates/checklist-template.md (verified aligned)

Follow-up TODOs: None
-->

# Sueldos Públicos Constitution

## Core Principles

### I. Code Quality

Code MUST be readable, consistent, and self-explanatory before it is clever. Every
contribution MUST adhere to a single, documented style for each part of the project,
enforced by an automated linter and formatter that run in CI; merges MUST be blocked on
lint or format failures. Public functions, types, and modules MUST have clear names and
documented intent; comments explain *why*, not *what*. Cyclomatic complexity and function
length SHOULD be kept low — prefer small, single-responsibility units. Dead code,
commented-out blocks, and TODO-without-owner markers MUST NOT be merged.

**Rationale**: A public-transparency project lives or dies by trust and maintainability.
Uniform, low-complexity code keeps the codebase auditable by contributors and reviewers and
reduces the surface for defects.

### II. Test-First Development (NON-NEGOTIABLE)

Test-Driven Development is mandatory. For every behavior change the cycle MUST be:
write the test → confirm it fails for the right reason → implement → confirm it passes →
refactor. Tests MUST be authored and committed *before* the implementation they cover, and
review MUST be able to verify this ordering from the change history. No production code path
may be merged without a failing-then-passing test that exercises it. Every bug fix MUST
begin with a regression test that reproduces the defect. CI MUST run the full test suite on
every change, and a red suite MUST block merge.

**Rationale**: Tests written first define the contract, prevent regressions in salary data
and calculations where correctness is non-negotiable, and give contributors a safety net for
fearless refactoring.

### III. User Experience Consistency

The cross-platform application MUST present consistent behavior, terminology, layout
conventions, and interaction patterns across every supported platform; platform-specific
divergence MUST be a deliberate, documented decision, never an accident. A shared design
language (naming, spacing, states, error messaging) MUST be defined once and reused. Every
user-facing state — loading, empty, error, success — MUST be handled explicitly. The
application MUST be accessible (keyboard navigation, sufficient contrast, screen-reader
labels) and MUST present clear, actionable, non-technical error messages.

**Rationale**: A transparency tool must be equally usable and trustworthy for any citizen on
any device; inconsistency erodes confidence and excludes users.

### IV. Performance Discipline

Performance targets MUST be defined per feature (e.g., server response latency, client
interaction responsiveness, memory and payload budgets) before implementation and recorded
in the feature plan. Server endpoints MUST meet an explicit latency budget under expected
load; the application MUST remain responsive and MUST NOT block the user interface on
long-running work. Performance-sensitive paths MUST have measurements, not assumptions, and
regressions beyond the agreed budget MUST block release. Premature optimization is rejected —
optimize against measured evidence, not speculation.

**Rationale**: Public datasets can be large; predictable, measured performance keeps the
service usable at scale and prevents silent degradation.

### V. Minimal Dependencies (Custom-First)

Custom implementations are preferred over third-party dependencies. A third-party dependency
MUST NOT be added unless it is genuinely necessary AND well-established (mature, widely
adopted, actively maintained, and appropriately licensed). Every proposed dependency MUST be
justified in writing in the feature plan, including why a custom implementation is
unreasonable and what the maintenance and security trade-offs are. The standard library and
platform-native capabilities MUST be the first choice. Transitive dependency weight is part
of the evaluation. Adding a dependency to avoid writing trivial code MUST be rejected.

**Rationale**: Fewer, well-vetted dependencies mean a smaller attack surface, fewer supply-
chain risks, longer-lived code, and full understanding of the system — essential for a
project whose integrity must be defensible.

## Architecture & Technology Constraints

The project is composed of two distinct, independently buildable and testable parts:

- **Server application**: owns data ingestion, storage, processing, and a well-defined API.
  It MUST expose a stable, versioned contract and MUST NOT leak storage or implementation
  details to clients.
- **Cross-platform application**: the client consumed by end users across platforms. It MUST
  share core logic across platforms and consume the server exclusively through the published
  API contract.

The two parts MUST remain decoupled: they communicate only through the documented API
contract, and a change to that contract MUST be versioned and accompanied by contract tests.
Each part maintains its own test suite and its own quality gates while both conform to this
constitution. All five Core Principles apply to both parts without exception.

## Development Workflow & Quality Gates

- **Branch & review**: Changes land via review. A reviewer MUST verify constitutional
  compliance — test-first ordering, code-quality gates, UX consistency, performance budgets,
  and dependency justification — before approval.
- **Automated gates**: Lint, format, and the full test suite MUST pass in CI before merge.
  Any new dependency MUST appear in the plan's justification section and be approved in
  review.
- **Definition of Done**: A change is done only when its tests were written first and pass,
  quality gates are green, user-facing states and accessibility are handled (for client work),
  performance budgets are met or explicitly waived with rationale, and documentation reflecting
  the change is updated.
- **Traceability**: Features MUST trace from spec → plan → tasks, and tasks MUST reflect the
  test-first ordering mandated by Principle II.

## Governance

This constitution supersedes all other development practices. Where a guideline conflicts with
this document, this document prevails.

**Amendments**: Changes to this constitution MUST be proposed in writing with rationale,
reviewed, and approved before adoption. Upon adoption, the version and amendment date MUST be
updated and all dependent templates (`plan`, `spec`, `tasks`, `checklist`) MUST be re-checked
for consistency in the same change.

**Versioning**: This constitution follows semantic versioning. MAJOR for backward-incompatible
governance or principle removals/redefinitions; MINOR for a new principle or materially
expanded guidance; PATCH for clarifications and non-semantic refinements.

**Compliance**: Every pull request and review MUST verify compliance with all Core Principles.
Any deviation MUST be justified in the feature plan's Complexity Tracking section and approved;
unjustified violations MUST block merge.

**Version**: 1.0.0 | **Ratified**: 2026-06-26 | **Last Amended**: 2026-06-26
