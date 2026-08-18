# Data Safety and Privacy Guide

The repository is educational. Examples should prefer synthetic or intentionally public data and should not require uploading private databases.

## Core rules

- Never commit passwords, API keys, database URLs containing credentials, private certificates, access tokens, or production `.env` files.
- Never commit real customer exports, private backups, payment data, private email lists, or other personal datasets.
- Use synthetic examples such as `example.invalid` addresses where practical.
- Keep production backups outside the repository.
- Treat database dumps as sensitive until proven otherwise.
- Redact secrets before sharing logs or query plans.

## Database examples

When creating sample data:

- use fictional names and identifiers
- use integer minor currency units where appropriate
- avoid realistic government IDs, card numbers, passwords, or authentication secrets
- keep datasets small enough for review

## Backups

The `backup-manifest-verifier` project checks file integrity; it does not prove that a backup is logically correct or safe to publish. Restore tests and application invariants remain necessary.

## Logs and diagnostics

Do not paste production SQL logs into public issues without checking for:

- credentials
- customer names/emails
- tokens/session IDs
- internal hostnames
- sensitive query parameters

## Public repository boundary

The complete paid Master PDF/DOCX/EPUB and buyer delivery packages stay outside this public source repository.

## Security reports

Follow `../SECURITY.md` for vulnerabilities. Do not disclose exploitable secrets or private datasets in public issues.

Official store: **https://ramsandesh.gumroad.com**
