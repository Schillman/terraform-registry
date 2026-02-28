# Project Research Summary

**Project:** Terraform Module Monorepo — Professional Toolchain
**Domain:** AI-operated Terraform Module Monorepo
**Researched:** 2026-02-28
**Confidence:** MEDIUM

## Executive Summary

This project is a Terraform module monorepo that serves as a private module registry, consumed via direct Git sourcing. The core goal is to make it professional, AI-agent-friendly, and capable of autonomous operation under human oversight. Experts build these repos with two non-negotiable foundations: (1) a strict `modules/{provider}/{resource}` directory structure that drives automated module-scoped semver tagging, and (2) a machine-readable agent instruction file (SKILL.md + CLAUDE.md) that teaches AI agents the commit conventions, module scaffold, and governance rules before they touch anything. Without both foundations in place, every subsequent tool integration will require rework.

The recommended approach is a sequential build order where directory structure and agent documentation come first, followed immediately by terraform-module-releaser integration to unlock automated versioning. The toolchain is well-established: terraform-module-releaser for module-scoped tags, terraform-docs for README generation, TFLint for static analysis, Trivy for IaC security scanning, native `terraform test` for unit/integration testing, and Terratest for complex Go-level integration tests. Dependabot handles dependency hygiene. The entire local development experience is unified by a pre-commit configuration that mirrors CI checks, preventing unnecessary fix-up commits.

The key risks are structural. The most dangerous is completing the module directory migration without verifying that terraform-module-releaser's changed-files detection reaches the two-level namespaced path (`modules/docker/container/`). If module detection silently fails, no releases are ever created and the entire versioning automation is dead. Second most critical: AI agents writing scope-qualified commit messages or burying `BREAKING CHANGE` in commit bodies can trigger wrong semver bumps, causing consumers to receive breaking changes on a minor version. Both risks are preventable with explicit CI validation steps and clear SKILL.md rules, but they must be addressed in Phase 1, before any consumers pin to a released version.

## Key Findings

### Recommended Stack

See `.planning/research/STACK.md` for full configurations and code snippets.

The toolchain is built on Terraform >= 1.6 (required for native `terraform test`), with the current constraint `~>1.5` needing a bump to `~>1.9`. The kreuzwerker/docker provider constraint should be loosened from an exact pin to `>= 3.0.2, < 4.0.0` to allow Dependabot patch updates. Every tool version in the stack is LOW confidence (training data cutoff August 2025) and must be verified at release pages before pinning in CI.

**Core technologies:**
- **Terraform >= 1.6 / ~> 1.9:** IaC runtime — required for `terraform test`; existing `~>1.5` constraint blocks native testing
- **terraform-module-releaser (techpivot):** Module-scoped semver tagging and GitHub Releases — purpose-built for monorepo module tagging; semantic-release and release-please are unsuitable replacements
- **terraform-docs v0.19+:** Auto-generated README tables via inject markers — `output-method: inject` preserves hand-written content
- **TFLint v0.52+:** Static analysis with `terraform` built-in plugin + `tflint-ruleset-azurerm` when Azure modules land; no official Docker plugin exists
- **Trivy (aquasecurity):** IaC misconfiguration scanning with `scan-type: config` — replaced tfsec when Aqua acquired it; block on CRITICAL/HIGH only
- **pre-commit (antonbabenko/pre-commit-terraform):** Local quality gate mirroring CI; `compilerla/conventional-pre-commit` enforces commit message format at commit-msg stage
- **Dependabot:** Native GitHub dependency updates for GitHub Actions, Terraform providers (per module directory), and Go modules; one entry required per module directory
- **`terraform test`:** Native unit/plan assertions using `.tftest.hcl`; requires Terraform >= 1.6; fast and no real infrastructure needed for plan-mode tests
- **Terratest (gruntwork):** Go-based deploy+assert+destroy tests for complex multi-module scenarios; defer until module count > 3

### Expected Features

See `.planning/research/FEATURES.md` for complete specifications including SKILL.md content, PR template, issue templates, CODEOWNERS, and branch protection rules.

**Must have (table stakes):**
- **SKILL.md + CLAUDE.md at repo root** — agents read this before any work session; without it, agents guess conventions and create wrong commits or broken modules
- **Namespaced module structure `modules/{provider}/{resource}`** — terraform-module-releaser expects exactly this layout; flat naming breaks tag format and provider grouping
- **Conventional Commits enforcement** — terraform-module-releaser requires CC to drive semver; `feat:` = minor, `fix:` = patch, `BREAKING CHANGE:` footer = major, `chore:`/`docs:`/`test:` = no bump
- **terraform-module-releaser integration** — auto-versioning, GitHub Releases, per-module wiki pages; core value unlock
- **`outputs.tf` in every module** — currently missing from docker/container; required for consumers to compose modules
- **Per-module README.md via terraform-docs** — inputs/outputs table expected by all consumers; inject markers are mandatory
- **GitHub Actions CI on PR** — lint, fmt, tflint, security scan must pass before merge; already partially exists
- **Trivy security scanning** — no HIGH/CRITICAL IaC findings should reach main
- **Native `terraform test` per module** — standard since Terraform 1.6; plan-mode tests catch variable/output errors without real infrastructure
- **CODEOWNERS + branch protection** — structural changes and SKILL.md require human review; modules themselves can be agent-autonomy zones
- **Dependabot config** — GitHub Actions and Terraform provider version drift prevention
- **PR template + issue templates** — checklist enforcement for both agents and humans

**Should have (differentiators):**
- **Terratest Go stubs per module** — full deploy+assert+destroy coverage beyond `terraform test` capabilities
- **`validation` blocks in variables** — fail at plan time with clear error messages for restart_policy, network_mode, gpus
- **`terraform validate` + `terraform plan -detailed-exitcode` in CI** — catches provider-level errors that fmt/tflint miss
- **Version badges per module** — consumers see current version at a glance in module README
- **Wiki Home.md seeded with module index** — terraform-module-releaser generates module wiki pages; Home.md provides the index

**Defer (v2+):**
- **Terratest until module count > 3** — complexity is high relative to current module count
- **`.tflint.hcl` Azure plugin** — add when Azure modules are introduced
- **Slack/notification webhooks** — adds secrets management overhead; GitHub's native notifications are sufficient
- **Terraform Cloud / HCP registry** — added infrastructure complexity; no benefit over direct Git sourcing for this consumption model

### Architecture Approach

See `.planning/research/ARCHITECTURE.md` for full directory tree, component boundaries, CI workflow patterns, and build order dependencies.

The repo follows a strict single-responsibility layout where each module is a self-contained unit at `modules/{provider}/{resource}/` with its own `versions.tf`, `main.tf`, `variables.tf`, `outputs.tf`, `README.md`, and a co-located `tests/` directory containing the example config, native `.tftest.hcl` files, and a Terratest Go stub. CI uses three workflows: a global lint workflow, a per-changed-module test matrix workflow (using `git diff` to fan out to only affected modules), and a release workflow that calls terraform-module-releaser on push to main. The critical architectural constraint is that `tests/example/main.tf` must use a **relative source path** (`source = "../../"`) when running in CI, NOT the published Git URL — consuming the published URL in tests causes shallow-clone resolution failures.

**Major components:**
1. **`modules/{provider}/{resource}/`** — self-contained module unit; public API = variables.tf + outputs.tf
2. **`.github/workflows/lint.yaml`** — global quality gate: terraform fmt, TFLint, Trivy, markdownlint
3. **`.github/workflows/test.yaml`** — matrix fan-out: detects changed modules via `git diff`, runs `terraform test` + Terratest per affected module
4. **`.github/workflows/release.yaml`** — calls terraform-module-releaser on main push; creates module-scoped tags and GitHub Releases
5. **`SKILL.md` + `CLAUDE.md`** — agent operational guide; read before any work session; defines commit conventions, scaffold rules, autonomy boundaries
6. **`.pre-commit-config.yaml`** — local mirror of CI checks; prevents CI-failing commits from landing in PRs

### Critical Pitfalls

See `.planning/research/PITFALLS.md` for full prevention configs, detection methods, and phase assignments.

1. **AI agent commit messages bypass semver detection** — Scoped `feat(scope):` messages and `BREAKING CHANGE:` buried in commit bodies are silently downgraded by terraform-module-releaser during squash merges. Prevention: mandate `feat!:` shorthand for breaking changes in SKILL.md; add PR title validation CI step (`^(feat|fix|chore|...)(scope)?(!)?: .+`).

2. **terraform-module-releaser silent failure on namespaced paths** — After migrating to `modules/docker/container/`, the action may not find modules if its detection glob doesn't recurse two levels. Prevention: push a test `feat:` commit immediately after wiring up the action and verify a release fires before any consumer depends on it.

3. **`depth=1` breaks pinned tag resolution** — `ref=modules/docker/container/v1.2.0` with `depth=1` fails once newer commits land on main because the tag is no longer at HEAD depth. Prevention: remove `depth=1` from all version-pinned source URLs; only use `depth=1` for floating `ref=main` references.

4. **Module migration breaks existing consumer refs** — Renaming from `modules/terraform-docker-container/` to `modules/docker/container/` orphans all old tag references. Prevention: keep old directory as a stub with migration notice; never delete old tags; update example source URLs before first release.

5. **terraform-docs CI commit-back creates infinite loop** — Without `[skip ci]` on the terraform-docs auto-commit message, CI triggers again and again. Prevention: always append `[skip ci]` to the git commit message in the terraform-docs action config.

6. **GITHUB_TOKEN missing `contents: write` on release job** — Default token permissions changed to read-only in 2023; the action silently succeeds but no tags or releases are created. Prevention: declare `permissions: contents: write, pull-requests: write` explicitly on the release job.

## Implications for Roadmap

The research establishes a clear dependency chain that dictates phase order. terraform-module-releaser cannot detect modules until the directory structure is correct. Agents cannot operate correctly until SKILL.md exists. Tests cannot run until `outputs.tf` exists and the example uses a relative source path. CI release workflow cannot fire correctly without explicit permissions. This hard dependency chain points to 6 phases.

### Phase 1: Foundation — Module Migration + Agent Docs

**Rationale:** Everything downstream depends on the correct directory structure and agent instruction file. This is the mandatory first step — no other work should proceed until this phase is complete and agents are operating under the correct conventions.

**Delivers:**
- Module migrated from `modules/terraform-docker-container/` to `modules/docker/container/`
- `terraform.tf` renamed to `versions.tf`; Terraform version constraint bumped to `~>1.9`
- Docker provider constraint loosened from exact pin to `>= 3.0.2, < 4.0.0`
- `outputs.tf` created (even if initially empty/minimal)
- `SKILL.md` and `CLAUDE.md` at repo root covering commit conventions, module scaffold, autonomy rules
- Migration notice in root README with before/after source snippets
- Old directory preserved as stub; old tags NOT deleted

**Addresses:** Module structure (table stake), SKILL.md + CLAUDE.md (table stake), outputs.tf (table stake)

**Avoids:** Pitfall 4 (migration breaking consumer refs), Pitfall 1 (agents committing with wrong conventions before SKILL.md exists)

**Research flag:** Standard patterns — no deeper research needed. Build order is documented in ARCHITECTURE.md Step 1.

---

### Phase 2: Automated Releases — terraform-module-releaser

**Rationale:** This is the core value unlock for the repo. All downstream features (wiki, version badges, consumer source URLs) depend on releases existing. Must be wired up immediately after Phase 1 so the first real commits trigger real version tags.

**Delivers:**
- `release.yaml` workflow with explicit `permissions: contents: write, pull-requests: write`
- `fetch-depth: 0` on release workflow checkout
- terraform-module-releaser configured and validated with a test `feat:` commit
- PR title validation CI step (Conventional Commits regex check)
- Wiki manually initialized (one-time GitHub UI step) before first release
- `depth=1` removed from all consumer-facing source URL examples

**Addresses:** terraform-module-releaser integration (table stake), module-scoped Git tags (table stake)

**Avoids:** Pitfall 2 (module not detected under namespaced path), Pitfall 9 (missing permissions), Pitfall 11 (missing fetch-depth), Pitfall 12 (wiki not initialized)

**Research flag:** Needs validation — verify terraform-module-releaser module detection with test commit immediately after wiring up. Check current release at https://github.com/techpivot/terraform-module-releaser/releases.

---

### Phase 3: Documentation Enforcement — terraform-docs + Governance

**Rationale:** Once releases exist, every module README must accurately reflect inputs/outputs. This phase also establishes the human-oversight governance layer (CODEOWNERS, branch protection) that is required before the repo is shared with consumers.

**Delivers:**
- terraform-docs GitHub Action with `output-method: inject` and `[skip ci]` on commit message
- `.terraform-docs.yml` config at repo root
- `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` markers in all module READMEs
- CODEOWNERS: `/.github/` and `/SKILL.md` require human review; `modules/` excluded for agent autonomy
- Branch protection: require CI checks, require up-to-date branches, CODEOWNERS review for structural paths
- Auto-merge workflow for agent `feat:`/`fix:` PRs once CI passes
- PR template + issue templates

**Addresses:** terraform-docs enforcement (table stake), CODEOWNERS + branch protection (table stake), PR/issue templates (table stake)

**Avoids:** Pitfall 5 (terraform-docs infinite CI loop), Pitfall 8 (CODEOWNERS silently blocking agent auto-merge), Pitfall 10 (super-linter natural language false positives — evaluate `VALIDATE_NATURAL_LANGUAGE: false`)

**Research flag:** Standard patterns — terraform-docs inject mode is well-documented. Branch protection rule configuration is straightforward.

---

### Phase 4: Security + Static Analysis — Trivy + TFLint

**Rationale:** Security and lint gates need to be configured before module count grows. Getting the Trivy severity threshold right on Phase 4 (not retroactively) prevents a wave of unresolvable CI failures on existing modules.

**Delivers:**
- `lint.yaml` workflow extended with explicit TFLint step (not relying solely on super-linter's bundled version)
- `.tflint.hcl` with `terraform` built-in plugin (`preset = "recommended"`)
- Trivy `aquasecurity/trivy-action` with `scan-type: config`, severity `CRITICAL,HIGH`, exit-code `1`
- `.trivyignore` with justified suppressions for intentionally permissive homelab Docker configs
- SARIF upload to GitHub Security tab via `github/codeql-action/upload-sarif`

**Addresses:** Trivy security scanning (table stake), TFLint with `.tflint.hcl` (differentiator)

**Avoids:** Pitfall 6 (Trivy blocking on intentionally permissive `network_mode=host` configs), Pitfall 7 (version drift between pre-commit and CI)

**Research flag:** Standard patterns — Trivy IaC config mode is well-documented. TFLint ruleset configuration is stable. Verify current tool versions before pinning.

---

### Phase 5: Testing — Native terraform test + Pre-commit

**Rationale:** With the structure, releases, docs, and security gates all in place, tests can be added systematically. `terraform test` is the immediate priority; Terratest is deferred until module count warrants it.

**Delivers:**
- `tests/unit.tftest.hcl` for docker/container module (plan-mode assertions on variable/output correctness)
- `tests/example/main.tf` updated to use relative source `../../` (not published Git URL)
- `tests/example/versions.tf` and committed `.terraform.lock.hcl`
- `test.yaml` matrix workflow: `git diff`-based module detection, per-changed-module `terraform test` fan-out
- `terraform_wrapper: false` enforced in setup-terraform for Terratest compatibility
- `.pre-commit-config.yaml` with antonbabenko/pre-commit-terraform collection + conventional-pre-commit + pre-commit-hooks + markdownlint-cli

**Addresses:** Native `terraform test` (table stake), pre-commit config (table stake), example using relative source (architecture requirement)

**Avoids:** Pitfall 7 (pre-commit/CI version drift — pin identical versions), Anti-pattern 7 (CI test using Git source URL instead of relative path)

**Research flag:** Needs attention for Terratest placement — verify co-location convention against current terraform-aws-modules and Gruntwork patterns.

---

### Phase 6: Maintenance Automation — Dependabot + Terratest Stubs

**Rationale:** Dependabot configuration is low-urgency but should not be deferred beyond the first month. Terratest stubs should be added once a second or third module is created, when cross-module integration testing becomes valuable.

**Delivers:**
- `.github/dependabot.yml` with `github-actions` ecosystem (weekly), `terraform` ecosystem per module directory (monthly), `gomod` ecosystem for tests
- `open-pull-requests-limit` set to prevent PR queue flooding
- Terratest stub (`go.mod` + `integration_test.go`) for docker/container module
- `tflint-ruleset-azurerm` added to `.tflint.hcl` when first Azure module is introduced

**Addresses:** Dependabot config (table stake), Terratest (differentiator — deferred to here)

**Avoids:** Pitfall 13 (Dependabot PR volume overwhelming agent queue — use monthly intervals for Terraform providers)

**Research flag:** Standard patterns — Dependabot configuration schema is well-documented. One Dependabot `terraform` entry is required per module directory; this must be remembered when adding new modules.

---

### Phase Ordering Rationale

- **Phases 1 and 2 are hard prerequisites.** Directory structure must exist before any tooling can run. SKILL.md must exist before agents commit. Releases must exist before documentation can reference version badges or consumer source URLs.
- **Phase 3 before Phase 4** because governance (CODEOWNERS, branch protection) should gate the repo before security scanning is added — otherwise there's no enforcement mechanism for security failures.
- **Phase 5 after Phase 3** because `terraform test` matrix workflow depends on the test file location convention being finalized, and that convention should be locked in (with SKILL.md updated) before tests proliferate across modules.
- **Phase 6 is maintenance** and can be partially parallelized with Phase 5 for the Dependabot config, but Terratest stubs should wait until there is more than one module to make co-location patterns worth establishing.
- **Anti-patterns documented in ARCHITECTURE.md** directly inform this phase order: keeping `.tf` files out of `modules/` root, using relative source in tests, keeping `versions.tf` not `terraform.tf`, and three workflows not one monolithic job.

### Research Flags

Phases needing deeper research during planning:

- **Phase 2:** Verify terraform-module-releaser's current module detection behavior for two-level `modules/{provider}/{resource}` paths against https://github.com/techpivot/terraform-module-releaser — the `module_regex` input configuration is LOW confidence from training data only.
- **Phase 5:** Verify Terratest co-location convention (per-module `tests/` vs top-level `testing/`) against current Gruntwork documentation at https://terratest.gruntwork.io/docs/ — this affects how the test.yaml matrix CI job must be structured.

Phases with standard, well-documented patterns (skip research-phase):

- **Phase 1:** Directory structure and SKILL.md are architectural decisions, not API-dependent. Build order is deterministic.
- **Phase 3:** terraform-docs inject mode, CODEOWNERS syntax, and branch protection are all stable, well-documented GitHub and terraform-docs features.
- **Phase 4:** Trivy `scan-type: config` mode and TFLint plugin configuration are stable APIs with high-confidence documentation.
- **Phase 6:** Dependabot YAML schema is stable and officially documented.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Tool choices and config patterns are HIGH confidence; all version numbers are LOW confidence (training data only, must verify at release pages) |
| Features | HIGH | Project requirements from PROJECT.md are authoritative; GitHub CODEOWNERS, PR templates, branch protection are well-documented; terraform-module-releaser wiki behavior is LOW confidence |
| Architecture | MEDIUM | Directory layout and workflow patterns are HIGH confidence; terraform-module-releaser two-level path detection is LOW confidence and must be validated with a test commit |
| Pitfalls | MEDIUM-HIGH | Pitfalls derived from known tool behavior patterns; most are HIGH confidence; `depth=1` tag resolution and agent commit message parsing issues are well-documented |

**Overall confidence:** MEDIUM

### Gaps to Address

- **terraform-module-releaser two-level path detection:** The action's `module_regex` or `modules_folder` behavior at `modules/{provider}/{resource}` depth is LOW confidence. Validate immediately after wiring up the action with a test `feat:` commit. If module detection fails silently, adjust the `modules_folder` or `module_regex` input before any consumer dependencies exist.

- **Tool versions:** Every tool version (Terraform, TFLint, terraform-docs, Trivy, pre-commit hooks) must be verified at their respective release pages before pinning in `.pre-commit-config.yaml` and CI workflows. Training data cutoff is August 2025 and these tools release frequently.

- **`depth=1` consumer URL guidance:** The existing README and example configs use `depth=1` in source URLs. This is documented as problematic for pinned version tags (Pitfall 3). Audit all consumer-facing documentation and remove `depth=1` from version-pinned URLs before the first release is published.

- **Terratest Go module placement:** The decision between a top-level `go.mod` at repo root vs per-module `go.mod` in `tests/` affects how the CI matrix workflow finds and runs Go tests. This needs a definitive decision in Phase 5 before tests proliferate.

- **Wiki initialization timing:** The GitHub Wiki must be manually initialized via the GitHub UI before terraform-module-releaser first runs. This is a one-time manual step that must be documented as a pre-flight checklist item, not just a CI task.

## Sources

### Primary (HIGH confidence)

- `.planning/PROJECT.md` — project goals, constraints, target module structure (authoritative for this project)
- `.planning/codebase/` — existing codebase analysis (existing tool configuration, current module state)
- HashiCorp Terraform 1.6+ docs — `terraform test` framework, `versions.tf` conventions, module source addressing
- GitHub CODEOWNERS documentation — syntax and branch protection integration
- GitHub Actions documentation — workflow permissions model, matrix strategy, `git diff` for changed file detection
- Conventional Commits spec v1.0.0 — footer parsing requirements for `BREAKING CHANGE`
- terraform-docs/gh-actions README — inject mode behavior, `[skip ci]` infinite loop prevention
- Aqua Security Trivy docs — `scan-type: config` IaC mode, severity filtering, `.trivyignore` format

### Secondary (MEDIUM confidence)

- terraform-module-releaser GitHub README (techpivot) — tag format, module detection pattern, wiki integration (verified from training data; web fetch unavailable during research)
- Gruntwork Terratest documentation — Go test co-location conventions, `terraform_wrapper: false` requirement
- Anthropic CLAUDE.md memory system — CLAUDE.md conventions and agent instruction file patterns
- antonbabenko/pre-commit-terraform — hook IDs and configuration patterns

### Tertiary (LOW confidence, must validate)

- terraform-module-releaser `module_regex` / `modules_folder` behavior for two-level namespaced paths — must verify against current action README
- All specific tool version numbers (TFLint v0.52.0, terraform-docs v0.19.0, Trivy action version, pre-commit hook revs) — training data only, verify at release pages before pinning
- terraform-module-releaser wiki output format — must verify against current tool documentation during Phase 2 implementation

---
*Research completed: 2026-02-28*
*Ready for roadmap: yes*
