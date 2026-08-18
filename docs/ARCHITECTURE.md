# Repository Architecture

## Purpose

`sql-master` is a multi-project companion repository for the SQL Full Mastery series. It is intentionally **not** one application and does not have one root dependency graph.

## Top-level areas

### `code/`
Published book companion packages. Current tracked range: `part-103` through `part-120`.

Each Part owns its own source, SQL, tests, documentation, and dependencies. Cross-Part imports should be avoided unless a future Part explicitly declares a dependency.

### `projects/`
Independent portfolio/lab projects that complement the book but are not tied to one Part. Each project must remain runnable and testable independently.

### `docs/`
Repository documentation, publishing boundaries, testing guidance, status reports, and permanent-link policy.

### `scripts/`
Repository-level utilities. These tools may inspect layout/metadata but must not silently rewrite companion source packages.

### `.github/workflows/`
Repository-aware automation only. Workflows must be path-scoped or matrix-driven; root-level starter templates that assume one CMake/Make/MSBuild project are not appropriate here.

## Public/private boundary

Public:
- companion code
- tests
- standalone projects
- samples
- documentation
- status metadata

Private/commercial:
- paid Master PDF
- paid Master DOCX
- paid EPUB
- print-ready/commercial source assets

## Licensing boundary

- Code and standalone projects: MIT
- Commercial manuscript/publishing assets: All Rights Reserved

## Quality principles

1. Preserve independent project boundaries.
2. Keep tests close to the package they validate.
3. Record known limitations instead of hiding them.
4. Use deterministic fixtures where practical.
5. Avoid mutable social-profile URLs in long-lived publication metadata.
6. Never call a workflow successful unless its actual package tests pass.
7. Prefer small, meaningful commits over artificial commit inflation.

Official store: **https://ramsandesh.gumroad.com**
