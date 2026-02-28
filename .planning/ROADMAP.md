# Roadmap: Terraform Module Mono Repo

## Overview

This roadmap transforms a single Docker container module in a flat directory structure into a professional, AI-agent-operated Terraform module monorepo with automated versioning, documentation, security scanning, testing, and maintenance. The six phases follow a strict dependency chain: the namespaced directory structure and agent conventions must be correct before any tooling is configured, releases must flow before documentation references version tags, and quality gates must exist before the module count grows. Every phase delivers a verifiable capability that unblocks the next.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation** - Migrate module to namespaced path and establish agent conventions
- [ ] **Phase 2: Automated Releases** - Wire up terraform-module-releaser and validate end-to-end
- [ ] **Phase 3: Documentation and Governance** - Enforce terraform-docs and establish CODEOWNERS, branch protection, PR/issue templates
- [ ] **Phase 4: Quality Gates** - Add dedicated TFLint and Trivy security scanning to CI
- [ ] **Phase 5: Testing** - Add native terraform test framework and pre-commit hooks
- [ ] **Phase 6: Maintenance Automation** - Configure Dependabot and scaffold Terratest stubs

## Phase Details

### Phase 1: Foundation
**Goal**: The Docker container module lives at its permanent namespaced path, agents have written operational instructions, and all downstream tooling prerequisites are satisfied
**Depends on**: Nothing (first phase -- unconditional prerequisite for all other phases)
**Requirements**: STRC-01, STRC-02, STRC-03, STRC-04, STRC-05, STRC-06, AGNT-01, AGNT-02, AGNT-03, AGNT-04, AGNT-05, MAINT-02
**Success Criteria** (what must be TRUE):
  1. `modules/docker/container/` exists and contains `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`, and a `tests/` directory
  2. `versions.tf` declares `terraform { required_version = "~> 1.9" }` (not `~> 1.5`, not named `terraform.tf`)
  3. `SKILL.md` at repo root documents commit conventions (type-to-semver mapping), module scaffold pattern, autonomy matrix, and consumer source URL pattern -- with `depth=1` explicitly excluded from version-pinned ref examples
  4. `CLAUDE.md` at repo root references or mirrors `SKILL.md` for Claude Code agents
  5. Old directory `modules/terraform-docker-container/` contains a deprecation stub pointing consumers to the new path; old Git tags are preserved
**Key Deliverables**:
  - `modules/docker/container/main.tf` (migrated)
  - `modules/docker/container/variables.tf` (migrated)
  - `modules/docker/container/outputs.tf` (created or migrated)
  - `modules/docker/container/versions.tf` (renamed from `terraform.tf`, version bumped)
  - `modules/docker/container/README.md` (migrated)
  - `modules/docker/container/tests/` (directory created)
  - `modules/terraform-docker-container/` (deprecation stub)
  - `SKILL.md` (new)
  - `CLAUDE.md` (new)
  - `.markdownlintignore` (excludes `.planning/`)
**UAT**:
  - Run `ls modules/docker/container/` and confirm all six files are present
  - Run `grep "required_version" modules/docker/container/versions.tf` and confirm `~> 1.9`
  - Confirm no file named `terraform.tf` exists in `modules/docker/container/`
  - Open `SKILL.md` and confirm it contains: commit convention table, module scaffold, autonomy matrix, consumer URL pattern without `depth=1` on version-pinned refs
  - Open `modules/terraform-docker-container/README.md` and confirm deprecation notice
**Research flag**: None -- standard patterns, build order is deterministic

**Critical constraints**:
- This phase is an unconditional prerequisite. No other phase can start until the module is at `modules/docker/container/` and `SKILL.md` exists
- `depth=1` must NOT appear in any version-pinned source URL examples (Pitfall 3)
**Plans**: TBD

Plans:
- [ ] 01-01: TBD
- [ ] 01-02: TBD

---

### Phase 2: Automated Releases
**Goal**: Every conventional commit merged to main automatically produces a module-scoped semantic version tag, a GitHub Release with generated notes, and a wiki page -- validated with a real test commit
**Depends on**: Phase 1 (module must be at namespaced path for tag format to work)
**Requirements**: REL-01, REL-02, REL-03, REL-04, REL-05, REL-06, QUAL-06
**Success Criteria** (what must be TRUE):
  1. A `feat:` commit merged to main creates a Git tag in format `modules/docker/container/v1.0.0` (validated with a real test commit, not just workflow syntax check)
  2. A GitHub Release is auto-generated with notes derived from commit messages
  3. PR titles that do not match Conventional Commits regex are rejected by CI
  4. The GitHub Wiki contains a page for the Docker container module (wiki initialized manually before first release)
  5. `release.yaml` workflow has explicit `permissions: contents: write, pull-requests: write` and uses `fetch-depth: 0`
**Key Deliverables**:
  - `.github/workflows/release.yaml` (new)
  - PR title validation CI step (new workflow or job in existing workflow)
  - GitHub Wiki initialized (manual step via GitHub UI)
  - First release tag `modules/docker/container/v1.0.0` (created by automation)
**UAT**:
  - Push a `feat: add initial module` commit to a branch, merge via PR, and confirm the tag `modules/docker/container/v1.0.0` appears under repository tags
  - Confirm a GitHub Release exists with auto-generated notes
  - Open a PR with title "did some stuff" and confirm CI fails the title check
  - Open a PR with title "feat: add thing" and confirm CI passes the title check
  - Navigate to the repository Wiki and confirm a Docker container module page exists
**Research flag**: Needs validation -- verify terraform-module-releaser's module detection for two-level `modules/{provider}/{resource}` paths against https://github.com/techpivot/terraform-module-releaser before assuming it works. Do NOT mark Phase 2 complete until a real tag is confirmed.

**Critical constraints**:
- Phase 2 must validate with a real test commit before being marked complete (Pitfall 2 -- silent failure on two-level paths)
- GITHUB_TOKEN must have write permissions (Pitfall 6 -- action exits green but creates nothing)
**Plans**: TBD

Plans:
- [ ] 02-01: TBD
- [ ] 02-02: TBD

---

### Phase 3: Documentation and Governance
**Goal**: Module READMEs are always current (auto-generated from source), breaking changes are detected before they reach consumers, structural repo files are protected from unauthorized changes, and agent PRs for routine changes merge without human intervention
**Depends on**: Phase 2 (documentation references version tags that must exist; governance protects a pipeline that must be working)
**Requirements**: DOCS-01, DOCS-02, DOCS-03, DOCS-04, DOCS-05, DOCS-06, GOV-01, GOV-02, GOV-03, GOV-04, GOV-05
**Success Criteria** (what must be TRUE):
  1. Module README contains auto-generated inputs/outputs section between `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` markers, kept current by CI
  2. The terraform-docs CI commit uses `[skip ci]` in its commit message (no infinite CI loops)
  3. `TAGS.json` is committed to each module directory by the release workflow, containing module name, release version, and latest commit author
  4. `tfbreak` runs in CI on PRs to detect breaking Terraform configuration changes; PRs with breaking changes are flagged for human review
  5. CODEOWNERS requires human review for `/.github/`, `/SKILL.md`, `/CLAUDE.md` but does NOT cover `modules/` (agent autonomy preserved)
  6. An agent `feat:` PR that passes all CI checks merges automatically without human review
  7. PR template includes Conventional Commits checklist; issue templates exist for bug reports and new module requests
**Key Deliverables**:
  - `.terraform-docs.yml` at repo root (new)
  - terraform-docs CI step (new workflow or addition to existing)
  - `TAGS.json` generation step in `release.yaml` (new)
  - `tfbreak` CI step in lint or governance workflow (new)
  - `CODEOWNERS` (new)
  - Branch protection rules on `main` (configured via GitHub UI or API)
  - `.github/workflows/auto-merge.yaml` or equivalent (new)
  - `.github/PULL_REQUEST_TEMPLATE.md` (new)
  - `.github/ISSUE_TEMPLATE/bug_report.yml` (new)
  - `.github/ISSUE_TEMPLATE/new_module.yml` (new)
  - Root `README.md` updated with module listing, source URL pattern, and version badge
**UAT**:
  - Modify a variable in `modules/docker/container/variables.tf`, push, and confirm CI auto-commits updated README with `[skip ci]` -- no second CI run triggered
  - Confirm `modules/docker/container/TAGS.json` is created/updated after a release with correct module name, version, and author fields
  - Open a PR that introduces a breaking change (remove a required variable) and confirm tfbreak flags it for human review
  - Open a PR that modifies `.github/workflows/release.yaml` and confirm CODEOWNERS requires human review
  - Open a PR that modifies `modules/docker/container/main.tf` and confirm CODEOWNERS does NOT require human review
  - Confirm branch protection on `main`: no direct pushes, no force pushes, CI checks required
  - Confirm PR template renders when creating a new PR
**Research flag**: tfbreak is a newer tool -- verify current installation method, CI integration pattern, and output format before implementation

**Critical constraints**:
- CODEOWNERS must NOT cover `modules/` (Pitfall 8 -- blocks agent auto-merge)
- terraform-docs CI commit must use `[skip ci]` (Pitfall 5 -- infinite loop)
- tfbreak is complementary to tflint, not a replacement -- both must run
**Plans**: TBD

Plans:
- [ ] 03-01: TBD
- [ ] 03-02: TBD

---

### Phase 4: Quality Gates
**Goal**: Every PR is automatically scanned for Terraform misconfigurations and security issues, with severity-appropriate gating that does not block intentional homelab configurations
**Depends on**: Phase 3 (governance and branch protection must be active so quality gates actually block merges)
**Requirements**: QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05
**Success Criteria** (what must be TRUE):
  1. `terraform fmt -check` runs recursively on all `.tf` files in CI and fails the PR if formatting is wrong
  2. TFLint runs as a dedicated CI step (not super-linter's bundled version) with `.tflint.hcl` config and explicit plugin loading
  3. Trivy IaC scan blocks PRs on CRITICAL and HIGH severity findings; justified suppressions are documented in `.trivyignore`
  4. Trivy SARIF output appears in the GitHub Security tab AND a PR comment is posted with the scan results
  5. A PR introducing a known CRITICAL misconfiguration is blocked by CI
**Key Deliverables**:
  - `.tflint.hcl` at repo root (new)
  - Updated `.github/workflows/lint.yaml` with dedicated TFLint step and Trivy step
  - `.trivyignore` (new, with justified suppressions for homelab configs)
  - SARIF upload step in lint workflow
**UAT**:
  - Submit a PR with an unformatted `.tf` file and confirm CI fails on `terraform fmt -check`
  - Submit a PR with a TFLint violation and confirm CI fails on the TFLint step
  - Submit a PR with a Trivy CRITICAL finding and confirm CI blocks the merge
  - Navigate to repository Security tab and confirm Trivy SARIF results are visible
  - Confirm `.trivyignore` contains documented suppressions (e.g., `network_mode: host` for Docker)
**Research flag**: None -- Trivy config mode and TFLint plugin configuration are stable. Verify current version numbers before pinning.

**Critical constraints**:
- TFLint must be a dedicated step, not super-linter's bundled version (cannot load provider plugins)
- Trivy severity filter must be CRITICAL,HIGH only (avoid false positives on homelab configs)
**Plans**: TBD

Plans:
- [ ] 04-01: TBD

---

### Phase 5: Testing
**Goal**: Every module has plan-mode unit tests that run in CI on every PR, and developers have a local pre-commit configuration that mirrors CI checks
**Depends on**: Phase 4 (quality gates must exist so the test workflow runs alongside lint and security)
**Requirements**: TEST-01, TEST-02, TEST-03, TEST-04, TEST-05, TEST-06
**Success Criteria** (what must be TRUE):
  1. `modules/docker/container/tests/unit.tftest.hcl` exists and contains plan-mode assertions (no real infrastructure provisioned)
  2. `modules/docker/container/tests/example/main.tf` uses `source = "../../"` (relative path, NOT the published Git URL)
  3. `test.yaml` matrix workflow detects changed modules via `git diff` and runs `terraform test` only for changed modules
  4. A PR modifying `modules/docker/container/` triggers `terraform test` for that module and CI reports pass/fail
  5. `.pre-commit-config.yaml` exists with hooks for: terraform fmt, terraform validate, tflint, terraform-docs, trivy, and conventional-pre-commit (commit-msg stage)
**Key Deliverables**:
  - `modules/docker/container/tests/unit.tftest.hcl` (new)
  - `modules/docker/container/tests/example/main.tf` (new or updated)
  - `modules/docker/container/tests/example/versions.tf` (new)
  - `modules/docker/container/tests/example/.terraform.lock.hcl` (committed)
  - `.github/workflows/test.yaml` (new)
  - `.pre-commit-config.yaml` at repo root (new)
**UAT**:
  - Run `terraform test` locally from `modules/docker/container/` and confirm plan-mode tests pass
  - Confirm `tests/example/main.tf` contains `source = "../../"` (not a Git URL)
  - Push a PR that modifies `modules/docker/container/main.tf` and confirm the test workflow triggers for that module
  - Push a PR that modifies only root `README.md` and confirm the test workflow does NOT run terraform test (no modules changed)
  - Run `pre-commit run --all-files` locally and confirm all hooks execute
**Research flag**: Verify Terratest co-location convention (per-module `tests/go.mod` vs top-level `go.mod`) against current Gruntwork docs before Phase 6

**Critical constraints**:
- `hashicorp/setup-terraform@v3` must use `terraform_wrapper: false` (required for future Terratest compatibility)
- Test examples must use relative source paths, never the published Git URL (circular dependency)
**Plans**: TBD

Plans:
- [ ] 05-01: TBD
- [ ] 05-02: TBD

---

### Phase 6: Maintenance Automation
**Goal**: Terraform provider versions and GitHub Actions versions are automatically monitored for updates, and Terratest scaffolding is ready for when module count warrants it
**Depends on**: Phase 5 (all CI workflows must be stable before Dependabot opens PRs against them)
**Requirements**: MAINT-01
**Success Criteria** (what must be TRUE):
  1. `.github/dependabot.yml` exists with `github-actions` ecosystem (weekly) and at least one `terraform` entry for `modules/docker/container/` (monthly)
  2. Dependabot opens a PR within one week for any outdated GitHub Actions version
  3. `SKILL.md` documents the operational note: one `terraform` Dependabot entry is required per new module directory
**Key Deliverables**:
  - `.github/dependabot.yml` (new)
  - `SKILL.md` updated with Dependabot maintenance note (DOCS-05 cross-reference)
**UAT**:
  - Open `.github/dependabot.yml` and confirm both `github-actions` and `terraform` ecosystem entries are present
  - Confirm `terraform` entry targets `modules/docker/container/` directory
  - Wait for Dependabot's first scan cycle and confirm at least one version update PR is opened (or confirm no updates needed if all versions are current)
  - Open `SKILL.md` and confirm Dependabot maintenance note is present
**Research flag**: None -- Dependabot YAML schema is stable. Key operational note: one `terraform` entry required per module directory (does not recurse).

**Critical constraints**:
- Dependabot does not recurse into subdirectories for Terraform -- one explicit entry per module directory is mandatory
- Monthly interval for Terraform providers prevents PR volume from overwhelming agent queue
**Plans**: TBD

Plans:
- [ ] 06-01: TBD

---

## Coverage

### Requirement-to-Phase Mapping

| Requirement | Phase | Description |
|-------------|-------|-------------|
| STRC-01 | 1 | Namespaced module structure |
| STRC-02 | 1 | Module file inventory |
| STRC-03 | 1 | `versions.tf` naming |
| STRC-04 | 1 | Terraform `~> 1.9` constraint |
| STRC-05 | 1 | Docker module migration |
| STRC-06 | 1 | Old directory deprecation stub |
| AGNT-01 | 1 | SKILL.md creation |
| AGNT-02 | 1 | CLAUDE.md creation |
| AGNT-03 | 1 | Commit type-to-semver mapping |
| AGNT-04 | 1 | Autonomy matrix |
| AGNT-05 | 1 | Consumer URL without `depth=1` |
| MAINT-02 | 1 | `.markdownlintignore` for `.planning/` |
| REL-01 | 2 | terraform-module-releaser workflow |
| REL-02 | 2 | `fetch-depth: 0` and permissions |
| REL-03 | 2 | Module-scoped Git tags |
| REL-04 | 2 | Auto-generated release notes |
| REL-05 | 2 | Wiki initialization and population |
| REL-06 | 2 | First release validation |
| QUAL-06 | 2 | PR title Conventional Commits validation |
| DOCS-01 | 3 | terraform-docs inject markers |
| DOCS-02 | 3 | CI auto-generates README with `[skip ci]` |
| DOCS-03 | 3 | `.terraform-docs.yml` config |
| DOCS-04 | 3 | Root README module listing |
| DOCS-05 | 3 | SKILL.md Dependabot maintenance note |
| DOCS-06 | 3 | TAGS.json per module with release metadata |
| GOV-01 | 3 | tfbreak breaking change detection in CI |
| GOV-02 | 3 | Branch protection on `main` |
| GOV-03 | 3 | Auto-merge for agent PRs |
| GOV-04 | 3 | PR template |
| GOV-05 | 3 | Issue templates |
| QUAL-01 | 4 | `terraform fmt -check` in CI |
| QUAL-02 | 4 | Dedicated TFLint CI step |
| QUAL-03 | 4 | Trivy CRITICAL/HIGH gating |
| QUAL-04 | 4 | `.trivyignore` for justified suppressions |
| QUAL-05 | 4 | Trivy SARIF to Security tab |
| TEST-01 | 5 | `unit.tftest.hcl` per module |
| TEST-02 | 5 | Example with relative source path |
| TEST-03 | 5 | Example `versions.tf` and lockfile committed |
| TEST-04 | 5 | `test.yaml` matrix with `git diff` detection |
| TEST-05 | 5 | `terraform_wrapper: false` |
| TEST-06 | 5 | `.pre-commit-config.yaml` |
| MAINT-01 | 6 | Dependabot configuration |

**Coverage: 43/43 v1 requirements mapped. No orphans.**

### Cross-Phase Dependency Chain

```
Phase 1: Foundation (unconditional prerequisite)
  |-- module at correct path (all tools need this)
  |-- SKILL.md written (agents need this before committing)
  v
Phase 2: Automated Releases
  |-- releases flowing (version tags, wiki, badges depend on this)
  v
Phase 3: Documentation and Governance
  |-- READMEs always current, repo access rules active
  v
Phase 4: Quality Gates
  |-- lint and security gates block bad PRs
  v
Phase 5: Testing
  |-- test matrix requires stable structure and working CI
  v
Phase 6: Maintenance Automation
  |-- all workflows stable before Dependabot opens PRs against them
```

## Progress

**Execution Order:**
Phases execute in numeric order: 1 --> 2 --> 3 --> 4 --> 5 --> 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 0/? | Not started | - |
| 2. Automated Releases | 0/? | Not started | - |
| 3. Documentation and Governance | 0/? | Not started | - |
| 4. Quality Gates | 0/? | Not started | - |
| 5. Testing | 0/? | Not started | - |
| 6. Maintenance Automation | 0/? | Not started | - |
