# Troubleshooting Guide

## `git push` cannot resolve GitHub

Symptom:

```text
Could not resolve host: github.com
```

This is a DNS/network problem before GitHub authentication. Verify DNS/network access first. Do not rotate credentials merely because DNS resolution failed.

## A GitHub Actions workflow fails at repository root

This repository is multi-project. A workflow that assumes a root `Makefile`, `CMakeLists.txt`, `.sln`, or Cargo workspace is probably incorrect.

Use the maintained repository-aware workflows under `.github/workflows/` and package-specific commands from `docs/TESTING.md`.

## Python tests are not discovered

Some companion packages intentionally use direct test runners instead of `unittest discover`.

Examples:

```bash
cd code/part-117/src
python test_contracts.py
```

```bash
cd code/part-118/src
python scripts/package_tests.py
```

Check `.github/workflows/companion-python-tests.yml` for the canonical command.

## SQLite reports `foreign key mismatch` or constraints appear inactive

Ensure the connection enables foreign keys:

```sql
PRAGMA foreign_keys = ON;
```

Also verify referenced keys are primary/unique as required by SQLite.

## PostgreSQL examples fail on SQLite/MySQL

Many advanced Parts are database-specific. Do not assume PostgreSQL syntax such as exclusion constraints, range types, `RETURNING`, or certain locking clauses will work unchanged on other engines.

Use the engine stated in the Part README.

## Checksums no longer match after an intentional fix

A source fix changes bytes. Update the checksum manifest in the same change and document why the new checksum is expected. Never edit a checksum merely to hide an unexplained difference.

## A permanent file contains an X/Twitter profile URL

Remove the mutable social URL from long-lived buyer/repository metadata. Keep stable store/GitHub/email links instead. See `PERMANENT_LINK_POLICY.md`.

## The paid book is accidentally staged for GitHub

Do not commit the paid Master PDF/DOCX/EPUB to this public repository. Remove it from the staging area and verify the public/private boundary before pushing.

## Repository validation fails

Run:

```bash
python scripts/validate_repository.py
```

Read every reported issue. The validator is designed to fail on documentation/status drift rather than silently repairing files.

## Support

- Repository issues: use the GitHub issue templates
- Support email: `supportramsandesh@gmail.com`
- Business: `sanskarin@outlook.in`
- Official store: **https://ramsandesh.gumroad.com**
