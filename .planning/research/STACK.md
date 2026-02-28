# Technology Stack

**Project:** Terraform Module Monorepo — Professional Toolchain
**Researched:** 2026-02-28
**Research Mode:** Ecosystem — Stack dimension
**Confidence Note:** WebSearch, WebFetch, and shell execution were unavailable during research. All version assertions are from training data (cutoff August 2025) and must be independently verified before pinning. Every version entry is marked LOW confidence. Config snippets are drawn from official documentation patterns and are MEDIUM confidence.

---

## CRITICAL: Verify These Versions Before Use

The table below contains the best-known versions as of August 2025. Before implementing any CI/CD or pre-commit configuration, verify each tool at its release page:

| Tool | Release Page |
|------|-------------|
| terraform-module-releaser | https://github.com/techpivot/terraform-module-releaser/releases |
| terraform-docs | https://github.com/terraform-docs/terraform-docs/releases |
| TFLint | https://github.com/terraform-linters/tflint/releases |
| Trivy | https://github.com/aquasecurity/trivy/releases |
| pre-commit | https://github.com/pre-commit/pre-commit/releases |
| Terratest | https://github.com/gruntwork-io/terratest/releases |
| Terraform | https://github.com/hashicorp/terraform/releases |

---

## Recommended Stack

### Core Terraform Runtime

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|-----------|
| Terraform | >= 1.6.0 | IaC runtime and native test execution | `terraform test` requires 1.6+; current stable is 1.9.x as of Aug 2025 | LOW — verify current |
| kreuzwerker/docker provider | >= 3.0.2, < 4.0.0 | Docker resource management | Current pinned version; range allows patch updates | HIGH — already in use |

**Terraform version rationale:** The project currently uses `~>1.5` but native `terraform test` (the `.tftest.hcl` format) requires **Terraform 1.6 or higher**. The constraint must be bumped to `>= 1.6` or `~> 1.9`. Use `~> 1.9` to allow patch updates within the 1.9.x stream.

---

### CI/CD — Automation Actions

#### 1. terraform-module-releaser

| Property | Value | Confidence |
|----------|-------|-----------|
| Maintainer | techpivot | HIGH |
| GitHub Action | `techpivot/terraform-module-releaser` | HIGH |
| **Version to pin** | `v1` (major tag) or latest specific release | LOW — verify at releases page |
| Required permissions | `contents: write`, `pull-requests: write`, `issues: write` | HIGH |

**Recommended GitHub Actions workflow snippet:**

```yaml
# .github/workflows/release.yaml
name: Terraform Module Releaser

on:
  push:
    branches:
      - main

permissions:
  contents: write
  pull-requests: write
  issues: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Terraform Module Releaser
        uses: techpivot/terraform-module-releaser@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          # modules-path defaults to "modules/" - matches our structure
          # module-path-prefix is automatically detected
```

**Config notes:**
- terraform-module-releaser reads Conventional Commits and creates module-scoped tags: `modules/docker/container/v1.2.0`
- It also generates GitHub Releases and optional wiki entries
- The `modules/` path is the default scan root — matches the target `modules/{provider}/{resource}` structure
- `BREAKING CHANGE:` footer in commit body triggers a major bump, NOT just the word in the subject line
- `feat:` → minor, `fix:` → patch, `chore:`/`docs:`/`test:` → no bump

**What NOT to use:** Do not use semantic-release or release-please for this — they operate on repo-level versioning, not module-scoped tags. terraform-module-releaser is purpose-built for monorepo module tagging.

---

#### 2. Trivy Security Scanning

| Property | Value | Confidence |
|----------|-------|-----------|
| Maintainer | Aqua Security | HIGH |
| GitHub Action | `aquasecurity/trivy-action` | HIGH |
| **Action version** | `v0.20.0` or `@master` (pin to release) | LOW — verify |
| IaC scan mode | `--scanners misconfig` with `--format sarif` for GitHub Security tab | HIGH |
| Terraform severity threshold | `HIGH,CRITICAL` — block on these | HIGH (project requirement) |

**Recommended GitHub Actions snippet:**

```yaml
# Inside a CI job
- name: Run Trivy IaC Scan
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'config'
    scan-ref: '.'
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'HIGH,CRITICAL'
    exit-code: '1'

- name: Upload Trivy SARIF results
  if: always()
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: 'trivy-results.sarif'
```

**Config notes:**
- `scan-type: 'config'` is the IaC/misconfiguration scanning mode (Terraform, Dockerfile, K8s, etc.)
- `format: 'sarif'` + upload to `github/codeql-action/upload-sarif` surfaces findings in the GitHub Security tab (Code scanning alerts)
- `exit-code: '1'` fails the pipeline on HIGH/CRITICAL findings
- Do NOT use `scan-type: 'fs'` for IaC — that scans for vulnerable packages, not misconfigurations

**What NOT to use:** Do not use checkov or tfsec as the primary IaC security scanner — Trivy subsumes tfsec's Terraform checks (Aqua acquired tfsec) and provides unified output. If tfsec is already in super-linter, it can be disabled once Trivy is active.

---

#### 3. terraform-docs

| Property | Value | Confidence |
|----------|-------|-----------|
| Maintainer | terraform-docs org | HIGH |
| **Version** | `v0.19.0` (latest stable as of Aug 2025) | LOW — verify |
| GitHub Action | `terraform-docs/gh-actions` | HIGH |
| Pre-commit hook | `terraform-docs/terraform-docs` | HIGH |

**Recommended GitHub Actions snippet (enforcement in CI):**

```yaml
# .github/workflows/docs.yaml or added to existing CI job
- name: Render terraform-docs and commit
  uses: terraform-docs/gh-actions@v1
  with:
    working-dir: .
    output-file: README.md
    output-method: inject
    git-push: "true"
    find-dir: modules/
```

**Config notes:**
- `output-method: inject` uses `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` markers in README.md — preferred over `replace` which wipes hand-written content
- `find-dir: modules/` recursively finds all modules under `modules/` and generates docs for each
- `git-push: "true"` commits updated docs back to the PR branch automatically
- Every module README.md must contain the inject markers

**Recommended .terraform-docs.yml config (per module or at repo root):**

```yaml
# .terraform-docs.yml (repo root — applies to all modules)
formatter: "markdown table"

version: ">= 0.19"

output:
  file: README.md
  mode: inject
  template: |-
    <!-- BEGIN_TF_DOCS -->
    {{ .Content }}
    <!-- END_TF_DOCS -->

content: |-
  {{ .Header }}

  ## Requirements

  {{ .Requirements }}

  ## Providers

  {{ .Providers }}

  ## Inputs

  {{ .Inputs }}

  ## Outputs

  {{ .Outputs }}

sort:
  enabled: true
  by: name

settings:
  anchor: true
  color: true
  default: true
  description: true
  escape: true
  indent: 2
  required: true
  sensitive: true
  type: true
```

---

### Static Analysis — TFLint

| Property | Value | Confidence |
|----------|-------|-----------|
| Maintainer | terraform-linters org | HIGH |
| **Version** | `v0.52.0` (latest stable as of Aug 2025) | LOW — verify |
| Azure plugin | `terraform-linters/tflint-ruleset-azurerm` | HIGH |
| Docker plugin | No official tflint ruleset for Docker provider | HIGH |

**Recommended .tflint.hcl:**

```hcl
# .tflint.hcl
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Azure ruleset — install only if Azure modules exist
plugin "azurerm" {
  enabled = true
  version = "0.27.0"   # VERIFY: https://github.com/terraform-linters/tflint-ruleset-azurerm/releases
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Rules
rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}
```

**Config notes:**
- The `terraform` built-in plugin with `preset = "recommended"` covers Terraform best practices (naming, documentation, required providers)
- `tflint-ruleset-azurerm` applies Azure provider-specific checks (deprecated resources, required arguments)
- There is no official `tflint-ruleset-docker` — the kreuzwerker/docker provider does not have a maintained TFLint ruleset; Docker module quality relies on `terraform validate` + Trivy
- The azurerm plugin version must be compatible with the TFLint core version — check the ruleset's own releases page
- In CI, run `tflint --recursive` to lint all modules

**TFLint version in CI:**

```yaml
- name: Setup TFLint
  uses: terraform-linters/setup-tflint@v4
  with:
    tflint_version: v0.52.0   # VERIFY current version

- name: Run TFLint
  run: tflint --recursive --format compact
```

**What NOT to do:** Do not rely solely on super-linter's bundled TFLint — the super-linter image bundles a pinned TFLint version that may lag behind. Run TFLint explicitly in a dedicated step where you control the version and can provide `.tflint.hcl` with plugins.

---

### Pre-commit Framework

| Property | Value | Confidence |
|----------|-------|-----------|
| **pre-commit version** | `3.7.x` (latest stable as of Aug 2025) | LOW — verify |
| Install method | `pip install pre-commit` or `brew install pre-commit` | HIGH |
| Hook config file | `.pre-commit-config.yaml` (repo root) | HIGH |

**Recommended .pre-commit-config.yaml:**

```yaml
# .pre-commit-config.yaml
default_install_hook_types:
  - pre-commit
  - commit-msg

repos:
  # ── Terraform formatting ───────────────────────────────────────────
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.96.1   # VERIFY: https://github.com/antonbabenko/pre-commit-terraform/releases
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
        args:
          - --args=--recursive
          - --args=--config=__GIT_WORKING_DIR__/.tflint.hcl
      - id: terraform_docs
        args:
          - --hook-config=--path-to-file=README.md
          - --hook-config=--add-on-failure=create
          - --args=--config=.terraform-docs.yml
      - id: terraform_trivy
        args:
          - --args=--severity=HIGH,CRITICAL
          - --args=--exit-code=1

  # ── Conventional Commits ───────────────────────────────────────────
  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v3.4.0   # VERIFY: https://github.com/compilerla/conventional-pre-commit/releases
    hooks:
      - id: conventional-pre-commit
        stages: [commit-msg]
        args:
          - feat
          - fix
          - chore
          - docs
          - test
          - refactor
          - ci
          - build

  # ── General hygiene ────────────────────────────────────────────────
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0   # VERIFY: https://github.com/pre-commit/pre-commit-hooks/releases
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-merge-conflict
      - id: mixed-line-ending
        args: [--fix=lf]

  # ── Markdown linting ───────────────────────────────────────────────
  - repo: https://github.com/igorshubovych/markdownlint-cli
    rev: v0.41.0   # VERIFY: https://github.com/igorshubovych/markdownlint-cli/releases
    hooks:
      - id: markdownlint
        args: [--config, .markdownlint.yml]
```

**Pre-commit hook source rationale:**

| Hook Source | Why Chosen | Confidence |
|-------------|-----------|-----------|
| `antonbabenko/pre-commit-terraform` | The de-facto standard for Terraform pre-commit hooks; wraps terraform_fmt, validate, tflint, docs, trivy in one collection | HIGH |
| `compilerla/conventional-pre-commit` | Validates commit messages against Conventional Commits spec; `commit-msg` stage hook | HIGH |
| `pre-commit/pre-commit-hooks` | Standard general hygiene (trailing whitespace, YAML syntax, merge conflicts) | HIGH |
| `igorshubovych/markdownlint-cli` | CLI wrapper for markdownlint; matches existing `.markdownlint.yml` config | HIGH |

**What NOT to use:**
- Do not use `pre-commit/mirrors-*` wrappers for tools that have native hooks — they lag behind
- Do not add `terraform init` as a pre-commit hook — it modifies `.terraform/` state and should not run on every commit

**Installation and CI enforcement:**

```yaml
# In CI — fail if pre-commit hooks would fail (optional, belt-and-suspenders)
- name: Run pre-commit checks
  uses: pre-commit/action@v3.0.1
  with:
    extra_args: --all-files
```

---

### Dependabot Configuration

| Property | Value | Confidence |
|----------|-------|-----------|
| Config file | `.github/dependabot.yml` | HIGH |
| GitHub Actions updates | Supported natively | HIGH |
| Terraform provider updates | Supported via `terraform` ecosystem | HIGH |

**Recommended .github/dependabot.yml:**

```yaml
# .github/dependabot.yml
version: 2

updates:
  # ── GitHub Actions ─────────────────────────────────────────────────
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      timezone: "Europe/Stockholm"
    open-pull-requests-limit: 5
    labels:
      - "dependencies"
      - "ci"
    commit-message:
      prefix: "chore"
      include: "scope"

  # ── Terraform providers — Docker module ────────────────────────────
  - package-ecosystem: "terraform"
    directory: "/modules/docker/container"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      timezone: "Europe/Stockholm"
    open-pull-requests-limit: 3
    labels:
      - "dependencies"
      - "terraform"
    commit-message:
      prefix: "chore"
      include: "scope"

  # ── Terraform providers — Azure modules (when added) ───────────────
  # Add additional entries per module directory as new modules are created
  # Example:
  # - package-ecosystem: "terraform"
  #   directory: "/modules/azure/resource-group"
  #   schedule:
  #     interval: "weekly"

  # ── Go dependencies (Terratest) ────────────────────────────────────
  - package-ecosystem: "gomod"
    directory: "/tests"   # Adjust to wherever go.mod will live
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      timezone: "Europe/Stockholm"
    open-pull-requests-limit: 3
    labels:
      - "dependencies"
      - "testing"
    commit-message:
      prefix: "chore"
      include: "scope"
```

**Dependabot notes:**
- The `terraform` ecosystem reads `.terraform.lock.hcl` files to detect provider version constraints — the lock file must exist for Dependabot to track it
- One `terraform` entry is required **per module directory** — Dependabot does not recursively scan subdirectories for Terraform lock files
- As new modules are added under `modules/{provider}/{resource}`, a new Dependabot entry must be added
- Dependabot PRs use `chore:` prefix which will NOT trigger terraform-module-releaser version bumps — correct behavior
- `SKIP_DEPENDABOT_UPDATES` label can be added to a repo to pause specific Dependabot PRs

**Why Dependabot over Renovate:** Native GitHub integration, no extra config services, simpler YAML format for this project's scope. Renovate has more power for complex monorepos but adds operational overhead not warranted here.

---

### Terratest (Go Integration Testing)

| Property | Value | Confidence |
|----------|-------|-----------|
| Maintainer | Gruntwork | HIGH |
| **Version** | `v0.46.x` (latest as of Aug 2025) | LOW — verify |
| Go version required | `>= 1.21` | MEDIUM |
| Module location | `tests/` at repo root or per-module | MEDIUM |

**Recommended Go module setup:**

```bash
# From repo root (or tests/ directory)
go mod init github.com/Schillman/terraform-registry/tests
go get github.com/gruntwork-io/terratest/modules/terraform@v0.46.0
go get github.com/stretchr/testify@v1.9.0
```

**Resulting go.mod:**

```go
module github.com/Schillman/terraform-registry/tests

go 1.21

require (
    github.com/gruntwork-io/terratest v0.46.0   // VERIFY version
    github.com/stretchr/testify v1.9.0
)
```

**Minimal Terratest stub for Docker container module:**

```go
// tests/docker/container/docker_container_test.go
package test

import (
    "testing"

    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestDockerContainerModule(t *testing.T) {
    t.Parallel()

    terraformOptions := &terraform.Options{
        // Path to the Terraform module example/test config
        TerraformDir: "../../modules/docker/container/tests/example",

        // Variables to pass — override for test isolation
        Vars: map[string]interface{}{
            "name": "terratest-container",
        },

        // Retry on known transient errors
        MaxRetries:         3,
        TimeBetweenRetries: 5 * time.Second,
        RetryableTerraformErrors: map[string]string{
            "connection refused": "Docker daemon not ready",
        },
    }

    // Ensure cleanup even on test failure
    defer terraform.Destroy(t, terraformOptions)

    // Init and apply
    terraform.InitAndApply(t, terraformOptions)

    // Assert outputs
    containerID := terraform.Output(t, terraformOptions, "container_id")
    assert.NotEmpty(t, containerID)
}
```

**CI integration for Terratest:**

```yaml
# .github/workflows/test.yaml
name: Terratest

on:
  pull_request:
    paths:
      - 'modules/**'

jobs:
  terratest:
    runs-on: ubuntu-latest
    services:
      docker:
        image: docker:dind
        options: --privileged

    steps:
      - uses: actions/checkout@v4

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.21'
          cache: true

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "~>1.9"
          terraform_wrapper: false   # CRITICAL: must be false for Terratest

      - name: Run Terratest
        run: go test ./tests/... -v -timeout 30m
```

**CRITICAL config note:** `terraform_wrapper: false` in `hashicorp/setup-terraform` is **required** when using Terratest. The wrapper script wraps the Terraform binary and changes its output format, breaking Terratest's output parsing. Without this, Terratest will fail to parse `terraform output` results.

**What NOT to do:**
- Do not commit real Azure credentials for Terratest — use managed identity or mock providers
- Do not run Terratest without `defer terraform.Destroy` — leaked resources in Docker/Azure environments cause cost and pollution
- Do not skip `t.Parallel()` — Terratest is designed for parallel execution

---

### Native Terraform Test (`terraform test`)

| Property | Value | Confidence |
|----------|-------|-----------|
| Minimum Terraform version | **1.6.0** | HIGH |
| Test file extension | `.tftest.hcl` | HIGH |
| Test file location | Module root or `tests/` subdirectory | HIGH |
| Mock provider support | Available in 1.7+ | MEDIUM |

**Terraform version constraint update required:**

```hcl
# modules/docker/container/terraform.tf
terraform {
  required_version = ">= 1.6"   # was ~>1.5, must bump for terraform test

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 3.0.2, < 4.0.0"
    }
  }
}
```

**Minimal .tftest.hcl structure:**

```hcl
# modules/docker/container/tests/unit.tftest.hcl
variables {
  name              = "test-container"
  docker_image_name = "nginx:latest"
}

run "creates_container_with_correct_name" {
  command = plan   # Use "plan" for unit tests (no real infrastructure)

  assert {
    condition     = docker_container.main.name == "test-container"
    error_message = "Container name does not match input variable"
  }
}

run "applies_network_mode_default" {
  command = plan

  assert {
    condition     = docker_container.main.network_mode == "bridge"
    error_message = "Default network_mode should be bridge, not host"
  }
}
```

**Integration test with real apply:**

```hcl
# modules/docker/container/tests/integration.tftest.hcl
variables {
  name              = "tftest-container"
  docker_image_name = "nginx:alpine"
  network_mode      = "bridge"
}

run "creates_real_container" {
  command = apply   # Actually provisions resources

  assert {
    condition     = docker_container.main.id != ""
    error_message = "Container was not created"
  }

  assert {
    condition     = docker_container.main.name == var.name
    error_message = "Container name mismatch"
  }
}
```

**CI integration:**

```yaml
- name: Setup Terraform
  uses: hashicorp/setup-terraform@v3
  with:
    terraform_version: "~>1.9"

- name: Terraform Init
  run: terraform init
  working-directory: modules/docker/container

- name: Terraform Test
  run: terraform test
  working-directory: modules/docker/container
```

**`terraform test` vs Terratest — when to use which:**

| Scenario | Use `terraform test` | Use Terratest |
|----------|---------------------|--------------|
| Unit/plan validation | Yes | No — overkill |
| Assert output values at plan time | Yes | No |
| Real infrastructure provisioning tests | Yes (integration) | Yes (complex scenarios) |
| Cross-module integration | Possible but complex | Yes — better suited |
| Custom assertions beyond Terraform types | No | Yes — full Go test libraries |
| Azure API assertions | No | Yes |

**Recommendation:** Use `terraform test` with `command = plan` for unit tests (fast, no real infra) and with `command = apply` for module-level integration tests. Use Terratest for cross-module integration, Azure API-level assertions, and scenarios requiring Go logic.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Module versioning | terraform-module-releaser | semantic-release | semantic-release operates on repo-level tags; doesn't support module-scoped `modules/docker/container/v1.2.0` tag format |
| Module versioning | terraform-module-releaser | release-please | Same problem as semantic-release — repo-level, not module-scoped |
| IaC security | Trivy | tfsec | Aqua acquired tfsec; Trivy now ships the same checks. Running both is redundant |
| IaC security | Trivy | checkov | Checkov is powerful but Trivy is already present and Aqua's primary IaC tool |
| TFLint delivery | Dedicated step | super-linter bundled | super-linter bundles a pinned TFLint version without plugin support; cannot load `.tflint.hcl` with provider plugins |
| Pre-commit Terraform | antonbabenko/pre-commit-terraform | individual tool hooks | antonbabenko is the standard collection; individual hooks require more maintenance |
| Dependabot | Dependabot | Renovate | Renovate more powerful but adds operational overhead; Dependabot is native GitHub and sufficient |
| Test commits message validation | compilerla/conventional-pre-commit | commitlint | commitlint requires Node.js in pre-commit environment; conventional-pre-commit is pure Python |

---

## Complete Installation Reference

```bash
# ── Terraform CLI (use tfenv or direct download) ──────────────────────
tfenv install 1.9.x   # VERIFY latest 1.9.x
tfenv use 1.9.x

# ── terraform-docs ──────────────────────────────────────────────────
brew install terraform-docs   # macOS
# or
curl -sSLo /usr/local/bin/terraform-docs \
  https://github.com/terraform-docs/terraform-docs/releases/download/v0.19.0/terraform-docs-v0.19.0-linux-amd64   # VERIFY version

# ── TFLint ──────────────────────────────────────────────────────────
brew install tflint   # macOS
# or
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# ── Trivy ───────────────────────────────────────────────────────────
brew install trivy   # macOS
# or
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# ── pre-commit ──────────────────────────────────────────────────────
pip install pre-commit   # or: brew install pre-commit
pre-commit install                         # install pre-commit hooks
pre-commit install --hook-type commit-msg  # install commit-msg hooks

# ── Go + Terratest ──────────────────────────────────────────────────
brew install go   # macOS, ensure >= 1.21
cd tests/
go mod init github.com/Schillman/terraform-registry/tests
go get github.com/gruntwork-io/terratest/modules/terraform@latest   # VERIFY version
go get github.com/stretchr/testify@latest
```

---

## Current Stack Delta (Existing → Target)

| Tool | Existing | Target | Change |
|------|---------|--------|--------|
| Terraform version constraint | `~>1.5` | `~>1.9` | Bump required for `terraform test` |
| Docker provider | `= 3.0.2` (pinned exact) | `>= 3.0.2, < 4.0.0` | Loosen to allow Dependabot patch updates |
| CI linting | super-linter v5 (bundles TFLint) | super-linter v5 + explicit TFLint step | Add dedicated TFLint step with plugin support |
| Security scanning | None | Trivy (`scan-type: config`) | New workflow or job |
| Module versioning | None | terraform-module-releaser | New workflow |
| Docs | Manual README.md | terraform-docs with inject markers | New GHA step + `.terraform-docs.yml` |
| Pre-commit | None | antonbabenko/pre-commit-terraform collection | New `.pre-commit-config.yaml` |
| Dependabot | None | `.github/dependabot.yml` with per-module terraform entries | New config file |
| Testing | Example-based (terraform plan/apply manually) | terraform test + Terratest | New `.tftest.hcl` files + Go test files |

---

## Sources

**Confidence legend:**
- HIGH: Well-established patterns from official documentation patterns, project constraints, or widely-verified community standard
- MEDIUM: Based on official documentation patterns but version numbers not live-verified
- LOW: Training data only (cutoff August 2025); must be verified at release pages before use

| Source | Confidence | Notes |
|--------|-----------|-------|
| terraform-module-releaser GitHub | HIGH (tool existence) / LOW (version) | https://github.com/techpivot/terraform-module-releaser — verify current release tag |
| aquasecurity/trivy-action | HIGH (tool, config pattern) / LOW (version) | https://github.com/aquasecurity/trivy-action/releases |
| terraform-docs/gh-actions | HIGH (tool, config pattern) / LOW (version) | https://github.com/terraform-docs/gh-actions/releases |
| terraform-linters/tflint | HIGH (tool, config pattern) / LOW (version) | https://github.com/terraform-linters/tflint/releases |
| antonbabenko/pre-commit-terraform | HIGH (hook IDs, config pattern) / LOW (rev) | https://github.com/antonbabenko/pre-commit-terraform/releases |
| HashiCorp terraform test docs | HIGH (syntax, 1.6+ requirement) | https://developer.hashicorp.com/terraform/language/tests |
| gruntwork-io/terratest | HIGH (API, patterns) / LOW (version) | https://github.com/gruntwork-io/terratest/releases |
| GitHub Dependabot docs | HIGH (config schema) | https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file |
