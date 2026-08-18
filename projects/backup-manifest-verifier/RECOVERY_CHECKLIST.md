# Recovery Verification Checklist

1. Confirm backup set and manifest belong to the same backup run.
2. Verify the SHA-256 manifest before restore.
3. Restore into a non-production environment first.
4. Run application invariants and row-count checks.
5. Verify permissions, extensions, scheduled jobs, and secrets separately.
6. Record restore duration and any manual steps.
7. Never treat a successful file checksum as proof that the logical database is valid.
