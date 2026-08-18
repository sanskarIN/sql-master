from pathlib import Path
import argparse
from auditor import summarize

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sql_file")
    args = ap.parse_args()
    for line in summarize(Path(args.sql_file).read_text(encoding="utf-8")):
        print(line)

if __name__ == "__main__":
    main()
