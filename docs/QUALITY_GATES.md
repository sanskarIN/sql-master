# Quality Gates

A change is ready to merge only when the relevant gates below pass.

## Gate 1 — Repository structure

```bash
python scripts/validate_repository.py
```

Required outcomes:

- required documentation present
- status JSON valid
- declared projects match actual project directories
- published companion range present
- permanent-link policy clean
- no paid Master artifact in the public tree
- required workflows and operations files present

## Gate 2 — Python compilation

```bash
python -m compileall -q scripts projects code
```

This catches syntax/import-file compilation failures but is not a substitute for behavioral tests.

## Gate 3 — Relative links

```bash
python scripts/check_relative_links.py
```

Repository-relative Markdown links must resolve inside the repository tree.

## Gate 4 — Standalone projects

```bash
python scripts/run_all_tests.py --standalone
```

The runner verifies both exit status and the declared number of discovered tests from `PROJECTS_STATUS.json`.

## Gate 5 — Advanced companion packages

```bash
python scripts/run_all_tests.py --companion
```

Parts 110–120 use package-specific test commands.

## Gate 6 — Security scanning

Review CodeQL results for supported languages and GitHub Actions.

## Gate 7 — Documentation truthfulness

Before merging, check that documentation does not overstate:

- database-engine execution
- cross-dialect portability
- production readiness
- performance characteristics
- test coverage

## Gate 8 — Publication boundary

The complete paid Master PDF, DOCX, EPUB, and buyer packages must not be committed to the public repo.

## Gate 9 — Stable links

Permanent metadata must use stable links. Mutable X/Twitter profile URLs are intentionally excluded.

A passing gate means the checks performed are green; it is not a mathematical guarantee that software contains no possible defect.

Official store: **https://ramsandesh.gumroad.com**
