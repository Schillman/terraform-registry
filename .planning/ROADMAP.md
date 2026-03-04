# Roadmap: Terraform Module Mono Repo

## Milestones

- ✅ **v1.0 MVP** — Phases 1-2 (shipped 2026-03-03)
- 📋 **v1.1** — Phases 3-6 (planned)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-2) — SHIPPED 2026-03-03</summary>

- [x] **Phase 1: Foundation** — Migrate module to namespaced path, establish agent
  conventions (3/3 plans) — completed 2026-02-28
- [x] **Phase 2: Automated Releases** — Wire up terraform-module-releaser, validate
  end-to-end (3/3 plans) — completed 2026-03-03

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

### 📋 v1.1 (Planned)

- [ ] **Phase 3: Documentation and Governance** - Establish CODEOWNERS, branch protection,
  PR/issue templates, and TAGS.json generation
- [ ] **Phase 4: Quality Gates** - Add dedicated TFLint and Trivy security scanning to CI
- [ ] **Phase 5: Testing** - Add native terraform test framework and pre-commit hooks
- [ ] **Phase 6: Maintenance Automation** - Configure Dependabot and scaffold Terratest stubs

## Phase Details

### Phase 3: Documentation and Governance

**Goal**: Module release metadata is captured in TAGS.json automatically, breaking changes
are detected before they reach consumers, structural repo files are protected from
unauthorized changes, and agent PRs for routine changes merge without human intervention
**Depends on**: Phase 2
**Requirements**: DOCS-04, DOCS-05, DOCS-06,
GOV-01, GOV-02, GOV-03, GOV-04, GOV-05
**Success Criteria** (what must be TRUE):

  1. `TAGS.json` is committed to each module directory by the release workflow,
     containing module name, release version, and latest commit author
  2. `tfbreak` runs in CI on PRs to detect breaking Terraform configuration changes;
     PRs with breaking changes are flagged for human review
  3. CODEOWNERS requires human review for `/.github/`, `/SKILL.md`, `/CLAUDE.md`
     but does NOT cover `modules/` (agent autonomy preserved)
  4. An agent `feat:` PR that passes all CI checks merges automatically without human
     review
  5. PR template includes Conventional Commits checklist; issue templates exist for
     bug reports and new module requests

**Critical constraints**:

- CODEOWNERS must NOT cover `modules/` (blocks agent auto-merge)
- tfbreak is complementary to tflint, not a replacement — both must run

**Plans**: 4 plans

Plans:
- [ ] 03-01-PLAN.md — TAGS.json generation workflow (DOCS-06)
- [ ] 03-02-PLAN.md — tfbreak breaking change detection workflow (GOV-01)
- [ ] 03-03-PLAN.md — CODEOWNERS, auto-merge workflow, branch protection (GOV-02, GOV-03)
- [ ] 03-04-PLAN.md — PR/issue templates, root README, SKILL.md Dependabot note (GOV-04, GOV-05, DOCS-04, DOCS-05)

---

### Phase 4: Quality Gates

**Goal**: Every PR is automatically scanned for Terraform misconfigurations and security
issues, with severity-appropriate gating that does not block intentional homelab configs
**Depends on**: Phase 3
**Requirements**: QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05
**Success Criteria** (what must be TRUE):

  1. `terraform fmt -check` runs recursively on all `.tf` files in CI
  2. TFLint runs as a dedicated CI step (not super-linter's bundled version) with
     `.tflint.hcl` config and explicit plugin loading
  3. Trivy IaC scan blocks PRs on CRITICAL and HIGH severity findings; justified
     suppressions documented in `.trivyignore`
  4. Trivy SARIF output appears in the GitHub Security tab AND a PR comment is posted
  5. A PR introducing a known CRITICAL misconfiguration is blocked by CI

**Critical constraints**:

- TFLint must be a dedicated step, not super-linter's bundled version
- Trivy severity filter: CRITICAL,HIGH only

**Plans**: TBD

---

### Phase 5: Testing

**Goal**: Every module has plan-mode unit tests that run in CI on every PR, and developers
have a local pre-commit configuration that mirrors CI checks
**Depends on**: Phase 4
**Requirements**: TEST-01, TEST-02, TEST-03, TEST-04, TEST-05, TEST-06
**Success Criteria** (what must be TRUE):

  1. `modules/docker/container/tests/unit.tftest.hcl` exists with plan-mode assertions
  2. `tests/example/main.tf` uses `source = "../../"` (relative path, not Git URL)
  3. `test.yaml` matrix detects changed modules via `git diff` and fans out per module
  4. `.pre-commit-config.yaml` mirrors CI: fmt, validate, tflint, trivy,
     conventional-pre-commit

**Critical constraints**:

- `hashicorp/setup-terraform@v3` must use `terraform_wrapper: false`
- Test examples must use relative source paths

**Plans**: TBD

---

### Phase 6: Maintenance Automation

**Goal**: Terraform provider versions and GitHub Actions versions are automatically
monitored for updates
**Depends on**: Phase 5
**Requirements**: MAINT-01
**Success Criteria** (what must be TRUE):

  1. `.github/dependabot.yml` with `github-actions` (weekly) and `terraform` entry
     per module directory (monthly)
  2. `SKILL.md` documents: one `terraform` Dependabot entry required per new module
     directory

**Critical constraints**:

- Dependabot does not recurse — one explicit entry per module directory

**Plans**: TBD

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 3/3 | Complete | 2026-02-28 |
| 2. Automated Releases | 3/3 | Complete | 2026-03-03 |
| 3. Documentation and Governance | 2/4 | In Progress|  |
| 4. Quality Gates | 0/? | Not started | - |
| 5. Testing | 0/? | Not started | - |
| 6. Maintenance Automation | 0/? | Not started | - |
