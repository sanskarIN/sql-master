from __future__ import annotations
from pathlib import Path
import argparse, re

PATTERN = re.compile(r"^(\d{3,})_[a-zA-Z0-9][a-zA-Z0-9_-]*\.sql$")

def inspect(directory: str | Path):
    directory = Path(directory)
    entries, invalid = [], []
    for path in sorted(directory.iterdir()):
        if not path.is_file():
            continue
        m = PATTERN.match(path.name)
        if not m:
            invalid.append(path.name)
            continue
        entries.append((int(m.group(1)), path.name))
    numbers = [n for n, _ in entries]
    duplicates = sorted({n for n in numbers if numbers.count(n) > 1})
    missing = []
    if numbers:
        expected = range(min(numbers), max(numbers) + 1)
        missing = [n for n in expected if n not in set(numbers)]
    return {"entries": entries, "invalid": invalid, "duplicates": duplicates, "missing": missing}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("directory")
    args = ap.parse_args()
    result = inspect(args.directory)
    print(result)
    raise SystemExit(1 if result["invalid"] or result["duplicates"] or result["missing"] else 0)

if __name__ == "__main__":
    main()
