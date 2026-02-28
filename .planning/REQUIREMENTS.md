# Requirements: Terraform Module Mono Repo

**Defined:** 2026-02-28
**Core Value:** Every module is production-ready out of the box — versioned, documented, tested, and security-scanned automatically, so consumers can pin a `ref` and trust what they get.

## v1 Requirements

### Structure

- [x] **STRC-01**: Modules live at `modules/{provider}/{resource}` (namespaced, max 3 levels)
- [x] **STRC-02**: Every module contains `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`, and `tests/`
- [x] **STRC-03**: `versions.tf` (not `terraform.tf`) declares the `terraform {}` block and provider requirements
- [x] **STRC-04**: Terraform version constraint is `~> 1.9` (not `~> 1.5`) across all modules
- [x] **STRC-05**: Existing Docker module migrated from `modules/terraform-docker-container/` to `modules/docker/container/`
- [x] **STRC-06**: Old module directory fully deleted (user decision: no stub needed); old tags v0.0.1 and v1.0 preserved

### Agent Conventions

- [x] **AGNT-01**: `SKILL.md` at repo root documents commit conventions, module scaffold, autonomy matrix, and correct consumer source URL patterns
- [x] **AGNT-02**: `CLAUDE.md` at repo root mirrors or references `SKILL.md` for Claude Code agents
- [x] **AGNT-03**: Commit message type-to-semver mapping documented: `feat:` = minor, `fix:` = patch, `feat!:`/`fix!:` = major, `chore:`/`docs:`/`test:` = no release
- [x] **AGNT-04**: Autonomy matrix defined: agents may autonomously commit `feat:`/`fix:`. Breaking changes reported by tfbreak should be verified by a human before merging.
- [x] **AGNT-05**: Consumer source URL pattern documented without `depth=1` on version-pinned refs (documented pitfall)

### Releases

- [x] **REL-01**: `release.yaml` workflow integrates `terraform-module-releaser` for automated per-module semantic versioning
- [x] **REL-02**: Release workflow uses `fetch-depth: 0` and explicit `permissions: contents: write, pull-requests: write`
- [x] **REL-03**: Module-scoped Git tags are created in format `modules/{provider}/{resource}/vX.Y.Z`
- [x] **REL-04**: GitHub Release notes are auto-generated per module from commit messages
- [x] **REL-05**: GitHub Wiki is initialized manually and populated by terraform-module-releaser per module
- [x] **REL-06**: First release validated end-to-end: `feat:` commit on main creates `modules/docker/container/v1.0.0` tag

### Documentation

- [ ] **DOCS-01**: Every module `README.md` contains terraform-docs inject markers (`<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->`)
- [ ] **DOCS-02**: CI auto-generates and commits the inputs/outputs section of each module README via `terraform-docs` inject mode with `[skip ci]` commit message
- [ ] **DOCS-03**: `.terraform-docs.yml` at repo root defines consistent output format (sorted, type/description/required columns)
- [ ] **DOCS-04**: Root `README.md` lists all available modules with source URL pattern and version badge
- [ ] **DOCS-05**: `SKILL.md` includes Dependabot maintenance note: one `terraform` entry required per new module directory
- [ ] **DOCS-06**: The release workflow generates a `TAGS.json` file and commits it in each module directory containing the module name, release version, and the author of the latest commit. Modules that support a `tags` input variable should reference this file and be merged with the consumer inputs, so that deployed resources are automatically tagged with these module specific details.

### Quality Gates

- [ ] **QUAL-01**: `lint.yaml` workflow runs `terraform fmt -check` recursively on all `.tf` files
- [ ] **QUAL-02**: Dedicated TFLint CI step (not super-linter's bundled version) with `.tflint.hcl` and explicit plugin loading
- [ ] **QUAL-03**: Trivy IaC scan (`scan-type: config`) blocks on `CRITICAL` and `HIGH` severity findings
- [ ] **QUAL-04**: `.trivyignore` documents justified suppressions for intentional homelab configs (e.g., `network_mode: host`)
- [ ] **QUAL-05**: Trivy SARIF output uploaded to GitHub Security tab and PR commment should be made with the result.
- [x] **QUAL-06**: PR title validation CI step rejects titles that do not match Conventional Commits regex

### Testing

- [ ] **TEST-01**: Every module has `tests/unit.tftest.hcl` with plan-mode assertions (no real infrastructure)
- [ ] **TEST-02**: Every module has `tests/example/main.tf` using relative source path `source = "../../"` (not published Git URL)
- [ ] **TEST-03**: `tests/example/versions.tf` and `tests/example/.terraform.lock.hcl` committed for reproducible CI
- [ ] **TEST-04**: `test.yaml` matrix workflow detects changed modules via `git diff` and fans out `terraform test` per changed module
- [ ] **TEST-05**: `hashicorp/setup-terraform@v3` configured with `terraform_wrapper: false` for future Terratest compatibility
- [ ] **TEST-06**: `.pre-commit-config.yaml` mirrors CI: `terraform fmt`, `terraform validate`, `tflint`, `terraform-docs`, `trivy`, `conventional-pre-commit` (commit-msg stage)

### Governance

- [ ] **GOV-01**: Implement tfbreak to compare two Terraform configurations and reports breaking changes. tfbreak is complementary to tflint - use tflint for code quality and tfbreak for safe releases.
- [ ] **GOV-02**: Branch protection on `main`: require CI checks, require up-to-date branch, no direct pushes, no force pushes
- [ ] **GOV-03**: Auto-merge workflow merges agent `feat:`/`fix:` PRs that pass all CI checks without waiting for human review
- [ ] **GOV-04**: PR template includes Conventional Commits checklist and testing confirmation
- [ ] **GOV-05**: Issue templates for bug reports and new module requests

### Maintenance

- [ ] **MAINT-01**: `.github/dependabot.yml` with `github-actions` ecosystem (weekly) and one `terraform` entry per module directory (monthly)
- [x] **MAINT-02**: `.markdownlintignore` excludes `.planning/` from markdownlint rules (internal tooling docs)

## v2 Requirements

### Terratest

- **TTEST-01**: Terratest stub per module (`go.mod` + `integration_test.go`) co-located in `modules/{p}/{r}/tests/`
- **TTEST-02**: `test.yaml` matrix extended to run `go test` against changed modules
- **TTEST-03**: Dependabot `gomod` ecosystem entry per module tests directory

### Azure Modules

- **AZUR-01**: First Azure module scaffolded under `modules/azure/{resource}/`
- **AZUR-02**: `.tflint.hcl` updated with `tflint-ruleset-azurerm` plugin
- **AZUR-03**: Dependabot `terraform` entry added for `modules/azure/{resource}/` directory
- **AZUR-04**: Azure provider constraint uses minor-range pin (`>= 3.0, < 4.0`)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Terraform Cloud / HCP Registry publishing | No benefit over direct Git sourcing for this consumption model |
| Manual version tagging | Automated by terraform-module-releaser; manual tags create divergence |
| Remote state management in this repo | Consumers supply their own backend |
| AWS provider modules | Docker and Azure only for v1 |
| `depth=1` on version-pinned source URLs | Breaks once newer commits land; documented as incorrect in SKILL.md |
| Separate `CHANGELOG.md` per module | GitHub Releases serve as changelog; parallel file diverges |
| Renovate | Dependabot is simpler and GitHub-native; no extra tooling |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| STRC-01 | Phase 1 | Complete |
| STRC-02 | Phase 1 | Complete |
| STRC-03 | Phase 1 | Complete |
| STRC-04 | Phase 1 | Complete |
| STRC-05 | Phase 1 | Complete |
| STRC-06 | Phase 1 | Complete |
| AGNT-01 | Phase 1 | Complete |
| AGNT-02 | Phase 1 | Complete |
| AGNT-03 | Phase 1 | Complete |
| AGNT-04 | Phase 1 | Complete |
| AGNT-05 | Phase 1 | Complete |
| REL-01 | Phase 2 | Pending |
| REL-02 | Phase 2 | Pending |
| REL-03 | Phase 2 | Pending |
| REL-04 | Phase 2 | Pending |
| REL-05 | Phase 2 | Pending |
| REL-06 | Phase 2 | Pending |
| DOCS-01 | Phase 3 | Pending |
| DOCS-02 | Phase 3 | Pending |
| DOCS-03 | Phase 3 | Pending |
| DOCS-04 | Phase 3 | Pending |
| DOCS-05 | Phase 3 | Pending |
| DOCS-06 | Phase 3 | Pending |
| QUAL-01 | Phase 4 | Pending |
| QUAL-02 | Phase 4 | Pending |
| QUAL-03 | Phase 4 | Pending |
| QUAL-04 | Phase 4 | Pending |
| QUAL-05 | Phase 4 | Pending |
| QUAL-06 | Phase 2 | Pending |
| TEST-01 | Phase 5 | Pending |
| TEST-02 | Phase 5 | Pending |
| TEST-03 | Phase 5 | Pending |
| TEST-04 | Phase 5 | Pending |
| TEST-05 | Phase 5 | Pending |
| TEST-06 | Phase 5 | Pending |
| GOV-01 | Phase 3 | Pending |
| GOV-02 | Phase 3 | Pending |
| GOV-03 | Phase 3 | Pending |
| GOV-04 | Phase 3 | Pending |
| GOV-05 | Phase 3 | Pending |
| MAINT-01 | Phase 6 | Pending |
| MAINT-02 | Phase 1 | Complete |

**Coverage:**
- v1 requirements: 41 total
- Mapped to phases: 41
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-28*
*Last updated: 2026-02-28 after initial definition*
