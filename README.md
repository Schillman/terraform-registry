# Terraform Registry

[![Lint Code Base](https://github.com/Schillman/terraform-registry/actions/workflows/lint.yaml/badge.svg)](https://github.com/Schillman/terraform-registry/actions/workflows/lint.yaml)

Central repository for production-ready Terraform modules.
Every module is versioned, documented, and CI-validated automatically.

## Available Modules

| Module | Description | Latest Release |
|--------|-------------|----------------|
| [docker/container](modules/docker/container/) | Manages a Docker container with configurable image, ports, volumes, environment variables, and restart policy | [![docker/container](https://img.shields.io/github/v/tag/Schillman/terraform-registry?filter=modules%2Fdocker%2Fcontainer%2Fv*&label=latest&sort=semver)](https://github.com/Schillman/terraform-registry/releases?q=modules%2Fdocker%2Fcontainer) |

## Using a Module

Pin to a specific version using the module-scoped `ref`:

```hcl
module "container" {
  source = "github.com/Schillman/terraform-registry//modules/docker/container?ref=modules/docker/container/v1.0.0"

  name              = "my-app"
  docker_image_name = "nginx:latest"
}
```

> **Never use `depth=1` with version-pinned refs.** Once new commits land after a release,
> a shallow clone cannot find older tags. Omit `depth` entirely.

## Adding Modules

New modules go in `modules/{provider}/{resource}/` and must include:
`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`, `tests/`

See [SKILL.md](SKILL.md) for full agent conventions, commit rules, and Dependabot guidance.
