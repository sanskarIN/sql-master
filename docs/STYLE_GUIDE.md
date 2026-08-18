# SQL and Python Style Guide

This guide keeps examples consistent without forcing every database dialect into one syntax.

## SQL

- Prefer explicit column lists over `SELECT *` in stable production examples.
- Use clear aliases and consistent indentation.
- State row grain before complex analytical queries.
- Use deterministic ordering when result order matters.
- Handle `NULL` semantics intentionally.
- Use integer minor currency units or an appropriate exact numeric type; avoid floating point for money.
- Put integrity rules in database constraints when the database can enforce them reliably.
- Use transactions for multi-statement invariants.
- Comment vendor-specific syntax rather than pretending it is portable.
- Keep destructive examples clearly labeled and isolated from production instructions.

## Schema design

- Use explicit primary keys.
- Name foreign keys and indexes descriptively where supported.
- Add `CHECK`, `UNIQUE`, and foreign-key constraints for real invariants.
- Avoid redundant indexes unless a demonstrated access pattern requires them.
- Document time zone and currency assumptions.

## Python

- Target Python 3.12+ for repository tooling unless a project says otherwise.
- Prefer the standard library for small educational tools.
- Use `pathlib` for filesystem paths.
- Use context managers for files and transactions.
- Avoid swallowing exceptions silently.
- Keep CLI entry points under `if __name__ == "__main__":`.
- Add unit tests for behavior, not merely import success.

## Tests

- Use deterministic fixtures.
- Cover edge cases and invalid inputs.
- Do not rely on external network access unless the project explicitly requires and documents it.
- Never claim an engine-specific behavior was tested if only a Python model was executed.

## Documentation

- Keep commands copyable.
- State prerequisites.
- Document known limitations.
- Use stable permanent links; omit mutable X/Twitter profile URLs from long-lived metadata.

Official store: **https://ramsandesh.gumroad.com**
