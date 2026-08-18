# Development Guide

## Local setup

Requirements depend on the package being edited. The repository itself has no single root dependency graph.

For Python/SQLite projects, Python 3.12+ is recommended for development and CI parity.

```bash
git clone https://github.com/sanskarIN/sql-master.git
cd sql-master
python scripts/validate_repository.py
```

## Git identity

Recommended repository-local identity:

```bash
git config user.name "Sanskar"
git config user.email "sanskarin@outlook.in"
```

Do not change global Git identity unless intentionally desired.

## Branch and commit workflow

1. Start from an up-to-date `main`.
2. Create a focused branch for non-trivial changes.
3. Change one logical concern at a time.
4. Run the package-specific tests.
5. Run `python scripts/validate_repository.py`.
6. Update documentation/status files when behavior changes.
7. Use meaningful commit messages.

Examples:

```text
feat(part-121): add new companion lab
fix(part-116): close CSV handles in tests
test(projects): add migration regression case
docs: clarify published companion range
ci: scope workflow to affected packages
```

## Adding a standalone project

A new `projects/<name>/` project should include:

- `README.md`
- runnable source
- tests where practical
- deterministic/safe example data
- no hidden network dependency unless documented
- no paid book content copied into the public repository

Then update:

- `projects/README.md`
- `PROJECTS_STATUS.json`
- `docs/STANDALONE_PROJECTS_CATALOG.md`
- CI matrix if the project needs automated tests
- `CHANGELOG.md`
- `what_changed.md`

## Adding a companion Part

Do not add an empty placeholder and call it published. Add a Part only when its public companion package is available and reviewed.

Recommended structure:

```text
code/part-NNN/
├── README.md
└── src/
    ├── SQL/source files
    ├── tests
    └── package documentation
```

Update `COMPANION_STATUS.json` and publication-status documentation in the same change.

## Source quality

- Prefer parameterized SQL/application calls over string-built queries.
- Store currency as integer minor units or an appropriate fixed-precision database type.
- Keep destructive examples clearly labeled and isolated from production instructions.
- Use deterministic ordering when query results depend on order.
- Document transaction and concurrency assumptions.
- Never claim a test/database execution that was not actually run.

## Permanent metadata

Use stable links in long-lived files. Mutable X/Twitter profile URLs are intentionally omitted.

Official store: **https://ramsandesh.gumroad.com**
