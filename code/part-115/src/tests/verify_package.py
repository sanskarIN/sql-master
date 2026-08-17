from pathlib import Path
import re, sys
root=Path(__file__).resolve().parents[1]
required=[
 'README.md','docker-compose.yml','Makefile',
 'sql/01_schema.sql','sql/02_seed.sql','sql/03_commands.sql','sql/04_queries_and_indexes.sql',
 'sql/05_security.sql','sql/06_operations.sql','sql/07_invariant_tests.sql',
 'docs/ARCHITECTURE.md','docs/ADRS.md','docs/DATA_DICTIONARY.md','docs/MIGRATION_PLAN.md','docs/TEST_PLAN.md','docs/RUNBOOK.md',
 'tests/test_capstone_model.py'
]
missing=[p for p in required if not (root/p).exists()]
if missing: raise SystemExit('Missing: '+', '.join(missing))
schema=(root/'sql/01_schema.sql').read_text()
commands=(root/'sql/03_commands.sql').read_text()
checks={
 'tenant scoped product key': 'PRIMARY KEY (tenant_id, product_id)' in schema,
 'booking exclusion': 'EXCLUDE USING gist' in schema,
 'integer money': 'bigint' in schema.lower() and 'paise' in schema.lower(),
 'outbox uniqueness': 'aggregate_type, aggregate_id, event_version' in schema,
 'stock locking': 'FOR UPDATE' in commands,
 'idempotency conflict': commands.count('idempotency conflict') >= 2,
 'security definer search path': 'SECURITY DEFINER' in commands and 'SET search_path' in commands,
}
failed=[k for k,v in checks.items() if not v]
if failed: raise SystemExit('Contract checks failed: '+', '.join(failed))
print(f'PACKAGE VERIFICATION PASSED ({len(required)} required files, {len(checks)} contract checks)')
