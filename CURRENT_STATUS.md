# Current Repository Status

**Repository:** `https://github.com/sanskarIN/sql-master`  
**Repository version:** `1.0.0`  
**Official store:** **https://ramsandesh.gumroad.com**  
**Edition context:** August 2026

## Companion-code publication

The SQL Full Mastery book series is planned as **Parts 1–120**.

The public GitHub repository currently contains companion packages for **Parts 103–120**. Parts **1–102 are not yet published here** and should only be added after their source packages are recovered, reviewed, and validated.

### Fresh advanced-package validation

Re-run during the final hardening pass:

- Part 110: 13/13 tests passed
- Part 111: 18/18 tests passed
- Part 112: 19/19 tests passed
- Part 113: 12/12 model tests passed
- Part 114: 16/16 model tests passed
- Part 115: 16/16 model tests passed + package verifier passed (17 required files / 7 contract checks)
- Part 116: 7/7 tests passed; the live file-handle fix also passed with `ResourceWarning` promoted to an error
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

Final hardening re-validation: **30/30 declared unit tests passed** across all 10 projects. The root test runner now verifies both process success and the declared test count from `PROJECTS_STATUS.json`.

## Repository tooling validation

- Repository-tool regression tests: **8/8 passed**
- Semantic `VERSION` marker added
- Repository validator hardened so the project count is driven by `PROJECTS_STATUS.json`, not a hard-coded number
- Validator now checks duplicate/undeclared projects, declared test counts, required operations files, release documentation, and semantic-version format
- Repository-relative Markdown link validator added
- Repository Quality workflow now compiles Python, runs tooling tests, validates structure/metadata, checks relative Markdown links, and re-runs the standalone portfolio

## CI architecture

Maintained repository-aware workflows:

- `codeql.yml`
- `companion-python-tests.yml`
- `standalone-projects-python.yml`
- `repository-quality.yml`

Generic root-level CMake/Make/MSBuild/Rust/SLSA starter workflows remain intentionally removed because this is a multi-project repository and those templates produced false failures.

## Documentation completion

The documentation hub now includes:

- quick start
- architecture
- testing and quality gates
- development and style rules
- adding standalone projects
- adding companion Parts
- database compatibility
- support matrix
- data safety/privacy
- governance
- maintenance and troubleshooting
- versioning and release process
- release checklist
- known limitations and FAQ
- permanent-link policy
- final repository audit

See `docs/README.md`.

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
- buyer delivery packages

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

The repository is maintained toward **zero known release-blocking defects under the defined quality gates**. Fresh tests, static/package checks, metadata validation, link checks, and security scanning reduce risk, but no non-trivial software project can truthfully guarantee that future or undiscovered defects are impossible.
