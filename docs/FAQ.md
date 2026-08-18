# Frequently Asked Questions

## Is the complete SQL Full Mastery book stored in this repository?

No. The public repository contains companion code, labs, documentation, and standalone projects. The paid Master PDF/DOCX/EPUB is intentionally kept outside the public repo.

## Where can I get the book?

Official store: **https://ramsandesh.gumroad.com**

## Why are only Parts 103–120 published here?

Those are the companion packages currently available in the public repository. Parts 1–102 should not be described as published here until their actual companion material is added and validated.

## Why are the Parts not one giant application?

Different Parts use different languages, database engines, dependencies, and teaching goals. Keeping them independent prevents dependency conflicts and preserves each Part's original context.

## How do I run all tests?

```bash
python scripts/run_all_tests.py
```

Run only standalone projects:

```bash
python scripts/run_all_tests.py --standalone
```

Run only advanced companion packages:

```bash
python scripts/run_all_tests.py --companion
```

## Does a passing Python test prove PostgreSQL/MySQL/Oracle/SQL Server syntax works?

No. Model/static tests and actual database-engine execution are different validation levels. The repository documentation is expected to state the real scope.

## Can I contribute a new project?

Yes. Read `CONTRIBUTING.md`, `ADDING_A_PROJECT.md`, `STYLE_GUIDE.md`, and `QUALITY_GATES.md` first.

## Can I put real customer data in an issue or sample?

No. Use synthetic/redacted data and follow `DATA_SAFETY.md`.

## Why is there no permanent X/Twitter profile URL?

Mutable social handles can become stale in purchased copies and long-lived metadata. The repository intentionally uses more stable canonical links instead.

## What license applies?

Repository source code is MIT-licensed where stated. Paid book/manuscript/publishing assets use their separate book-license terms; see `LICENSE` and `BOOK_LICENSE.md`.
