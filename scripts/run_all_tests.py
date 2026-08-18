from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

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
    for entry in status["projects"]:
        project = ROOT / "projects" / entry["name"]
        command = [sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"]
        if not run_command(command, project):
            ok = False
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
        ok = run_standalone() and run_companion()

    print("\nALL REQUESTED TESTS PASSED" if ok else "\nONE OR MORE TEST SUITES FAILED")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
