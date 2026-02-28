# Codebase Concerns

**Analysis Date:** 2026-02-28

## Tech Debt

**Type Mismatch in Device Container Path Default:**
- Issue: In `modules/terraform-docker-container/variables.tf`, the `devices` variable's `container_path` is defined as `optional(string, 0)` with a numeric default (0) instead of a string default (e.g., "0" or a valid path string)
- Files: `modules/terraform-docker-container/variables.tf` (line 30)
- Impact: Type mismatch will cause validation errors at runtime when the default is used. The `container_path` field expects a string but receives a number, leading to Terraform plan failures
- Fix approach: Change `optional(string, 0)` to `optional(string, "")` or `optional(string, "/dev")` depending on intended behavior

**Type Mismatch in Healthcheck Interval/Timeout/Start Period Defaults:**
- Issue: In `modules/terraform-docker-container/variables.tf`, the `healthcheck` variable's time-based fields (`interval`, `start_period`, `timeout`) are defined as `optional(string, 0)` with numeric defaults instead of string defaults
- Files: `modules/terraform-docker-container/variables.tf` (lines 46, 48, 49)
- Impact: Type mismatch will cause validation errors. These fields require duration strings like "30s" or "1m", but numeric 0 is provided as default, breaking healthcheck configuration
- Fix approach: Change numeric defaults to string format: `optional(string, "0s")` to match Docker healthcheck duration format requirements

**Missing Module Outputs:**
- Issue: The Docker container module has no `outputs.tf` file defined, leaving no way for consumers to reference created resources
- Files: `modules/terraform-docker-container/` - outputs.tf missing
- Impact: Prevents downstream modules or configurations from accessing container ID, image digest, or volume information. Users cannot pass container references to other infrastructure components
- Fix approach: Create `outputs.tf` with at least: container_id, image_id, volume names/IDs

## Security Considerations

**Insecure Default Network Configuration:**
- Issue: Default `network_mode` is set to "host" in `modules/terraform-docker-container/variables.tf` (line 58)
- Files: `modules/terraform-docker-container/variables.tf` (line 58)
- Current mitigation: None - users must explicitly override this value
- Recommendations: Change default to `"bridge"` for improved network isolation. Host networking exposes container to all network interfaces and can bypass security controls. Add security note in documentation explaining the risks of host networking

**Port Binding Defaults to All Interfaces:**
- Issue: Port binding defaults to IP `0.0.0.0` (all interfaces) in `modules/terraform-docker-container/variables.tf` (line 66)
- Files: `modules/terraform-docker-container/variables.tf` (line 66)
- Current mitigation: Documentation exists but is not prominent in README warnings
- Recommendations: Document security implications in README with prominent warning. Consider changing default to `"127.0.0.1"` for local-only binding, or require explicit IP specification

**No Input Validation on Critical Fields:**
- Issue: No validation blocks exist for critical variables like `docker_image_name`, `restart` policy values, or `gpus` parameter
- Files: `modules/terraform-docker-container/variables.tf`
- Current mitigation: Comments in variable descriptions mention constraints (e.g., gpus must be "all")
- Recommendations: Add validation blocks to enforce constraints. For example, `restart` should validate against `["no", "on-failure", "always", "unless-stopped"]`

## Performance Bottlenecks

**GPU Parameter Documentation Unclear:**
- Issue: In `modules/terraform-docker-container/variables.tf` (line 39), the `gpus` parameter states "only the value all is supported. Passing any other value will result in unexpected behavior"
- Files: `modules/terraform-docker-container/variables.tf` (line 39)
- Cause: No validation prevents users from passing invalid GPU values, leading to silent failures
- Improvement path: Add `validation` block to restrict to "all" value only, fail fast at plan time instead of apply time

## Fragile Areas

**Volume Configuration Inconsistency:**
- Files: `modules/terraform-docker-container/main.tf` (lines 60-68), `modules/terraform-docker-container/variables.tf` (lines 84-101)
- Why fragile: The module creates volumes via `docker_volume.volumes` resource (line 5-18 of main.tf) but then references them in `docker_container` dynamic block using `volumes.value.name`. If the volume object structure changes or required fields are missing, the reference breaks
- Safe modification: Test thoroughly with incomplete volume configurations. Add validation to ensure required fields (`name` and `container_path`) are always present before use
- Test coverage: The test file `modules/terraform-docker-container/tests/example/main.tf` only tests a basic scenario with one volume. Edge cases (no volumes, multiple volumes, volume without container_path) are not tested

**Type Inconsistency in README Auto-Generated Documentation:**
- Files: `modules/terraform-docker-container/README.md` (line 59)
- Why fragile: The README is auto-generated from `terraform-docs` but contains a typo: `optional(Number, 0)` (capital N) instead of `optional(number, 0)` (lowercase n as in actual code). This causes documentation to diverge from source
- Safe modification: Regenerate documentation using terraform-docs tool to keep in sync with actual variable definitions
- Test coverage: No automation to verify documentation matches actual Terraform configuration

**Unspecified Provider Constraint in Test:**
- Files: `modules/terraform-docker-container/tests/example/main.tf` (line 5), `modules/terraform-docker-container/terraform.tf`
- Why fragile: Both files pin Docker provider to exact version 3.0.2. If this version has a bug or security issue, all tests fail. No flexibility for patch updates
- Safe modification: Consider using constraint `>= 3.0.2, < 4.0.0` to allow patch updates while preventing breaking changes
- Test coverage: Only tested against one specific provider version

## Missing Critical Features

**No State Output Capability:**
- Problem: Module provides no outputs for created resources (container ID, image digest, volume IDs)
- Blocks: Cannot reference created container in other modules or data sources. Cannot export container state for monitoring/debugging
- Priority: High

**No Validation Rules:**
- Problem: Critical input parameters lack Terraform validation blocks
- Blocks: Invalid configurations are not caught until apply time, wasting time and resources
- Priority: High

**Incomplete Test Coverage:**
- Problem: Only one basic example test exists that uses minimal configuration
- Blocks: Cannot confidently validate edge cases or complex multi-container scenarios
- Priority: Medium

## Test Coverage Gaps

**Basic Configuration Testing Only:**
- What's not tested:
  - Volume mounting without docker_volume creation (host_path mount)
  - GPU configuration
  - Advanced healthcheck configurations
  - Multiple containers with shared volumes
  - Device binding scenarios
  - Restart policy variations
- Files: `modules/terraform-docker-container/tests/example/main.tf`
- Risk: Breaking changes to GPU support, device binding, or volume behavior could go undetected
- Priority: High

**No Negative Test Cases:**
- What's not tested: Invalid inputs (wrong restart policy, invalid GPU value, missing required variables)
- Files: `modules/terraform-docker-container/tests/`
- Risk: Invalid configurations proceed to apply phase instead of failing at plan
- Priority: High

**No Multi-Module Integration Tests:**
- What's not tested: Using this module in a larger infrastructure context with dependencies
- Files: `modules/terraform-docker-container/tests/`
- Risk: Module may work in isolation but fail when combined with other modules
- Priority: Medium

---

*Concerns audit: 2026-02-28*
