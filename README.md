# SQL Full Mastery — Companion Code

> **Official store:** **https://ramsandesh.gumroad.com**

![Gumroad Highlight](assets/branding/gumroad-highlight-badge.svg)

Official companion-code and documentation repository for **SQL Full Mastery** by **Ram Sandesh**.

## Repository purpose

This repository is for the code, exercises, setup instructions, errata, sample material, supporting resources, and standalone SQL/database projects for the 120-part SQL Full Mastery series.

**The paid full book manuscripts (Master PDF, editable DOCX, and EPUB) should not be committed to this public repository.** Keep those files in the publishing/private release workflow.

## Repository

- Repository name: `sql-master`
- Link: `https://github.com/sanskarIN/sql-master`

## Part companion-code policy

Each Part remains independent:

```text
code/
├── part-001/
├── part-002/
├── ...
└── part-120/
```

Do not combine all 120 companion projects into one dependency graph. A Part may use PostgreSQL, SQLite, MySQL, SQL Server, Oracle, Python, Java, Kotlin, Rust, Go, C/C++, Dart/Flutter, Node.js, or other tooling specific to that volume.

## Standalone projects

The repository now also includes a separate `projects/` portfolio containing **10 independent, test-backed projects**:

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

See [`projects/README.md`](projects/README.md), [`docs/STANDALONE_PROJECTS_CATALOG.md`](docs/STANDALONE_PROJECTS_CATALOG.md), and [`PROJECTS_STATUS.json`](PROJECTS_STATUS.json).

A dedicated GitHub Actions workflow runs each project's Python test suite independently.

## Licensing

- Companion and standalone source code: MIT License
- Book manuscript, cover and paid publishing assets: All Rights Reserved unless explicitly released under another license

See `BOOK_LICENSE.md` and `LICENSE`.

## Permanent-link policy

Permanent publication metadata intentionally omits mutable X/Twitter profile URLs. See `docs/PERMANENT_LINK_POLICY.md`.

## Author / links

- Author: Ram Sandesh
- GitHub: https://github.com/sanskarIN
- Business: sanskarin@outlook.in
- Business: sanskarin.business@gmail.com
- Support: supportramsandesh@gmail.com
- Buy Me a Coffee: https://buymeacoffee.com/sanskarIN
- Gumroad: https://ramsandesh.gumroad.com
