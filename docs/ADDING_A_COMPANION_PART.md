# Adding a Companion Part

Each book Part must remain an independent companion package under `code/part-XXX/`.

## Directory convention

```text
code/part-XYZ/
├── README.md
└── src/
    ├── README.md
    ├── SQL/source files
    ├── tests or package checks
    └── optional documentation
```

## Rules

- Use zero-padded Part directories such as `part-103`.
- Do not merge unrelated Part dependencies into one root application.
- Preserve the original Part intent and database dialect.
- Document database/runtime prerequisites.
- Include tests or validation scripts when practical.
- State clearly whether SQL was actually executed against PostgreSQL/MySQL/SQL Server/Oracle or only statically/model-tested.
- Keep companion code under the repository code license; do not copy paid book manuscript pages into the repo.
- Use synthetic/sample data rather than private data.
- Keep permanent metadata free of mutable X/Twitter URLs.

## Status metadata

When the public companion range changes, update:

- `COMPANION_STATUS.json`
- `CURRENT_STATUS.md`
- `README.md`
- relevant documentation/catalogs
- CI matrices when a new package has runnable tests

## Validation

Run:

```bash
python -m compileall -q scripts projects code
python scripts/validate_repository.py
python scripts/check_relative_links.py
python scripts/run_all_tests.py --companion
```

Add package-specific engine tests only when the required engine is available and the test genuinely executes it.

Official store: **https://ramsandesh.gumroad.com**
