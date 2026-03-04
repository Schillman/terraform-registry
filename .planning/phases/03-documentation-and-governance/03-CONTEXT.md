# Phase 3: Documentation and Governance - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Automated TAGS.json generation on module release, breaking change detection via tfbreak,
CODEOWNERS protecting critical repo files (not modules/), auto-merge for all bot-authored
PRs that pass required CI checks, and PR/issue templates with Conventional Commits guidance.
Restore commands, scheduled automation, and tagging strategy beyond this scope belong in
other phases.

</domain>

<decisions>
## Implementation Decisions

### TAGS.json generation
- Trigger: release tag push in path-scoped format `modules/{module-name}/v{version}`
- Scope: only the module identified by the tag — not all modules on every release
- Fields: module name, release version, latest commit author (exactly the three locked fields, nothing more)
- Location: top-level of module directory — `modules/{module-name}/TAGS.json`
- Committer: bot/CI identity (`github-actions[bot]`) — not the human who pushed the tag

### Auto-merge eligibility
- All commit types qualify (feat:, fix:, chore:, refactor:, test:, ci:, docs:, and breaking variants feat!/fix!) — CI checks are the gate, not commit type
- Agent identification: PR author is `github-actions[bot]` or a known bot account (no manual labels)
- Gate: all required branch protection status checks must pass before auto-merge triggers
- Breaking changes (feat!, fix!) auto-merge too — consumers pin to specific tags; a major version bump via terraform-module-releaser handles the versioning signal; no human review required
- Mechanism: GitHub native auto-merge via `gh pr merge --auto --squash`
- Merge strategy: squash merge
- Branch cleanup: auto-delete branch after merge

### CODEOWNERS
- Human review required for: `/.github/`, `/SKILL.md`, `/CLAUDE.md`
- modules/ intentionally NOT covered — agent autonomy must be preserved for auto-merge to work

### Breaking change handling (tfbreak)
- Separate workflow file: `.github/workflows/tfbreak.yaml`
- Trigger: only when `.tf` files change (path filter)
- Required status check: yes — tfbreak must complete before merge (even though it never blocks)
- Comparison baseline: latest release tag (not just base branch) — semantically correct for versioning
- On breaking change detected: post PR comment describing what changed + apply `terraform-breaking` label (orange)
- On no breaking changes: post a "no breaking changes detected" comment — always visible confirmation that tfbreak ran
- tfbreak is complementary to tflint — both run, neither replaces the other

### PR/issue templates
- PR template: minimal — reminder text at top ("Title must follow Conventional Commits: `type: description`") + description field; no checkboxes
- Bug report template: module name, description of the bug, expected vs actual behavior
- New module request template: provider, module purpose, why it's needed

### Claude's Discretion
- Exact TAGS.json JSON schema formatting (key order, whitespace)
- How tfbreak is installed/invoked in the workflow (binary, action, or script)
- Branch protection rule details beyond what's specified (e.g., dismiss stale reviews, require up-to-date branches)
- Label creation step for `terraform-breaking` if it doesn't exist

</decisions>

<specifics>
## Specific Ideas

- The terraform-module-releaser action handles semver bumping based on conventional commit type — breaking changes (feat!, fix!) automatically produce a major version bump; tfbreak's job is detection and signaling, not gating
- "All commits should qualify for auto-merge — the checks need to be robust enough to cover for potential failures" — robustness lives in CI, not in restricting which types can merge
- Consumers who don't update their pinned tag are never affected by breaking changes; auto-merge is safe in this model

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/lint.yaml`: Existing CI workflow; tfbreak.yaml should follow same trigger/jobs structure as a reference
- GitHub Actions already configured with `hashicorp/setup-terraform@v3` and `actions/checkout@v4` — reusable in new workflows

### Established Patterns
- Path-scoped tags (`modules/terraform-docker-container/v1.2.0`) are the release convention — TAGS.json workflow should parse module name from the tag ref
- `github-actions[bot]` identity is the natural committer for automated commits (consistent with how lint/CI bots operate)
- No existing CODEOWNERS, PR templates, or issue templates — all net-new

### Integration Points
- New workflows connect into `.github/workflows/` alongside `lint.yaml`
- CODEOWNERS lives at `.github/CODEOWNERS` (GitHub's lookup path)
- PR template at `.github/pull_request_template.md`
- Issue templates at `.github/ISSUE_TEMPLATE/bug_report.md` and `.github/ISSUE_TEMPLATE/new_module_request.md`
- TAGS.json committed inside module dirs: `modules/{module-name}/TAGS.json`

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 03-documentation-and-governance*
*Context gathered: 2026-03-04*
