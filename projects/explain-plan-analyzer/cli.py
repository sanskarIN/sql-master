from pathlib import Path
import argparse, json
from plan_analyzer import analyze

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("plan")
    args = ap.parse_args()
    print(json.dumps(analyze(Path(args.plan).read_text(encoding="utf-8")), indent=2))

if __name__ == "__main__":
    main()
