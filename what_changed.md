# What Changed

## 2026-08-18 — Final repository hardening and documentation completion

### Added
- Complete documentation index at `docs/README.md`.
- Architecture guide: `docs/ARCHITECTURE.md`.
- Testing guide: `docs/TESTING.md`.
- Development guide: `docs/DEVELOPMENT.md`.
- Database compatibility guide: `docs/DATABASE_COMPATIBILITY.md`.
- Maintenance guide: `docs/MAINTENANCE.md`.
- Troubleshooting guide: `docs/TROUBLESHOOTING.md`.
- Release checklist: `docs/RELEASE_CHECKLIST.md`.
- Final audit: `docs/FINAL_REPOSITORY_AUDIT.md`.
- Repository validator: `scripts/validate_repository.py`.
- Unified local test runner: `scripts/run_all_tests.py`.
- Repository-wide quality workflow: `.github/workflows/repository-quality.yml`.
- Dependabot for GitHub Actions.
- CODEOWNERS.
- Pull-request quality template.
- Structured feature-request template.
- GitHub funding links for Gumroad and Buy Me a Coffee.
- `.editorconfig` and `.gitattributes`.
- `THIRD_PARTY_NOTICES.md`.

### CI cleanup
- Removed invalid root-level C/C++ workflow.
- Removed invalid multi-platform CMake workflow.
- Removed invalid single-platform CMake workflow.
- Removed invalid root Makefile workflow.
- Removed invalid root MSBuild workflow.
- Removed invalid root Rust workflow.
- Removed placeholder SLSA workflow that generated dummy artifacts.
- Retained/hardened only repository-aware workflows:
  - CodeQL
  - Parts 110–120 companion tests
  - standalone-project tests
  - repository-quality validation
- Updated maintained Actions to supported August 2026 major versions.

### Fixed
- Corrected documentation that implied `code/part-001` through `code/part-120` were already tracked publicly. The actual published companion range is **Parts 103–120**.
- Parts 1–102 are now clearly labeled **not yet published** rather than placeholder/published.
- Fixed Part 116 unclosed CSV file handles in package tests.
- Refreshed Part 116 SHA-256 checksum after the intentional test-file change.
- Reconciled `README.md`, `CURRENT_STATUS.md`, `COMPANION_STATUS.json`, `ROADMAP.md`, `CHANGELOG.md`, and CI documentation.
- Expanded `.gitignore` for Python, virtualenv, local DB, coverage, and editor artifacts.

### Quality status
- 10 standalone projects remain recorded with **30/30 local unit tests passed** before publication.
- Parts 110–120 retain their recorded package/model validation results in `COMPANION_STATUS.json`.
- Repository validation now automatically checks layout, metadata, links, workflows, and public/private boundaries.
- Target quality level: **zero known release-blocking defects under the defined validation gates**.

### Known limitations
- Companion packages for Parts 1–102 are not yet published.
- Part 119/120 long CSV banks remain relay-safe contract-preserving versions pending a reliable byte-identical transfer route.
- Targeted C/C++/Rust/Go CI for Parts 103–105 is intentionally deferred until each package can be cleanly built/tested in the available execution environment.
- A CI workflow is only considered green when an actual successful run is observed; configuration alone is not treated as proof.

### Links
- Repository: `https://github.com/sanskarIN/sql-master`
- Official store: **https://ramsandesh.gumroad.com**
- GitHub profile: https://github.com/sanskarIN
- Business: sanskarin@outlook.in
- Business: sanskarin.business@gmail.com
- Support: supportramsandesh@gmail.com
- Permanent metadata intentionally omits mutable X/Twitter profile URLs.

## 2026-08-18 — Standalone SQL project expansion

### Added
- New `projects/` portfolio separate from Part companion packages.
- **10 independent SQL/database projects**:
  - SQLite Inventory Manager
  - Migration Order Checker
  - Schema Quality Auditor
  - EXPLAIN Plan Analyzer
  - Synthetic Data Factory
  - Backup Manifest Verifier
  - Transaction Invariant Simulator
  - SQL Query Practice Lab
  - Data Quality Rule Runner
  - SQLite Booking Calendar
- Dedicated project catalog at `docs/STANDALONE_PROJECTS_CATALOG.md`.
- Machine-readable project status at `PROJECTS_STATUS.json`.
- Dedicated GitHub Actions test matrix at `.github/workflows/standalone-projects-python.yml`.

### Validation
- All 10 standalone projects were executed locally before publication.
- Combined local result: **30/30 unit tests passed**.

## 2026-08-18 — Permanent-link and publication-package cleanup

### Added
- Permanent-link policy under `docs/PERMANENT_LINK_POLICY.md`.
- Stable canonical purchase link: **https://ramsandesh.gumroad.com**.

### Changed
- Audited the live repository for mutable X/Twitter URLs.
- Permanent publishing metadata intentionally omits mutable X/Twitter profile URLs.
- Paid full-book PDF, DOCX, and EPUB remain outside the public GitHub repository.

## 2026-08-17 — Initial GitHub publication

### Added
- Public SQL Full Mastery companion repository.
- Companion packages for Parts 103–120.
- Publishing/repository documentation and licensing boundary.
- Gumroad store documentation and custom highlight badge.
- Requested commit email: `sanskarin@outlook.in`.

### Fixed
- Part 111 purchase-order-line identifier issue introduced during relay/transcription.
