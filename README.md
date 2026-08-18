# SQL Full Mastery — Companion Code

> **Official store:** **https://ramsandesh.gumroad.com**

![Gumroad Highlight](assets/branding/gumroad-highlight-badge.svg)

Official companion-code, lab, documentation, and standalone-project repository for **SQL Full Mastery** by **Ram Sandesh**.

## Repository purpose

This public repository contains:

- published companion packages for **Parts 103–120**
- validated SQL/database labs and interview packages
- **10 independent standalone SQL/database projects** under `projects/`
- tests, CI workflows, support/security documentation, and publishing-support metadata

The complete paid Master PDF, editable DOCX, EPUB, and commercial cover assets are intentionally kept **outside** this public repository.

## Current publication status

- Planned book series: **Parts 1–120**
- Companion packages currently published here: **Parts 103–120**
- Parts **1–102 are not yet published in this repository**
- Validated Python-backed advanced packages: **Parts 110–120**
- Standalone project portfolio: **10 projects / 30 local unit tests passed before publication**

See [`CURRENT_STATUS.md`](CURRENT_STATUS.md), [`COMPANION_STATUS.json`](COMPANION_STATUS.json), and [`PROJECTS_STATUS.json`](PROJECTS_STATUS.json).

## Repository layout

```text
sql-master/
├── code/                     # published per-Part companion packages
│   ├── part-103/
│   ├── ...
│   └── part-120/
├── projects/                 # independent SQL/database projects
├── docs/                     # architecture, testing, publishing and support docs
├── scripts/                  # repository validation/import helpers
├── .github/workflows/        # repository-aware CI and CodeQL
├── COMPANION_STATUS.json
├── PROJECTS_STATUS.json
└── README.md
```

Each companion Part remains independent. Do not combine all Parts into one dependency graph; different Parts may use PostgreSQL, SQLite, MySQL, SQL Server, Oracle, Python, Rust, Go, C/C++, or other tooling.

## Standalone projects

The `projects/` portfolio currently contains:

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

See [`projects/README.md`](projects/README.md) and [`docs/STANDALONE_PROJECTS_CATALOG.md`](docs/STANDALONE_PROJECTS_CATALOG.md).

## Testing and quality

Repository-aware CI includes:

- standalone-project Python test matrix
- Parts 110–120 companion-package test matrix
- repository metadata/layout validator
- CodeQL scanning for Actions, Python, C/C++, and Rust

See [`docs/TESTING.md`](docs/TESTING.md) and [`docs/FINAL_REPOSITORY_AUDIT.md`](docs/FINAL_REPOSITORY_AUDIT.md).

## Documentation

Start at [`docs/README.md`](docs/README.md).

Important references:

- Architecture: `docs/ARCHITECTURE.md`
- Testing: `docs/TESTING.md`
- Development: `docs/DEVELOPMENT.md`
- Troubleshooting: `docs/TROUBLESHOOTING.md`
- Release checklist: `docs/RELEASE_CHECKLIST.md`
- Permanent-link policy: `docs/PERMANENT_LINK_POLICY.md`
- Security: `SECURITY.md`
- Contributing: `CONTRIBUTING.md`
- Support: `SUPPORT.md`

## Licensing

- Companion and standalone source code: **MIT License**
- Book manuscript, paid PDF/DOCX/EPUB, cover, and commercial publishing assets: **All Rights Reserved** unless explicitly released under another license

See [`LICENSE`](LICENSE) and [`BOOK_LICENSE.md`](BOOK_LICENSE.md).

## Permanent links

Permanent publication metadata intentionally omits mutable X/Twitter profile URLs.

- Author: **Ram Sandesh**
- GitHub: https://github.com/sanskarIN
- Repository: https://github.com/sanskarIN/sql-master
- Gumroad: **https://ramsandesh.gumroad.com**
- Buy Me a Coffee: https://buymeacoffee.com/sanskarIN
- Business: sanskarin@outlook.in
- Business: sanskarin.business@gmail.com
- Support: supportramsandesh@gmail.com
