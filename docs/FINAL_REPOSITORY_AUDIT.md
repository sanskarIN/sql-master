# Final Repository Audit

**Repository:** `sanskarIN/sql-master`  
**Audit date:** 2026-08-18  
**Official store:** **https://ramsandesh.gumroad.com**

## Scope audited

- repository structure
- published companion-code range
- standalone project portfolio
- Python/model test commands
- GitHub Actions configuration
- CodeQL configuration
- licensing/public-private boundary
- permanent-link policy
- root/status documentation consistency
- known warning/error inventory

## Corrections completed

### CI cleanup

Removed generic starter workflows that incorrectly assumed a single root project:

- root C/C++ `./configure`/Make workflow
- multi-platform CMake starter
- single-platform CMake starter
- root Makefile starter
- root MSBuild starter
- root Rust starter
- placeholder SLSA workflow that generated dummy artifacts

Retained/hardened repository-aware automation:

- `codeql.yml`
- `companion-python-tests.yml`
- `standalone-projects-python.yml`
- `repository-quality.yml`

### Workflow dependency refresh

Maintained workflows were updated to current supported major action versions used by this repository's August 2026 configuration:

- `actions/checkout@v6`
- `actions/setup-python@v6`
- `github/codeql-action@v4`

### Documentation consistency

Corrected the inaccurate implication that Parts 1–102 are already tracked as public companion directories.

Current truth source:

- book plan: Parts 1–120
- public companion packages in this repository: Parts 103–120
- Parts 1–102: not yet published here
- standalone projects: 10

### Part 116 warning cleanup

The two CSV reads in `code/part-116/src/tests/test_package.py` now use context managers, removing the previously documented file-handle `ResourceWarning` source. `SHA256SUMS.txt` was updated for the intentional test-file change.

Fresh post-fix verification was run against the actual Part 116 companion package with `ResourceWarning` promoted to an error:

```bash
PYTHONDONTWRITEBYTECODE=1 python -W error::ResourceWarning -m unittest discover -s tests -v
```

Result: **7/7 tests passed** with no `ResourceWarning` failure. The reconstructed fixed test file produced SHA-256:

```text
d68ddfa3750415690f72cafe1e873d3c01b009796435400082b04814944a2e14  tests/test_package.py
```

which matches the refreshed manifest committed in the repository.

### Repository validation

Added `scripts/validate_repository.py` to fail on:

- missing required documentation
- malformed status JSON
- missing published Part 103–120 directories
- missing standalone project directories/tests
- stale mutable X/Twitter profile URLs
- missing canonical Gumroad link in key documentation
- reintroduced obsolete generic workflows
- accidental paid Master artifacts in the public tree

Added `scripts/run_all_tests.py` to reproduce standalone and companion package test commands locally.

## Recorded test results

### Standalone projects

- 10 projects
- 30/30 local unit tests passed before publication

### Advanced companion packages

- Part 110: 13/13
- Part 111: 18/18
- Part 112: 19/19
- Part 113: 12/12
- Part 114: 16/16
- Part 115: 16/16 + package verifier
- Part 116: 7/7 strict post-fix rerun with `ResourceWarning` treated as error
- Part 117: 9/9
- Part 118: 11/11
- Part 119: 13/13
- Part 120: 17/17

## Known limitations

1. Parts 1–102 companion packages are not yet published in this repository.
2. Passing Python/model/package tests does not mean every vendor-specific SQL statement has been executed against every database engine.
3. Some advanced packages contain PostgreSQL-specific behavior and must be tested against PostgreSQL when engine-level verification is required.
4. Part 119 and Part 120 large CSV assets were previously published in relay-safe, contract-preserving form because the connector truncated long source relay text; this limitation remains documented in `CHECKSUM_NOTES.md`.
5. Targeted C/C++/Rust/Go CI for Parts 103–105 is deferred until each package can be cleanly built/tested in the available execution environment.
6. The GitHub connector used during this audit did not expose the repository-wide Actions run-list endpoint, so workflow configuration is not treated as proof that every newly configured run is green.
7. No non-trivial software repository can truthfully guarantee that undiscovered future defects are impossible. The release target is zero known release-blocking defects under the defined validation gates.

## Release gate

The repository should be considered release-ready only when:

```bash
python scripts/validate_repository.py
python scripts/run_all_tests.py --standalone
python scripts/run_all_tests.py --companion
```

pass in a clean checkout and the maintained GitHub Actions checks are green.

See `RELEASE_CHECKLIST.md` for the complete gate.
