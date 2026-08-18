# Testing and Validation Guide

## Testing model

This repository contains independent packages, so testing is intentionally split by package type rather than forced through one root build.

## Standalone projects

Each project under `projects/` uses its own `tests/` directory.

Run one project:

```bash
cd projects/sqlite-inventory-manager
python -m unittest discover -s tests -v
```

Run all standalone projects locally:

```bash
python scripts/run_all_tests.py --standalone
```

Current pre-publication result recorded in `PROJECTS_STATUS.json`: **30/30 tests passed across 10 projects**.

## Companion packages

Parts 110–120 use package-specific commands because their test layouts differ.

The canonical commands are stored in `.github/workflows/companion-python-tests.yml` and mirrored by `scripts/run_all_tests.py`.

Examples:

```bash
cd code/part-110/src
python -m unittest discover -s tests -v
```

```bash
cd code/part-117/src
python test_contracts.py
```

```bash
cd code/part-118/src
python scripts/package_tests.py
```

## Repository validation

Run:

```bash
python scripts/validate_repository.py
```

The validator checks:

- required root documentation
- JSON metadata validity
- published Part 103–120 directory presence
- 10 standalone-project directory presence
- Gumroad canonical-link policy
- absence of mutable X/Twitter URLs in permanent text metadata
- allowed workflow set
- public/private publishing boundary markers

## GitHub Actions

Maintained workflows:

- `repository-quality.yml`
- `standalone-projects-python.yml`
- `companion-python-tests.yml`
- `codeql.yml`

Generic root-level CMake/Make/MSBuild/Rust/SLSA starter workflows were removed because they did not represent this repository's architecture.

## SQL execution scope

A Python/model test passing does not prove every PostgreSQL/MySQL/SQL Server/Oracle statement has been executed against every engine. Documentation must distinguish:

- static/package checks
- Python model checks
- SQLite execution
- actual PostgreSQL/database-engine execution

Never claim database-engine execution unless it was really performed.

## Before a release

1. Run repository validation.
2. Run all available project/package tests.
3. Review CodeQL results.
4. Check `git status` locally if using CLI.
5. Confirm no paid Master manuscript is in the public tree.
6. Review `CURRENT_STATUS.md` and status JSON files.
7. Update `CHANGELOG.md` and `what_changed.md`.

Official store: **https://ramsandesh.gumroad.com**
