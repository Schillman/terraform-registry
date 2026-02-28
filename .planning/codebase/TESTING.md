# Testing Patterns

**Analysis Date:** 2026-02-28

## Test Framework

**Approach:**
- Terraform native testing via example/test modules in `tests/` directory
- No automated test runner framework (e.g., pytest, go test) - testing relies on Terraform plan/apply validation
- Example modules serve as functional validation of module configuration

**Execution:**
```bash
cd modules/terraform-docker-container/tests/example/
terraform init
terraform plan      # Validate configuration
terraform apply     # Deploy example
terraform destroy   # Clean up
```

**Validation Tools:**
- Terraform Format validation: `terraform fmt -diff -recursive -check`
- TFLint: static analysis of Terraform code via Super Linter integration
- Super Linter: comprehensive linting including Terraform, Bash, Markdown, GitHub Actions validation

**CI/CD Validation:**
- GitHub Actions workflow: `.github/workflows/lint.yaml`
- Automated on: pull requests to main and direct pushes to main
- All linters run against changed files before merge

## Test File Organization

**Location:**
- Example test module at: `modules/terraform-docker-container/tests/example/main.tf`
- Test files are integral to each module directory structure
- Providers and dependencies locked with `.terraform.lock.hcl` for reproducibility

**Naming:**
- Follows Terraform convention: example modules within `tests/` subdirectory
- Single example per module demonstrating canonical usage pattern

**Structure:**
```
modules/
└── terraform-docker-container/
    ├── main.tf
    ├── variables.tf
    ├── terraform.tf
    └── tests/
        └── example/
            ├── main.tf
            └── .terraform.lock.hcl
```

## Test Structure

**Example Module Pattern:**
```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
}

module "ubuntu" {
  source = "github.com/Schillman/terraform-registry//modules/terraform-docker-container?ref=v1.0"

  name              = format("server-%s", "tst")
  docker_image_name = "ubuntu"
  network_mode      = "bridge"

  environment_variables = ["KEY1=VALUE1", "KEY2=VALUE2"]

  ports = [{
    internal = 22
    external = 22
  }]

  volumes = {
    "Files" = {
      name           = "Files"
      container_path = "/Files"
    }
  }
}
```

**Patterns:**
- Example modules use `format()` function for dynamic naming (e.g., `format("server-%s", "tst")`)
- Demonstrates minimal required configuration
- Shows optional parameter usage (network_mode override, port mapping)
- Illustrates complex nested structures (ports as list of objects, volumes as map)
- Provider block included for full configuration context

## Validation Approach

**Configuration Validation:**
- `terraform init`: verifies provider availability and module source accessibility
- `terraform plan`: validates syntax, variable types, and resource configuration
- `terraform apply`: functional validation that resources can be created with given configuration

**What is Tested:**
- Module source accessibility via GitHub URL with versioned reference
- Variable type validation through Terraform's type system
- Provider compatibility (Docker provider 3.0.2)
- Dynamic block generation and nested object handling
- Interpolation expressions (format function)

**What is NOT Tested:**
- No unit test framework present
- No pre-commit hooks for automated validation
- No output assertion framework
- No state validation tests
- No regression test suite

## Linting & Static Analysis

**Tools:**
- **Terraform Format (terraform fmt)**: enforced via CI/CD as mandatory check
- **TFLint**: enabled in Super Linter for static analysis
- **Super Linter**: comprehensive multi-language linting on PR/push
  - Validates: ARM, Bash, GitHub Actions YAML, Markdown, Natural Language, PowerShell, Terraform

**CI/CD Integration:**
- GitHub Actions workflow: `.github/workflows/lint.yaml`
- Runs on all PRs to main and all pushes to main
- Fails build if formatting check fails
- Fails build if any linter detects issues

**Configuration Files:**
- Terraform linting: no custom tflint.hcl found - uses defaults
- Markdown linting: `.markdownlint.yml` with custom rules:
  - MD013: line length set to 180 characters
  - MD024: duplicate heading check enabled for sibling headings only
  - MD033: allows inline HTML for links, breaks, and pre tags

## Coverage & Metrics

**Coverage Strategy:**
- No programmatic test coverage metrics tracked
- Coverage based on example module execution success
- All module variables demonstrated in at least one example

**Validation:**
- Single comprehensive example per module covers:
  - Required variables (name, docker_image_name)
  - Optional simple variables (network_mode)
  - Complex optional structures (ports, volumes)
  - Environment variable configuration

**Current Coverage:**
- Example module exercises: image selection, volume management, port mapping, environment configuration
- Network mode configuration
- Does NOT exercise: healthcheck, devices, GPUs, runtime, command override, restart policies

---

*Testing analysis: 2026-02-28*
