# Concurrency Note

This project is a SQLite teaching demo. The overlap check and insert are performed in one transaction, but production booking systems with high write concurrency should use database-native exclusion or locking strategies appropriate to their database engine.

For PostgreSQL, an exclusion constraint over a range type is a strong option when the business rule is “no overlapping active bookings for the same resource.”
