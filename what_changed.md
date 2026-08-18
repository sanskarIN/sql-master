# What Changed

## 2026-08-18 — Standalone SQL project expansion

### Added
- New `projects/` portfolio separate from the Part 1–120 companion-code folders.
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
- Projects use dependency-free Python standard-library and/or SQLite workflows so they are easy to run and audit.

### Repository structure
- `code/part-001` through `code/part-120`: book Part companion packages.
- `projects/`: independent portfolio/lab projects.
- Paid Master PDF/DOCX/EPUB files remain outside the public repository.

### Links
- Official store remains **https://ramsandesh.gumroad.com**.
- Permanent metadata continues to omit mutable X/Twitter profile URLs.

## 2026-08-18 — Permanent-link and publication-package cleanup

### Added
- Permanent link policy under `docs/PERMANENT_LINK_POLICY.md`.
- Stable canonical purchase link: **https://ramsandesh.gumroad.com**.
- Publication-platform guide and final buyer/seller package workflow outside the public repository.

### Changed
- Audited the live repository for X/Twitter URLs; no mutable X/Twitter URL remains in the repository.
- Permanent publishing metadata now intentionally omits X/Twitter profile URLs so purchased copies do not become stale when a social handle changes.
- Rebuilt the GitHub distribution packages after removing older embedded `https://www.x.com/Sanskar_in` metadata copies.
- Kept the complete paid PDF, DOCX, and EPUB outside the public GitHub repository.

### Verification
- Final publication-package scan: **0 actual X/Twitter profile URL hits**.
- Official store remains highlighted: **https://ramsandesh.gumroad.com**.

## 2026-08-17 — GitHub publication setup

### Added
- Public repository structure for SQL Full Mastery companion resources.
- Separate code policy for Parts 1–120.
- Companion packages currently available for Parts 103–120.
- Publishing and repository documentation.
- Commercial book licensing boundary.
- GitHub push instructions.
- Dedicated official store documentation.
- Custom Gumroad highlight badge.

### Changed
- Highlighted the official Gumroad store throughout key repository documentation: **https://ramsandesh.gumroad.com**
- Kept paid full-book PDF, DOCX, and EPUB outputs outside the public repository scope.

### Git
- Target repository: `https://github.com/sanskarIN/sql-master`
- Requested commit email: `sanskarin@outlook.in`

### Known limitations
- Companion packages for Parts 1–102 are not currently available in this workspace, so those folders remain pending for future code publication.
