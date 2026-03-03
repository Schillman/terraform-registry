# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — MVP

**Shipped:** 2026-03-03
**Phases:** 2 | **Plans:** 6 | **Timeline:** 2026-02-28 → 2026-03-03 (4 days)

### What Was Built

- `modules/docker/container/` — namespaced module structure with all required scaffold files,
  migrated from flat `modules/terraform-docker-container/`
- `SKILL.md` + `CLAUDE.md` — full agent operating conventions: commit types, module scaffold,
  autonomy matrix, consumer URL pitfalls
- `release.yaml` — terraform-module-releaser@v2 integration producing per-module semver tags,
  GitHub Releases, and wiki pages automatically
- `pr-title.yaml` — Conventional Commits enforcement on every PR, CI-gate proven with
  real `conclusion=failure` run
- `modules/docker/container/v1.0.0` — first end-to-end validated release: git tag,
  GitHub Release, wiki page all confirmed live

### What Worked

- **SKILL.md-first approach:** Writing agent conventions before any tooling meant all
  subsequent automation was consistent with documented intent. No rework needed.
- **Phase verification gates:** 7/7 must-haves verified per phase caught the QUAL-06
  gap before milestone completion — would have been invisible otherwise.
- **Throwaway PR pattern for CI rejection proof:** Creating a test PR with bad title,
  recording run ID + conclusion, closing without merging is a reusable pattern for
  demonstrating negative CI paths.
- **Wave-based parallel execution:** Plans within a wave executed in parallel, reducing
  wall-clock time. Phase 2 wave 1 + wave 2 structure was clean.

### What Was Inefficient

- **REL-01/REL-02 traceability not updated:** Workflows landed on main and worked, but
  REQUIREMENTS.md checkbox was never ticked. Verifier caught it but it required a note
  rather than a clean pass. Should update REQUIREMENTS.md in the same commit as the
  implementation.
- **Gap closure required a separate plan (02-03):** QUAL-06 could have been demonstrated
  in the original 02-02 plan. Separating validation steps across plans is cleaner in
  theory but creates rework when a gap is found.
- **Branch protection blocked direct push:** The phase branch workflow assumed direct
  push to main was possible, but branch protection was active. VALIDATION_LOG.md update
  required an extra PR (#13). Plan should account for this.

### Patterns Established

- **Module path format:** `modules/{provider}/{resource}/vX.Y.Z` — confirmed working with
  terraform-module-releaser's two-level path detection
- **Consumer source URL:** `github.com/Schillman/terraform-registry//modules/docker/container?ref=modules/docker/container/v1.0.0`
  — no `depth=1` on version-pinned refs
- **Breaking change signal:** `feat!:`/`fix!:` shorthand only — `BREAKING CHANGE:` footer
  is lost in squash merges
- **module-path-ignore:** `tests/example/` must be excluded from terraform-module-releaser
  or it produces an extra tag for the test directory
- **Workflows must land on main before triggering PR:** CI workflows fire on merge events —
  cherry-pick to main before opening the validation PR, not after

### Key Lessons

1. **Validate with real infrastructure, not just syntax.** Silent failure (action exits green,
   creates nothing) is the primary risk with GitHub Actions-based release tooling.
   Always require a real tag or run ID as evidence.
2. **Document the negative path.** PR title validation only has meaning if rejection is
   empirically demonstrated. A passing check alone doesn't prove the gate works.
3. **`depth=1` is a footgun on version-pinned refs.** It works for the first consumer pull
   but breaks silently once the repo advances past the pinned tag.
4. **Squash merge discards commit body.** `BREAKING CHANGE:` footer is lost. Mandate
   `feat!:`/`fix!:` shorthand in SKILL.md and enforce via PR title regex.

### Cost Observations

- Model: claude-sonnet-4-6 throughout (quality profile)
- Sessions: ~4
- Notable: Executor agents with fresh 200k context per plan kept orchestrator lean;
  no context overflow across 6 plans

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 | 2 | 6 | Baseline — GSD workflow established |

### Top Lessons (Verified Across Milestones)

1. Real evidence beats syntax checks — always require a run ID, tag, or file on disk as proof.
2. Agent conventions written before tooling prevents rework later.
