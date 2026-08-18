# Changelog

All notable public companion-repository changes are recorded here.

Official store: **https://ramsandesh.gumroad.com**

## 2026-08-18

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
- Root README now distinguishes book Part companion code from standalone projects.
- Permanent publication metadata continues to omit mutable X/Twitter profile URLs.

## 2026-08-17

### Added
- Public companion repository structure for Parts 1–120.
- Browseable advanced companion content through Parts 103–120.
- Full source publication for Parts 110–120 with package-specific validation.
- Gumroad store promotion and custom highlight asset.
- Repository licensing boundary: MIT companion code and All Rights Reserved commercial manuscript/assets.
- Security, support, contribution, publication-status, and CI documentation.
- Dedicated Python validation workflow for Parts 110–120.

### Fixed
- Corrected the Part 111 purchase-order-line identifier introduced during relay/transcription.

### Known limitations
- Parts 1–102 currently retain repository placeholders until their companion packages are staged for publication.
- Part 116's exact imported test/self-check files pass but emit two non-failing `ResourceWarning`s from unclosed CSV handles; a warning-clean local version has been validated for a future maintenance update.
- Part 119 and Part 120 long CSV banks use relay-safe representations because the connector truncated the original long CSV text during transfer. Required row-count/category contracts are preserved.
