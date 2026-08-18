# Repository Maintenance Guide

## Routine maintenance

### On every source change

- run the affected package/project tests
- run `python scripts/validate_repository.py`
- update checksums when a checksummed file changes intentionally
- update status metadata when publication/test state changes
- update documentation when behavior changes

### Weekly / dependency maintenance

- review Dependabot pull requests for GitHub Actions
- merge only after repository-aware CI passes
- review CodeQL findings and triage true positives

### Monthly

- review `CURRENT_STATUS.md`, `COMPANION_STATUS.json`, and `PROJECTS_STATUS.json`
- check permanent links
- verify paid manuscript files are not present in the public tree
- review open issues and stale documentation

### Before a tagged release

Follow `RELEASE_CHECKLIST.md` and run:

```bash
python scripts/validate_repository.py
python scripts/run_all_tests.py --standalone
python scripts/run_all_tests.py --companion
```

## Adding new dependencies

Before adding a dependency:

1. confirm it is actually needed
2. review its license and maintenance status
3. prefer small, well-maintained dependencies
4. avoid introducing a root dependency solely for one isolated Part/project
5. document setup and version constraints in the owning package

## Checksums

Checksums prove file-byte integrity, not logical correctness. When an intentional fix changes a checksummed file:

1. make the source change
2. run tests
3. regenerate the affected checksum
4. commit source and checksum changes with clear messages
5. document the reason in the changelog if user-visible

## Documentation drift

The repository validator intentionally fails when machine-readable status and live directories disagree. Do not weaken that check to hide drift; correct the documentation/status data instead.

## Security

- do not commit secrets, tokens, production database dumps, or customer data
- use synthetic/example data in public fixtures
- report sensitive issues using the process in `../SECURITY.md`
- keep public SQL examples clearly separated from production credentials/configuration

## Permanent publication metadata

Use stable links only. Mutable X/Twitter profile URLs remain excluded from long-lived metadata.

Official store: **https://ramsandesh.gumroad.com**
