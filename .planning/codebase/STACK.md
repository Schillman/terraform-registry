# Technology Stack

**Analysis Date:** 2026-02-28

## Languages

**Primary:**
- HashiCorp Configuration Language (HCL) - Terraform module definitions and configurations
- YAML - GitHub Actions workflows and configuration files
- Markdown - Documentation

## Runtime

**Environment:**
- Terraform ~>1.5 (as specified in CI/CD pipeline)

**Package Manager:**
- Terraform Registry - No traditional package manager; modules are retrieved from GitHub source URLs

## Frameworks

**Core:**
- Terraform 1.5+ - Infrastructure as Code framework for provisioning and managing cloud/container resources

**Build/Dev:**
- GitHub Actions - CI/CD automation for linting and code validation

## Key Dependencies

**Critical:**
- kreuzwerker/docker v3.0.2 - Docker provider for Terraform, enables management of Docker resources (images, containers, volumes)

**Infrastructure:**
- hashicorp/setup-terraform@v3 - GitHub Action to set up Terraform in CI/CD pipeline
- github/super-linter@v5 - Multi-language linting framework for code quality validation
- actions/checkout@v4 - GitHub Action for checking out repository code

## Configuration

**Environment:**
- Linting rules defined in `.markdownlint.yml`
- GitHub Actions workflow configuration in `.github/workflows/lint.yaml`
- Terraform version constraint: ~>1.5

**Build:**
- `.github/workflows/lint.yaml` - Primary CI/CD pipeline that:
  - Validates Terraform formatting: `terraform fmt -diff -recursive -check`
  - Runs TFLint for Terraform validation
  - Validates Markdown, Bash, PowerShell, GitHub Actions, and ARM templates
  - Enforces code quality standards

## Platform Requirements

**Development:**
- Terraform CLI v1.5 or higher
- Docker (for running Docker provider against local daemon or remote hosts)
- Git for version control

**Production:**
- Terraform state management backend (not configured in repository - users supply their own)
- Docker daemon or Docker API endpoint (specified by provider configuration)
- GitHub for module source retrieval

---

*Stack analysis: 2026-02-28*
