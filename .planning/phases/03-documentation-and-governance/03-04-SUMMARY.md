---
phase: 03-documentation-and-governance
plan: "04"
subsystem: governance
tags: [github-templates, pull-request, issue-templates, conventional-commits, dependabot, readme]

# Dependency graph
requires:
  - phase: 03-documentation-and-governance
    provides: "Phase context and locked interface decisions for PR/issue template content"
provides:
  - "PR template enforcing Conventional Commits format for all contributors"
  - "Bug report issue template with structured module/description/expected/actual fields"
  - "New module request template with provider/purpose/why fields"
  - "Root README with Available Modules table, correct source URL, version badge"
  - "SKILL.md section 5 with one-entry-per-module Dependabot requirement"
affects: [all-future-phases, contributors, consumers]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GitHub issue template YAML frontmatter (name/about/labels)"
    - "shields.io badge with filter parameter for per-module tag scoping"
    - "Dependabot one-entry-per-directory pattern for non-recursive registry monitoring"

key-files:
  created:
    - ".github/pull_request_template.md"
    - ".github/ISSUE_TEMPLATE/bug_report.md"
    - ".github/ISSUE_TEMPLATE/new_module_request.md"
  modified:
    - "README.md"
    - "SKILL.md"

key-decisions:
  - "PR template is minimal: Conventional Commits reminder + description field only, no checkboxes"
  - "shields.io badge filter uses URL-encoded slashes (%2F) to scope to per-module tags"
  - "Dependabot one-entry-per-directory requirement added to SKILL.md as section 5"

patterns-established:
  - "GitHub issue templates use YAML frontmatter with name/about/labels fields"
  - "Module version badges use filter=modules%2F{provider}%2F{resource}%2Fv* pattern"

requirements-completed: [GOV-04, GOV-05, DOCS-04, DOCS-05]

# Metrics
duration: 3min
completed: 2026-03-04
---

# Phase 3 Plan 04: Community Templates, README Module Listing, and Dependabot Guidance Summary

**GitHub PR/issue templates for contributor guidance, root README with docker/container module table and correct source URL, and SKILL.md section 5 with Dependabot one-entry-per-directory requirement**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-04T22:34:34Z
- **Completed:** 2026-03-04T22:37:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Created PR template with Conventional Commits reminder at top and description field — no checkboxes (locked decision honored)
- Created bug report and new module request issue templates with structured required fields
- Rewrote root README with Available Modules table listing docker/container with shields.io version badge and correct namespaced source URL
- Appended SKILL.md section 5 documenting the Dependabot one-entry-per-module-directory requirement

## Task Commits

Each task was committed atomically:

1. **Task 1: Create PR template and issue templates** - `6366ed9` (docs)
2. **Task 2: Update README.md and SKILL.md** - `c0258ef` (docs)

**Plan metadata:** (final commit below)

## Files Created/Modified

- `.github/pull_request_template.md` - Minimal PR template with Conventional Commits reminder and description field
- `.github/ISSUE_TEMPLATE/bug_report.md` - Structured bug report with module name, description, expected vs actual
- `.github/ISSUE_TEMPLATE/new_module_request.md` - New module request with provider, purpose, and why fields
- `README.md` - Rewritten with Available Modules table, correct source URL example, depth=1 warning, SKILL.md cross-reference
- `SKILL.md` - Section 5 appended with Dependabot maintenance requirement (one entry per module directory, monthly schedule)

## Decisions Made

- PR template kept minimal per locked interface decision: reminder text + description field, zero checkboxes
- shields.io badge filter uses `modules%2Fdocker%2Fcontainer%2Fv*` (URL-encoded slashes) to scope the badge to only docker/container version tags
- Dependabot note placed in a dedicated section 5, no existing SKILL.md content modified

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 3 governance artifacts are complete: lint workflow (03-01), tfbreak breaking-change detection (03-02), auto-merge for bots (03-03), and community templates + README + Dependabot guidance (03-04)
- Phase 4 (or remaining v1.1 phases) can proceed; consumers browsing the repo now see the correct module listing and source URL pattern immediately

---
*Phase: 03-documentation-and-governance*
*Completed: 2026-03-04*
