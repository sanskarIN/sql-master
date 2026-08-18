# Database Compatibility Guide

This repository contains examples for multiple database engines and application stacks. There is **no single SQL dialect** that should be assumed across every Part/project.

## Source of truth

For any companion package, use this precedence:

1. the Part/project README
2. package comments and setup files
3. tests and executable fixtures
4. general repository documentation

If a package says PostgreSQL, do not assume its SQL runs unchanged on SQLite, MySQL, SQL Server, or Oracle.

## Common portability differences

### Identity / generated keys

Examples may use engine-specific identity syntax, sequences, or `RETURNING` behavior.

### Date/time functions

Date arithmetic, timezone types, interval syntax, and formatting functions differ substantially by engine.

### Upsert syntax

`ON CONFLICT`, `ON DUPLICATE KEY`, and `MERGE` are not interchangeable.

### Pagination

`LIMIT/OFFSET`, `TOP`, and `FETCH FIRST` vary by engine. Keyset pagination also requires deterministic ordering and engine-appropriate indexes.

### Concurrency and locking

`FOR UPDATE`, exclusion constraints, advisory locks, isolation behavior, and lock hints are engine-specific.

### JSON

JSON types, operators, path syntax, indexing, and functions differ by engine/version.

### DDL and migrations

Online index creation, generated columns, constraint validation, partitioning, and schema-change locking differ by engine/version.

## Money

Prefer integer minor units (for example paise) or an appropriate fixed-precision database type. Avoid floating-point storage for monetary values.

## NULL and ordering

Always make NULL behavior and tie-breaking explicit when correctness depends on them. Add a deterministic final ordering key when results must be stable.

## Testing claims

Documentation must distinguish among:

- static review
- Python/model tests
- SQLite execution
- PostgreSQL execution
- MySQL execution
- SQL Server execution
- Oracle execution

Never claim cross-engine compatibility merely because a query is syntactically similar.

Official store: **https://ramsandesh.gumroad.com**
