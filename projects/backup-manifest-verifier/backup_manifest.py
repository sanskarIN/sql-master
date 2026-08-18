from __future__ import annotations
import argparse, hashlib, json
from pathlib import Path

def sha256(path: Path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024*1024), b""):
            h.update(chunk)
    return h.hexdigest()

def build(directory):
    root = Path(directory)
    return {
        "algorithm": "sha256",
        "files": {
            str(p.relative_to(root)).replace("\\","/"): {"size": p.stat().st_size, "sha256": sha256(p)}
            for p in sorted(root.rglob("*")) if p.is_file()
        },
    }

def verify(directory, manifest):
    root = Path(directory)
    expected = json.loads(Path(manifest).read_text(encoding="utf-8"))
    problems = []
    for rel, meta in expected["files"].items():
        p = root / rel
        if not p.exists():
            problems.append(f"missing:{rel}")
        elif p.stat().st_size != meta["size"] or sha256(p) != meta["sha256"]:
            problems.append(f"changed:{rel}")
    extras = sorted(str(p.relative_to(root)).replace("\\","/") for p in root.rglob("*") if p.is_file() and str(p.relative_to(root)).replace("\\","/") not in expected["files"])
    problems += [f"extra:{x}" for x in extras]
    return problems

def main():
    ap = argparse.ArgumentParser()
    sp = ap.add_subparsers(dest="cmd", required=True)
    c = sp.add_parser("create"); c.add_argument("directory"); c.add_argument("manifest")
    v = sp.add_parser("verify"); v.add_argument("directory"); v.add_argument("manifest")
    a = ap.parse_args()
    if a.cmd == "create":
        Path(a.manifest).write_text(json.dumps(build(a.directory), indent=2)+"\n", encoding="utf-8")
    else:
        problems = verify(a.directory, a.manifest)
        print("\n".join(problems) if problems else "OK")
        raise SystemExit(1 if problems else 0)

if __name__ == "__main__":
    main()
