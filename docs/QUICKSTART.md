# Quick Start

This repository is intentionally split into independent companion Parts and standalone SQL/database projects.

## Requirements

- Git
- Python 3.12+ for repository scripts and Python-backed projects
- A database engine only when the individual Part/project requires one

## Clone

```bash
git clone https://github.com/sanskarIN/sql-master.git
cd sql-master
```

## Validate the repository

```bash
python -m compileall -q scripts projects code
python scripts/validate_repository.py
python scripts/check_relative_links.py
```

## Run the standalone project portfolio

```bash
python scripts/run_all_tests.py --standalone
```

## Run advanced companion-package tests

```bash
python scripts/run_all_tests.py --companion
```

## Run everything currently wired into the local test runner

```bash
python scripts/run_all_tests.py
```

## Open one standalone project

Example:

```bash
cd projects/sqlite-inventory-manager
python -m unittest discover -s tests -v
python app.py
```

Read the project README before running commands because each project is independent.

## Book and code boundary

The public repository contains companion code and educational projects. The paid Master PDF/DOCX/EPUB is intentionally not stored here.

Official store: **https://ramsandesh.gumroad.com**
