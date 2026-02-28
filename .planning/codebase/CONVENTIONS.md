# Coding Conventions

**Analysis Date:** 2026-02-28

## Naming Patterns

**Files:**
- Standard Terraform file naming conventions strictly followed
- Core module files: `main.tf` (resource definitions), `variables.tf` (input variables), `terraform.tf` (provider configuration)
- Example/test files: contained in `tests/example/main.tf`
- Module directory naming: `terraform-${provider}-${module_name}` format (e.g., `terraform-docker-container`)
  - All module names use hyphens as separators, not underscores

**Variables:**
- Descriptive snake_case naming for variable identifiers (e.g., `docker_image_name`, `network_mode`, `environment_variables`)
- Resource arguments follow Terraform provider conventions exactly (e.g., `container_path`, `host_path`, `restart_policy`)
- Local identifiers use descriptive names reflecting their purpose in the module

**Resources:**
- Resource type identifiers use singular nouns or descriptive labels (e.g., `docker_image "main"`, `docker_container "main"`, `docker_volume "volumes"`)
- Primary or main resources use the label `"main"` for consistency
- Plural labels for collections (e.g., `docker_volume "volumes"`)

**Type Names:**
- Complex variable types use `object()` with explicit nested schema documentation
- Map and list structures use clear type definitions with inline comments explaining each field

## Code Style

**Formatting:**
- Terraform Format (terraform fmt) enforced as part of CI/CD pipeline
- Automated formatting runs on all commits with `-recursive` flag to ensure consistency across all .tf files
- Indentation: 2 spaces (Terraform standard)

**Linting:**
- HashiCorp's Super Linter integration with Terraform-specific plugins
- VALIDATE_TERRAFORM_FMT: enabled - ensures all files pass fmt check
- VALIDATE_TERRAFORM_TFLINT: enabled - runs TFLint for additional code quality checks
- Markdown linting: active with custom configuration at `.markdownlint.yml`
- GitHub Actions validation: enabled to catch workflow syntax issues

**Checked in CI/CD:**
- `terraform fmt -diff -recursive -check`: verifies formatting compliance
- Super Linter with multiple validators: ARM, Bash, GitHub Actions, Markdown, Natural Language, PowerShell, Terraform (fmt and tflint)

## Import Organization

**Module Structure:**
- Provider configuration defined separately in `terraform.tf`
- Variables defined in dedicated `variables.tf` file
- Resource implementations in `main.tf`
- Clear separation of concerns by file purpose

**Module Dependencies:**
- Provider requirement specified in `terraform.tf` block with explicit source and version constraints
- Example: `source = "kreuzwerker/docker"` with `version = "3.0.2"` (pinned to specific versions)
- Module references in tests/examples use GitHub source with tag references: `github.com/Schillman/terraform-registry//modules/terraform-docker-container?ref=v1.0`

## Error Handling

**Patterns:**
- Variable defaults used to provide safe fallback values (e.g., `default = null`, `default = []`, `default = {}`)
- Optional fields in complex objects defined using `optional()` with sensible defaults:
  - `optional(string, "local")` for driver defaults
  - `optional(bool, false)` for boolean flags
  - `optional(string, "tcp")` for protocol defaults
- Type validation enforced through strict type declarations
- Complex nested structures validated through object type definitions

## Documentation

**Comments:**
- Inline comments used within variable type definitions to explain field purposes
- Example from variables.tf: `# The path on the host where the device is located.`
- Comments positioned after field names in object definitions for clarity
- Description fields mandatory on all variables with detailed explanations
- Multi-line descriptions use heredoc syntax (<<-DESC...DESC) for readability

**Variable Documentation:**
- Every variable includes `description` field (mandatory)
- Type information always explicit with full schema for complex types
- Inline comments in object fields explain optional parameters and default behaviors
- Examples provided in descriptions when helpful for usage clarity

## Module Design

**Exports:**
- No explicit outputs.tf found - module focuses on resource creation side effects
- Resources created directly represent the module's output (Docker containers, volumes, images)
- Module designed to be called with simple configuration in consuming Terraform code

**Variables as Interface:**
- Comprehensive variable definitions serve as the module's public interface
- All configuration options exposed as variables with sensible defaults
- Optional parameters use `optional()` to allow flexibility without forcing all arguments

**Internal Naming Consistency:**
- Resource labels (`"main"`, `"volumes"`) remain consistent across the module
- Dynamic blocks use `for_each` consistently for iteration patterns
- Block variable references use descriptive iterator names (e.g., `devices.value.host_path`, `volumes.value.container_path`)

---

*Convention analysis: 2026-02-28*
