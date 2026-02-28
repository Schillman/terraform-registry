# Architecture

**Analysis Date:** 2026-02-28

## Pattern Overview

**Overall:** Terraform Module Registry (monolithic repository pattern)

**Key Characteristics:**
- Centralized repository for storing reusable Terraform modules
- Module-based architecture following Terraform conventions
- Single-provider focus per module (currently Docker provider)
- Standardized input/output contracts using HCL variable blocks
- Dynamic resource generation using `for_each` and `dynamic` blocks

## Layers

**Module Layer:**
- Purpose: Encapsulates infrastructure as code patterns for specific providers and resources
- Location: `modules/`
- Contains: Provider configuration, resource definitions, input variables, documentation
- Depends on: Terraform provider (Docker provider in current module)
- Used by: External consumers referencing modules via GitHub source URLs

**Provider Layer:**
- Purpose: Defines required Terraform providers and versions
- Location: `modules/terraform-docker-container/terraform.tf`
- Contains: Provider version constraints (docker 3.0.2)
- Depends on: External Terraform provider registry
- Used by: Terraform CLI during initialization

**Resource Layer:**
- Purpose: Defines concrete infrastructure resources managed by the provider
- Location: `modules/terraform-docker-container/main.tf`
- Contains: docker_image, docker_volume, docker_container resources
- Depends on: Provider configuration, input variables
- Used by: Terraform apply/plan operations

**Configuration Layer:**
- Purpose: Accepts external inputs to customize resource behavior
- Location: `modules/terraform-docker-container/variables.tf`
- Contains: Input variable definitions with type constraints and defaults
- Depends on: Module caller providing values
- Used by: Resource layer for dynamic configuration

**Test/Example Layer:**
- Purpose: Demonstrates module usage and validates functionality
- Location: `modules/terraform-docker-container/tests/example/`
- Contains: Example module invocation with sample values
- Depends on: Module being tested
- Used by: Module developers and documentation

## Data Flow

**Module Consumption Flow:**

1. Consumer declares module block with GitHub source URL (e.g., `github.com/Schillman/terraform-registry//modules/terraform-docker-container?ref=v1.0`)
2. Terraform clones module from repository at specified reference
3. Consumer provides input variables (name, docker_image_name, ports, volumes, etc.)
4. Module terraform.tf loads required Docker provider version (3.0.2)
5. main.tf processes inputs through dynamic blocks to configure:
   - Docker image resource (pulled from docker_image_name variable)
   - Docker volumes (iterated from volumes map)
   - Docker container (created with consolidated configuration)
6. Terraform provider applies resources to Docker daemon
7. Infrastructure state is tracked locally or in remote backend

**State Management:**
- State stored locally in consumer's `terraform.tfstate` (not committed to registry)
- Module provides no outputs (docker resources created as side effect)
- No remote state sharing between module and consumers

## Key Abstractions

**Module as Abstraction:**
- Purpose: Hides Docker complexity behind simplified HCL interface
- Examples: `modules/terraform-docker-container/`
- Pattern: Input variables abstract provider-specific resource configuration. Dynamic blocks (healthcheck, devices, ports, volumes) manage variable-length collections without explicit repetition.

**Dynamic Configuration:**
- Purpose: Enables flexible, optional resource properties through variable iteration
- Examples: `dynamic "healthcheck" { for_each = var.healthcheck ... }` in `main.tf` (lines 30-40)
- Pattern: Optional object types with defaults (e.g., `optional(string, "rwm")`) combined with dynamic blocks allow consumers to provide configuration only when needed

**Typed Input Contract:**
- Purpose: Enforces valid configurations at Terraform validation time
- Examples: `healthcheck` as `list(object({...}))`, `ports` as constrained list, `volumes` as typed map
- Pattern: HCL type system validates inputs before resource creation (no invalid configs reach Docker provider)

## Entry Points

**Module Entry Point:**
- Location: `modules/terraform-docker-container/main.tf`
- Triggers: Terraform apply invoked on consumer configuration
- Responsibilities: Defines three concrete resource types (docker_image, docker_volume, docker_container) that terraform operates on

**Configuration Entry Point:**
- Location: `modules/terraform-docker-container/variables.tf`
- Triggers: Terraform plan/apply phase reads variable definitions
- Responsibilities: Declares all valid inputs and their constraints; two required (name, docker_image_name), eleven optional with sensible defaults

**Module Registry Entry Point:**
- Location: Root repository (GitHub URL `github.com/Schillman/terraform-registry`)
- Triggers: External consumer module source declaration
- Responsibilities: Provides discoverable modules via Git references (tags, branches, commits)

## Error Handling

**Strategy:** Declarative validation through type constraints; Terraform provider validates at apply time

**Patterns:**
- Input validation: HCL type system enforces object shapes at plan time (e.g., ports must be list of objects with internal/external numbers)
- Provider-level: Docker provider returns errors if resource creation fails (e.g., port already in use, image not found)
- No custom error handling in module code (Terraform handles provider errors)
- Variables with sensible defaults reduce invalid states (network_mode defaults to "host", restart defaults to "unless-stopped")

## Cross-Cutting Concerns

**Logging:** No explicit logging in module; Docker provider and Terraform CLI output logs

**Validation:** Enforced through HCL type system in variable definitions (no runtime validation code)

**Authentication:** Docker provider authentication handled by Terraform provider (uses Docker daemon socket/credentials on consumer host)

**Naming:** Follows Terraform naming convention: `terraform-{provider}-{module_name}` (e.g., `terraform-docker-container`)

---

*Architecture analysis: 2026-02-28*
