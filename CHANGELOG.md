# Changelog

All notable public companion-repository changes are recorded here.

Official store: **https://ramsandesh.gumroad.com**

## 2026-08-18 — Final repository hardening

### Added
- Complete documentation hub under `docs/`.
- Architecture, testing, development, troubleshooting, database-compatibility, maintenance, release-checklist, and final-audit documentation.
- `scripts/validate_repository.py` for structure/status/link-policy validation.
- `scripts/run_all_tests.py` for unified local standalone/companion test execution.
- `repository-quality.yml` CI gate.
- Dependabot configuration for GitHub Actions.
- CODEOWNERS, PR template, feature-request template, funding links, `.editorconfig`, `.gitattributes`, and `THIRD_PARTY_NOTICES.md`.

### Changed
- Corrected repository status to reflect the actual published companion range: **Parts 103–120**.
- Updated CodeQL, companion, and standalone workflows to current supported major action versions used by the August 2026 configuration.
- Expanded `.gitignore` for Python caches, virtual environments, local databases, coverage output, and editor files.
- Reconciled README, CURRENT_STATUS, ROADMAP, CI audit, and machine-readable status metadata.

### Fixed
- Removed invalid root-level C/C++/CMake/Make/MSBuild/Rust starter workflows that assumed a monolithic root build.
- Removed placeholder SLSA workflow that generated dummy artifacts.
- Fixed Part 116 test CSV file-handle leaks by using context managers.
- Refreshed the Part 116 SHA-256 manifest after the intentional test-file change.
- Corrected earlier documentation that implied Parts 1–102 were already tracked as published/placeholder companion directories.

### Validation notes
- Standalone project portfolio remains recorded at **30/30 local unit tests passed** across 10 projects.
- Advanced package validation remains recorded for Parts 110–120 in `COMPANION_STATUS.json`.
- CI workflow definitions are committed, but a workflow must only be called green when an actual successful run is observed.

### Known limitations
- Parts 1–102 companion packages are not yet published in this repository.
- Part 119 and Part 120 long CSV banks remain relay-safe, contract-preserving representations pending a reliable byte-identical transfer route.
- Targeted C/C++/Rust/Go CI for Parts 103–105 remains future work until each package has a clean verified build/test contract in the available execution environment.

## 2026-08-18 — Standalone SQL project expansion

### Added
- Standalone `projects/` portfolio with 10 independent SQL/database projects.
- Dedicated standalone-project catalog and machine-readable project status.
- GitHub Actions matrix that tests each standalone Python/SQLite project independently.
- 30 local unit tests across the new project portfolio, all passing before publication.

### Project portfolio
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

### Documentation
- Root README distinguishes book Part companion code from standalone projects.
- Permanent publication metadata continues to omit mutable X/Twitter profile URLs.

## 2026-08-17 — Initial public companion publication

### Added
- Public companion repository structure and licensing boundary.
- Browseable advanced companion content for Parts 103–120.
- Full source publication for Parts 110–120 with package-specific validation.
- Gumroad store promotion and custom highlight asset.
- Security, support, contribution, publication-status, and CI documentation.
- Dedicated Python validation workflow for Parts 110–120.

### Fixed
- Corrected the Part 111 purchase-order-line identifier introduced during relay/transcription.

### Known limitations
- Parts 1–102 companion packages were not yet available for public publication.
- Part 119 and Part 120 long CSV banks used relay-safe representations because the connector truncated the original long CSV text during transfer; required row-count/category contracts were preserved.
