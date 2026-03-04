---
phase: 03-documentation-and-governance
plan: "02"
subsystem: ci
tags: [tfbreak, github-actions, breaking-changes, terraform, ci-workflow]

# Dependency graph
requires: []
provides:
  - "tfbreak CI workflow that detects breaking Terraform module changes on every PR touching .tf files"
  - "PR comments for both breaking and non-breaking tfbreak results"
  - "terraform-breaking label created and applied automatically on breaking PRs"
affects:
  - 03-03  # branch protection plan needs to add tfbreak as required status check
  - consumers  # breaking changes are now surfaced before merge

# Tech tracking
tech-stack:
  added: [tfbreak binary (go install github.com/jokarl/tfbreak-core/cmd/tfbreak@latest)]
  patterns:
    - "Non-blocking required status check — workflow exits 0 always, result communicated via PR comment and label"
    - "git archive + temp dir baseline extraction pattern for per-module version comparison"
    - "GITHUB_OUTPUT multiline heredoc pattern for passing breaking change details between steps"

key-files:
  created:
    - .github/workflows/tfbreak.yaml
  modified: []

key-decisions:
  - "Workflow always exits 0 so it satisfies 'required status check must complete' without blocking merge"
  - "Comparison baseline is latest release tag (not base branch HEAD) — semantically correct for semver versioning"
  - "Both tfbreak and tflint (lint.yaml) run independently — neither replaces the other"
  - "terraform-breaking label uses orange (#E4800D) matching the severity signal intent"
  - "Label is created on-demand with || true guard so first run never fails on missing label"

patterns-established:
  - "Non-blocking required check pattern: exit 0 always, surface result via PR comment + label"
  - "Module path extraction: git diff name-only | grep .tf | sed strip filename | grep ^modules/ | sort -u"

requirements-completed: [GOV-01]

# Metrics
duration: 1min
completed: 2026-03-04
---

# Phase 3 Plan 02: Breaking Change Detection Summary

**tfbreak CI workflow using busser/tfbreak binary, comparing changed modules against their latest release tag and posting PR comments and terraform-breaking label on detection**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-04T22:34:31Z
- **Completed:** 2026-03-04T22:35:17Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `.github/workflows/tfbreak.yaml` — triggers on every PR to main that changes `.tf` files
- Breaking changes surface as a PR comment with per-module details and a `terraform-breaking` (orange) label
- Non-breaking runs post a visible confirmation comment so it's always clear tfbreak ran
- Workflow always exits 0, satisfying the "required status check must complete" contract without blocking merge

## Task Commits

Each task was committed atomically:

1. **Task 1: Create tfbreak CI workflow** - `a79678d` (ci)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `.github/workflows/tfbreak.yaml` — Breaking change detection CI workflow; installs tfbreak binary, finds changed modules, compares each against latest release tag, posts PR comment + applies label

## Decisions Made

- Used `jokarl/tfbreak-core/` binary (installed with go@latest) since there is no official GitHub Action for tfbreak
- Workflow always exits 0 — breaking changes are communicated via PR comment and label, not CI failure; this is the correct "required-but-non-blocking" pattern
- Comparison baseline is the latest release tag per module (not base branch HEAD) — this is semantically correct for consumers who pin to version tags
- The `terraform-breaking` label is created on-demand with `|| true` so the first PR with breaking changes never fails due to a missing label
- Used `git archive | tar -x` to extract baseline module files into a temp dir for tfbreak comparison rather than git worktree (simpler, avoids worktree cleanup edge cases)

## Deviations from Plan

None - plan executed exactly as written. Minor improvements made within the provided template:
- Added `await` to `github.rest.issues.createComment()` calls (correct async JS in github-script)
- Used `printf '%b'` for BREAKING_DETAILS output to correctly handle escape sequences in GITHUB_OUTPUT
- Added `mkdir -p` before `git archive` extraction for reliability

These are implementation quality improvements that stay within the plan's intent, not deviations.

## Issues Encountered

None.

## User Setup Required

**Branch protection required in Plan 03-03.** The tfbreak job (`tfbreak / Detect Breaking Changes`) must be added as a required status check in GitHub branch protection rules for main. The workflow is in place and ready; it becomes a required check once branch protection is configured.

No other external configuration required.

## Next Phase Readiness

- tfbreak workflow is deployed and will run on any PR touching .tf files
- Plan 03-03 (branch protection + auto-merge) should add `tfbreak / Detect Breaking Changes` as a required status check
- Both tflint (via lint.yaml) and tfbreak now run independently — governance CI stack is complete pending branch protection

---
*Phase: 03-documentation-and-governance*
*Completed: 2026-03-04*

## Self-Check: PASSED

- `.github/workflows/tfbreak.yaml` — FOUND
- `03-02-SUMMARY.md` — FOUND
- Commit `a79678d` — FOUND
