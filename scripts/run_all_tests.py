from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEST_COUNT_RE = re.compile(r"Ran\s+(\d+)\s+tests?")

COMPANION_COMMANDS = {
    110: [[sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"]],
    111: [[sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"]],
    112: [[sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"]],
    113: [[sys.executable, "-m", "unittest", "-v", "test_warehouse_model.py"]],
    114: [[sys.executable, "-m", "unittest", "-v", "test_saas_model.py"]],
    115: [
        [sys.executable, "-m", "unittest", "-v", "tests.test_capstone_model"],
        [sys.executable, "tests/verify_package.py"],
    ],
    116: [[sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"]],
    117: [[sys.executable, "test_contracts.py"]],
    118: [[sys.executable, "scripts/package_tests.py"]],
    119: [[sys.executable, "model_tests.py"]],
    120: [[sys.executable, "model_tests.py"]],
}


def run_command(command: list[str], cwd: Path) -> bool:
    print(f"\n==> {cwd.relative_to(ROOT)} :: {' '.join(command)}")
    result = subprocess.run(command, cwd=cwd, check=False)
    return result.returncode == 0


def run_standalone() -> bool:
    status = json.loads((ROOT / "PROJECTS_STATUS.json").read_text(encoding="utf-8"))
    ok = True
    total_tests = 0

    for entry in status["projects"]:
        project = ROOT / "projects" / entry["name"]
        command = [sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"]
        print(f"\n==> {project.relative_to(ROOT)} :: {' '.join(command)}")
        result = subprocess.run(
            command,
            cwd=project,
            check=False,
            text=True,
            capture_output=True,
        )
        output = (result.stdout or "") + (result.stderr or "")
        if output:
            print(output, end="" if output.endswith("\n") else "\n")

        match = TEST_COUNT_RE.search(output)
        actual = int(match.group(1)) if match else None
        expected = entry.get("tests")

        if result.returncode != 0:
            print(f"FAIL {entry['name']}: unittest command returned {result.returncode}")
            ok = False
            continue
        if actual is None:
            print(f"FAIL {entry['name']}: could not determine discovered test count")
            ok = False
            continue
        if actual != expected:
            print(f"FAIL {entry['name']}: expected {expected} tests but discovered {actual}")
            ok = False
            continue

        total_tests += actual
        print(f"PASS {entry['name']}: {actual}/{expected} declared tests")

    if ok:
        print(f"\nStandalone summary: {len(status['projects'])} projects / {total_tests} tests passed")
    return ok


def run_companion() -> bool:
    ok = True
    for part, commands in COMPANION_COMMANDS.items():
        workdir = ROOT / "code" / f"part-{part:03d}" / "src"
        if not workdir.is_dir():
            print(f"Missing companion workdir: {workdir.relative_to(ROOT)}")
            ok = False
            continue
        for command in commands:
            if not run_command(command, workdir):
                ok = False
    return ok


def main() -> int:
    parser = argparse.ArgumentParser(description="Run sql-master package test suites.")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--standalone", action="store_true", help="run only standalone projects")
    group.add_argument("--companion", action="store_true", help="run only Parts 110-120")
    args = parser.parse_args()

    if args.standalone:
        ok = run_standalone()
    elif args.companion:
        ok = run_companion()
    else:
        standalone_ok = run_standalone()
        companion_ok = run_companion()
        ok = standalone_ok and companion_ok

    print("\nALL REQUESTED TESTS PASSED" if ok else "\nONE OR MORE TEST SUITES FAILED")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
