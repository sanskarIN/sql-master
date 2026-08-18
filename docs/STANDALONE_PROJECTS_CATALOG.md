# Standalone Projects Catalog

The `projects/` directory contains independent learning utilities and mini-projects that complement the 120-part companion code.

## Current projects

1. `sqlite-inventory-manager` — quantity ledger, constraints, and reorder reporting.
2. `migration-order-checker` — detects gaps, duplicates, and invalid migration names.
3. `schema-quality-auditor` — educational static checks for common schema/query smells.
4. `explain-plan-analyzer` — summarizes PostgreSQL-style EXPLAIN text and review prompts.
5. `synthetic-data-factory` — deterministic fictional data with reserved example domains.
6. `backup-manifest-verifier` — SHA-256 backup manifest creation and verification.
7. `transaction-invariant-simulator` — transfer invariants and idempotency model.
8. `sql-query-practice-lab` — SQLite joins, windows, latest-row and running-total exercises.
9. `data-quality-rule-runner` — zero-row invariant checks with structured results.
10. `sqlite-booking-calendar` — interval validation and overlap-rejection practice.

## Validation

All ten projects were executed locally before publication and their unit-test suites passed. GitHub Actions also has a dedicated matrix workflow at `.github/workflows/standalone-projects-python.yml`.

## Repository boundaries

- Standalone projects live under `projects/`.
- Book Part companion packages remain under `code/part-001` through `code/part-120`.
- Paid Master PDF/DOCX/EPUB files stay outside the public repository.
- Permanent metadata does not include mutable X/Twitter profile URLs.

Official store: **https://ramsandesh.gumroad.com**
