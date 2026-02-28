# Claude Code Agent Instructions

Before doing any work in this repository, read @SKILL.md.

SKILL.md contains all operating conventions for this repo:

- Commit type to semver impact mapping (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `ci:`, and breaking variants)
- Required files for every module (module scaffold pattern: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`, `tests/`)
- Autonomy matrix: what you can do freely — all operations proceed when workflow checks pass
- Correct consumer source URL format and why `depth=1` is forbidden on version-pinned refs
