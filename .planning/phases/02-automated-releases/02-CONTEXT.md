# Phase 2: Automated Releases - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire up terraform-module-releaser to automatically produce a module-scoped semantic version tag (`modules/docker/container/vX.Y.Z`), a GitHub Release with auto-generated notes, and a wiki page update on every conventional commit merged to main. PR title must be validated against Conventional Commits regex before merge is allowed. Phase is NOT complete until a real test commit confirms the tag was created — workflow syntax alone is not sufficient.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion

No implementation decisions were captured interactively. All of the following are at Claude's discretion — choose the standard/recommended approach for each:

- Release workflow structure: whether release.yaml is separate from lint.yaml, and what triggers it uses
- PR title enforcement: whether to add a job to lint.yaml or create a dedicated workflow
- terraform-module-releaser configuration: explicit path configuration to prevent silent-skip on two-level paths
- Test commit validation: approach for real-commit end-to-end validation required by the roadmap
- Wiki initialization: manual step sequencing relative to first release
- Permissions model: `contents: write` and `pull-requests: write` as stated in roadmap success criteria

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets

- `.github/workflows/lint.yaml`: Existing workflow with `fetch-depth: 0`, `GITHUB_TOKEN`, triggers on `pull_request` + `push` to `main`. Pattern to follow for new workflows.

### Established Patterns

- Workflow triggers: `pull_request: branches: main` and `push: branches: main` — match this pattern
- `fetch-depth: 0` already used in lint.yaml (required by terraform-module-releaser for full history tag detection)
- `GITHUB_TOKEN` already injected via `secrets.GITHUB_TOKEN` in lint.yaml
- `actions/checkout@v4` pinned version already in use

### Integration Points

- New `release.yaml` connects to main branch push events
- PR title validation connects to `pull_request` event (title available in `github.event.pull_request.title`)
- terraform-module-releaser needs `contents: write` and `pull-requests: write` permissions (currently only `GITHUB_TOKEN` is used with default read permissions in lint.yaml)
- Module path: `modules/docker/container/` — releaser must detect this two-level path correctly

</code_context>

<specifics>
## Specific Ideas

- The roadmap explicitly calls out: `release.yaml` must have `permissions: contents: write, pull-requests: write` and `fetch-depth: 0`
- Validation MUST use a real test commit — not just workflow syntax validation
- terraform-module-releaser source: https://github.com/techpivot/terraform-module-releaser — research must verify two-level path detection before planning
- Critical pitfall documented in STATE.md: terraform-module-releaser may silently skip modules it cannot find (exits green, creates nothing) — push a real `feat:` commit and confirm a tag appears

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 02-automated-releases*
*Context gathered: 2026-02-28*
