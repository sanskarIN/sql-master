DATABASE_URL ?= postgresql://postgres:postgres@localhost:55432/atlasops

.PHONY: reset schema seed commands sql-test model-test verify

schema:
	psql "$(DATABASE_URL)" -v ON_ERROR_STOP=1 -f sql/01_schema.sql

seed:
	psql "$(DATABASE_URL)" -v ON_ERROR_STOP=1 -f sql/02_seed.sql

commands:
	psql "$(DATABASE_URL)" -v ON_ERROR_STOP=1 -f sql/03_commands.sql

reset:
	psql "$(DATABASE_URL)" -v ON_ERROR_STOP=1 -c "DROP SCHEMA IF EXISTS audit, integration, ledger, commerce, booking, inventory, catalog, core CASCADE;"
	$(MAKE) schema seed commands

sql-test:
	psql "$(DATABASE_URL)" -v ON_ERROR_STOP=1 -f sql/07_invariant_tests.sql

model-test:
	python -m unittest -v tests.test_capstone_model
	python tests/verify_package.py

verify: model-test
