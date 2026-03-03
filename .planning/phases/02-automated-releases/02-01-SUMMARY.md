---
plan: 02-01
phase: 02-automated-releases
status: complete
completed: 2026-02-28
duration: 5 min
---

# Plan 02-01: Create release.yaml and PR title validation workflows

## What Was Built

Created two GitHub Actions workflows that form the automated release pipeline for the terraform module registry.

## Key Files Created

- `.github/workflows/release.yaml` — terraform-module-releaser@v2 workflow triggered on PR events to main
- `.github/workflows/pr-title.yaml` — amannn/action-semantic-pull-request@v5 enforcing conventional commits on all PRs

## Self-Check: PASSED

All tasks completed successfully:

- [x] Task 1: release.yaml created with permissions: contents: write, pull-requests: write, fetch-depth: 0
- [x] Task 2: pr-title.yaml created with all 7 conventional commit types (feat, fix, docs, chore, refactor, test, ci)
- [x] Task 3: Both files committed with ci: prefix

Verification commands passed:
- YAML syntax valid for both files
- `grep -c "write" release.yaml` = 2 (contents: write + pull-requests: write)
- `grep -c "fetch-depth: 0" release.yaml` = 1
- `grep -c "terraform-module-releaser@v2" release.yaml` = 1
- `grep -c "closed" release.yaml` = 1 (PR closed/merged trigger for actual tag creation)
- Both files in git commit 50ddb2f

## What This Enables

Wave 2 (Plan 02-02) can now proceed to validate the release pipeline end-to-end by:
1. Initializing the GitHub Wiki (manual step)
2. Opening a feat: PR and confirming the pr-title.yaml check passes
3. Merging the PR and confirming modules/docker/container/v1.0.0 tag is created

## Notes

- Used actions/checkout@v4 to match existing lint.yaml pattern (not @v6 from demo)
- No additional terraform-module-releaser inputs needed — auto-detects modules/docker/container/ via recursive .tf file scan
- PR title action uses pull_request (not pull_request_target) — no fork PRs expected in this repo
