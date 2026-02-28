# Agent Operating Conventions — terraform-registry

Read this file before doing any work in this repository. It is the single source of truth for all operating conventions.

---

## 1. Commit Conventions

All commits follow [Conventional Commits](https://www.conventionalcommits.org/). The table below maps commit type to semver impact.

| Commit Type | Semver Impact |
|---|---|
| `feat:` | minor bump (1.x.0) |
| `fix:` | patch bump (1.0.x) |
| `docs:` | patch bump |
| `chore:` | patch bump |
| `refactor:` | patch bump |
| `test:` | patch bump |
| `ci:` | patch bump |
| `feat!:` or `fix!:` (breaking shorthand) | major bump (x.0.0) |
| `BREAKING CHANGE:` footer | major bump (x.0.0) |

**Important:** Prefer `feat!:` or `fix!:` shorthand over `BREAKING CHANGE:` footer.
Squash merges discard the commit body, so `BREAKING CHANGE:` footers are silently lost.
The `!` prefix on the type is preserved in the PR title and survives squash merges.

---

## 2. Module Scaffold Pattern

Every module under `modules/{provider}/{resource}/` must contain exactly these six items:

| File / Directory | Purpose |
|---|---|
| `main.tf` | Resource definitions |
| `variables.tf` | Input variable declarations |
| `outputs.tf` | Output value declarations (required even if minimal; needed for terraform-docs) |
| `versions.tf` | `terraform {}` block with `required_version` and provider `required_providers` (NOT `terraform.tf`) |
| `README.md` | Module documentation — must include terraform-docs inject markers |
| `tests/` | Test directory — `unit.tftest.hcl` and `tests/example/` added in Phase 5 |

Target directory pattern: `modules/{provider}/{resource}/`

Example: `modules/docker/container/`

---

## 3. Autonomy Matrix

| Operation | Agent Autonomy |
|-----------|----------------|
| Edit/create `.tf`, `.md`, `.yml`, `.json` files | Freely — workflow checks must pass |
| Edit CI workflows (`lint.yaml`, `release.yaml`, etc.) | Freely — workflow checks must pass |
| Delete files | Freely — workflow checks must pass |
| Force push | Freely — workflow checks must pass |
| Create releases | Freely — workflow checks must pass |
| Modify branch protection rules | Freely — workflow checks must pass |

---

## 4. Consumer Source URL Pattern

Use a namespaced, version-pinned `ref` when sourcing a module from this registry. The `ref` follows the format `modules/{provider}/{resource}/v{semver}`.

```hcl
# CORRECT — version-pinned ref, no depth=1
module "container" {
  source = "github.com/Schillman/terraform-registry//modules/docker/container?ref=modules/docker/container/v1.0.0"
}
```

**Pitfall — never use `depth=1` in version-pinned source URLs.**
Once new commits land after a release tag, `depth=1` with an older pinned tag will fail because
Git cannot find the tag object in a shallow clone that does not include it.
Do **not** use `?depth=1&ref=modules/docker/container/v1.0.0` or any variant.
