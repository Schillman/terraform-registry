# External Integrations

**Analysis Date:** 2026-02-28

## APIs & External Services

**Container Orchestration:**
- Docker API/Daemon - Manages Docker images, containers, volumes, and networking
  - SDK/Client: kreuzwerker/docker provider v3.0.2
  - Auth: Docker daemon connection (configured via provider block in `terraform.tf`)

**Module Distribution:**
- GitHub - Provides Git-based module source for Terraform module retrieval
  - Source pattern: `github.com/Schillman/terraform-registry//modules/terraform-docker-container?ref=v1.0`
  - Auth: Public repository (no auth required for reading)

## Data Storage

**Databases:**
- Not used - This is infrastructure-as-code repository with no persistent data storage

**File Storage:**
- Docker Volumes - Managed via `docker_volume` resource for container persistent storage
  - Configuration: Defined in module variables as `volumes` map in `variables.tf`
  - Driver: Default "local" driver with optional custom driver support

**Caching:**
- Docker Image Cache - Local Docker daemon image caching mechanism (implicit)

## Authentication & Identity

**Auth Provider:**
- Docker Daemon Authentication - Configured via provider block in test example (`tests/example/main.tf`)
  - Implementation: Direct Docker daemon connection (socket or remote API endpoint)
  - No API token/credentials stored in code - delegated to Docker daemon configuration

**GitHub API:**
- GITHUB_TOKEN (secrets) - Used in `.github/workflows/lint.yaml` for super-linter authentication
  - Scope: Public repository access, limited to linting operations
  - Configuration: Injected via GitHub Actions secrets

## Monitoring & Observability

**Error Tracking:**
- None detected

**Logs:**
- GitHub Actions workflow logs - Linting and validation output visible in GitHub Actions UI
- Docker container logs - Managed through Docker provider's inherent logging

## CI/CD & Deployment

**Hosting:**
- GitHub (repository hosting and module distribution)
  - Modules referenced via GitHub URLs with tag-based versioning (e.g., `?ref=v1.0`)

**CI Pipeline:**
- GitHub Actions (`.github/workflows/lint.yaml`)
  - Triggers: on pull requests to main branch and pushes to main
  - Jobs: Terraform fmt validation, TFLint validation, multi-language linting via super-linter
  - Terraform validation tools:
    - terraform fmt -check
    - TFLint (Terraform linter)
    - super-linter for additional code quality

## Environment Configuration

**Required env vars:**
- `GITHUB_TOKEN` - For GitHub Actions authentication in super-linter (injected automatically)
- Docker daemon configuration - Required at runtime for Docker provider:
  - Docker socket/endpoint location
  - Authentication credentials (if using remote Docker daemon)

**Secrets location:**
- GitHub Actions Secrets (for `GITHUB_TOKEN`)
- Docker daemon credentials - External to repository, configured on host/runner

## Webhooks & Callbacks

**Incoming:**
- GitHub Push/Pull Request webhooks - Trigger CI/CD pipeline automatically
  - Branches: main
  - Events: pull_request, push

**Outgoing:**
- Docker resource lifecycle callbacks (implicit) - Container startup, health checks defined in variables
  - Health check tests defined in `healthcheck` variable
  - Restart policies configurable via `restart` variable (no, on-failure, always, unless-stopped)

---

*Integration audit: 2026-02-28*
