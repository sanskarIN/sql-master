# Versioning Policy

`sql-master` uses Semantic Versioning for repository-level releases.

## Format

`MAJOR.MINOR.PATCH`

- **MAJOR** — incompatible repository-layout or public-contract changes.
- **MINOR** — backward-compatible additions such as new projects, new companion packages, or major documentation features.
- **PATCH** — fixes, documentation corrections, CI repairs, metadata corrections, and non-breaking maintenance.

The current repository version is stored in [`../VERSION`](../VERSION).

## Independent companion projects

Files under `code/part-XXX/` and `projects/` are intentionally independent. A repository release does not imply that every project shares one runtime dependency version.

## Release rules

1. Update `VERSION`.
2. Update `CHANGELOG.md`.
3. Update `CURRENT_STATUS.md` when scope changes.
4. Run `python scripts/validate_repository.py`.
5. Run `python scripts/run_all_tests.py` for the testable published packages.
6. Review CodeQL and GitHub Actions results.
7. Confirm no paid Master PDF/DOCX/EPUB is present in the public tree.
8. Confirm permanent metadata contains no mutable X/Twitter profile URL.
9. Create the GitHub release/tag only after the checks above pass.

## Pre-release labels

Use suffixes such as `-rc.1` only when a public pre-release is genuinely needed. Do not create version tags merely to inflate activity.

Official store: **https://ramsandesh.gumroad.com**
