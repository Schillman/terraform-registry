# Feature Landscape

**Domain:** Professional AI-agent-friendly Terraform Module Monorepo
**Researched:** 2026-02-28
**Overall confidence:** MEDIUM — Web search and WebFetch were unavailable; findings draw on training data (knowledge through August 2025) cross-referenced with the repo's existing planning files. terraform-module-releaser wiki details are LOW confidence without live doc access; CLAUDE.md conventions are HIGH confidence from Anthropic's own tooling.

---

## Table Stakes

Features users (and agents) expect. Missing = repo feels unfinished or unsafe to consume.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `SKILL.md` (agent instruction file) | Agents read this before working; without it they guess conventions and make wrong commits | Low | Single flat file at repo root; covers commit conventions, module scaffold, CI/CD, PR rules — see detail section below |
| Conventional Commits enforcement | terraform-module-releaser requires CC to drive semver; agents need exact spec | Low | `.commitlintrc.json` + Husky pre-commit hook; also document in SKILL.md |
| Namespaced module structure `modules/{provider}/{resource}` | terraform-module-releaser expects this layout; consumers expect predictable paths in `ref` URIs | Low | Migrate `terraform-docker-container/` → `modules/docker/container/` as first step |
| terraform-module-releaser integration | Auto-versioning, GitHub releases, per-module wiki pages; consumers depend on release tags | Medium | Needs `GITHUB_TOKEN` with write:packages + wiki write permissions; `chore:` commits excluded from release |
| Module-scoped Git tags | Direct Git sourcing requires tags like `modules/docker/container/v1.2.0`; consumers pin via `ref=` | Low | Generated automatically by terraform-module-releaser; do NOT create manually |
| Per-module `README.md` via terraform-docs | Every consumer expects generated inputs/outputs table; CI enforces it | Low | Add terraform-docs GitHub Action; use `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` markers |
| `outputs.tf` in every module | Consumers need container IDs, volume IDs, image digests to wire modules together | Low | Currently missing from docker/container; table stake for any serious module |
| GitHub Actions CI on PR | Lint, fmt, tflint, security scan must pass before merge | Low | Already exists; add Trivy + terraform test steps |
| Trivy security scanning | No known HIGH/CRITICAL CVEs should reach main; standard for IaC repos | Low | `aquasecurity/trivy-action` in CI; fail on HIGH/CRITICAL |
| Native `terraform test` per module | Terraform >= 1.6 native testing is now the standard; replaces ad-hoc example-only testing | Medium | `tests/*.tftest.hcl` alongside example directory; run in CI |
| `CODEOWNERS` | Required for mixed-autonomy model: routine PRs auto-merge, BREAKING CHANGE PRs route to human | Low | See detail section below |
| Branch protection rules | Prevent direct pushes to main; require passing CI; require CODEOWNERS review on BREAKING CHANGE PRs | Low | See detail section below |
| Dependabot config | Provider pinning drifts; Dependabot keeps GitHub Actions and Terraform provider versions fresh | Low | `.github/dependabot.yml` with `terraform` and `github-actions` ecosystems |
| PR template | Agents and humans need a structured template; ensures checklist coverage before merge | Low | `.github/pull_request_template.md` — see detail section below |
| Issue templates | Bug report + new module request templates; agents should create issues before large PRs | Low | `.github/ISSUE_TEMPLATE/` directory with YAML front-matter templates |
| Root `README.md` with module index | Consumers discover modules here; must list all modules with source snippets and version badges | Low | See root README structure section below |
| Pre-commit hook configuration | Local quality gate before push; prevents CI-failing commits from agents and humans alike | Low | `.pre-commit-config.yaml` with terraform-fmt, terraform-docs, tflint, trailing-whitespace |

---

## Differentiators

Features that make this repo stand out from a generic Terraform module repo. Not universally expected, but high value.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Terratest Go stubs per module | Full integration test suite that can deploy + verify + destroy; exceeds terraform test for complex scenarios | High | `tests/integration/container_test.go` scaffold per module; GitHub Actions job with `go test -timeout 30m` |
| Agent-specific commit workflow documented in SKILL.md | Agents know exactly which commit type triggers what semver bump; eliminates wrong-type commits | Low | Table: feat → minor, fix → patch, BREAKING CHANGE footer → major, chore/docs/test → no bump |
| BREAKING CHANGE PR approval gate | All BREAKING CHANGE commits require human PR approval before merge; protects consumers pinned to minor/patch | Medium | Branch protection "required reviewers" for PRs with BREAKING CHANGE in commit message body; see pitfall about detection |
| Module consumption reference in SKILL.md | Agents writing consumer configs know the exact `git::https://` source pattern with depth=1 and ref format | Low | Critical for agents that also write downstream consumers of this registry |
| `terraform validate` + `terraform plan -detailed-exitcode` in CI | Catches provider-level errors that fmt/tflint miss; proves module is syntactically valid end-to-end | Low | Add as CI step; requires a provider-mock or `terraform plan -out` in check mode |
| terraform-docs version badge per module | Consumers see current version at a glance in module README | Low | terraform-module-releaser generates release badges; wire into per-module README |
| Wiki seeded with module index | terraform-module-releaser generates per-module wiki pages; seed a Home.md that auto-links all pages | Low | See wiki structure section below |
| `.tflint.hcl` with AWS/Azure/Docker rule plugins | tflint catches provider-specific errors that terraform validate alone misses | Low | Currently no `.tflint.hcl`; add with `plugin "terraform"` + `plugin "azurerm"` / `plugin "docker"` as modules grow |
| `validation` blocks in variables | Fail at plan time with clear error messages; prevents silent misconfigurations | Low | Currently missing from docker/container module; add for restart policy, network_mode, gpus |

---

## Anti-Features

Features to deliberately NOT add. Keep the repo minimalistic and purpose-fit.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Terraform Cloud / HCP registry | Added infrastructure complexity, no benefit over direct Git sourcing for this consumption model | Stay with `git::https://` source + `ref` tags |
| Remote state in registry repo | Registry is a code repo, not a state backend; mixing concerns is a maintenance hazard | Consumers supply their own backend; document this in SKILL.md |
| Manual version tag creation | terraform-module-releaser owns all tagging; human-created tags break the semver automation | Let the action create all tags; document "never tag manually" in SKILL.md |
| Monolithic CI job | One giant GitHub Actions job is slow and fails-everything-on-one-lint-error | Separate jobs: lint, security, test, release — fail fast per concern |
| Nested module directories beyond `modules/{provider}/{resource}` | terraform-module-releaser's tag regex expects exactly two path segments; deeper nesting breaks release automation | Hard rule: no `modules/docker/container/network/` — create a new sibling module instead |
| Shared `terraform.tf` at repo root | Modules should be fully self-contained; a root provider block creates ambiguity about module boundaries | Each module owns its own `terraform.tf` with pinned provider versions |
| Automated `terraform apply` in CI | IaC repos run plan + validate in CI, not apply; applying in CI creates real infrastructure from PRs | Limit CI to plan, validate, fmt, lint, and destroy-after-test |
| Renovate bot in addition to Dependabot | Two dependency bots create conflicting PRs and dueling commits | The project decision is Dependabot; one tool only |
| Slack / notification webhooks | Adds secrets management overhead for a small-team repo; GitHub's native notifications are sufficient | Use GitHub's built-in PR/issue notifications |
| Separate CHANGELOG.md per module | terraform-module-releaser generates GitHub release notes from commit history; a parallel CHANGELOG diverges | Rely on GitHub Releases as the changelog; link to them from module READMEs |

---

## Feature Details

### SKILL.md — AI Agent Instruction File

**Confidence:** HIGH (based on Anthropic's CLAUDE.md memory system, which SKILL.md mirrors)

SKILL.md is the most important file in the repo for AI agent operation. Agents (Claude Code, Copilot) read it before performing any work. It must be machine-parseable, section-structured, and contain explicit rules — not aspirational prose.

**Required sections:**

```markdown
# SKILL.md — Terraform Registry Operational Guide

## What This Repo Is
[2-3 sentence description: monorepo, providers covered, consumption model]

## Module Structure
modules/{provider}/{resource}/
├── main.tf          # Resources only
├── variables.tf     # Inputs with type constraints and validation blocks
├── outputs.tf       # Outputs: always include at minimum the primary resource ID
├── terraform.tf     # required_providers block; pin to minor version (~>X.Y)
└── tests/
    ├── example/
    │   └── main.tf  # Full working example; must init/plan/apply/destroy cleanly
    └── unit/
        └── module.tftest.hcl  # terraform test assertions

## Adding a New Module
1. Create directory at modules/{provider}/{resource}/
2. Copy scaffold from modules/docker/container/ as template
3. Update terraform.tf with correct provider and version
4. Implement resources in main.tf
5. Define all variables in variables.tf with description, type, and validation
6. Add outputs.tf with at least the primary resource ID
7. Write tests/example/main.tf demonstrating all required + key optional variables
8. Write tests/unit/module.tftest.hcl with at least one plan-mode assertion
9. Open PR with title: feat(modules/{provider}/{resource}): add {resource} module
10. CI must pass (fmt, tflint, trivy, terraform test) before merge

## Commit Conventions
This repo uses Conventional Commits. Every commit MUST follow this format:
  type(scope): description

Types and their semver impact:
| type  | semver impact | when to use |
|-------|---------------|-------------|
| feat  | minor bump    | new variable, new output, new resource type in module |
| fix   | patch bump    | bug fix, incorrect default, type mismatch correction |
| chore | no bump       | CI config, .gitignore, tooling, non-module changes |
| docs  | no bump       | README, SKILL.md, comments only |
| test  | no bump       | test file changes only |
| BREAKING CHANGE | major bump | footer "BREAKING CHANGE: <description>" in commit body |

Scope = module path, e.g., modules/docker/container
Full example: feat(modules/docker/container): add restart_policy validation block

CRITICAL: BREAKING CHANGE commits require human PR approval before merge.
Do NOT auto-merge PRs containing "BREAKING CHANGE" in the commit message body.

## Module Source Pattern (for consumer configs)
module "container" {
  source = "git::https://github.com/Schillman/terraform-registry.git//modules/docker/container?depth=1&ref=modules/docker/container/v1.2.0"
}
Always use the latest tag for the module. Never pin to `main` or a commit SHA.

## CI/CD Pipeline
Triggered on: all PRs to main, all pushes to main
Jobs (run in parallel where possible):
- lint: terraform fmt -check, tflint, markdownlint
- security: trivy (fail on HIGH/CRITICAL)
- test: terraform test (per module; plan mode only in CI)
- release: terraform-module-releaser (main branch only, after merge)

If any job fails: fix the issue before creating new commits.
Never push --force to main.

## PR Rules
- Title: {type}({scope}): {description} (Conventional Commits format)
- Body: use PR template (.github/pull_request_template.md)
- All CI checks must pass
- BREAKING CHANGE PRs: add label "breaking-change" and request human review
- Routine feat/fix PRs: can be auto-merged once CI passes

## What NOT to Do
- Do NOT create version tags manually (terraform-module-releaser handles all tags)
- Do NOT commit *.tfstate, *.tfvars, .terraform/ directories
- Do NOT nest modules deeper than modules/{provider}/{resource}/
- Do NOT run terraform apply in CI (plan and validate only)
- Do NOT modify SKILL.md without human approval
```

**Placement:** Repo root as `SKILL.md`. Also create a symlink or duplicate as `CLAUDE.md` — Claude Code specifically looks for `CLAUDE.md` in the project root and parent directories before any work session begins.

**CLAUDE.md vs SKILL.md:** CLAUDE.md is the Claude Code-specific memory file. SKILL.md is the generic agent instruction file. For maximum compatibility, maintain both: `CLAUDE.md` that sources/imports or directly mirrors the content of `SKILL.md`. Alternatively, `CLAUDE.md` can simply `@import SKILL.md` syntax if supported, or be a brief wrapper that says "See SKILL.md for full operational guide."

---

### GitHub PR Template

**Confidence:** HIGH (standard GitHub feature, well-established pattern)

**File:** `.github/pull_request_template.md`

```markdown
## Summary
<!-- What does this PR do? One sentence. -->

## Type
<!-- Check one -->
- [ ] feat — new feature or variable (minor version bump)
- [ ] fix — bug fix (patch version bump)
- [ ] chore — tooling, CI, non-module (no version bump)
- [ ] docs — documentation only (no version bump)
- [ ] BREAKING CHANGE — incompatible interface change (major version bump — requires human approval)

## Module(s) Affected
<!-- e.g., modules/docker/container -->

## Testing
- [ ] `terraform fmt -recursive` passes locally
- [ ] `terraform validate` passes for affected module(s)
- [ ] `terraform test` passes for affected module(s)
- [ ] Trivy scan passes (no HIGH/CRITICAL)
- [ ] Example in `tests/example/main.tf` updated if interface changed
- [ ] `outputs.tf` updated if new resources added

## Breaking Changes
<!-- If BREAKING CHANGE: describe what consumers must change in their configs -->

## Notes for Reviewers
<!-- Anything unusual, context, or decisions made -->
```

---

### GitHub Issue Templates

**Confidence:** HIGH

Two templates are sufficient. More than two creates overhead.

**`.github/ISSUE_TEMPLATE/bug_report.yml`** (YAML front-matter format, preferred over MD):
```yaml
name: Bug Report
description: Report a bug in an existing module
labels: ["bug"]
body:
  - type: input
    id: module
    attributes:
      label: Module
      placeholder: "modules/docker/container"
    validations:
      required: true
  - type: input
    id: version
    attributes:
      label: Module Version
      placeholder: "v1.2.0"
    validations:
      required: true
  - type: textarea
    id: description
    attributes:
      label: What happened?
    validations:
      required: true
  - type: textarea
    id: expected
    attributes:
      label: What did you expect?
    validations:
      required: true
  - type: textarea
    id: repro
    attributes:
      label: Reproduction (Terraform config snippet)
      render: hcl
```

**`.github/ISSUE_TEMPLATE/new_module.yml`**:
```yaml
name: New Module Request
description: Request a new Terraform module
labels: ["enhancement"]
body:
  - type: input
    id: provider
    attributes:
      label: Provider
      placeholder: "docker, azurerm"
    validations:
      required: true
  - type: input
    id: resource
    attributes:
      label: Resource Type
      placeholder: "container, network, volume"
    validations:
      required: true
  - type: textarea
    id: use_case
    attributes:
      label: Use Case
    validations:
      required: true
```

---

### CODEOWNERS Configuration

**Confidence:** HIGH (GitHub official documentation is well-known)

**File:** `.github/CODEOWNERS`

**Pattern for module monorepo:**
```
# Default owner for everything
* @Schillman

# Per-module ownership (add as modules grow and team expands)
/modules/docker/    @Schillman
/modules/azurerm/   @Schillman

# CI/CD and tooling — human must always approve
/.github/           @Schillman
/SKILL.md           @Schillman
/CLAUDE.md          @Schillman
```

**Rules that matter for AI-operated repos:**
- The `*` catch-all pattern ensures no PR is ever ownerless
- Module-directory-level patterns (`/modules/docker/`) allow future fine-grained team ownership as modules multiply
- `.github/` and `SKILL.md` should be human-only review — agents should not modify their own operating instructions autonomously
- CODEOWNERS review is automatically required on PRs that touch owned paths (requires "Require review from CODEOWNERS" branch protection rule)
- Glob `**` does NOT work in CODEOWNERS — use single `*` for subdirectory matching. The pattern `/modules/docker/` matches all files under that directory without needing `**`

**BREAKING CHANGE detection gap:** GitHub cannot natively route PRs by commit message content. The CODEOWNERS approach for BREAKING CHANGE enforcement works only if agents add a `breaking-change` label and the CODEOWNERS rule applies to a sentinel file (e.g., a `BREAKING_CHANGES.md` that agents must touch for every breaking change PR). A GitHub Actions workflow checking for `BREAKING CHANGE` in commit messages and adding a required label is the more reliable approach.

---

### Branch Protection Rules

**Confidence:** MEDIUM (based on GitHub docs knowledge through August 2025; verify exact settings in GitHub UI)

**Recommended ruleset for `main` branch:**

```
Branch: main
Settings:
  - Require a pull request before merging: YES
    - Require approvals: 0 (for routine feat/fix — CI alone is sufficient)
    - Dismiss stale pull request approvals when new commits are pushed: YES
    - Require review from Code Owners: YES
  - Require status checks to pass before merging: YES
    - Required checks: lint, security, test (all CI jobs)
    - Require branches to be up to date before merging: YES
  - Require conversation resolution before merging: YES
  - Require signed commits: NO (agents cannot GPG-sign; skip unless security model demands it)
  - Do not allow bypassing the above settings: YES (applies to admins too)
  - Allow force pushes: NO
  - Allow deletions: NO
```

**For BREAKING CHANGE PRs specifically:** Use a GitHub Actions workflow that detects `BREAKING CHANGE` in commit messages and auto-assigns the CODEOWNER as required reviewer OR adds a required label. The built-in branch protection cannot filter by commit message content.

**GitHub Rulesets vs. Classic Branch Protection:** GitHub Rulesets (available in all plans as of 2024) are preferred over Classic Branch Protection for new repos — they support more conditions, inheritance, and bypass lists. Consider migrating if not already using Rulesets.

---

### terraform-module-releaser Wiki Structure

**Confidence:** LOW — verified from training data and GitHub repo README but wiki output format not confirmed against live docs. Treat as hypothesis requiring validation during implementation.

terraform-module-releaser automatically creates and updates a GitHub Wiki with the following structure when integrated:

**Auto-generated pages (per module):**
- `modules/docker/container` — one wiki page per module containing: current version, changelog of releases, inputs table, outputs table, usage example sourced from terraform-docs output

**Seeding the wiki (what to do manually before first release):**
1. Enable GitHub Wiki on the repository settings
2. Create a `Home.md` manually as the wiki index. terraform-module-releaser does not create Home.md — it only creates module-specific pages
3. `Home.md` should contain: repo description, link to SKILL.md, link to each module wiki page (agents should update this when adding new modules)

**Example Home.md seed content:**
```markdown
# Terraform Registry Wiki

Auto-generated module documentation. Each page is maintained by
[terraform-module-releaser](https://github.com/techpivot/terraform-module-releaser).

## Modules

| Module | Latest Version | Source |
|--------|---------------|--------|
| [docker/container](modules/docker/container) | See page | `git::https://github.com/Schillman/terraform-registry.git//modules/docker/container` |

## Agent Guidance

See [SKILL.md](https://github.com/Schillman/terraform-registry/blob/main/SKILL.md) for
operational instructions for AI agents.
```

**Important:** The wiki is a separate Git repository (`<repo>.wiki.git`). terraform-module-releaser needs write permissions to the wiki repo — ensure `GITHUB_TOKEN` permissions include `contents: write` on the wiki endpoint or use a PAT with wiki write scope.

---

### README Structure — Root vs Module

**Confidence:** HIGH (established community standard for Terraform module repos)

**Root `README.md` structure:**
```
# Terraform Registry

Badge row: CI status | License | Terraform version

## Overview
[2-3 sentences: what this repo is, who it's for, consumption model]

## Modules

| Module | Description | Latest Version | Source |
|--------|-------------|----------------|--------|
| [docker/container](modules/docker/container/) | Docker container provisioning | v1.x.x | `git::https://github.com/Schillman/terraform-registry.git//modules/docker/container` |

## Usage

Quick-start example showing the full source URL with depth=1 and ref:
```hcl
module "container" {
  source = "git::https://github.com/Schillman/terraform-registry.git//modules/docker/container?depth=1&ref=modules/docker/container/v1.0.0"
  ...
}
```

## Contributing
Link to SKILL.md and PR template.

## License
```

**Per-module `README.md` structure (terraform-docs enforced):**
```
# Module: docker/container

[One-line description]

## Usage

[Full example with all required variables — copy from tests/example/main.tf]

## Requirements

[Auto-generated by terraform-docs — do not edit manually]

<!-- BEGIN_TF_DOCS -->
[terraform-docs injects: Requirements, Providers, Modules, Resources, Inputs, Outputs tables]
<!-- END_TF_DOCS -->

## Notes

[Manual section for gotchas, security considerations, known limitations]
```

The `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` markers are mandatory — terraform-docs replaces content between these markers on each run. Everything outside the markers is preserved and can be written manually.

---

### AI-Operated Repo Conventions (2025–2026)

**Confidence:** MEDIUM — based on training data through August 2025 plus emerging patterns visible in open-source Anthropic and community tooling.

**Emerging conventions observed:**

1. **CLAUDE.md is a first-class file.** Claude Code reads `CLAUDE.md` (and `~/.claude/CLAUDE.md`) before any session. Repos that want consistent agent behavior should maintain a `CLAUDE.md` at root. This is the Claude equivalent of SKILL.md and should exist alongside it.

2. **Explicit agent autonomy levels.** Repos are beginning to define an "autonomy matrix" — a table stating which operations agents can perform autonomously vs. which require human approval. For infrastructure repos, the pattern is: read/explore (always autonomous), feat/fix commits to non-breaking modules (autonomous), BREAKING CHANGE (human approval required), CODEOWNERS file changes (human approval required).

3. **Agent-readable operation checklists.** Rather than prose descriptions, the convention is markdown checklists with exact commands. Agents can check items off as they complete them and are less likely to miss steps when the format is a list.

4. **Commit-message-as-configuration.** terraform-module-releaser, semantic-release, and similar tools make commit messages the primary configuration mechanism for versioning. Repos explicitly teach agents the commit type-to-outcome mapping rather than expecting agents to infer it.

5. **"Never modify your own instructions" rule.** A consistent rule across AI-operated repos: agents must not autonomously modify SKILL.md, CLAUDE.md, or CODEOWNERS. These files require human review. Encoding this explicitly in SKILL.md and branch protection prevents self-modification feedback loops.

6. **Test-first for infrastructure.** Agents that write modules without tests create untested infrastructure that passes CI linting but fails at apply time. The convention is requiring `terraform test` to pass in CI before any module PR merges — this forces agents to write tests as part of the module creation task.

---

## Feature Dependencies

```
Conventional Commits enforcement
  → terraform-module-releaser (requires CC to function)
    → Module-scoped Git tags (generated by releaser)
      → Consumer source URLs (depend on tag format)

SKILL.md
  → Agent knows commit conventions → CC enforcement has effect
  → Agent knows module scaffold → New modules pass CI

CODEOWNERS
  → Branch protection "require CODEOWNERS review" must be enabled
    → CODEOWNERS review gates take effect on PRs

terraform-docs enforcement (CI)
  → Per-module README is always current
    → Wiki pages generated by terraform-module-releaser are accurate

outputs.tf in every module
  → Consumers can compose modules (pass container ID to next module)
```

---

## MVP Recommendation

For the "make this repo professional and AI-agent-friendly" milestone, prioritize in this order:

1. **Migrate module to `modules/docker/container/`** — unblocks terraform-module-releaser; everything downstream depends on namespaced structure
2. **SKILL.md + CLAUDE.md** — enables all subsequent agent work to follow correct conventions; write this before agents touch anything else
3. **terraform-module-releaser integration** — auto-versioning is the core value unlock; releases, wiki, tags all flow from this
4. **`outputs.tf` for docker/container** — currently missing; table stake for any module consumer
5. **terraform-docs enforcement in CI** — README always reflects actual variables/outputs
6. **Trivy security scan in CI** — required for "production-ready" claim
7. **`terraform test` in CI** — native test framework per module
8. **CODEOWNERS + branch protection** — governance layer; needed before repo is shared broadly
9. **PR/issue templates** — quality gate for both agents and humans
10. **Dependabot** — maintenance automation; low urgency but should not be deferred past first month
11. **Pre-commit hook configuration** — nice-to-have for local dev; CI is the real gate

**Defer:**
- Terratest (Go): Complexity is high relative to current module count; add when module count > 3 and test complexity warrants it
- `.tflint.hcl` with provider plugins: Add when Azure modules are introduced
- Wiki `Home.md` seeding: Do after first terraform-module-releaser release so the wiki exists

---

## Sources

- `/Users/p950cvo/Files/p-repositories/terraform-registry/.planning/PROJECT.md` — project goals and constraints (HIGH confidence — authoritative for this project)
- `/Users/p950cvo/Files/p-repositories/terraform-registry/.planning/codebase/` — existing codebase analysis (HIGH confidence)
- Anthropic Claude Code memory system (CLAUDE.md): training data knowledge through August 2025 (HIGH confidence for CLAUDE.md conventions)
- GitHub CODEOWNERS documentation: training data knowledge through August 2025 (HIGH confidence for syntax; verify current UI for Rulesets)
- terraform-module-releaser GitHub repo: training data knowledge (LOW confidence for wiki output format — verify against `techpivot/terraform-module-releaser` README during implementation)
- Terraform documentation for `terraform test` framework (>= 1.6): training data (MEDIUM confidence — framework is stable but check for updates)
- Community patterns for AI-operated IaC repos: training data + emerging conventions (MEDIUM confidence — fast-moving area)
