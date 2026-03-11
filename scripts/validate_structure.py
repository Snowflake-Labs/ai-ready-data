#!/usr/bin/env python3
"""Validate multi-platform repository structure guardrails."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REQ_ROOT = ROOT / "skills" / "ai-ready-data" / "requirements"
INDEX_FILE = REQ_ROOT / "index.yaml"


def fail(msg: str) -> None:
    print(f"ERROR: {msg}")


def check_index() -> int:
    if not INDEX_FILE.exists():
        fail(f"Missing requirement index: {INDEX_FILE.relative_to(ROOT)}")
        return 1
    return 0


def check_snowflake_impl_presence() -> int:
    errors = 0
    for req_yaml in sorted(REQ_ROOT.glob("*/requirement.yaml")):
        req_dir = req_yaml.parent
        impl_check = req_dir / "implementations" / "snowflake" / "check.sql"
        if not impl_check.exists():
            fail(f"Missing snowflake check implementation: {impl_check.relative_to(ROOT)}")
            errors += 1
    return errors


def check_no_root_sql() -> int:
    errors = 0
    for req_yaml in sorted(REQ_ROOT.glob("*/requirement.yaml")):
        req_dir = req_yaml.parent
        for legacy_sql in sorted(req_dir.glob("*.sql")):
            fail(f"Legacy root SQL file is not allowed: {legacy_sql.relative_to(ROOT)}")
            errors += 1
    return errors


def check_skill_mirror() -> int:
    cmd = [sys.executable, str(ROOT / "scripts" / "sync_skill_mirrors.py"), "--check"]
    result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        print(result.stdout.strip())
        print(result.stderr.strip())
        return 1
    return 0


def check_databricks_pilot() -> int:
    pilot_requirements = [
        "semantic_documentation",
        "classification",
        "lineage_completeness",
    ]
    errors = 0
    for req in pilot_requirements:
        check_path = (
            REQ_ROOT / req / "implementations" / "databricks" / "check.sql"
        )
        if not check_path.exists():
            fail(f"Missing Databricks pilot check: {check_path.relative_to(ROOT)}")
            errors += 1
    return errors


def main() -> int:
    errors = 0
    errors += check_index()
    errors += check_snowflake_impl_presence()
    errors += check_no_root_sql()
    errors += check_skill_mirror()
    errors += check_databricks_pilot()
    if errors:
        print(f"\nStructure validation failed with {errors} issue(s).")
        return 1
    print("Structure validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
