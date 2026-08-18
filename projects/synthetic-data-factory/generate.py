from __future__ import annotations
import argparse, csv, random
from pathlib import Path

FIRST = ["Aarav","Diya","Ishaan","Meera","Kabir","Tara","Rohan","Nisha"]
CITY = ["Delhi","Mumbai","Lucknow","Pune","Jaipur","Bengaluru"]

def rows(count=100, seed=42):
    rng = random.Random(seed)
    for i in range(1, count+1):
        first = rng.choice(FIRST)
        city = rng.choice(CITY)
        yield {
            "customer_id": i,
            "name": f"{first} Demo{i:04d}",
            "email": f"demo{i:04d}@example.invalid",
            "city": city,
            "lifetime_value_paise": rng.randrange(0, 500_001),
        }

def write_csv(path, count=100, seed=42):
    data = list(rows(count, seed))
    fields = data[0].keys() if data else ["customer_id","name","email","city","lifetime_value_paise"]
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(data)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rows", type=int, default=100)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--out", default="synthetic_customers.csv")
    a = ap.parse_args()
    write_csv(Path(a.out), a.rows, a.seed)

if __name__ == "__main__":
    main()
