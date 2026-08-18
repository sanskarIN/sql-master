# Schema Quality Auditor

A lightweight educational SQL schema reviewer that flags common design smells without connecting to a live database.

Checks include missing visible primary keys, `SELECT *`, and money-like floating-point columns. It is a learning aid, not a full SQL parser.

```bash
python cli.py examples/problematic_schema.sql
python -m unittest discover -s tests
```

Official store: **https://ramsandesh.gumroad.com**
