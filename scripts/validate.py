#!/usr/bin/env python3
"""Validate framework structure against the multi-platform architecture."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
SKILL_ROOT = ROOT / "skills" / "ai-ready-data"
REQ_ROOT = SKILL_ROOT / "requirements"
PLAT_ROOT = SKILL_ROOT / "platforms"
WORKLOAD_ROOT = SKILL_ROOT / "workloads"
INDEX_FILE = REQ_ROOT / "index.yaml"

PLATFORMS = ["snowflake", "databricks", "aws", "azure"]
VALID_FACTORS = {"clean", "contextual", "consumable", "current", "correlated", "compliant"}
CHECK_VALUE_PAT = re.compile(r"\bas\s+value\b", re.IGNORECASE)

REQUIRED_DOCS = [
    ROOT / "CONTRIBUTING.md",
    ROOT / "AGENTS.md",
    ROOT / "README.md",
    SKILL_ROOT / "SKILL.md",
    ROOT / "docs" / "contracts" / "execution-contract.md",
    ROOT / "docs" / "PLATFORM_CONTRIBUTOR_SPEC.md",
]


def fail(msg: str) -> None:
    print(f"  ERROR: {msg}")


def load_yaml(path: Path) -> dict:
    return yaml.safe_load(path.read_text(encoding="utf-8")) or {}


def check_required_docs() -> int:
    print("Checking required docs...")
    errors = 0
    for path in REQUIRED_DOCS:
        if not path.exists():
            fail(f"Missing: {path.relative_to(ROOT)}")
            errors += 1
    return errors


def check_platform_refs() -> int:
    print("Checking platform references...")
    errors = 0
    for platform in PLATFORMS:
        flat = PLAT_ROOT / f"{platform.upper()}.md"
        nested = PLAT_ROOT / platform / f"{platform.upper()}.md"
        if not flat.exists() and not nested.exists():
            fail(f"Missing platform reference for {platform} (expected {flat.relative_to(ROOT)} or {nested.relative_to(ROOT)})")
            errors += 1
    return errors


def check_workload_profiles() -> int:
    print("Checking workload profiles...")
    errors = 0
    if not WORKLOAD_ROOT.exists():
        fail(f"Missing workloads directory: {WORKLOAD_ROOT.relative_to(ROOT)}")
        return 1
    for name in ["rag", "feature-serving", "training", "agents"]:
        path = WORKLOAD_ROOT / f"{name}.yaml"
        if not path.exists():
            fail(f"Missing workload profile: {path.relative_to(ROOT)}")
            errors += 1
    return errors


def check_requirement_index() -> int:
    print("Checking requirement index...")
    if not INDEX_FILE.exists():
        fail(f"Missing: {INDEX_FILE.relative_to(ROOT)}")
        return 1
    return 0


def check_no_root_sql() -> int:
    print("Checking for legacy root SQL files...")
    errors = 0
    for req_yaml in sorted(REQ_ROOT.glob("*/requirement.yaml")):
        for sql in sorted(req_yaml.parent.glob("*.sql")):
            fail(f"Legacy root SQL not allowed: {sql.relative_to(ROOT)}")
            errors += 1
    return errors


def check_snowflake_implementations() -> int:
    print("Checking Snowflake implementations...")
    errors = 0
    for req_yaml in sorted(REQ_ROOT.glob("*/requirement.yaml")):
        req_dir = req_yaml.parent
        check_sql = req_dir / "snowflake" / "check.sql"
        if not check_sql.exists():
            fail(f"Missing: {check_sql.relative_to(ROOT)}")
            errors += 1
            continue
        text = check_sql.read_text(encoding="utf-8")
        if not CHECK_VALUE_PAT.search(text):
            fail(f"{check_sql.relative_to(ROOT)} must alias score as `value`")
            errors += 1
    return errors


def check_requirement_metadata() -> int:
    print("Checking requirement metadata...")
    errors = 0
    required_fields = {"name", "description", "factor", "workload", "scope", "placeholders"}
    for req_yaml in sorted(REQ_ROOT.glob("*/requirement.yaml")):
        data = load_yaml(req_yaml)
        missing = required_fields - set(data.keys())
        if missing:
            fail(f"{req_yaml.relative_to(ROOT)} missing fields: {sorted(missing)}")
            errors += 1
        factor = data.get("factor")
        if factor and factor not in VALID_FACTORS:
            fail(f"{req_yaml.relative_to(ROOT)} invalid factor: {factor}")
            errors += 1
        name = data.get("name")
        if name and name != req_yaml.parent.name:
            fail(f"{req_yaml.relative_to(ROOT)} name '{name}' must match directory '{req_yaml.parent.name}'")
            errors += 1
    return errors


def check_no_old_structure() -> int:
    print("Checking for removed structure artifacts...")
    errors = 0
    old_paths = [
        SKILL_ROOT / "assessments",
        SKILL_ROOT / "reference",
        ROOT / "skills" / "build-assessment",
    ]
    for path in old_paths:
        if path.exists():
            fail(f"Old structure artifact still present: {path.relative_to(ROOT)}")
            errors += 1
    for platform in PLATFORMS:
        for old_file in ["capabilities.yaml", "gotchas.md", "README.md"]:
            path = PLAT_ROOT / platform / old_file
            if path.exists():
                fail(f"Old platform file still present: {path.relative_to(ROOT)}")
                errors += 1
    return errors


def check_skill_mirror() -> int:
    print("Checking skill mirror sync...")
    canonical = SKILL_ROOT / "SKILL.md"
    mirror = ROOT / ".agents" / "skills" / "ai-ready-data" / "SKILL.md"
    if not mirror.exists():
        fail(f"Missing mirror: {mirror.relative_to(ROOT)}")
        return 1
    if canonical.read_text(encoding="utf-8") != mirror.read_text(encoding="utf-8"):
        fail("Skill mirror is out of sync with canonical SKILL.md")
        return 1
    return 0


def main() -> int:
    errors = 0
    errors += check_required_docs()
    errors += check_platform_refs()
    errors += check_workload_profiles()
    errors += check_requirement_index()
    errors += check_no_root_sql()
    errors += check_snowflake_implementations()
    errors += check_requirement_metadata()
    errors += check_no_old_structure()
    errors += check_skill_mirror()

    print()
    if errors:
        print(f"Validation FAILED with {errors} issue(s).")
        return 1
    print("Validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
