# Known Limitations

This repository is intentionally transparent about what has and has not been verified.

## Companion coverage

- The public repository currently publishes companion material for Parts **103–120**.
- Parts **1–102** are not yet published here, so no public-repository completeness claim is made for that range.

## Database-engine execution

Many advanced packages include PostgreSQL-oriented SQL and cross-dialect discussion. A passing Python/model/package test does not prove that every SQL statement was executed against every database engine.

Where engine execution was not performed, documentation should say so.

## Cross-dialect portability

PostgreSQL, SQLite, MySQL, SQL Server, and Oracle differ in:

- data types
- identity/sequence syntax
- date/time functions
- upsert syntax
- locking and isolation behavior
- indexing features
- JSON support
- recursive/analytic capabilities

Examples should be treated according to their documented dialect.

## Standalone projects

The standalone projects are educational reference implementations. They are intentionally small and do not claim to include every production feature such as authentication, horizontal scaling, managed-secret integration, or high-availability deployment.

## Static analysis

The Schema Quality Auditor and EXPLAIN Plan Analyzer use lightweight educational heuristics rather than full vendor SQL parsers. Their findings require engineering judgment.

## Backup verification

File hashes verify byte integrity, not logical database correctness. A backup still needs a restore test and application-level validation.

## Booking demo

The SQLite Booking Calendar demonstrates interval logic but does not replace stronger database-native concurrency controls required by high-contention production booking systems.

## Security

CodeQL and tests reduce risk but do not prove that no vulnerability or bug exists. Security-sensitive deployments need environment-specific review.

## Publication boundary

Paid book files are intentionally outside the public source repository.

Official store: **https://ramsandesh.gumroad.com**
