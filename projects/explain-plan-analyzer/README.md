# EXPLAIN Plan Analyzer

An educational parser for PostgreSQL-style text EXPLAIN output.

It summarizes plan nodes and highlights potentially expensive patterns such as sequential scans, disk-spilling sorts, and nested loops. These operators are not automatically bad; the tool is designed to prompt evidence-based review.

```bash
python cli.py examples/slow_plan.txt
python -m unittest discover -s tests
```

Official store: **https://ramsandesh.gumroad.com**
