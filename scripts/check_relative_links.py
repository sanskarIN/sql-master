from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
EXTERNAL_PREFIXES = ("http://", "https://", "mailto:", "tel:", "#")


def normalize_target(raw: str) -> str:
    target = raw.strip()
    if target.startswith("<") and target.endswith(">"):
        target = target[1:-1]
    # Markdown permits an optional quoted title after the destination.
    if " " in target and not target.startswith("./") and not target.startswith("../"):
        target = target.split(" ", 1)[0]
    target = target.split("#", 1)[0].split("?", 1)[0]
    return unquote(target)


def main() -> int:
    errors: list[str] = []
    checked = 0
    root_resolved = ROOT.resolve()

    for markdown in sorted(ROOT.rglob("*.md")):
        if ".git" in markdown.parts:
            continue
        text = markdown.read_text(encoding="utf-8", errors="replace")
        for raw in LINK_RE.findall(text):
            target = normalize_target(raw)
            if not target or target.lower().startswith(EXTERNAL_PREFIXES):
                continue

            checked += 1
            candidate = (markdown.parent / target).resolve()
            try:
                candidate.relative_to(root_resolved)
            except ValueError:
                errors.append(
                    f"{markdown.relative_to(ROOT)}: repository-relative link escapes tree: {raw}"
                )
                continue

            if not candidate.exists():
                errors.append(
                    f"{markdown.relative_to(ROOT)}: missing relative target: {raw}"
                )

    if errors:
        print("Relative-link validation FAILED")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"Relative-link validation PASSED: {checked} internal targets checked")
    return 0


if __name__ == "__main__":
    sys.exit(main())
