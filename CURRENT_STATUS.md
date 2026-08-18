# Current Repository Status

**Repository:** `https://github.com/sanskarIN/sql-master`  
**Official store:** **https://ramsandesh.gumroad.com**  
**Edition context:** August 2026

## Companion-code publication

The SQL Full Mastery book series is planned as **Parts 1–120**.

The public GitHub repository currently contains companion packages for **Parts 103–120**. Parts **1–102 are not yet published here** and should only be added after their source packages are recovered, reviewed, and validated.

### Validated advanced packages

- Part 110: 13/13 tests passed
- Part 111: 18/18 tests passed
- Part 112: 19/19 tests passed
- Part 113: 12/12 model tests passed
- Part 114: 16/16 model tests passed
- Part 115: 16/16 model tests + package verification passed
- Part 116: 7/7 tests passed; original import has two non-failing ResourceWarnings
- Part 117: 9/9 direct contract tests passed
- Part 118: 11/11 package tests passed
- Part 119: 13/13 package/model checks passed
- Part 120: 17/17 final package/reasoning checks passed

See `COMPANION_STATUS.json`, `docs/PARTS_103_120_PUBLICATION_STATUS.md`, and `docs/CHECKSUM_NOTES.md`.

## Standalone project portfolio

The repository contains **10 independent projects** under `projects/`:

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

Local validation before publication: **30/30 unit tests passed** across these projects.

See `PROJECTS_STATUS.json`, `projects/README.md`, and `docs/STANDALONE_PROJECTS_CATALOG.md`.

## CI status architecture

Only repository-aware workflows should remain:

- `codeql.yml`
- `companion-python-tests.yml`
- `standalone-projects-python.yml`
- `repository-quality.yml`

Generic root-level CMake/Make/MSBuild/Rust/SLSA starter workflows were removed because this is a multi-project repository and those templates produced false failures.

## Public/private boundary

Public repository:
- companion code
- standalone projects
- tests
- samples
- documentation
- status metadata

Not public:
- paid Master PDF
- paid Master DOCX
- paid EPUB
- commercial cover/source publishing assets

## Licensing

- Companion and standalone project code: **MIT**
- Commercial book/manuscript/cover assets: **All Rights Reserved**

## Permanent links

- Gumroad: **https://ramsandesh.gumroad.com**
- GitHub profile: https://github.com/sanskarIN
- Repository: https://github.com/sanskarIN/sql-master
- Buy Me a Coffee: https://buymeacoffee.com/sanskarIN
- Business: sanskarin@outlook.in
- Business: sanskarin.business@gmail.com
- Support: supportramsandesh@gmail.com

Mutable X/Twitter profile URLs remain intentionally excluded from permanent repository/publication metadata.

## Quality statement

The repository is maintained with automated tests, validation, CodeQL, documentation audits, and explicit known-limitations tracking. These checks reduce known defects, but no non-trivial software project can truthfully guarantee that future or undiscovered bugs are impossible.
