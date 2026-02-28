# Phase 1: Foundation - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Migrate the existing Docker container module from `modules/terraform-docker-container/` to `modules/docker/container/`. Create `outputs.tf`, rename `terraform.tf` to `versions.tf` with updated Terraform version constraint. Write `SKILL.md` and `CLAUDE.md` at repo root to establish agent operating conventions. Remove the old module directory entirely. Creating new modules, configuring release automation, or adding CI quality gates are out of scope.

</domain>

<decisions>
## Implementation Decisions

### Module outputs
- Expose three outputs: `container_id`, `container_name`, `image_id`
- Sourced from `docker_container.main.id`, `docker_container.main.name`, `docker_image.main.image_id`
- No ports output, no full-resource output

### versions.tf scope
- File named `versions.tf` (not `terraform.tf`)
- Declares `required_version = "~> 1.9"`
- Also includes the existing provider block from `terraform.tf` migrated as-is (kreuzwerker/docker, version 3.0.2)

### SKILL.md scope and structure
- Focused document — exactly what agents need to operate this repo
- **Commit convention table** (standard set):
  - `feat:` → minor bump
  - `fix:` → patch bump
  - `docs:`, `chore:`, `refactor:`, `test:`, `ci:` → patch bump
  - `BREAKING CHANGE:` footer → major bump
- **Autonomy matrix**: agents may freely edit/create `.tf`, `.md`, `.yml`, `.json` files and CI workflows (`lint.yaml`, `release.yaml`, etc.) without asking. Must ask before: deleting files, force-pushing, creating releases, modifying branch protection rules.
- **Module scaffold pattern**: required files per module (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`, `tests/`)
- **Consumer source URL pattern**: tag-pinned ref, no `depth=1`:
  ```
  source = "github.com/Schillman/terraform-registry//modules/docker/container?ref=modules/docker/container/v1.0.0"
  ```
  `depth=1` must NOT appear in any version-pinned examples

### CLAUDE.md approach
- Short file that @-references SKILL.md
- Does not duplicate SKILL.md content inline
- Tells Claude Code agents to read SKILL.md for all operating conventions

### Old directory removal
- `modules/terraform-docker-container/` is fully deleted — no .tf files, no README
- User decision: no deprecation stub needed
- Note: this overrides the roadmap success criterion that called for a deprecation stub

### Claude's Discretion
- Exact wording and formatting of SKILL.md sections
- Whether to add `description` fields to outputs (standard Terraform practice — yes)
- `.markdownlintignore` content (exclude `.planning/`)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/terraform-docker-container/main.tf`: source for `docker_image.main`, `docker_volume.volumes`, `docker_container.main` resources — copy verbatim to new path
- `modules/terraform-docker-container/variables.tf`: all variable definitions migrate unchanged
- `modules/terraform-docker-container/README.md`: migrates to new path
- `modules/terraform-docker-container/tests/`: directory structure migrates to `modules/docker/container/tests/`
- `modules/terraform-docker-container/terraform.tf`: provider block (kreuzwerker/docker 3.0.2) migrates into `versions.tf` with added `required_version`

### Established Patterns
- Primary resource label is `"main"` — preserve in outputs (`docker_container.main.id`, etc.)
- No existing `outputs.tf` — this phase creates the first one
- `terraform fmt` enforced in CI — all `.tf` files must pass before committing

### Integration Points
- CI workflow (`.github/workflows/lint.yaml`) references `.tf` files globally — no path-specific config to update for Phase 1
- `tests/example/main.tf` currently references old module path via GitHub source tag — this test file migrates into `modules/docker/container/tests/` and its source URL will need updating to new path (or left for Phase 2 when tags exist)

</code_context>

<specifics>
## Specific Ideas

- Consumer URL example must use `ref=modules/docker/container/v1.0.0` format (namespaced tag) — this exact format is required by Phase 2's release automation
- `depth=1` is explicitly forbidden in version-pinned source URL examples in SKILL.md

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-02-28*
