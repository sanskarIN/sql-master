# Release Process

This document defines the repository release process for `sanskarIN/sql-master`.

## 1. Prepare

- Work on a focused branch when practical.
- Keep each companion Part and standalone project independent.
- Do not add the paid Master PDF, DOCX, EPUB, or commercial buyer package to the public repository.
- Do not add mutable X/Twitter profile URLs to permanent metadata.

## 2. Validate source

Run:

```bash
python -m compileall -q scripts projects code
python scripts/validate_repository.py
python scripts/check_relative_links.py
python scripts/run_all_tests.py
```

A database-engine claim must match what was actually tested. Python/model validation is not the same as executing PostgreSQL, MySQL, SQL Server, or Oracle.

## 3. Review metadata

Verify:

- `VERSION`
- `CHANGELOG.md`
- `CURRENT_STATUS.md`
- `COMPANION_STATUS.json`
- `PROJECTS_STATUS.json`
- README project counts and published ranges
- Gumroad canonical store link
- license boundaries

## 4. Review CI and security

Required maintained workflows:

- Repository Quality
- Companion Python Tests
- Standalone SQL Projects - Python Tests
- CodeQL

Review failures before release. Do not mark a release healthy while required checks are failing.

## 5. Commit and tag

Use meaningful commit messages. Repository-level releases use Semantic Versioning as documented in `VERSIONING.md`.

Suggested tag:

```text
v1.0.0
```

## 6. Release notes

Release notes should state:

- newly published companion Parts
- newly added standalone projects
- bug fixes
- documentation changes
- known limitations
- exact testing scope

## 7. Post-release

- Verify the GitHub release page.
- Verify the README and stable purchase links.
- Re-run a smoke validation after any emergency hotfix.
- Record the change in `what_changed.md`.

Official store: **https://ramsandesh.gumroad.com**
