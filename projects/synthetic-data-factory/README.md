# Synthetic Data Factory

A deterministic, dependency-free generator for fictional customer/order practice data.

It creates synthetic records only and uses the reserved `example.invalid` domain for generated emails.

```bash
python generate.py --rows 100 --seed 42 --out demo.csv
python -m unittest discover -s tests
```

Official store: **https://ramsandesh.gumroad.com**
