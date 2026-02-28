# Phase 1: Foundation - Research

**Researched:** 2026-02-28
**Domain:** Terraform module migration, file naming conventions, agent operational documentation
**Confidence:** HIGH (all deliverables are deterministic file operations with no tool uncertainty; user decisions locked all ambiguous choices)

---

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions

**Module outputs**
- Expose three outputs: `container_id`, `container_name`, `image_id`
- Sourced from `docker_container.main.id`, `docker_container.main.name`, `docker_image.main.image_id`
- No ports output, no full-resource output

**versions.tf scope**
- File named `versions.tf` (not `terraform.tf`)
- Declares `required_version = "~> 1.9"`
- Also includes the existing provider block from `terraform.tf` migrated as-is (kreuzwerker/docker, version 3.0.2)

**SKILL.md scope and structure**
- Focused document — exactly what agents need to operate this repo
- **Commit convention table** (standard set):
  - `feat:` → minor bump
  - `fix:` → patch bump
  - `docs:`, `chore:`, `refactor:`, `test:`, `ci:` → patch bump
  - `BREAKING CHANGE:` footer → major bump
- **Autonomy matrix**: agents may freely edit/create `.tf`, `.md`, `.yml`, `.json` files and CI workflows (`lint.yaml`, `release.yaml`, etc.) without asking. Must ask before: deleting files, force-pushing, creating releases, modifying branch protection rules.
- **Module scaffold pattern**: required files per module (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`, `tests/`)
- **Consumer source URL pattern**: tag-pinned ref, no `depth=1`:
  ```
  source = "github.com/Schillman/terraform-registry//modules/docker/container?ref=modules/docker/container/v1.0.0"
  ```
  `depth=1` must NOT appear in any version-pinned examples

**CLAUDE.md approach**
- Short file that @-references SKILL.md
- Does not duplicate SKILL.md content inline
- Tells Claude Code agents to read SKILL.md for all operating conventions

**Old directory removal**
- `modules/terraform-docker-container/` is fully deleted — no .tf files, no README
- User decision: no deprecation stub needed
- Note: this overrides the roadmap success criterion that called for a deprecation stub
- Old Git tags (`v0.0.1`, `v1.0`) are preserved (not deleted)

### Claude's Discretion

- Exact wording and formatting of SKILL.md sections
- Whether to add `description` fields to outputs (standard Terraform practice — yes)
- `.markdownlintignore` content (exclude `.planning/`)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.

</user_constraints>

---

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| STRC-01 | Modules live at `modules/{provider}/{resource}` (namespaced, max 3 levels) | Directory migration creates `modules/docker/container/` as the target path — satisfies this pattern |
| STRC-02 | Every module contains `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`, and `tests/` | Existing code has all except `outputs.tf`; this phase creates `outputs.tf` and carries everything else over |
| STRC-03 | `versions.tf` (not `terraform.tf`) declares the `terraform {}` block and provider requirements | Existing `terraform.tf` is renamed and its content migrated into `versions.tf` |
| STRC-04 | Terraform version constraint is `~> 1.9` (not `~> 1.5`) across all modules | `versions.tf` will declare `required_version = "~> 1.9"` in the `terraform {}` block |
| STRC-05 | Existing Docker module migrated from `modules/terraform-docker-container/` to `modules/docker/container/` | Full copy of `main.tf`, `variables.tf`, `README.md`, `tests/` to new path |
| STRC-06 | Old module directory preserved as stub with deprecation notice; old tags not deleted | **User override**: directory is fully deleted, not stubbed. Old tags (`v0.0.1`, `v1.0`) are preserved. Requirement partially satisfied — tags preserved, stub waived by user. |
| AGNT-01 | `SKILL.md` at repo root documents commit conventions, module scaffold, autonomy matrix, and correct consumer source URL patterns | New file created; content dictated by locked decisions in CONTEXT.md |
| AGNT-02 | `CLAUDE.md` at repo root mirrors or references `SKILL.md` for Claude Code agents | New short file created that @-references SKILL.md |
| AGNT-03 | Commit message type-to-semver mapping documented: `feat:` = minor, `fix:` = patch, `feat!:`/`fix!:` = major, `chore:`/`docs:`/`test:` = no release | Goes in SKILL.md commit convention table. Note: CONTEXT.md locked `docs:` etc. to "patch bump" rather than "no release" — SKILL.md must follow the locked user decision |
| AGNT-04 | Autonomy matrix defined: agents may autonomously commit `feat:`/`fix:`. Breaking changes reported by tfbreak should be verified by a human before merging. | Goes in SKILL.md autonomy matrix; locked user decisions specify the exact file type permissions |
| AGNT-05 | Consumer source URL pattern documented without `depth=1` on version-pinned refs (documented pitfall) | Goes in SKILL.md; `depth=1` is explicitly forbidden in version-pinned examples |
| MAINT-02 | `.markdownlintignore` excludes `.planning/` from markdownlint rules | New file at repo root; single line excluding `.planning/` |

</phase_requirements>

---

## Summary

Phase 1 is a migration and documentation phase — no new tooling is introduced, no CI workflows are modified, and no infrastructure is provisioned. The entire phase consists of deterministic file operations: copy existing module files to a new directory path, create two missing files (`outputs.tf`, `versions.tf`), write two new agent instruction files (`SKILL.md`, `CLAUDE.md`), create `.markdownlintignore`, and delete the old module directory. All user decisions are locked, leaving only content wording at Claude's discretion.

The existing codebase is in excellent shape for migration. `main.tf` and `variables.tf` are clean, well-documented, and copy verbatim to the new path. The existing `terraform.tf` becomes the body of `versions.tf` with `required_version = "~> 1.9"` added. The only net-new Terraform file is `outputs.tf`, which exposes three attributes that are directly available on existing resources. The `tests/` directory already exists with one file (`tests/example/main.tf`) and a lockfile that both migrate unchanged.

There is one requirement conflict to acknowledge: STRC-06 called for a deprecation stub in the old directory; the user overrode this in CONTEXT.md. The old Git tags (`v0.0.1`, `v1.0`) are preserved. The old directory is deleted cleanly. The AGNT-03 commit-type semver mapping in REQUIREMENTS.md says `chore:`/`docs:`/`test:` = "no release" but the user locked these to "patch bump" in CONTEXT.md. SKILL.md must follow the locked user decision.

**Primary recommendation:** Execute as four atomic commits in this order: (1) create `modules/docker/container/` with all six files, (2) delete `modules/terraform-docker-container/`, (3) write `SKILL.md` and `CLAUDE.md`, (4) write `.markdownlintignore`. This order keeps the repo in a valid state at every commit — the new path exists before the old is removed.

---

## Standard Stack

### Core

| Tool | Version / Constraint | Purpose | Why Used |
|------|---------------------|---------|----------|
| Terraform | `~> 1.9` | IaC runtime for all modules | Minimum required for native `terraform test` (>= 1.6); `~> 1.9` is current stable minor series |
| kreuzwerker/docker provider | `3.0.2` (exact, migrated as-is) | Docker resource management | Existing pin; not changed in this phase |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `terraform fmt` | bundled with Terraform | Canonical HCL formatting | Run before committing any `.tf` file; CI enforces recursively |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Exact provider pin `3.0.2` | Range pin `>= 3.0.2, < 4.0.0` | Range pin is preferred long-term (enables Dependabot patch bumps) but user locked the provider block to migrate "as-is" — range pinning is deferred to a future phase |

---

## Architecture Patterns

### Target Directory Structure After Phase 1

```
modules/
└── docker/
    └── container/
        ├── main.tf           # migrated verbatim from terraform-docker-container/main.tf
        ├── variables.tf      # migrated verbatim from terraform-docker-container/variables.tf
        ├── outputs.tf        # NEW — exposes container_id, container_name, image_id
        ├── versions.tf       # NEW — renamed from terraform.tf + required_version added
        ├── README.md         # migrated verbatim from terraform-docker-container/README.md
        └── tests/
            └── example/
                ├── main.tf              # migrated verbatim (source URL needs future update in Phase 5)
                └── .terraform.lock.hcl  # migrated verbatim

SKILL.md          # NEW at repo root
CLAUDE.md         # NEW at repo root
.markdownlintignore  # NEW at repo root
```

Old path removed:
```
modules/terraform-docker-container/   # DELETED — no stub
```

### Pattern 1: Terraform Module File Convention (versions.tf)

**What:** The `terraform {}` block (required version + provider requirements) lives in a file named `versions.tf`, not `terraform.tf`. This is the community standard since Terraform 0.13.

**When to use:** Every Terraform module in this repo.

**Example:**
```hcl
# modules/docker/container/versions.tf
terraform {
  required_version = "~> 1.9"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}
```

### Pattern 2: Module Outputs Convention

**What:** `outputs.tf` exposes the identifiers that consumers and downstream modules need. Add `description` to every output (standard practice).

**When to use:** Every module must have an `outputs.tf`. Even if outputs are minimal, the file must exist so terraform-docs can generate the Outputs section.

**Example:**
```hcl
# modules/docker/container/outputs.tf
output "container_id" {
  description = "The ID of the Docker container."
  value       = docker_container.main.id
}

output "container_name" {
  description = "The name of the Docker container."
  value       = docker_container.main.name
}

output "image_id" {
  description = "The ID of the Docker image used by the container."
  value       = docker_image.main.image_id
}
```

### Pattern 3: SKILL.md Structure

**What:** A repo-root file that agents read before starting any session. Focused on exactly what agents need — nothing more.

**Required sections (locked by user):**
1. Commit Convention Table (type → semver impact)
2. Module Scaffold Pattern (required files per module)
3. Autonomy Matrix (what agents can do freely vs. must ask)
4. Consumer Source URL Pattern (with `depth=1` forbidden on version-pinned refs)

**Example commit convention table:**
```markdown
| Commit Type | Semver Impact |
|-------------|---------------|
| `feat:` | minor bump (1.x.0) |
| `fix:` | patch bump (1.0.x) |
| `docs:`, `chore:`, `refactor:`, `test:`, `ci:` | patch bump |
| `BREAKING CHANGE:` footer or `feat!:`/`fix!:` | major bump (x.0.0) |
```

**Example autonomy matrix:**
```markdown
| Operation | Agent Autonomy |
|-----------|----------------|
| Edit/create `.tf`, `.md`, `.yml`, `.json` files | Freely — no approval needed |
| Edit CI workflows (`lint.yaml`, `release.yaml`, etc.) | Freely — no approval needed |
| Delete files | Must ask human first |
| Force push | Must ask human first |
| Create releases | Must ask human first |
| Modify branch protection rules | Must ask human first |
```

**Example consumer source URL (the correct pattern):**
```hcl
# CORRECT — version-pinned ref, no depth=1
module "container" {
  source = "github.com/Schillman/terraform-registry//modules/docker/container?ref=modules/docker/container/v1.0.0"
}

# WRONG — depth=1 breaks once newer commits land after the tag
# source = "github.com/...?depth=1&ref=modules/docker/container/v1.0.0"
```

### Pattern 4: CLAUDE.md as a Thin Reference File

**What:** CLAUDE.md at repo root is read by Claude Code on every session start. It should be a short pointer to SKILL.md — not a duplicate.

**Example:**
```markdown
# Claude Code Agent Instructions

Read SKILL.md at repo root before doing any work in this repository.
SKILL.md contains all operating conventions: commit types, module scaffold pattern,
autonomy matrix, and correct consumer source URL format.
```

### Pattern 5: .markdownlintignore

**What:** Excludes internal planning docs from markdownlint (the `.planning/` directory uses informal formatting that would fail lint rules).

**Example:**
```
.planning/
```

### Anti-Patterns to Avoid

- **Using `terraform.tf` instead of `versions.tf`**: The CI, docs tooling, and community convention all expect `versions.tf`. Renaming is required.
- **Omitting `required_version` from `versions.tf`**: The `terraform {}` block must declare `required_version = "~> 1.9"` alongside the provider. A block without `required_version` satisfies the file rename but not STRC-04.
- **Including `depth=1` in version-pinned source URL examples**: Even as a comment or "alternative", it must not appear. Document it only as a pitfall to avoid.
- **Duplicating SKILL.md content in CLAUDE.md**: CLAUDE.md must be a thin reference, not a mirror. Duplication creates drift.
- **Deleting old git tags**: Tags `v0.0.1` and `v1.0` must not be deleted. Old consumers may still reference them via old commit history.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HCL formatting | Custom formatting logic | `terraform fmt` | Terraform's built-in formatter is the only authoritative formatter; any custom approach will diverge |
| Output attribute references | Guess attribute names | Read `docker_container` resource schema directly from `main.tf` | `docker_container.main.id`, `docker_container.main.name`, `docker_image.main.image_id` are confirmed present in the existing resource definitions |

**Key insight:** This phase has no complex tooling. Every deliverable is a file write or file move. The only risk is incorrect attribute names in `outputs.tf` — these are verified directly from the existing `main.tf`.

---

## Common Pitfalls

### Pitfall 1: Wrong Resource Attribute in outputs.tf

**What goes wrong:** `docker_image.main.image_id` is the correct attribute; `docker_image.main.id` is different (it includes the sha256 digest with the image name as a compound string, not just the ID). Using the wrong attribute produces a valid plan but wrong output semantics.

**Why it happens:** The kreuzwerker/docker provider has both `.id` and `.image_id` on `docker_image` resources; they are not the same value.

**How to avoid:** The user explicitly specified `docker_image.main.image_id` (not `.id`) in the locked decisions. Write that exact attribute path.

**Warning signs:** An output named `image_id` returning a string like `sha256:abc123:nginx:latest` instead of a bare ID.

### Pitfall 2: Forgetting required_version in versions.tf

**What goes wrong:** Renaming `terraform.tf` to `versions.tf` without adding `required_version = "~> 1.9"` satisfies STRC-03 but fails STRC-04. The CI grep check `grep "required_version" modules/docker/container/versions.tf` will return nothing.

**Why it happens:** The rename is done correctly but the content addition is forgotten.

**How to avoid:** The `versions.tf` file must contain BOTH `required_version = "~> 1.9"` AND the provider block. Write the full file, not just a rename.

**Warning signs:** `terraform init` succeeds on older Terraform versions that should be rejected.

### Pitfall 3: tests/example/main.tf Source URL Left as Old Path

**What goes wrong:** The existing `tests/example/main.tf` references `github.com/Schillman/terraform-registry//modules/terraform-docker-container?ref=v1.0`. After migration, this URL points to a deleted directory. If left unchanged, `terraform init` in the example directory will fail.

**Why it happens:** It is easy to migrate the file verbatim without updating the embedded source URL.

**How to avoid:** Update the source URL in `tests/example/main.tf` to use the new path. The CONTEXT.md notes this file "migrates into `modules/docker/container/tests/`" and "its source URL will need updating to new path (or left for Phase 2 when tags exist)." Since no tags exist yet at the new path, the correct Phase 1 approach is to update the source to a relative path (`source = "../../"`) which works for local testing without a tag.

**Warning signs:** `terraform init` error in `modules/docker/container/tests/example/` citing the old module path.

### Pitfall 4: SKILL.md Commit Type Table Conflict

**What goes wrong:** AGNT-03 in REQUIREMENTS.md says `chore:`/`docs:`/`test:` produce "no release". The user locked in CONTEXT.md that these produce "patch bump". Writing the REQUIREMENTS.md version in SKILL.md creates an inconsistency with the user's decision.

**Why it happens:** Two authoritative sources disagree.

**How to avoid:** CONTEXT.md user decisions take precedence over REQUIREMENTS.md. Write the SKILL.md commit convention table using the locked user decision: `docs:`, `chore:`, `refactor:`, `test:`, `ci:` → patch bump.

**Warning signs:** SKILL.md says "no release" for `docs:` commits when the user expects a patch bump.

### Pitfall 5: CI Fails on Migrated .tf Files Due to terraform fmt

**What goes wrong:** The existing `.tf` files pass `terraform fmt` today. After migration, if any whitespace or line ending is accidentally altered during copy, CI will fail the format check on the first PR.

**Why it happens:** Copy-paste or editor auto-formatting can silently alter HCL files.

**How to avoid:** Use `cp` or `git mv` for file migration, not editor-based copy-paste. Run `terraform fmt -check -recursive modules/docker/container/` locally before committing.

**Warning signs:** CI `terraform fmt -diff -recursive -check` step shows diff output on migrated files.

---

## Code Examples

### outputs.tf (complete file)

```hcl
output "container_id" {
  description = "The ID of the Docker container."
  value       = docker_container.main.id
}

output "container_name" {
  description = "The name of the Docker container."
  value       = docker_container.main.name
}

output "image_id" {
  description = "The ID of the Docker image used by the container."
  value       = docker_image.main.image_id
}
```

### versions.tf (complete file)

```hcl
terraform {
  required_version = "~> 1.9"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}
```

### tests/example/main.tf (updated source path)

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
  source = "../../"

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

### .markdownlintignore (complete file)

```
.planning/
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `terraform.tf` for the `terraform {}` block | `versions.tf` | Terraform 0.13 (2020) | Community standard; tools and docs expect `versions.tf` |
| Flat module directory naming (`terraform-docker-container`) | Namespaced path (`modules/{provider}/{resource}`) | Adopted by terraform-module-releaser pattern | Required for module-scoped tag format `modules/docker/container/vX.Y.Z` |
| No `outputs.tf` (resource side-effect only) | `outputs.tf` required in every module | Standard since Terraform 0.7 | Required for consumers to compose modules; required for terraform-docs to generate Outputs section |
| `~> 1.5` Terraform version constraint | `~> 1.9` | Current recommendation | Enables native `terraform test` (requires >= 1.6); `~> 1.9` is latest stable minor series |

**Deprecated/outdated in this repo after Phase 1:**
- `modules/terraform-docker-container/`: Deleted. References must use `modules/docker/container/`.
- `modules/terraform-docker-container/terraform.tf`: Superseded by `modules/docker/container/versions.tf`.
- Old flat tag format (`v1.0`, `v0.0.1`): Preserved but superseded by namespaced tags (`modules/docker/container/vX.Y.Z`) which Phase 2 will create.

---

## Open Questions

1. **tests/example/main.tf source URL — Phase 2 timing**
   - What we know: The existing file uses a Git source URL with an old path and old tag. After migration, this URL points to a deleted directory.
   - What's unclear: Should Phase 1 update to a relative path (`source = "../../"`) or leave the URL update for Phase 2? The CONTEXT.md says "left for Phase 2 when tags exist."
   - Recommendation: Use relative source `source = "../../"` in Phase 1. This makes the example immediately functional for local `terraform init` without requiring a tag. The relative path is also the correct long-term approach per Phase 5 requirements (TEST-02). There is no reason to leave a broken URL.

2. **AGNT-03 conflict: "no release" vs "patch bump" for `docs:`/`chore:` types**
   - What we know: REQUIREMENTS.md says "no release" for these types. CONTEXT.md (user decision) says "patch bump."
   - What's unclear: Which is authoritative for SKILL.md?
   - Recommendation: User decision in CONTEXT.md is authoritative. SKILL.md documents "patch bump" for `docs:`, `chore:`, `refactor:`, `test:`, `ci:`. Note this discrepancy so the user can resolve it in Phase 2 when wiring up terraform-module-releaser (the tool's actual behavior will be the final arbiter).

---

## Sources

### Primary (HIGH confidence)

- `/Users/p950cvo/Files/p-repositories/terraform-registry/.planning/phases/01-foundation/01-CONTEXT.md` — All locked user decisions; authoritative for this phase
- `/Users/p950cvo/Files/p-repositories/terraform-registry/modules/terraform-docker-container/main.tf` — Existing resource definitions confirming `docker_container.main`, `docker_image.main`, `docker_volume.volumes` labels and attribute availability
- `/Users/p950cvo/Files/p-repositories/terraform-registry/modules/terraform-docker-container/terraform.tf` — Existing provider block to migrate into `versions.tf`
- `/Users/p950cvo/Files/p-repositories/terraform-registry/modules/terraform-docker-container/variables.tf` — Migrates verbatim; verified no changes needed
- `/Users/p950cvo/Files/p-repositories/terraform-registry/.planning/research/PITFALLS.md` — Pitfall 3 (`depth=1`) and Pitfall 4 (migration breaking consumer refs)
- `/Users/p950cvo/Files/p-repositories/terraform-registry/.planning/research/SUMMARY.md` — Phase 1 scope, deliverables, and conflict resolution for `versions.tf` vs `terraform.tf`

### Secondary (MEDIUM confidence)

- `/Users/p950cvo/Files/p-repositories/terraform-registry/.planning/REQUIREMENTS.md` — Phase requirement IDs and descriptions; used for phase_requirements mapping
- `/Users/p950cvo/Files/p-repositories/terraform-registry/.planning/ROADMAP.md` — UAT checklist and success criteria for Phase 1
- `/Users/p950cvo/Files/p-repositories/terraform-registry/.planning/codebase/CONVENTIONS.md` — Existing code conventions confirming `"main"` resource label pattern

### Tertiary (LOW confidence)

- None applicable — Phase 1 has no uncertain technical domains.

---

## Metadata

**Confidence breakdown:**
- File operations (copy, rename, delete): HIGH — fully determined by existing file inventory
- outputs.tf attribute paths: HIGH — verified directly from existing `main.tf` resource definitions
- versions.tf content: HIGH — directly specified by user locked decision
- SKILL.md content: HIGH for structure (locked), MEDIUM for exact wording (Claude's discretion)
- CLAUDE.md content: HIGH — simple pointer file
- Pitfalls: HIGH — all identified from existing codebase analysis and project research

**Research date:** 2026-02-28
**Valid until:** N/A — this phase has no external tool dependencies or version-sensitive decisions. The research is valid for the lifetime of Phase 1.
