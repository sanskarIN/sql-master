# Project Expansion — 2026-08-18

This expansion adds a dedicated `projects/` portfolio to the SQL Full Mastery companion repository while keeping all Part-specific material under `code/part-001` through `code/part-120`.

## Added projects

1. SQLite Inventory Manager
2. Migration Order Checker
3. Schema Quality Auditor
4. EXPLAIN Plan Analyzer
5. Synthetic Data Factory
6. Backup Manifest Verifier
7. Transaction Invariant Simulator
8. SQL Query Practice Lab
9. Data Quality Rule Runner
10. SQLite Booking Calendar

## Validation

All ten projects were executed locally before publication.

**Combined result: 30/30 unit tests passed.**

The repository also includes `.github/workflows/standalone-projects-python.yml` so the projects can be validated independently in GitHub Actions.

## Design rules

- Each project is independent.
- Standard-library Python and SQLite are preferred where they keep the project easy to run.
- Examples use fictional/demo data.
- Paid book files remain outside the public repository.
- Permanent metadata omits mutable X/Twitter profile URLs.
- The stable purchase link is **https://ramsandesh.gumroad.com**.
