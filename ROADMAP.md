# SQL Full Mastery Companion Repository Roadmap

Official store: **https://ramsandesh.gumroad.com**

## Completed

- [x] Publish advanced companion range Parts 103–120.
- [x] Add package-level documentation and tests for Parts 110–120.
- [x] Add repository security, contribution, support, licensing, and CI guidance.
- [x] Keep paid Master PDF/DOCX/EPUB files out of the public repository.
- [x] Add a separate `projects/` portfolio for independent learning projects.
- [x] Publish 10 standalone SQL/database projects with 30 passing local unit tests.
- [x] Add standalone-project CI, project catalog, and machine-readable status.
- [x] Remove invalid root-level C/C++/CMake/Make/MSBuild/Rust/SLSA starter workflows.
- [x] Add repository-aware CodeQL, companion, standalone-project, and repository-quality workflows.
- [x] Add repository validator and unified local test runner.
- [x] Correct repository documentation to reflect the actual published range: Parts 103–120.
- [x] Fix Part 111 relay/transcription identifier issue.
- [x] Fix Part 116 unclosed CSV test handles and refresh its checksum manifest.
- [x] Add complete architecture, testing, development, troubleshooting, compatibility, maintenance, release, and audit documentation.
- [x] Add Dependabot, CODEOWNERS, PR/issue templates, funding links, editor rules, and Git attributes.
- [x] Keep mutable X/Twitter profile URLs out of permanent repository/publication metadata.

## Remaining publication work

- [ ] Recover, audit, and publish companion-code packages for Parts 1–102.
- [ ] Replace relay-safe Part 119/120 CSV banks with byte-identical originals if a reliable binary/file-transfer route becomes available.
- [ ] Add targeted language CI for Part 103 (C/C++), Part 104 (Rust), and Part 105 (Go) only after each package has a clean verified build/test contract in the available execution environment.
- [ ] Add tagged releases after a public release-artifact/checksum policy is finalized and the maintained CI gates are green.

## Standalone-project direction

Future projects should remain independent, test-backed, and clearly scoped. Strong candidates include:

- PostgreSQL migration and rollback laboratory
- ETL pipeline quality checker
- query benchmark harness
- database observability data model
- CDC/event-outbox practice project
- SQL interview challenge runner
- index selectivity simulator
- schema-diff reporter

## Release quality target

The repository target is **zero known release-blocking defects under the defined test/validation gates**, not an unverifiable promise that future bugs are impossible.

Before a release, follow `docs/RELEASE_CHECKLIST.md` and run:

```bash
python scripts/validate_repository.py
python scripts/run_all_tests.py --standalone
python scripts/run_all_tests.py --companion
```

## Publishing boundary

The commercial Master PDF, editable DOCX, EPUB, and private publishing assets remain outside this public code repository. Purchase/distribution information belongs at **https://ramsandesh.gumroad.com**.
