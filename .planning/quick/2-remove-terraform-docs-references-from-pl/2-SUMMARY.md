---
phase: quick-2
plan: 2
subsystem: planning-docs
tags: [docs, cleanup, terraform-docs, planning]
dependency_graph:
  requires: []
  provides: [accurate-phase-3-scope, clean-requirements]
  affects: [ROADMAP.md, REQUIREMENTS.md, SKILL.md]
tech_stack:
  added: []
  patterns: []
key_files:
  created: []
  modified:
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
    - SKILL.md
decisions:
  - "terraform-module-releaser wiki handles doc generation; no standalone terraform-docs CI step needed"
  - "DOCS-01/02/03 removed from requirements; coverage count reduced from 41 to 38"
metrics:
  duration: "~3 min"
  completed: "2026-03-03T22:30:57Z"
  tasks_completed: 2
  files_modified: 3
---

# Quick Task 2: Remove terraform-docs References from Planning Layer Summary

**One-liner:** Removed all standalone terraform-docs CI references from ROADMAP.md, REQUIREMENTS.md, and SKILL.md since terraform-module-releaser already handles documentation generation natively.

## What Was Done

### Task 1: ROADMAP.md

**Phase 3 summary bullet:** Changed from "Enforce terraform-docs and establish CODEOWNERS..." to "Establish CODEOWNERS, branch protection, PR/issue templates, and TAGS.json generation".

**Phase 3 goal:** Changed from "Module READMEs are always current (auto-generated from source)..." to "Module release metadata is captured in TAGS.json automatically...".

**Phase 3 requirements line:** Removed DOCS-01, DOCS-02, DOCS-03. Kept DOCS-04, DOCS-05, DOCS-06, GOV-01 through GOV-05.

**Phase 3 success criteria:** Removed items 1 and 2 (terraform-docs inject markers and `[skip ci]` commit message). Renumbered remaining 5 items as 1-5.

**Phase 3 critical constraints:** Removed the `terraform-docs CI commit must use [skip ci]` constraint. Kept CODEOWNERS and tfbreak constraints.

**Phase 5 success criteria item 4:** Removed `terraform-docs` from the `.pre-commit-config.yaml` hook list.

Commit: `27d9a0f`

---

### Task 2: REQUIREMENTS.md and SKILL.md

**REQUIREMENTS.md — DOCS-01/02/03 replaced:** Three requirement entries describing standalone terraform-docs CI injection replaced with a single informational note:
> Documentation generation (inputs/outputs tables) is handled by `terraform-module-releaser` via GitHub Wiki. No standalone `terraform-docs` CI step is needed.

**REQUIREMENTS.md — TEST-06 updated:** Removed `terraform-docs` from the `.pre-commit-config.yaml` hook list description.

**REQUIREMENTS.md — Traceability table:** Removed the three rows for DOCS-01, DOCS-02, DOCS-03.

**REQUIREMENTS.md — Coverage count:** Updated from 41 total / 41 mapped to 38 total / 38 mapped.

**SKILL.md — outputs.tf purpose:** Changed from "needed for terraform-docs" to "needed for consumers to compose modules".

**SKILL.md — README.md purpose:** Changed from "must include terraform-docs inject markers" to "summarise inputs, outputs, and usage example".

Commit: `7f78b3c`

---

## Final State of Phase 3 Requirements

Phase 3 now only references these requirements:
- DOCS-04: Root README lists all available modules with source URL and version badge
- DOCS-05: SKILL.md includes Dependabot maintenance note
- DOCS-06: Release workflow generates TAGS.json per module directory
- GOV-01 through GOV-05: Branch protection, auto-merge, PR/issue templates, tfbreak

## Verification

```
grep -rn "terraform-docs" .planning/ROADMAP.md .planning/REQUIREMENTS.md SKILL.md
```

Result: Only the intentional explanatory note in REQUIREMENTS.md line 36 (verbatim from plan spec). ROADMAP.md and SKILL.md are completely clean.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- `.planning/ROADMAP.md` — FOUND and verified clean
- `.planning/REQUIREMENTS.md` — FOUND and updated correctly
- `SKILL.md` — FOUND and updated correctly
- Commit `27d9a0f` — exists (Task 1)
- Commit `7f78b3c` — exists (Task 2)
