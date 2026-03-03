---
phase: quick-2
plan: 2
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/ROADMAP.md
  - .planning/REQUIREMENTS.md
  - SKILL.md
autonomous: true
requirements: []

must_haves:
  truths:
    - "No planning document references standalone terraform-docs as a CI step"
    - "REQUIREMENTS.md removes DOCS-01, DOCS-02, DOCS-03 (terraform-docs specific) and replaces with a note that terraform-module-releaser handles doc generation"
    - "Phase 3 in ROADMAP.md no longer lists terraform-docs enforcement as a goal or constraint"
    - "SKILL.md module scaffold table no longer references terraform-docs as a dependency reason"
  artifacts:
    - path: ".planning/ROADMAP.md"
      provides: "Updated Phase 3 description without terraform-docs"
    - path: ".planning/REQUIREMENTS.md"
      provides: "Updated DOCS requirements without standalone terraform-docs steps"
    - path: "SKILL.md"
      provides: "Updated scaffold table without terraform-docs dependency notes"
  key_links:
    - from: ".planning/REQUIREMENTS.md"
      to: ".planning/ROADMAP.md"
      via: "DOCS-01/02/03 requirement IDs referenced in Phase 3"
      pattern: "DOCS-0[123]"
---

<objective>
Remove all planning-layer references to standalone terraform-docs from Phase 3 (and Phase 5)
since terraform-module-releaser already handles documentation generation natively. This keeps
the planning documents accurate so future phase planning does not build on an assumption that
is no longer true.

Purpose: Prevent agents from implementing a redundant terraform-docs CI step that conflicts
with or duplicates what terraform-module-releaser already produces.
Output: Updated ROADMAP.md, REQUIREMENTS.md, and SKILL.md with terraform-docs references
removed or replaced with accurate notes about terraform-module-releaser handling docs.
</objective>

<execution_context>
@/Users/p950cvo/.claude/get-shit-done/workflows/execute-plan.md
@/Users/p950cvo/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@SKILL.md
@.planning/STATE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Update ROADMAP.md — remove terraform-docs from Phase 3 and Phase 5</name>
  <files>.planning/ROADMAP.md</files>
  <action>
Edit `.planning/ROADMAP.md` to remove all terraform-docs-specific content. Make the following
targeted changes (do not alter unrelated content):

**Phase 3 — title and goal block (lines ~24-64):**
- Change the phase title from "Documentation and Governance" to "Documentation and Governance"
  (title can stay the same; it is fine) — BUT remove terraform-docs from the body description.
- Current description says: "Enforce terraform-docs and establish CODEOWNERS..."
  Change to: "Establish CODEOWNERS, branch protection, PR/issue templates, and TAGS.json generation"
- **Goal** line: Remove "Module READMEs are always current (auto-generated from source)" or
  replace it with "Module release metadata is captured in TAGS.json automatically" — since
  terraform-module-releaser wiki handles docs; our phase goal is governance, not docs generation.
- **Success criteria** — remove items 1 and 2:
  - Remove item 1: "Module README contains auto-generated inputs/outputs section between
    `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` markers, kept current by CI"
  - Remove item 2: "The terraform-docs CI commit uses `[skip ci]` in its commit message..."
  - Renumber remaining items 3-7 to 1-5.
- **Requirements** line: Remove DOCS-01, DOCS-02, DOCS-03 from the list. Keep DOCS-04,
  DOCS-05, DOCS-06, GOV-01 through GOV-05.
- **Critical constraints**: Remove the constraint "terraform-docs CI commit must use `[skip ci]`
  (prevents infinite loop)". Keep the CODEOWNERS and tfbreak constraints.

**Phase 5 — success criteria item 4 (line ~104):**
- Change: "`.pre-commit-config.yaml` mirrors CI: fmt, validate, tflint, terraform-docs, trivy,
  conventional-pre-commit"
- To: "`.pre-commit-config.yaml` mirrors CI: fmt, validate, tflint, trivy, conventional-pre-commit"
  (remove terraform-docs from the list — terraform-module-releaser handles docs)
  </action>
  <verify>
    <automated>grep -n "terraform-docs" .planning/ROADMAP.md | grep -v "milestones" || echo "PASS — no terraform-docs references in ROADMAP.md"</automated>
  </verify>
  <done>
  ROADMAP.md contains no references to terraform-docs. Phase 3 goal and success criteria
  reflect governance and TAGS.json, not docs generation. Phase 5 pre-commit list excludes
  terraform-docs.
  </done>
</task>

<task type="auto">
  <name>Task 2: Update REQUIREMENTS.md and SKILL.md — remove terraform-docs requirement entries</name>
  <files>.planning/REQUIREMENTS.md, SKILL.md</files>
  <action>
**REQUIREMENTS.md changes:**

1. Replace DOCS-01, DOCS-02, DOCS-03 entirely. These three requirements describe standalone
   terraform-docs CI injection, which is superseded by terraform-module-releaser. Replace the
   three lines with a single informational note:

   Remove:
   ```
   - [ ] **DOCS-01**: Every module `README.md` contains terraform-docs inject markers (`<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->`)
   - [ ] **DOCS-02**: CI auto-generates and commits the inputs/outputs section of each module README via `terraform-docs` inject mode with `[skip ci]` commit message
   - [ ] **DOCS-03**: `.terraform-docs.yml` at repo root defines consistent output format (sorted, type/description/required columns)
   ```

   Replace with a single note (no requirement ID — not a tracked requirement):
   ```
   - **Note:** Documentation generation (inputs/outputs tables) is handled by `terraform-module-releaser` via GitHub Wiki. No standalone `terraform-docs` CI step is needed.
   ```

2. TEST-06: Remove `terraform-docs` from the `.pre-commit-config.yaml` hook list:
   - Change: "`.pre-commit-config.yaml` mirrors CI: `terraform fmt`, `terraform validate`, `tflint`, `terraform-docs`, `trivy`, `conventional-pre-commit` (commit-msg stage)"
   - To: "`.pre-commit-config.yaml` mirrors CI: `terraform fmt`, `terraform validate`, `tflint`, `trivy`, `conventional-pre-commit` (commit-msg stage)"

3. In the Traceability table at the bottom, remove the three rows for DOCS-01, DOCS-02, DOCS-03:
   ```
   | DOCS-01 | Phase 3 | Pending |
   | DOCS-02 | Phase 3 | Pending |
   | DOCS-03 | Phase 3 | Pending |
   ```
   Update the Coverage count: change "v1 requirements: 41 total" and "Mapped to phases: 41"
   to reflect the 3 removed requirements (38 total, 38 mapped).

**SKILL.md changes:**

In the Module Scaffold Pattern table (Section 2), two cells reference terraform-docs:

1. `outputs.tf` purpose: "Output value declarations (required even if minimal; needed for terraform-docs)"
   Change to: "Output value declarations (required even if minimal; needed for consumers to compose modules)"

2. `README.md` purpose: "Module documentation — must include terraform-docs inject markers"
   Change to: "Module documentation — summarise inputs, outputs, and usage example"
   (terraform-module-releaser wiki handles the auto-generated table; README is now hand-authored)
  </action>
  <verify>
    <automated>grep -n "terraform-docs" .planning/REQUIREMENTS.md SKILL.md || echo "PASS — no terraform-docs references in REQUIREMENTS.md or SKILL.md"</automated>
  </verify>
  <done>
  REQUIREMENTS.md has no DOCS-01/02/03 entries, no terraform-docs in TEST-06, and the
  traceability table and coverage count are consistent. SKILL.md scaffold table contains
  no terraform-docs references.
  </done>
</task>

</tasks>

<verification>
After both tasks complete, verify no terraform-docs references remain in the three files:

```
grep -rn "terraform-docs" .planning/ROADMAP.md .planning/REQUIREMENTS.md SKILL.md
```

Expected: zero matches (or only the note in REQUIREMENTS.md explaining terraform-module-releaser
handles docs — which does not mention terraform-docs by name).
</verification>

<success_criteria>
- ROADMAP.md Phase 3 no longer lists DOCS-01, DOCS-02, DOCS-03 in Requirements, no longer
  has success criteria items about terraform-docs inject markers or `[skip ci]` commits, and
  the critical constraints section has no terraform-docs constraint.
- ROADMAP.md Phase 5 `.pre-commit-config.yaml` success criterion omits terraform-docs.
- REQUIREMENTS.md has no DOCS-01, DOCS-02, DOCS-03 rows; TEST-06 omits terraform-docs from
  the hook list; traceability table is clean; coverage count is accurate.
- SKILL.md module scaffold table contains no terraform-docs references.
- All three files pass: `grep -n "terraform-docs" .planning/ROADMAP.md .planning/REQUIREMENTS.md SKILL.md` returns zero matches.
</success_criteria>

<output>
After completion, create `.planning/quick/2-remove-terraform-docs-references-from-pl/2-SUMMARY.md`
documenting what was changed in each file and the final state of Phase 3 requirements.
</output>
