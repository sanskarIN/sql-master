# CI Workflow Audit

Official store: **https://ramsandesh.gumroad.com**

`sql-master` is a **multi-part, multi-language companion repository**, not one root-level CMake/MSBuild/Make application. CI is therefore scoped to repository/package contracts it can actually validate.

## Maintained workflows

### `repository-quality.yml`

Runs on `main` pushes, pull requests, and manual dispatch. It:

- checks Python syntax with `compileall`
- runs `scripts/validate_repository.py`
- verifies repository layout/status/link-policy rules

### `standalone-projects-python.yml`

Runs the ten independent `projects/` test suites in a matrix with Python 3.12.

### `companion-python-tests.yml`

Runs the package-specific validation commands for Parts 110–120. Each Part keeps its own canonical runner instead of being forced through one generic command.

### `codeql.yml`

Scans repository Actions, Python, C/C++, and Rust code using CodeQL v4. The workflow uses supported major action versions and a weekly scheduled scan.

## Removed invalid starter workflows

The following generic templates were removed during the 2026-08-18 hardening audit because they assumed a root project/build that does not exist:

- root C/C++ configure/make workflow
- multi-platform CMake starter
- single-platform CMake starter
- root Makefile starter
- root MSBuild starter
- root Rust starter
- placeholder SLSA workflow that generated dummy artifacts

These produced or risked **false CI failures** unrelated to the actual companion/package contracts.

## Current action majors

- `actions/checkout@v6`
- `actions/setup-python@v6`
- `github/codeql-action@v4`

## Future targeted language CI

Potential path-scoped builds:

- Part 103 — C/C++/SQLite
- Part 104 — Rust
- Part 105 — Go

Add these only after a clean build/test contract can be verified in the available execution environment. Do not reintroduce a root-level generic build simply to obtain a CI badge.

## CI design rules

1. Keep independent Parts/projects independent.
2. Use path filters and matrices where practical.
3. Keep permissions minimal.
4. Use supported action versions and review Dependabot updates.
5. Make each workflow prove a real package contract.
6. Do not publish paid Master PDF/DOCX/EPUB assets from public CI.
7. Never claim a workflow is green without an observed successful run.

See `TESTING.md`, `RELEASE_CHECKLIST.md`, and `FINAL_REPOSITORY_AUDIT.md`.
