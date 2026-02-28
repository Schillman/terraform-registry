# Phase 2: Automated Releases - Research

**Researched:** 2026-02-28
**Domain:** GitHub Actions — terraform-module-releaser, PR title validation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

No locked user decisions captured. All implementation decisions are at Claude's discretion.

### Claude's Discretion

- Release workflow structure: whether release.yaml is separate from lint.yaml, and what triggers it uses
- PR title enforcement: whether to add a job to lint.yaml or create a dedicated workflow
- terraform-module-releaser configuration: explicit path configuration to prevent silent-skip on two-level paths
- Test commit validation: approach for real-commit end-to-end validation required by the roadmap
- Wiki initialization: manual step sequencing relative to first release
- Permissions model: `contents: write` and `pull-requests: write` as stated in roadmap success criteria

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| REL-01 | `release.yaml` workflow integrates `terraform-module-releaser` for automated per-module semantic versioning | terraform-module-releaser@v2 confirmed; workflow pattern documented |
| REL-02 | Release workflow uses `fetch-depth: 0` and explicit `permissions: contents: write, pull-requests: write` | Confirmed required by action; documented in Architecture Patterns |
| REL-03 | Module-scoped Git tags are created in format `modules/{provider}/{resource}/vX.Y.Z` | Module discovery algorithm confirmed — detects `modules/docker/container/` via .tf file scan |
| REL-04 | GitHub Release notes are auto-generated per module from commit messages | Built into terraform-module-releaser@v2; uses conventional commits |
| REL-05 | GitHub Wiki is initialized manually and populated by terraform-module-releaser per module | Manual init required before first run — documented in Common Pitfalls |
| REL-06 | First release validated end-to-end: `feat:` commit on main creates `modules/docker/container/v1.0.0` tag | Validation task must be a REAL push + tag confirmation, not syntax check |
| QUAL-06 | PR title validation CI step rejects titles that do not match Conventional Commits regex | `amannn/action-semantic-pull-request@v5` is the standard; workflow example documented |
</phase_requirements>

## Summary

Phase 2 wires up two GitHub Actions workflows: `release.yaml` (terraform-module-releaser) and PR title validation. The core tooling is mature and well-documented.

**Critical finding — module path detection is safe:** The `terraform-module-releaser@v2` action uses a recursive directory scan that looks for any directory containing `.tf` files (`findTerraformModuleDirectories` in the action source). It does **not** have a depth limit. Our `modules/docker/container/` structure will be detected correctly and produce tags in the format `modules/docker/container/vX.Y.Z`. This eliminates the "Pitfall 2 — silent failure on two-level paths" concern from the roadmap. Confirmation: the demo repository uses analogous multi-level paths (`aws/vpc-endpoint/`, `null/random/`) and produces tags like `aws/vpc-endpoint/v1.1.8`.

**Critical remaining risk — GITHUB_TOKEN write permissions:** The action requires `permissions: contents: write, pull-requests: write` at the workflow job level. Without these explicit declarations, the default read-only token causes the action to exit green without creating any tags or releases. This is the top pitfall.

**Primary recommendation:** Use `techpivot/terraform-module-releaser@v2` with `amannn/action-semantic-pull-request@v5` for PR validation. Both are the ecosystem standard for Terraform monorepo release automation. Keep `release.yaml` separate from `lint.yaml` — they have different triggers and permissions requirements.

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| techpivot/terraform-module-releaser | @v2 | Per-module semantic versioning, GitHub Releases, wiki generation | Purpose-built for this exact use case; scans .tf files recursively |
| amannn/action-semantic-pull-request | @v5 | PR title conventional commits validation | Most widely used; well-maintained; no dependencies |
| actions/checkout | @v4 | Repository checkout | Already used in lint.yaml; required for fetch-depth: 0 |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| step-security/action-semantic-pull-request | @v5 | Hardened drop-in for amannn/action-semantic-pull-request | When security hardening is required; same API |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| amannn/action-semantic-pull-request | Namchee/conventional-pr | Both work; amannn has larger adoption and simpler config |
| amannn/action-semantic-pull-request | Raw regex in shell step | More portable but harder to maintain and configure |
| techpivot/terraform-module-releaser | Custom release scripts | Far more complex; reinventing the wheel |

## Architecture Patterns

### Workflow Structure

Two separate workflow files:

```
.github/workflows/
├── lint.yaml       # Existing — runs on PR + push to main
└── release.yaml    # New — runs on PR events (opened, reopened, synchronize, closed)
```

**Why separate:** `release.yaml` needs `contents: write` and `pull-requests: write` permissions. Combining with `lint.yaml` would grant those permissions to the lint jobs unnecessarily.

### Pattern 1: release.yaml — terraform-module-releaser

Based on the official demo repository (`techpivot/terraform-modules-demo`):

```yaml
# .github/workflows/release.yaml
name: Terraform Module Releaser

on:
  pull_request:
    types: [opened, reopened, synchronize, closed]
    branches:
      - main

permissions:
  contents: write
  pull-requests: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Terraform Module Releaser
        uses: techpivot/terraform-module-releaser@v2
```

**Notes:**
- `fetch-depth: 0` is REQUIRED — the action uses full git history for tag detection
- `permissions` must be at the `workflow` or `job` level (not inherited from repo defaults)
- The action uses `pull_request` event (not `push`): it runs on PR open/update/close and tags on close
- `actions/checkout@v4` (not @v6 shown in demo) — match the existing lint.yaml pattern

### Pattern 2: PR title validation workflow

```yaml
# Add as a new job in lint.yaml OR new file pr-title.yaml
name: Lint PR Title

on:
  pull_request:
    types: [opened, reopened, edited, synchronize]
    branches:
      - main

permissions:
  pull-requests: write

jobs:
  validate-pr-title:
    name: Validate PR Title
    runs-on: ubuntu-latest
    steps:
      - uses: amannn/action-semantic-pull-request@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          types: |
            feat
            fix
            docs
            chore
            refactor
            test
            ci
```

**Recommendation:** Add as a new job in `lint.yaml` (reuses the existing workflow file) OR create a dedicated `pr-title.yaml`. Either approach satisfies QUAL-06. Dedicated file is cleaner for future maintenance.

### Pattern 3: release.yaml trigger behavior

`terraform-module-releaser` runs on the `pull_request` event, NOT `push`:
- On PR open/synchronize: posts a comment with the planned release (preview)
- On PR close (merged): creates the actual Git tag and GitHub Release
- The tag `modules/docker/container/v1.0.0` is created when the PR merges, not on direct push

**Implication for UAT:** The roadmap UAT says "merge via PR" — this is correct. Direct `git push` to main does NOT trigger the action (it uses `pull_request`, not `push`). If you push directly to main (bypassing PR), no release is created.

### Pattern 4: Wiki initialization (manual step)

Before the first merge:
1. GitHub UI: Repository > Wiki > "Create the first page" (manual)
2. After wiki page is created, terraform-module-releaser can write to it on subsequent merges
3. If wiki is not initialized, the action will fail the wiki step on first run

### Anti-Patterns to Avoid

- **Missing `fetch-depth: 0`:** Action cannot detect previous tags; may re-create v1.0.0 on subsequent runs
- **Implicit permissions (no explicit declaration):** GITHUB_TOKEN defaults to read-only on many org repos; action exits green without creating tags
- **Using `push` trigger for release.yaml:** Module releaser expects `pull_request` event to work correctly
- **Direct push to main for validation:** Bypasses PR-based tagging mechanism; use a PR for end-to-end validation
- **Forgetting wiki initialization:** Action fails on wiki write; must be done manually before first merge

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Module-scoped versioning | Custom tag scripts | terraform-module-releaser@v2 | Handles diff detection, tagging, releases, wiki |
| PR title validation | Regex in bash step | amannn/action-semantic-pull-request@v5 | Handles edge cases, provides helpful PR comments |
| Release note generation | Custom changelog scripts | Built into terraform-module-releaser | Parses conventional commits automatically |

## Common Pitfalls

### Pitfall 1: Implicit GITHUB_TOKEN permissions (CRITICAL)

**What goes wrong:** Workflow exits green but no tags or releases are created.
**Why it happens:** GitHub org settings or repo defaults may restrict `GITHUB_TOKEN` to read-only. Without explicit `permissions: contents: write, pull-requests: write` in the workflow, the action silently fails.
**How to avoid:** Always declare permissions explicitly at the workflow level. Confirmed by roadmap success criteria (SC-5).
**Warning signs:** Action completes with exit 0, no new tags appear in repo.

### Pitfall 2: Module detection (RESOLVED — not a real risk)

**Original concern:** terraform-module-releaser might silently skip `modules/docker/container/` (three-level path).
**Research finding:** The action uses `findTerraformModuleDirectories()` — a recursive scan from workspace root that detects any directory containing `.tf` files, regardless of depth. The demo repository uses `aws/vpc-endpoint/` and `null/random/` (multi-level paths) and produces tags like `aws/vpc-endpoint/v1.1.8`. Our `modules/docker/container/` path will be detected and tagged as `modules/docker/container/v1.0.0`.
**Validation required:** Despite low theoretical risk, roadmap requires a real test commit — not just workflow syntax validation.

### Pitfall 3: Wrong event trigger

**What goes wrong:** Using `on: push: branches: main` instead of `on: pull_request` for release.yaml.
**Why it happens:** Confusion with other CI patterns.
**How to avoid:** terraform-module-releaser requires the `pull_request` event with `types: [opened, reopened, synchronize, closed]`. The release is triggered specifically when a PR is closed (merged).

### Pitfall 4: fetch-depth: 0 missing

**What goes wrong:** Action cannot access full git history, breaks tag detection.
**Why it happens:** Default checkout is shallow (`fetch-depth: 1`).
**How to avoid:** Always set `fetch-depth: 0` in the checkout step of release.yaml.

### Pitfall 5: Wiki not initialized before first release

**What goes wrong:** Action fails with an error writing to the wiki on first run.
**Why it happens:** GitHub Wiki must have at least one page before the API can write to it.
**How to avoid:** Initialize the wiki manually via GitHub UI before the first PR merge.
**Sequencing:** Wiki init → first PR merge → auto-release (correct order).

### Pitfall 6: PR title action permissions

**What goes wrong:** `amannn/action-semantic-pull-request` cannot post a comment on the PR about why it failed.
**Why it happens:** Missing `pull-requests: write` permission in the validation workflow.
**How to avoid:** Include `permissions: pull-requests: write` in the PR title validation workflow.

## Code Examples

### Complete release.yaml

```yaml
name: Terraform Module Releaser

on:
  pull_request:
    types: [opened, reopened, synchronize, closed]
    branches:
      - main

permissions:
  contents: write
  pull-requests: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Terraform Module Releaser
        uses: techpivot/terraform-module-releaser@v2
```

### PR title validation (standalone file)

```yaml
name: Lint PR Title

on:
  pull_request:
    types: [opened, reopened, edited, synchronize]
    branches:
      - main

permissions:
  pull-requests: write

jobs:
  validate-pr-title:
    name: Validate PR Title
    runs-on: ubuntu-latest
    steps:
      - uses: amannn/action-semantic-pull-request@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          types: |
            feat
            fix
            docs
            chore
            refactor
            test
            ci
```

### Expected tag format for this repo

When a PR with a `feat:` commit title is merged:
- Action detects `modules/docker/container/` has changed `.tf` files
- Creates Git tag: `modules/docker/container/v1.0.0`
- Creates GitHub Release: `modules/docker/container/v1.0.0`
- Writes wiki page: Docker container module documentation

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual `git tag` per module | terraform-module-releaser@v2 | 2023+ | Fully automated per-module versioning |
| Separate `CHANGELOG.md` files | GitHub Releases | Current | Releases serve as changelog |
| PR title enforced by convention only | amannn/action-semantic-pull-request | 2022+ | CI gate, not honor system |

## Open Questions

1. **PR title action trigger: `pull_request` vs `pull_request_target`**
   - What we know: `pull_request_target` is required for fork-based PRs; `pull_request` is simpler but doesn't work with forks
   - What's unclear: Whether this repo accepts external PRs from forks
   - Recommendation: Use `pull_request` — this is a private monorepo with agent-only contributors; no fork PRs expected

2. **actions/checkout@v4 vs @v6 in release.yaml**
   - What we know: Demo uses @v6; lint.yaml uses @v4
   - What's unclear: Whether @v6 exists as a stable tag (may be pre-release)
   - Recommendation: Use @v4 to match existing lint.yaml pattern and ensure stability

## Sources

### Primary (HIGH confidence)
- [techpivot/terraform-module-releaser README](https://github.com/techpivot/terraform-module-releaser) — action inputs, permissions, workflow structure
- [terraform-module-releaser source: src/utils/file.ts](https://github.com/techpivot/terraform-module-releaser/blob/main/src/utils/file.ts) — `findTerraformModuleDirectories` recursive scan algorithm
- [techpivot/terraform-modules-demo releases](https://github.com/techpivot/terraform-modules-demo/releases) — confirmed multi-level path tags (aws/vpc-endpoint/v1.1.8)
- [terraform-modules-demo workflow](https://raw.githubusercontent.com/techpivot/terraform-modules-demo/main/.github/workflows/terraform-module-releaser.yml) — canonical workflow YAML
- [amannn/action-semantic-pull-request](https://github.com/amannn/action-semantic-pull-request) — PR validation configuration and example

### Secondary (MEDIUM confidence)
- [GitHub Marketplace: semantic-pull-request](https://github.com/marketplace/actions/semantic-pull-request) — ecosystem adoption confirmed
- [gjorgji-ts/demo-tf-module-releaser](https://github.com/gjorgji-ts/demo-tf-module-releaser) — additional multi-level path example (aws/s3/v0.1.0)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified against official source and demo repos
- Module path detection: HIGH — source code examined, algorithm confirmed depth-unlimited
- Architecture patterns: HIGH — canonical workflow YAML retrieved from demo
- Pitfalls: HIGH — permissions pitfall confirmed by official docs; wiki pitfall documented in action README

**Research date:** 2026-02-28
**Valid until:** 2026-08-28 (stable tools; check for action version updates)
