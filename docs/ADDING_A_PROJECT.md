# Adding a Standalone Project

Standalone projects live under `projects/` and must remain independent from the Part companion packages.

## Required structure

```text
projects/<project-name>/
├── README.md
├── tests/
└── source files
```

A project may add SQL, Python, configuration, fixtures, or other files as needed.

## Requirements

1. Use a descriptive lowercase-kebab-case directory name.
2. Add a project README containing purpose, requirements, run commands, test commands, limitations, and the official Gumroad store link.
3. Add meaningful automated tests where practical.
4. Do not commit secrets, private data, production database dumps, or paid book files.
5. Use synthetic datasets for demonstrations whenever practical.
6. Keep external dependencies minimal and documented.
7. Add the project to `PROJECTS_STATUS.json` with its real test count.
8. Add the project to `projects/README.md` and the standalone-project catalog.
9. Add it to `.github/workflows/standalone-projects-python.yml` when it uses the standard Python test layout.
10. Run repository validation and all relevant tests before merging.

## Validation

```bash
python scripts/validate_repository.py
python scripts/check_relative_links.py
python scripts/run_all_tests.py --standalone
```

The repository validator compares actual project directories with `PROJECTS_STATUS.json`, so undeclared directories and stale metadata are treated as errors.

## Commit style

Prefer separate meaningful commits for scaffold, core implementation, tests, documentation, and CI integration when those are independently reviewable.

Official store: **https://ramsandesh.gumroad.com**
