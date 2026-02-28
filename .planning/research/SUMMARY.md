# Project Research Summary

**Project:** Terraform Module Monorepo — Professional AI-Agent-Friendly Toolchain
**Domain:** IaC Module Registry (self-hosted, Git-sourced, monorepo)
**Researched:** 2026-02-28
**Confidence:** MEDIUM (tool versions LOW — verify before pinning; integration patterns and dependency logic HIGH)

## Executive Summary

This project is a Terraform module monorepo that serves as a private module registry consumed via direct Git source URLs. The professional pattern for this type of repo centers on five interlocking systems: a namespaced directory structure (`modules/{provider}/{resource}`), conventional commit enforcement that drives automated per-module semantic versioning, a machine-generated documentation pipeline, a multi-layer quality gate (pre-commit locally and CI remotely), and an AI agent instruction file (`SKILL.md` / `CLAUDE.md`) that encodes all conventions before agents touch anything. The entire system is ordered around one tool — `terraform-module-releaser` — which expects the namespaced directory structure, reads conventional commits to determine version bumps, and emits module-scoped Git tags (`modules/docker/container/v1.2.0`) that consumers pin via `ref=` parameters. Configuring any other tool before the directory migration is wasted effort; the migration is the unconditional prerequisite.

The recommended approach is strict sequential execution: migrate the module to the namespaced path and write `SKILL.md` first, then integrate `terraform-module-releaser` and validate that it actually detects the two-level path, then add documentation enforcement (`terraform-docs`), then quality gates (TFLint, Trivy), then testing (`terraform test`), and finally governance and maintenance automation (CODEOWNERS, branch protection, Dependabot). Terratest is deliberately deferred until module count exceeds three — its Go setup cost is not warranted for a single module. This sequencing is structural, not stylistic: the releaser, the CI test matrix, and the consumer URL format all depend on the namespaced path being stable before they are configured.

The two highest-impact risks cut across the research findings. First: `depth=1` appears in the existing project docs and SKILL.md examples as a consumer URL option, but PITFALLS research shows it breaks any pinned version tag once newer commits land on `main`. This documentation error must be corrected in Phase 1 before any consumer-facing documentation is published. Second: AI agents routinely write `BREAKING CHANGE:` in commit body footers, which squash-merge discards — terraform-module-releaser then fires a `minor` bump instead of `major`, silently shipping breaking changes to pinned consumers. Both risks require SKILL.md rules and a PR title validation CI step, not just documentation.

## Key Findings

### Recommended Stack

See `.planning/research/STACK.md` for complete configurations, workflow snippets, and installation instructions.

The toolchain is almost entirely GitHub-native and avoids operational overhead from third-party services. `terraform-module-releaser` (techpivot) is the only purpose-built tool for module-scoped semver tagging in a monorepo — alternatives like `semantic-release` and `release-please` operate at repo level and cannot produce `modules/{p}/{r}/vX.Y.Z` tag format. The current Terraform version constraint `~>1.5` is a blocking problem: native `terraform test` requires >= 1.6, so the constraint must be bumped to `~>1.9` as part of Phase 1. The Docker provider constraint should simultaneously be loosened from an exact pin (`= 3.0.2`) to a minor-range pin (`>= 3.0.2, < 4.0.0`) so Dependabot can manage patch updates.

**Core technologies:**
- **Terraform ~> 1.9:** IaC runtime — current `~>1.5` blocks native `terraform test`; bump is required in Phase 1
- **terraform-module-releaser (techpivot):** Per-module semver tagging, GitHub Releases, wiki generation — no viable alternative for module-scoped tags
- **terraform-docs v0.19+ (inject mode):** Auto-generated README sections — `output-method: inject` preserves hand-written content outside markers
- **TFLint:** Static analysis via dedicated CI step with explicit `.tflint.hcl` — do NOT rely on super-linter's bundled TFLint, which cannot load provider plugins
- **Trivy (`scan-type: config`):** IaC misconfiguration scanning — replaced tfsec (Aqua acquired it); block on CRITICAL+HIGH only to avoid false positives on intentional homelab configs
- **antonbabenko/pre-commit-terraform:** Local quality gate wrapping terraform fmt, validate, tflint, docs, trivy in one hook collection
- **compilerla/conventional-pre-commit:** Commit-msg stage hook enforcing Conventional Commits — pure Python, no Node.js dependency
- **Native `terraform test`:** Plan-mode unit assertions via `.tftest.hcl` files, no real infrastructure; fast and self-contained
- **Dependabot:** One `terraform` ecosystem entry required per module directory (does not recurse)
- **Terratest (deferred):** Go-based deploy+assert+destroy; add when module count > 3

**File naming resolution:** Use `versions.tf` (not `terraform.tf`) for the `terraform {}` block everywhere. ARCHITECTURE.md establishes this as the community standard since Terraform 0.13; STACK.md examples that use `terraform.tf` should be treated as outdated references.

### Expected Features

See `.planning/research/FEATURES.md` for complete specifications including SKILL.md content, PR/issue templates, CODEOWNERS patterns, and branch protection rule settings.

**Must have (table stakes):**
- **SKILL.md + CLAUDE.md at repo root** — agents read before any session; without it, agents guess conventions and produce wrong commits or broken modules
- **Namespaced module structure `modules/{provider}/{resource}`** — terraform-module-releaser expects exactly this layout; flat naming breaks tag format and provider grouping
- **Conventional Commits enforcement** — terraform-module-releaser requires CC to drive semver; `feat:` = minor, `fix:` = patch, `BREAKING CHANGE:` footer = major, `chore:`/`docs:`/`test:` = no release
- **terraform-module-releaser integration** — core value unlock; versioning, releases, and wiki all flow from this
- **`outputs.tf` in every module** — currently missing from docker/container; required for consumers to compose modules
- **Per-module README.md via terraform-docs** — inject markers mandatory; CI auto-generates the inputs/outputs section
- **GitHub Actions CI on PR** — lint, fmt, tflint, security, test jobs must pass before merge
- **Trivy security scanning in CI** — gated on CRITICAL+HIGH only; `.trivyignore` for justified suppressions
- **Native `terraform test` per module** — plan-mode tests in CI; apply-mode integration optional
- **CODEOWNERS + branch protection** — structural paths protected; `modules/` intentionally excluded for agent autonomy
- **Dependabot** — per-module `terraform` entries + `github-actions` entries; monthly interval for Terraform providers
- **PR template + issue templates** — checklist input for agents and humans

**Should have (differentiators):**
- **Autonomy matrix in SKILL.md** — explicit table: which operations agents can do autonomously vs. require human approval
- **`validation` blocks in all variables** — fail at plan time with clear messages for restart_policy, network_mode, gpus, etc.
- **PR title validation CI step** — rejects PR titles that do not match Conventional Commits regex; catches both agent and human mistakes
- **Auto-merge workflow** — `feat:`/`fix:` agent PRs that pass CI merge automatically without waiting for human review
- **Version badges per module README** — consumers see current version at a glance
- **Wiki Home.md seeded** — must be created manually before first terraform-module-releaser run; action only creates module-specific pages, not Home.md

**Defer:**
- **Terratest** — Go test setup cost is not justified until module count > 3
- **`.tflint.hcl` Azure/Docker provider plugins** — add when Azure modules are introduced; no official Docker plugin exists
- **Separate CHANGELOG.md per module** — GitHub Releases serve as the changelog; a parallel CHANGELOG diverges
- **Terraform Cloud / HCP registry** — no benefit over direct Git sourcing for this consumption model

### Architecture Approach

See `.planning/research/ARCHITECTURE.md` for full directory tree, component boundaries, data flow, build order, and scalability analysis.

The architecture is a flat three-level monorepo with all test assets co-located inside each module (`modules/{provider}/{resource}/tests/`), three global GitHub Actions workflows (lint, test, release), and no per-module workflow files (GitHub Actions ignores workflow files outside `.github/workflows/` at repo root). The test workflow uses `git diff` to detect which modules changed and fans out a matrix of one job per changed module — this is more reliable than `paths:` trigger filters, which skip the entire workflow rather than the affected jobs. A critical architecture rule: `tests/example/main.tf` must use a relative source path (`source = "../../"`) in CI, not the published Git URL. Consuming the published URL in tests creates a circular dependency where CI would need to resolve a tag that may not exist yet, or uses `depth=1` and fails for the reasons described in Pitfall 3.

**Major components:**
1. **`modules/{provider}/{resource}/`** — self-contained module; public API = `variables.tf` + `outputs.tf`; must include `versions.tf` (not `terraform.tf`), `README.md` with terraform-docs markers, and `tests/` directory
2. **`.github/workflows/lint.yaml`** — global recursive: `terraform fmt -check`, explicit TFLint step, Trivy config scan, markdownlint
3. **`.github/workflows/test.yaml`** — matrix fan-out: `git diff`-based changed module detection, per-changed-module `terraform test` (and later Terratest)
4. **`.github/workflows/release.yaml`** — push-to-main only; terraform-module-releaser with `fetch-depth: 0` and explicit `permissions: contents: write, pull-requests: write`
5. **`SKILL.md` / `CLAUDE.md`** — agent operational guide: commit convention table, module scaffold, autonomy matrix, correct consumer source URL pattern (no `depth=1` on version-pinned refs)
6. **`.pre-commit-config.yaml`** — local mirror of CI checks; prevents CI-failing commits from landing in PRs

### Critical Pitfalls

See `.planning/research/PITFALLS.md` for full prevention configs, detection patterns, and phase assignments for all 13 documented pitfalls.

1. **BREAKING CHANGE signal lost in squash merges** — Agents write `BREAKING CHANGE:` in commit body footers; squash-merge discards the body and terraform-module-releaser fires `minor` instead of `major`. Prevention: mandate `feat!:` / `fix!:` shorthand in SKILL.md AND validate PR titles with a CI regex check (`^(feat|fix|...)(scope)?(!)?: .+`). The CI check is essential — SKILL.md alone relies on agents following instructions.

2. **terraform-module-releaser silent failure on two-level paths** — After migrating to `modules/docker/container/`, the action's module detection may silently skip modules it cannot find. Exits green, creates nothing. Prevention: push a test `feat:` commit immediately after wiring up the action and confirm a tag is created before treating the integration as complete.

3. **`depth=1` breaks version-pinned source URLs** — Once new commits land after a release, `depth=1` with an older pinned tag fails on `git clone --depth=1 --branch <tag>` because the tag is no longer HEAD. Prevention: remove `depth=1` from all version-pinned source URL examples before any consumer documentation is published. This is a documentation error in the existing project that must be corrected in Phase 1.

4. **Module migration breaks existing consumer refs** — Renaming the module directory orphans old tag references. Prevention: keep the old directory as a stub with a deprecation notice, do not delete old tags, update example source URLs to new format before the first release fires.

5. **terraform-docs CI commit-back causes infinite loop** — Without `[skip ci]` appended to the terraform-docs auto-commit message, every CI run triggers another CI run. Prevention: always include `[skip ci]` in the `git-commit-message` parameter of the terraform-docs action.

6. **GITHUB_TOKEN missing write permissions on release job** — Default token permissions changed to read-only in 2023. The action exits green but creates no tags or releases. Prevention: declare `permissions: contents: write, pull-requests: write` explicitly on the release workflow job.

## Implications for Roadmap

The combined research establishes an unambiguous dependency chain: the directory structure must be correct before any tooling is configured; agent instructions must exist before agents commit; releases must be validated before documentation references version tags; quality gates must be configured before they can block real module changes. This chain produces six phases with minimal discretionary reordering.

### Phase 1: Foundation — Module Migration and Agent Conventions

**Rationale:** Two prerequisites everything else depends on: the module at the correct namespaced path, and agents operating under written conventions. Neither can be deferred. The current `modules/terraform-docker-container/` path breaks terraform-module-releaser tag detection and produces wrong consumer URLs. Agents writing commits before SKILL.md exists will use incorrect commit types and create wrong version bumps.

**Delivers:**
- Module migrated from `modules/terraform-docker-container/` to `modules/docker/container/`
- `terraform.tf` renamed to `versions.tf`
- Terraform version constraint bumped from `~>1.5` to `~>1.9`
- Docker provider constraint loosened from `= 3.0.2` to `>= 3.0.2, < 4.0.0`
- `outputs.tf` created (minimal but present — required by consumers and terraform-docs)
- `SKILL.md` and `CLAUDE.md` at repo root: commit convention table, module scaffold, autonomy matrix, consumer source URL pattern with `depth=1` explicitly excluded from version-pinned refs
- Root `README.md` migration notice with before/after source snippets
- Old directory preserved as stub with deprecation notice; old tags NOT deleted

**Addresses:** Module structure (table stakes), SKILL.md + CLAUDE.md (table stakes), outputs.tf (table stakes), Terraform version bump (unblocks terraform test)

**Avoids:** Pitfall 4 (migration breaking existing consumers), Pitfall 1 (agents committing before conventions documented), Pitfall 3 (depth=1 error documented correctly before consumer docs published)

**Research flag:** Standard patterns — no deeper research needed. Build order is deterministic and documented in ARCHITECTURE.md.

---

### Phase 2: Automated Releases — terraform-module-releaser

**Rationale:** This is the core value unlock. All downstream features (version badges, consumer source URLs, wiki) depend on releases existing. Wire up and validate before any consumers pin to the repo. The wiki must be manually initialized before the first release fires — this is a one-time GitHub UI step, not a CI task.

**Delivers:**
- `release.yaml` workflow with `permissions: contents: write, pull-requests: write`
- `fetch-depth: 0` on release workflow checkout (required for changelog generation)
- PR title validation CI step enforcing Conventional Commits regex
- Wiki initialized manually via GitHub UI (one-time prerequisite)
- First test release validated: push a `feat:` commit and confirm tag `modules/docker/container/v1.0.0` is created

**Addresses:** terraform-module-releaser integration (table stakes), module-scoped Git tags (table stakes), PR title validation (differentiator)

**Avoids:** Pitfall 2 (module detection silent failure — validate with test commit), Pitfall 9 (GITHUB_TOKEN permissions), Pitfall 11 (missing fetch-depth), Pitfall 12 (wiki not initialized)

**Research flag:** Needs validation — verify terraform-module-releaser's current module detection for two-level `modules/{provider}/{resource}` paths against https://github.com/techpivot/terraform-module-releaser before assuming it works. Treat the integration as unproven until a real tag is created.

---

### Phase 3: Documentation Enforcement — terraform-docs and Governance

**Rationale:** Once releases are flowing, README accuracy becomes a real maintenance problem. This phase also establishes governance (CODEOWNERS, branch protection) before the repo is shared. Governance design must specifically accommodate agent autonomy — a naive CODEOWNERS catch-all blocks all agent PRs.

**Delivers:**
- `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` markers added to all module READMEs
- `.terraform-docs.yml` at repo root with inject mode, sorted output, type/description/required columns
- CI step using `terraform-docs/gh-actions` with `output-method: inject`, `git-push: true`, `[skip ci]` on commit message
- CODEOWNERS: `/.github/`, `/SKILL.md`, `/CLAUDE.md` require human review; `modules/` intentionally excluded
- Branch protection on `main`: require CI checks, require up-to-date branch, no force pushes, no direct pushes
- Auto-merge workflow for agent `feat:`/`fix:` PRs that pass CI
- PR template and issue templates (bug report, new module request)

**Addresses:** terraform-docs enforcement (table stakes), CODEOWNERS + branch protection (table stakes), PR/issue templates (table stakes)

**Avoids:** Pitfall 5 (terraform-docs infinite CI loop — `[skip ci]` required), Pitfall 8 (CODEOWNERS silently blocking agent auto-merge — omit `modules/` from CODEOWNERS), Pitfall 10 (super-linter natural language false positives — evaluate `VALIDATE_NATURAL_LANGUAGE: false`)

**Research flag:** Standard patterns — terraform-docs inject mode and GitHub branch protection are well-documented.

---

### Phase 4: Quality Gates — TFLint and Trivy

**Rationale:** Security and lint gates must be configured before module count grows and before existing modules accumulate intentional configurations that Trivy would block. Getting severity filters right on day one prevents a wave of unresolvable CI failures on existing modules.

**Delivers:**
- `.tflint.hcl` at repo root with `terraform` built-in plugin (`preset = "recommended"`)
- `lint.yaml` workflow with explicit TFLint step (`terraform-linters/setup-tflint@v4` + `tflint --recursive`) — separate from super-linter to enable plugin loading
- Trivy `aquasecurity/trivy-action` with `scan-type: config`, `severity: CRITICAL,HIGH`, `exit-code: 1`
- `.trivyignore` with justified suppressions for intentionally permissive homelab Docker configs (e.g., `network_mode: host`)
- SARIF output uploaded to GitHub Security tab via `github/codeql-action/upload-sarif`

**Addresses:** TFLint enforcement (differentiator), Trivy security scanning (table stakes)

**Avoids:** Pitfall 6 (Trivy blocking on intentional homelab configs — severity filter on day one, `.trivyignore` for justified suppressions), Pitfall 7 (version drift between pre-commit and CI — use same pinned versions)

**Research flag:** Standard patterns — Trivy config mode and TFLint plugin configuration are stable and well-documented. Verify current version numbers before pinning.

---

### Phase 5: Testing — Native terraform test and Pre-commit Hooks

**Rationale:** With structure, releases, docs, and security gates all in place, tests can be added systematically. `terraform test` is the minimum viable test layer; Terratest is deferred. The pre-commit configuration mirrors CI and should be set up in this phase alongside tests.

**Delivers:**
- `modules/docker/container/tests/unit.tftest.hcl` — plan-mode assertions (validate variable/output correctness without real infrastructure)
- `modules/docker/container/tests/example/main.tf` updated to use `source = "../../"` (relative path — not published Git URL)
- `modules/docker/container/tests/example/versions.tf` with provider pin
- `modules/docker/container/tests/example/.terraform.lock.hcl` committed for reproducible CI
- `test.yaml` matrix workflow: `git diff`-based changed module detection, per-changed-module `terraform test` fan-out
- `hashicorp/setup-terraform@v3` with `terraform_wrapper: false` (required for later Terratest compatibility)
- `.pre-commit-config.yaml` with `antonbabenko/pre-commit-terraform` (terraform_fmt, terraform_validate, terraform_tflint, terraform_docs, terraform_trivy), `compilerla/conventional-pre-commit` (commit-msg stage), `pre-commit/pre-commit-hooks` (hygiene), `igorshubovych/markdownlint-cli`

**Addresses:** Native terraform test per module (table stakes), pre-commit config (table stakes), correct test source path (architecture requirement)

**Avoids:** Architecture Anti-pattern 7 (CI test using Git source URL), Pitfall 7 (pre-commit/CI version drift — pin identical versions; document CI as authoritative for agents)

**Research flag:** Verify Terratest co-location convention (per-module `tests/go.mod` vs top-level `go.mod`) against current Gruntwork docs before adding Terratest in Phase 6. This affects how the test.yaml matrix addresses Go test directories.

---

### Phase 6: Maintenance Automation — Dependabot and Terratest Stubs

**Rationale:** Dependabot should not be deferred past the first month — provider and Actions version drift accumulates quickly. Terratest stubs should be added once a second module is created, making co-location patterns worth establishing. Terratest for the first module alone does not justify the Go toolchain setup in CI.

**Delivers:**
- `.github/dependabot.yml` with `github-actions` ecosystem (weekly, `open-pull-requests-limit: 5`), `terraform` ecosystem per module directory (monthly, `open-pull-requests-limit: 3`), `gomod` ecosystem for `tests/` once Go tests exist
- Terratest stub per module (`go.mod` + `integration_test.go`) using co-located `modules/{p}/{r}/tests/` placement
- `.tflint.hcl` updated with `tflint-ruleset-azurerm` plugin when first Azure module is introduced
- New Dependabot `terraform` entry added per new module directory as modules are created

**Addresses:** Dependabot configuration (table stakes), Terratest stubs (differentiator — deferred to here)

**Avoids:** Pitfall 13 (Dependabot PR volume overwhelming agent queue — monthly intervals for Terraform providers, weekly for Actions)

**Research flag:** Standard patterns — Dependabot YAML schema is well-documented. Key operational note: one Dependabot `terraform` entry is required per module directory; this must be a checklist item when adding new modules.

---

### Phase Ordering Rationale

Hard dependency chain driving this order:

```
Phase 1: Migration + SKILL.md
     |— module at correct path (all subsequent tools need this)
     |— SKILL.md written (agents need this before committing)
     v
Phase 2: terraform-module-releaser
     |— releases flowing (consumer URLs, version badges, wiki all depend on tags existing)
     v
Phase 3: terraform-docs + Governance
     |— README always current (releaser wiki uses terraform-docs output)
     |— CODEOWNERS + branch protection active before repo shared broadly
     v
Phase 4: Quality Gates (TFLint, Trivy)
     |— lint and security gates active before module count grows
     v
Phase 5: terraform test + pre-commit
     |— test matrix requires stable module structure (Phase 1) and example using relative source
     v
Phase 6: Dependabot + Terratest
     |— maintenance automation deferred until pipeline is solid
```

Four cross-research tensions resolved in this ordering:

- **`depth=1` conflict:** STACK.md and existing project docs show `depth=1` in version-pinned source URLs; PITFALLS (Pitfall 3) shows this fails once newer commits land. Resolved in Phase 1 — remove `depth=1` from all version-pinned examples in SKILL.md and README before any consumer documentation is published.
- **CODEOWNERS agent autonomy conflict:** FEATURES.md recommends CODEOWNERS for module paths; PITFALLS (Pitfall 8) shows this blocks all agent PRs. Resolved in Phase 3 — explicitly omit `modules/` from CODEOWNERS and add auto-merge workflow for agent PRs.
- **`versions.tf` vs `terraform.tf` naming conflict:** STACK.md examples use `terraform.tf`; ARCHITECTURE.md mandates `versions.tf`. Resolved in Phase 1 migration — rename to `versions.tf` as part of the migration commit.
- **Test placement conflict:** STACK.md suggests top-level `tests/`; ARCHITECTURE.md argues for co-located `modules/{p}/{r}/tests/`. Resolved in favor of co-location — self-contained modules, simpler CI matrix addressing, consistent with terraform-aws-modules convention.

### Research Flags

**Phases needing deeper research during planning:**

- **Phase 2:** Verify terraform-module-releaser's module detection behavior for two-level `modules/{provider}/{resource}` paths against the current action README at https://github.com/techpivot/terraform-module-releaser. The `module_regex` or `modules_folder` input behavior at this depth is LOW confidence from training data. Do not treat Phase 2 as complete until a real tag is created.
- **Phase 6 (Azure modules):** Azure provider patterns, Terratest Azure module conventions, and managed identity for CI require dedicated research before planning any Azure module work.

**Phases with standard, well-documented patterns (skip research):**

- **Phase 1:** Directory structure and SKILL.md are architectural decisions. Build order is deterministic.
- **Phase 3:** terraform-docs inject mode and GitHub branch protection are stable, official documentation.
- **Phase 4:** Trivy `scan-type: config` and TFLint plugin configuration are stable APIs.
- **Phase 6:** Dependabot YAML schema is stable and officially documented.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Tool choices and config patterns HIGH; all version numbers LOW — must verify at release pages before pinning in any config file |
| Features | HIGH | Project requirements from PROJECT.md are authoritative; GitHub features (CODEOWNERS, PR templates, branch protection) are well-documented; terraform-module-releaser wiki output format LOW |
| Architecture | MEDIUM | Directory layout, workflow patterns, and test placement HIGH; terraform-module-releaser two-level path detection MEDIUM-LOW — needs live validation with test commit |
| Pitfalls | MEDIUM-HIGH | Most pitfalls derived from well-established platform behaviors (GitHub token defaults, Git shallow clone semantics, CC spec, terraform-docs infinite loop); agent commit message parsing issue is a known pattern |

**Overall confidence:** MEDIUM

### Gaps to Address

- **terraform-module-releaser two-level path detection:** The action's detection behavior for `modules/{provider}/{resource}` paths is LOW confidence. Validate immediately after wiring up the action — do not proceed past Phase 2 until a real tag is confirmed. If detection fails silently, check `modules_folder` and `module_regex` inputs against the current action README.

- **All tool version numbers:** Every version in STACK.md (Terraform, TFLint, terraform-docs, Trivy action, pre-commit hook revs) is from training data (cutoff August 2025). Verify each at its release page before writing any workflow or config file. The STACK.md verification URL table lists each release page.

- **`depth=1` in existing project documentation:** The existing project README and example configs use `depth=1` in version-pinned source URLs. This is a documentation error (Pitfall 3). Audit all consumer-facing documentation and remove `depth=1` from version-pinned URLs in Phase 1, before any consumer documentation is published.

- **Wiki initialization timing:** The GitHub Wiki must be manually initialized via the GitHub UI before terraform-module-releaser's first run. This is a one-time manual step that must be on a Phase 2 pre-flight checklist. The action cannot create the wiki repository — it can only write to an existing one.

- **Terratest Go module placement decision:** The choice between per-module `go.mod` (co-located in `tests/`) vs a single top-level `go.mod` affects how the CI matrix workflow locates Go tests. Make this decision in Phase 5 and document it in SKILL.md before any Go test files are written.

- **BREAKING CHANGE PR routing mechanism:** CODEOWNERS and branch protection cannot natively gate PRs by commit message content. A CI workflow that detects `BREAKING CHANGE` in commits and adds a required label or reviewer is needed. Prototype this workflow in Phase 2 alongside the PR title validation step.

## Sources

### Primary (HIGH confidence)

- `.planning/PROJECT.md` — project goals, constraints, and target module structure (authoritative for this project)
- `.planning/codebase/` — existing codebase analysis: current tool configuration, existing module state, CI workflows
- HashiCorp Terraform 1.6+ documentation — `terraform test` framework, `tests/` directory discovery, `versions.tf` conventions, module source addressing
- GitHub CODEOWNERS documentation — syntax, auto-merge interaction, branch protection integration
- GitHub Actions documentation — workflow permissions model, matrix strategy, `paths:` trigger filters vs `git diff` detection
- Conventional Commits spec v1.0.0 — footer parsing requirements, `!` shorthand for breaking changes
- terraform-docs/gh-actions README — inject mode behavior, `[skip ci]` infinite loop prevention
- Aqua Security Trivy documentation — `scan-type: config` IaC mode, SARIF output, `.trivyignore` format

### Secondary (MEDIUM confidence)

- terraform-module-releaser GitHub README (techpivot) — tag format, module detection pattern, wiki integration (training data; web fetch unavailable during research)
- Gruntwork Terratest documentation — Go test co-location conventions, `terraform_wrapper: false` requirement
- Anthropic CLAUDE.md memory system documentation — CLAUDE.md file conventions and agent instruction patterns
- antonbabenko/pre-commit-terraform — hook IDs, configuration patterns, `commit-msg` stage integration

### Tertiary (LOW confidence, must verify before implementing)

- terraform-module-releaser `module_regex` / `modules_folder` behavior for two-level namespaced paths — verify against current action README
- All specific tool version numbers (TFLint, terraform-docs, Trivy action version, pre-commit hook revs) — training data only; see STACK.md for verification URLs
- terraform-module-releaser wiki output format per module — verify against current documentation during Phase 2 implementation

---
*Research completed: 2026-02-28*
*Ready for roadmap: yes*
