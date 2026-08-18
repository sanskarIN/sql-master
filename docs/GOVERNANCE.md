# Repository Governance

`sql-master` is maintained as an educational companion-code and database-project repository.

## Maintainer authority

The repository owner/maintainer has final responsibility for:

- accepting or rejecting changes
- repository structure
- published companion ranges
- release tagging
- license boundaries
- security response
- public/private publishing boundaries

`CODEOWNERS` defines the default review owner for repository paths.

## Contribution principles

Changes should be:

- technically justified
- independently testable where practical
- documented
- scoped to the affected Part/project
- free of secrets and private data
- compatible with the permanent-link policy

## Commit policy

Prefer many small, coherent commits when work naturally separates into independent changes. Do not create empty or meaningless commits merely to increase commit count.

Good examples:

- `fix(part-111): correct receiving line identifier`
- `test(project): add overlap regression case`
- `docs: clarify PostgreSQL execution scope`
- `ci: add repository-relative link validation`

## Compatibility

Do not force all Part projects into one dependency graph. Each Part/project may have its own database engine, language, runtime, and build instructions.

## Disputes and review

Technical disagreements should be resolved through reproducible examples, documentation, tests, and clearly stated trade-offs. Security reports follow `../SECURITY.md`.

## Commercial/public boundary

The MIT license applies to repository source code where stated. Paid manuscripts and commercial publishing assets remain under their separate book-license terms.

Official store: **https://ramsandesh.gumroad.com**
