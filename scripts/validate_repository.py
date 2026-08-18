from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STORE = "https://ramsandesh.gumroad.com"
MUTABLE_SOCIAL_URL = re.compile(r"https?://(?:www\.)?(?:x|twitter)\.com/", re.IGNORECASE)
TEXT_SUFFIXES = {".md", ".txt", ".json", ".py", ".sql", ".yml", ".yaml", ".toml"}


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def load_json(path: Path, errors: list[str]):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # validator should report malformed metadata cleanly
        fail(errors, f"invalid JSON: {path.relative_to(ROOT)}: {exc}")
        return None


def main() -> int:
    errors: list[str] = []

    required_root = [
        "README.md",
        "LICENSE",
        "BOOK_LICENSE.md",
        "CHANGELOG.md",
        "CODE_OF_CONDUCT.md",
        "CONTRIBUTING.md",
        "CURRENT_STATUS.md",
        "ROADMAP.md",
        "SECURITY.md",
        "SUPPORT.md",
        "STORE_LINKS.md",
        "COMPANION_STATUS.json",
        "PROJECTS_STATUS.json",
    ]
    for rel in required_root:
        if not (ROOT / rel).is_file():
            fail(errors, f"missing required root file: {rel}")

    required_docs = [
        "docs/README.md",
        "docs/ARCHITECTURE.md",
        "docs/TESTING.md",
        "docs/DEVELOPMENT.md",
        "docs/TROUBLESHOOTING.md",
        "docs/RELEASE_CHECKLIST.md",
        "docs/FINAL_REPOSITORY_AUDIT.md",
        "docs/PERMANENT_LINK_POLICY.md",
    ]
    for rel in required_docs:
        if not (ROOT / rel).is_file():
            fail(errors, f"missing required documentation: {rel}")

    companion = load_json(ROOT / "COMPANION_STATUS.json", errors)
    if isinstance(companion, dict):
        published = companion.get("published_companion_range", {})
        first, last = published.get("first"), published.get("last")
        if (first, last) != (103, 120):
            fail(errors, "COMPANION_STATUS published range must be 103-120")
        for part in range(103, 121):
            if not (ROOT / "code" / f"part-{part:03d}").is_dir():
                fail(errors, f"missing published companion directory: code/part-{part:03d}")
        if companion.get("official_store") != STORE:
            fail(errors, "COMPANION_STATUS official_store is not canonical")
        if companion.get("mutable_social_links_in_permanent_metadata") is not False:
            fail(errors, "COMPANION_STATUS must disable mutable social links")

    projects = load_json(ROOT / "PROJECTS_STATUS.json", errors)
    if isinstance(projects, dict):
        entries = projects.get("projects", [])
        if projects.get("count") != len(entries):
            fail(errors, "PROJECTS_STATUS count does not match project entries")
        if len(entries) != 10:
            fail(errors, f"expected 10 standalone projects, found {len(entries)}")
        for entry in entries:
            name = entry.get("name")
            if not name:
                fail(errors, "project entry missing name")
                continue
            p = ROOT / "projects" / name
            if not p.is_dir():
                fail(errors, f"missing standalone project directory: projects/{name}")
                continue
            if not (p / "README.md").is_file():
                fail(errors, f"project missing README: projects/{name}")
            if not (p / "tests").is_dir():
                fail(errors, f"project missing tests directory: projects/{name}")
        if projects.get("official_store") != STORE:
            fail(errors, "PROJECTS_STATUS official_store is not canonical")

    for rel in ["README.md", "STORE_LINKS.md", "SUPPORT.md"]:
        path = ROOT / rel
        if path.is_file() and STORE not in path.read_text(encoding="utf-8"):
            fail(errors, f"canonical store link missing from {rel}")

    for path in ROOT.rglob("*"):
        if not path.is_file() or ".git" in path.parts or path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if MUTABLE_SOCIAL_URL.search(text):
            fail(errors, f"mutable X/Twitter URL found: {path.relative_to(ROOT)}")

    forbidden_workflows = {
        "c-cpp.yml",
        "cmake-multi-platform.yml",
        "cmake-single-platform.yml",
        "generator-generic-ossf-slsa3-publish.yml",
        "makefile.yml",
        "msbuild.yml",
        "rust.yml",
    }
    workflows = ROOT / ".github" / "workflows"
    for name in forbidden_workflows:
        if (workflows / name).exists():
            fail(errors, f"obsolete generic workflow still present: {name}")

    required_workflows = {
        "codeql.yml",
        "companion-python-tests.yml",
        "standalone-projects-python.yml",
        "repository-quality.yml",
    }
    for name in required_workflows:
        if not (workflows / name).is_file():
            fail(errors, f"required workflow missing: {name}")

    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        low = path.name.lower()
        if "complete_120_part_master" in low or "complete-120-part-master" in low:
            fail(errors, f"paid master artifact appears in public tree: {path.relative_to(ROOT)}")

    if errors:
        print("Repository validation FAILED")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Repository validation PASSED")
    print("- required documentation present")
    print("- published companion range 103-120 present")
    print("- 10 standalone projects present")
    print("- metadata JSON valid")
    print("- permanent-link policy clean")
    print("- workflow policy clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
