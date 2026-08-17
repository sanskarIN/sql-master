# SQL Full Mastery - Part 116 Companion Package

**Title:** Beginner SQL Interview Questions with Explanations  
**Author:** Ram Sandesh  
**Edition:** August 2026

## Contents

- `sql/01_schema.sql` - compact PostgreSQL interview schema
- `sql/02_seed.sql` - deterministic sample data
- `sql/03_practice_questions.sql` - guided query prompts
- `sql/04_selected_solutions.sql` - selected reference solutions
- `workbook/flashcards.csv` - 60 question-answer flashcards
- `workbook/mock_interview.md` - timed ten-question interview
- `workbook/answer_framework.md` - five-step response framework and rubric
- `tools/self_check.py` - dependency-free flashcard quiz and package checks
- `tests/test_package.py` - dependency-free contract tests

## Quick start

```bash
python tools/self_check.py --check-package
python -m unittest discover -s tests -v
```

For PostgreSQL practice:

```bash
psql -f sql/01_schema.sql
psql -f sql/02_seed.sql
psql -f sql/03_practice_questions.sql
```

The schema and questions are educational. Review syntax and behavior against the exact database engine and version used in an interview.
