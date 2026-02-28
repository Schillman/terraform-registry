# Domain Pitfalls

**Domain:** AI-operated Terraform Module Monorepo
**Researched:** 2026-02-28
**Confidence:** MEDIUM-HIGH (based on known terraform-module-releaser behavior, GitHub Actions semantics, and Terraform ecosystem patterns; web search unavailable during this session)

---

## Critical Pitfalls

Mistakes that cause rewrites, broken consumers, or silent wrong version bumps.

---

### Pitfall 1: AI Agents Using Scope-Qualified Commit Messages That Bypass Semver Detection

**What goes wrong:**
terraform-module-releaser parses raw commit messages against the Conventional Commits spec. AI agents (Claude, Copilot) frequently emit scoped messages like `feat(docker/container): add restart policy` or multi-line commit messages where the `BREAKING CHANGE:` footer is on line 3+ of the commit body. The releaser reads only the PR title (or merge commit subject) for its semver signal — not the full commit body in all configurations.

**Why it happens:**
- AI agents are trained on GitHub-style commits and will naturally add scope annotations (`feat(scope):`) which are valid Conventional Commits but can trip up simpler regex-based parsers if the tool only looks for `feat:` at the start of the line.
- `BREAKING CHANGE:` in the commit **body** footer requires the releaser to parse the full multi-paragraph message. If the PR squash-merge subject is just `feat: add restart policy`, the breaking change footer is discarded and only a `minor` bump is triggered instead of `major`.
- Agents writing chore/docs commits on files that live inside a module directory will still trigger a version bump if the releaser's changed-files detection sees any `.tf` file change.

**Consequences:**
- `1.2.0` released when `2.0.0` was required (breaking change silently missed).
- Consumers pinned to `modules/docker/container/v1.2.0` receive breaking changes without notice.
- `v1.0.1` patch released when a `feat:` commit warranted `v1.1.0`.

**Prevention:**
1. In `SKILL.md`, mandate that breaking changes use the footer format AND the PR title must also start with `feat!:` or `fix!:` (the `!` shorthand) to ensure the signal survives squash merges.
2. Configure the repo to use **merge commits** (not squash) for PRs created by agents, or document that agents must put the semver signal in the PR title (which terraform-module-releaser reads for squash-merge workflows).
3. Add a branch protection rule or CI step that validates the PR title matches `^(feat|fix|chore|docs|test|refactor|perf|ci|build|revert)(\(.+\))?(!)?: .+`.

```yaml
# .github/workflows/pr-title-check.yml
name: Validate PR Title
on:
  pull_request:
    types: [opened, edited, synchronize]
jobs:
  check-title:
    runs-on: ubuntu-latest
    steps:
      - name: Check conventional commit format
        run: |
          echo "${{ github.event.pull_request.title }}" \
            | grep -Eq '^(feat|fix|chore|docs|test|refactor|perf|ci|build|revert)(\(.+\))?(!)?: .+' \
            || (echo "PR title must follow Conventional Commits" && exit 1)
```

**Detection:** Watch for `v1.x.y` releases where the PR contained a `BREAKING CHANGE` footer. Alert if semver major is never bumped despite breaking changes being expected.

**Phase:** Phase 1 (Conventional Commits + SKILL.md setup) — must be solved before the releaser is integrated.

---

### Pitfall 2: terraform-module-releaser Fails to Detect Modules After Directory Rename

**What goes wrong:**
terraform-module-releaser uses a `modules_folder` config (default: `modules/`) and detects module directories by looking for a `*.tf` file at exactly one level inside the folder. After migrating `modules/terraform-docker-container/` to `modules/docker/container/`, the tool now needs to find `.tf` files two levels deep (`modules/docker/container/*.tf`). The default glob pattern may not recurse deeply enough, causing the module to be silently skipped and no release to ever fire.

**Why it happens:**
- The releaser is designed around a flat `modules/{module-name}/` layout.
- A two-level namespaced layout (`modules/{provider}/{resource}/`) requires explicit configuration of `modules_folder` or a custom `module_regex` pattern.
- If misconfigured, the action completes with no errors but also creates no release — silent failure.

**Consequences:**
- Module changes merge to main, no tag is created, no GitHub Release is published. Consumers using `ref=modules/docker/container/v1.x.y` will get 404 or point to a stale tag.
- The wiki is never updated, documentation goes stale.

**Prevention:**
Verify the releaser's module detection pattern. Based on terraform-module-releaser docs, the `modules_folder` input sets the root. For two-level paths, test with the `module_regex` input if available, or nest such that the action finds `modules/docker/container` as the leaf:

```yaml
# .github/workflows/release.yml
- uses: techjavelin/terraform-module-releaser@v1
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    modules_folder: modules        # root folder
    # Verify that the action finds modules/docker/container — check action README for module_regex
```

Immediately after wiring up the action, push a test `feat:` commit that touches `modules/docker/container/` and confirm a release is fired before migrating production traffic.

**Detection:** After setup, check Actions output. If the releaser logs show "No modules changed" after a commit to `modules/docker/container/*.tf`, the detection is broken.

**Phase:** Phase 2 (terraform-module-releaser integration) — validate module detection against the namespaced path before going live.

---

### Pitfall 3: depth=1 Shallow Clone Cannot Resolve Module-Scoped Tags

**What goes wrong:**
Consumer configs use `ref=modules/docker/container/v1.2.0` with `depth=1`. A `depth=1` clone fetches only the tip commit. If that tip commit does not have the tag `modules/docker/container/v1.2.0` pointing directly at it (e.g., the tag points to an older commit), `git` cannot resolve the tag reference and Terraform throws:

```
Error: Failed to download module
│ Could not resolve module: ...ref=modules/docker/container/v1.2.0
```

**Why it happens:**
- Module-scoped tags created by terraform-module-releaser point to the commit on `main` at release time.
- When a new commit lands on `main` after the `v1.2.0` tag, the tag is now one or more commits behind HEAD.
- A `depth=1` clone fetches the single latest commit. The tag `modules/docker/container/v1.2.0` is not reachable at `depth=1` from HEAD.
- Terraform's git source fetcher resolves `ref` by doing a shallow clone with `--depth=1 --branch <ref>` — this works only when the `ref` is a branch or when the tag is the HEAD of the target. For arbitrary older tags, `depth=1` is insufficient.

**Consequences:**
- New consumers who pin an older version get intermittent or consistent clone failures.
- CI pipelines in consumer repos break when pulling pinned module versions.

**Prevention:**
This is a known constraint of `depth=1` with non-HEAD tags in Terraform git sources. The mitigation options in priority order:

1. **Do not advertise `depth=1` in module source URLs for version pinning.** Omit `depth` from the `ref`-pinned source string. Use `depth=1` only for "always latest" floating references pointing at a branch name like `ref=main`.

```hcl
# WRONG — depth=1 with an old tag that isn't HEAD
source = "git::https://github.com/Schillman/terraform-registry.git//modules/docker/container?depth=1&ref=modules/docker/container/v1.2.0"

# CORRECT — depth=1 only works reliably when ref IS the current HEAD
source = "git::https://github.com/Schillman/terraform-registry.git//modules/docker/container?ref=modules/docker/container/v1.2.0"
```

2. Document in `SKILL.md` and consumer docs that `depth=1` is incompatible with pinned version tags.

**Detection:** Attempting `terraform init` on a consumer using an older pinned version with `depth=1` after new commits have landed on the registry's `main` branch.

**Phase:** Phase 2 (terraform-module-releaser integration) — correct the example source URL format in docs and README before any consumer documentation is published.

---

### Pitfall 4: Module Migration Breaks Existing Tag References and Consumer Configs

**What goes wrong:**
Migrating `modules/terraform-docker-container/` to `modules/docker/container/` means the old tag namespace (`terraform-docker-container/v1.0.0` or `v1.0.0`) no longer maps to the new path. If any consumers (or the existing README) reference the old path, those refs silently resolve to a directory that no longer exists.

**Why it happens:**
- Git tags are immutable namespace pointers. The old tags point to commits where the module existed at the old path.
- After the rename, `modules/docker/container/` starts at `v1.0.0` (first release under new naming). Old tags become orphaned from the new path.
- No automatic redirect exists — Terraform has no concept of module path aliases.

**Consequences:**
- Existing consumers using `ref=v1.0.0` (flat tag) or `ref=terraform-docker-container/v1.0.0` get a module path that no longer contains `.tf` files.
- If the old directory is deleted immediately, those consumers break on next `terraform init`.

**Prevention:**
1. **Keep old directory alive as a stub** for at least one release cycle, containing only a `README.md` with a migration notice pointing to the new path.
2. **Do not delete old tags.** Old tags must remain in the repository so pinned consumers can still resolve them against the commit history (even if the old directory no longer exists at HEAD, pinned refs resolve to old commits where it did exist).
3. **Version-start new tags at a fresh minor** (`modules/docker/container/v1.0.0`) so consumers know this is a new namespace, not a continuation of the old one.
4. Add a migration notice to the root `README.md` with a before/after source snippet.

```hcl
# Before (deprecated — do not use)
source = "git::https://github.com/Schillman/terraform-registry.git//modules/terraform-docker-container?ref=v1.0"

# After (new namespaced path)
source = "git::https://github.com/Schillman/terraform-registry.git//modules/docker/container?ref=modules/docker/container/v1.0.0"
```

5. In `SKILL.md`, document that agents must never delete module directories without a deprecation period.

**Detection:** Search all consumer repos (or internal docs) for `terraform-docker-container` in source strings before completing the migration.

**Phase:** Phase 1 (migration planning) — must be addressed before or during the rename commit.

---

### Pitfall 5: terraform-docs README Enforcement Causing Merge Conflicts on Agent PRs

**What goes wrong:**
When terraform-docs is run in CI in "update" mode (it rewrites the README in-place and commits back to the PR branch), two parallel agent PRs targeting the same module will both update `README.md` on their respective branches. When the first PR merges, the second PR's `README.md` is now out of sync with `main`. The merge creates a conflict in the auto-generated block between `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->`.

**Why it happens:**
- terraform-docs CI commit-back creates a new commit on the feature branch.
- If two agents work on the same module simultaneously (e.g., one adds a variable, another fixes docs), both update the same generated block.
- The markers `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` delimit the entire auto-generated section — any interior change produces a conflict.

**Consequences:**
- PR merge blocked with a conflict on a file that should be fully machine-managed.
- Agent or human must manually resolve a conflict in auto-generated content.
- If CI runs in "check" mode (fail if README is stale) instead of "update" mode, every PR that touches variables requires a local `terraform-docs` run before committing — agents without pre-commit hooks will always fail CI on first push.

**Prevention:**
1. **Use "update + commit-back" mode in CI**, not "check" mode, so CI always produces the authoritative README. Accept that sequential PR merges will resolve conflicts by re-running terraform-docs on the target branch after rebase.
2. **Enforce single-module-per-PR for agents.** Document in `SKILL.md` that agents must never open a second PR on a module that already has an open PR.
3. **Rebase-then-merge strategy.** Configure branch protection to require "up to date" before merge, forcing the second agent PR to rebase against the post-first-merge HEAD (where README is already updated).

```yaml
# .github/workflows/terraform-docs.yml (update mode)
- name: Render terraform docs and commit changes
  uses: terraform-docs/gh-actions@v1
  with:
    working-dir: modules/docker/container
    output-file: README.md
    output-method: inject
    git-push: "true"          # commit-back to PR branch
    git-commit-message: "docs(docker/container): update terraform-docs [skip ci]"
```

Note the `[skip ci]` suffix: without it, the terraform-docs commit triggers another CI run, which runs terraform-docs again, which commits again — an infinite loop.

**Detection:** Two open PRs for the same module. Watch for CI failures mentioning "README.md is out of date" on a PR that previously passed.

**Phase:** Phase 3 (terraform-docs enforcement) — design the CI job carefully on first implementation.

---

### Pitfall 6: Trivy False Positives on Terraform Configs That Are Intentionally Permissive

**What goes wrong:**
Trivy IaC scanning will flag Terraform resource configurations that are deliberately permissive for a homelab/self-hosted context. Known high-signal false positives for this repo:

- `network_mode = "host"` — Trivy flags as HIGH (container host networking bypass)
- `ports` with `ip = "0.0.0.0"` — Trivy flags as MEDIUM (bind to all interfaces)
- No `read_only = true` on container root filesystem — Trivy flags as LOW/MEDIUM
- No `cap_drop = ["ALL"]` in container capabilities — Trivy flags as MEDIUM

If ALL findings block merge (Trivy exit code non-zero on any finding), PRs adding legitimate container configs will be permanently blocked.

**Why it happens:**
- Trivy's default IaC rules are written for production hardened environments.
- A homelab Docker module has different threat model — `network_mode = "host"` may be intentional for certain workloads (e.g., a media server needing host networking).
- The `--exit-code 1` flag causes Trivy to block on any finding including LOW, which is too aggressive.

**Consequences:**
- Every module PR blocked by Trivy findings that can never be fixed (by design).
- Agents retry CI in a loop, generating spam commits to satisfy a check that cannot pass.

**Prevention:**
1. Configure Trivy to only block on `CRITICAL` and `HIGH` by severity, not on all findings:

```yaml
- name: Run Trivy IaC scan
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'config'
    scan-ref: '.'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'            # only fail on CRITICAL/HIGH
    ignore-unfixed: true
```

2. Use a `.trivyignore` file for intentional suppressions with mandatory justification comments:

```
# .trivyignore
# AVD-DS-0013: network_mode=host is intentional for homelab workloads
# that require host networking (e.g., media servers, VPN containers).
# Consumers must explicitly set this; default is "bridge" post-migration.
AVD-DS-0013
```

3. Never suppress `CRITICAL` without a GitHub Issue reference in the `.trivyignore` comment.

**Detection:** CI logs showing Trivy findings on the `network_mode` or `ports` resources that existed before Trivy was added.

**Phase:** Phase 4 (Trivy integration) — configure severity filter on day one, not after PRs start failing.

---

## Moderate Pitfalls

---

### Pitfall 7: Pre-commit Hooks and CI Running the Same Checks with Different Versions

**What goes wrong:**
Pre-commit hooks run terraform-docs, tflint, and terraform-fmt locally. CI runs the same tools. If the tool versions differ (e.g., pre-commit uses `tflint v0.49` while CI uses `tflint v0.51`), rules that are warnings in one version become errors in another. A commit that passes locally fails in CI. Agents that cannot run pre-commit locally (GitHub Copilot in Codespaces without pre-commit installed) push commits that always fail CI on the first run.

**Why it happens:**
- `.pre-commit-config.yaml` pins tool versions; CI workflow pins different versions.
- Version drift accumulates over weeks without explicit sync.
- Dependabot updates one but not the other.

**Consequences:**
- Developers (and agents with local dev access) have false confidence that passing pre-commit means CI will pass.
- CI becomes the authoritative gate, making pre-commit redundant noise.
- Agents without pre-commit installed spam fix commits.

**Prevention:**
1. Define a single source of truth for tool versions in `.pre-commit-config.yaml` and use the same pinned Docker image or version string in CI:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.94.0
    hooks:
      - id: terraform_tflint
      - id: terraform_docs
        args:
          - --hook-config=--path-to-file=README.md
          - --hook-config=--add-on-failure=true
```

```yaml
# In CI workflow — pin same version
- name: Setup tflint
  uses: terraform-linters/setup-tflint@v4
  with:
    tflint_version: v0.51.0  # must match pre-commit-config rev
```

2. Document in `SKILL.md` that agents should not run pre-commit; CI is the authoritative check. Pre-commit is for humans only.
3. Configure Dependabot to update `.pre-commit-config.yaml` hooks:

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
  # pre-commit doesn't have native Dependabot support — pin manually or use renovate
```

**Detection:** pre-commit passes locally, CI fails on the same file. Compare version strings in both configs.

**Phase:** Phase 5 (pre-commit setup) — pin versions explicitly from day one; add a comment linking the CI and pre-commit version strings.

---

### Pitfall 8: CODEOWNERS Rules That Silently Block Agent PR Auto-Merge

**What goes wrong:**
CODEOWNERS assigns human reviewers as required approvers. An AI agent opens a PR. The required reviewer is a human who is offline. GitHub prevents auto-merge (even if all CI checks pass) because the CODEOWNERS requirement is unsatisfied. For breaking-change PRs this is intentional. For routine `feat:` and `fix:` PRs this blocks the autonomous workflow.

**Why it happens:**
- CODEOWNERS with `*` (catch-all) requires at least one human approval for all PRs.
- GitHub's "auto-merge" feature merges when all required status checks pass AND required reviews are approved. Required reviews from CODEOWNERS block auto-merge even if CI is green.
- A bot account (GitHub App or PAT-based agent) cannot self-approve a PR.

**Consequences:**
- Agent-created `fix:` PRs sit open indefinitely waiting for human review.
- Accumulating open PRs from agents create noise.
- The autonomous operation goal of the project is defeated.

**Prevention:**
Configure tiered CODEOWNERS by commit type, enforced at the branch protection level rather than CODEOWNERS alone:

```
# .github/CODEOWNERS
# Only breaking-change PRs require human review — enforced by convention
# Routine feat/fix PRs are auto-merged via GitHub Actions after CI passes

# Require human review for structural changes
/.github/     @Schillman
/SKILL.md     @Schillman

# Modules DO NOT have a CODEOWNERS entry — CI gates are sufficient for routine changes
# modules/      <-- intentionally absent for agent autonomy
```

Then use a GitHub Actions auto-merge workflow triggered on `feat:` and `fix:` PRs:

```yaml
# .github/workflows/auto-merge.yml
name: Auto-merge agent PRs
on:
  pull_request:
    types: [opened, synchronize]
jobs:
  auto-merge:
    if: |
      github.actor == 'github-actions[bot]' ||
      contains(github.event.pull_request.title, '[auto-merge]')
    runs-on: ubuntu-latest
    steps:
      - name: Enable auto-merge
        run: gh pr merge --auto --squash "${{ github.event.pull_request.number }}"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Detection:** Agent-opened PRs sitting open more than 24 hours with no human activity and all CI checks green.

**Phase:** Phase 6 (CODEOWNERS + branch protection) — design the CODEOWNERS file to enable, not block, agent autonomy.

---

### Pitfall 9: terraform-module-releaser Missing permissions:write Scope on GITHUB_TOKEN

**What goes wrong:**
terraform-module-releaser creates GitHub Releases (requires `contents: write`), creates/updates pull requests (requires `pull-requests: write`), and updates the repository wiki (requires `contents: write` on the wiki). The default `GITHUB_TOKEN` in GitHub Actions has read-only permissions on all scopes unless `permissions` is explicitly declared in the workflow.

If the workflow job does not declare:

```yaml
permissions:
  contents: write
  pull-requests: write
```

the action fails with HTTP 403 on the first attempt to create a release or tag. This is a silent configuration gap — the action itself runs, GitHub executes it, but the API calls fail.

**Why it happens:**
- GitHub changed the default `GITHUB_TOKEN` permissions to `read-all` in 2023 for repositories with that setting in organization or repo security settings.
- The action README may show examples without explicit `permissions:` blocks, leading users to assume defaults are sufficient.

**Consequences:**
- No GitHub Releases are created. No tags are pushed. Module versioning silently stops working.
- The error is buried in the action step's log under an API response, not a workflow-level failure.

**Prevention:**
Always declare explicit permissions on the release job:

```yaml
jobs:
  release:
    name: Release Terraform modules
    runs-on: ubuntu-latest
    permissions:
      contents: write          # create releases, push tags, update wiki
      pull-requests: write     # create/update PRs (changelog PRs)
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0       # full history required for changelog generation
      - uses: techjavelin/terraform-module-releaser@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

Also verify that the repository's "Actions permissions" in Settings > Actions > General > Workflow permissions is set to "Read and write permissions" OR that the workflow-level `permissions` block overrides it.

**Detection:** Action run succeeds (green check) but no release or tag appears in the repository. Check the action step logs for `403 Resource not accessible by integration`.

**Phase:** Phase 2 (terraform-module-releaser integration) — verify permissions on day one before any real release is needed.

---

## Minor Pitfalls

---

### Pitfall 10: super-linter VALIDATE_NATURAL_LANGUAGE Flagging AI-Generated Commit Messages

**What goes wrong:**
The existing workflow enables `VALIDATE_NATURAL_LANGUAGE: true`. This runs `misspell` or a similar natural language checker against Markdown files. AI-generated docs often use British vs. American English inconsistencies, unusual technical compound words, or repeated filler phrases that trip the checker.

**Prevention:**
Add a `.spelling` exception file, or set `VALIDATE_NATURAL_LANGUAGE: false` if the false-positive rate outweighs the benefit. In a technical IaC repo, natural language checking adds low value.

**Phase:** Phase 3 (docs enforcement) — evaluate when terraform-docs generates first READMEs.

---

### Pitfall 11: fetch-depth: 0 Missing on Release Workflow Causes Changelog Truncation

**What goes wrong:**
terraform-module-releaser needs full git history to generate changelogs spanning multiple versions. If `actions/checkout` uses the default `fetch-depth: 1`, the action only sees the most recent commit and generates an empty or single-entry changelog.

**Prevention:**
Always use `fetch-depth: 0` on the release workflow checkout step (as shown in Pitfall 9's prevention config).

**Phase:** Phase 2 (terraform-module-releaser integration).

---

### Pitfall 12: Wiki Requires Initial Manual Creation Before terraform-module-releaser Can Update It

**What goes wrong:**
terraform-module-releaser writes module documentation to the repository wiki. The GitHub wiki is a separate Git repository (`<repo>.wiki.git`) that does not exist until someone creates it manually (by clicking "Create the first page" in the GitHub UI). If the wiki repo does not exist, the action fails silently or with a cryptic `git clone` error when trying to push wiki content.

**Prevention:**
Create the wiki before wiring up terraform-module-releaser. Navigate to the repository wiki tab, click "Create the first page," add a placeholder, and save. This initializes the `.wiki.git` repository. Only then enable wiki writes in the releaser workflow.

**Phase:** Phase 2 (terraform-module-releaser integration) — one-time manual setup step.

---

### Pitfall 13: Dependabot PR Volume Overwhelming Agent Queue

**What goes wrong:**
Dependabot creates PRs for GitHub Actions updates and Terraform provider updates. Each Dependabot PR triggers the full CI pipeline. With multiple modules and multiple providers, this can generate 5-20 open PRs weekly. If agents are also creating module PRs, the PR queue becomes unmanageable.

**Prevention:**
Configure Dependabot with `open-pull-requests-limit` and scheduled batching:

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 5
  - package-ecosystem: "terraform"
    directory: "/modules/docker/container"
    schedule:
      interval: "monthly"      # monthly, not weekly, for Terraform providers
    open-pull-requests-limit: 3
```

**Phase:** Phase 6 (Dependabot configuration).

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|----------------|------------|
| Conventional Commits + SKILL.md | AI agents using scope notation or burying BREAKING CHANGE in body | PR title validation CI step + SKILL.md mandate for `!` shorthand |
| Module migration (rename) | Old tag refs and consumer source strings break | Keep old directory stub; never delete old tags |
| terraform-module-releaser integration | Module not detected under namespaced path; missing `contents:write` permission; wiki not initialized | Verify detection with test commit; explicit `permissions:` block; manual wiki init |
| depth=1 consumer docs | `depth=1` with pinned tags fails once newer commits land | Remove `depth=1` from version-pinned source URLs; document the constraint |
| terraform-docs enforcement | Infinite CI loop from commit-back trigger; merge conflicts on parallel module PRs | Add `[skip ci]` to terraform-docs commit message; require "up to date" before merge |
| Trivy IaC scanning | Blocks on intentional `network_mode=host` and `0.0.0.0` port bindings | Scope Trivy to CRITICAL+HIGH only; use `.trivyignore` with justification |
| Pre-commit hook setup | Version drift between pre-commit and CI causing CI failures after passing locally | Single-source tool versions; document that CI is authoritative for agents |
| CODEOWNERS + branch protection | All PRs blocked waiting for human review, defeating agent autonomy | Omit `modules/` from CODEOWNERS; add auto-merge workflow for agent PRs |
| Dependabot configuration | PR volume overwhelming agent queue | Monthly intervals for Terraform providers; weekly for Actions; batch limits |

---

## Sources

- terraform-module-releaser GitHub repository (techjavelin/terraform-module-releaser) — tag format, module detection, wiki requirements (MEDIUM confidence — verified against known behavior; web fetch unavailable during research)
- GitHub Actions default permissions behavior post-2023 (MEDIUM confidence — well-established GitHub platform change)
- Terraform git source `depth` parameter behavior with non-HEAD tags (HIGH confidence — documented Terraform source address behavior)
- aquasecurity/trivy-action severity filtering configuration (HIGH confidence — well-documented Trivy IaC scan parameters)
- Conventional Commits spec v1.0.0 — footer parsing requirements for BREAKING CHANGE (HIGH confidence — official spec)
- terraform-docs/gh-actions `[skip ci]` infinite loop prevention (HIGH confidence — documented in terraform-docs action README)
- GitHub CODEOWNERS interaction with auto-merge (HIGH confidence — GitHub platform docs)
