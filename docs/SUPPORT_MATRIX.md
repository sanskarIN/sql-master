# Support Matrix

This repository contains multiple independent SQL/database learning packages. Support is defined by package, not by one global runtime.

## Repository tooling

| Area | Supported baseline |
|---|---|
| Repository scripts | Python 3.12+ |
| Standalone projects | Python 3.12+ unless a project README states otherwise |
| SQLite labs | Python standard-library `sqlite3` / SQLite available with Python |
| GitHub Actions | Ubuntu GitHub-hosted runners |

## Companion range

| Range | Public status | Validation status |
|---|---|---|
| Parts 1–102 | Not yet published in this public repository | Not claimed |
| Parts 103–109 | Published companion content | Package/source review; use each Part README |
| Parts 110–120 | Published | Python/model/package tests maintained in CI |

## Database engines

The book and companion materials may discuss PostgreSQL, SQLite, MySQL, SQL Server, and Oracle. Syntax and behavior can differ by engine and version.

- **SQLite:** several standalone projects execute against SQLite through Python.
- **PostgreSQL:** advanced packages contain PostgreSQL-oriented SQL and design patterns; engine execution must only be claimed where actually performed.
- **MySQL / SQL Server / Oracle:** examples may be educational or dialect-specific; consult the individual Part documentation and `DATABASE_COMPATIBILITY.md`.

## Operating systems

The repository is source-oriented and should be usable on Windows, macOS, and Linux where the required runtime/database is available. CI currently validates supported Python workflows on Ubuntu runners.

## Support boundaries

Supported:

- reproducible issues in published repository code
- documentation mistakes
- broken repository-relative links
- CI failures caused by repository changes
- package-test regressions

Not guaranteed:

- every historical database version
- third-party service availability
- production deployment architecture for every environment
- compatibility with modified forks

For sensitive security matters, follow `../SECURITY.md` rather than posting secrets publicly.

Official store: **https://ramsandesh.gumroad.com**
