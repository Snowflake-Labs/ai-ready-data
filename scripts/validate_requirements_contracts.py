#!/usr/bin/env python3
"""Validate requirement metadata and implementation contracts."""

from __future__ import annotations

import re
import sys
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
REQ_ROOT = ROOT / "skills" / "ai-ready-data" / "requirements"
PLAT_ROOT = ROOT / "skills" / "ai-ready-data" / "platforms"
INDEX_FILE = REQ_ROOT / "index.yaml"
CONFORMANCE_FIXTURE = ROOT / "tests" / "conformance" / "databricks-pilot.yaml"

REQUIRED_REQ_FIELDS = {"name", "description", "factor", "workload", "scope", "placeholders"}
VALID_FACTORS = {"clean", "contextual", "consumable", "current", "correlated", "compliant"}
PLATFORM_LEAK_PATTERNS = [
    r"\bsnowflake\b",
    r"\baccount_usage\b",
    r"\bresult_scan\b",
    r"\bshow\s+\w+",
    r"\bcurrent_role\s*\(",
    r"\bis_role_in_session\s*\(",
]
CHECK_VALUE_PAT = re.compile(r"\bas\s+value\b", re.IGNORECASE)


def fail(msg: str) -> None:
    print(f"ERROR: {msg}")


def load_yaml(path: Path) -> dict:
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    return data or {}


def get_platforms() -> set[str]:
    platforms: set[str] = set()
    for cap in sorted(PLAT_ROOT.glob("*/capabilities.yaml")):
        data = load_yaml(cap)
        platform = data.get("platform")
        if isinstance(platform, str) and platform:
            platforms.add(platform)
    return platforms


def check_requirement_schema(req_dir: Path) -> tuple[int, dict]:
    errors = 0
    req_yaml = req_dir / "requirement.yaml"
    data = load_yaml(req_yaml)

    missing = REQUIRED_REQ_FIELDS - set(data.keys())
    if missing:
        fail(f"{req_yaml.relative_to(ROOT)} missing fields: {sorted(missing)}")
        errors += 1

    name = data.get("name")
    if not isinstance(name, str) or not name:
        fail(f"{req_yaml.relative_to(ROOT)} has invalid name")
        errors += 1
    elif name != req_dir.name:
        fail(
            f"{req_yaml.relative_to(ROOT)} name '{name}' "
            f"must match directory '{req_dir.name}'"
        )
        errors += 1

    factor = data.get("factor")
    if factor not in VALID_FACTORS:
        fail(f"{req_yaml.relative_to(ROOT)} invalid factor '{factor}'")
        errors += 1

    workloads = data.get("workload")
    if not isinstance(workloads, list) or not workloads:
        fail(f"{req_yaml.relative_to(ROOT)} workload must be a non-empty list")
        errors += 1

    placeholders = data.get("placeholders")
    if not isinstance(placeholders, list) or not placeholders:
        fail(f"{req_yaml.relative_to(ROOT)} placeholders must be a non-empty list")
        errors += 1

    constraints = data.get("constraints", [])
    if constraints is None:
        constraints = []
    if not isinstance(constraints, list):
        fail(f"{req_yaml.relative_to(ROOT)} constraints must be a list")
        errors += 1
    else:
        for constraint in constraints:
            text = str(constraint)
            for pat in PLATFORM_LEAK_PATTERNS:
                if re.search(pat, text, flags=re.IGNORECASE):
                    fail(
                        f"{req_yaml.relative_to(ROOT)} has platform-specific constraint: "
                        f"'{text}'"
                    )
                    errors += 1
                    break

    return errors, data


def check_sql_contract(req_dir: Path, known_platforms: set[str]) -> tuple[int, list[str]]:
    errors = 0
    implementations: list[str] = []
    impl_root = req_dir / "implementations"
    if not impl_root.exists():
        fail(f"{req_dir.relative_to(ROOT)} missing implementations directory")
        return 1, implementations

    for impl in sorted(impl_root.iterdir()):
        if not impl.is_dir():
            continue
        platform = impl.name
        implementations.append(platform)
        if platform not in known_platforms:
            fail(
                f"{req_dir.relative_to(ROOT)} uses unknown platform "
                f"implementation '{platform}'"
            )
            errors += 1

        check_sql = impl / "check.sql"
        if not check_sql.exists():
            fail(f"Missing required check.sql: {check_sql.relative_to(ROOT)}")
            errors += 1
            continue
        text = check_sql.read_text(encoding="utf-8")
        if not CHECK_VALUE_PAT.search(text):
            fail(
                f"{check_sql.relative_to(ROOT)} must alias score as `value` "
                f"(expected `AS value`)"
            )
            errors += 1

    return errors, implementations


def check_index_consistency(requirements: dict[str, dict]) -> int:
    errors = 0
    if not INDEX_FILE.exists():
        fail(f"Missing requirement index: {INDEX_FILE.relative_to(ROOT)}")
        return 1

    index = load_yaml(INDEX_FILE)
    if index.get("version") != "v1":
        fail(f"{INDEX_FILE.relative_to(ROOT)} must set version: v1")
        errors += 1

    rows = index.get("requirements")
    if not isinstance(rows, list):
        fail(f"{INDEX_FILE.relative_to(ROOT)} requirements must be a list")
        return errors + 1

    seen: set[str] = set()
    for row in rows:
        if not isinstance(row, dict):
            fail(f"{INDEX_FILE.relative_to(ROOT)} has non-object row")
            errors += 1
            continue
        key = row.get("key")
        if not isinstance(key, str):
            fail(f"{INDEX_FILE.relative_to(ROOT)} row missing string key")
            errors += 1
            continue
        if key in seen:
            fail(f"{INDEX_FILE.relative_to(ROOT)} duplicate key '{key}'")
            errors += 1
            continue
        seen.add(key)

        expected = requirements.get(key)
        if expected is None:
            fail(f"{INDEX_FILE.relative_to(ROOT)} contains unknown requirement '{key}'")
            errors += 1
            continue

        if row.get("name") != expected["name"]:
            fail(f"Index name mismatch for {key}")
            errors += 1
        if row.get("factor") != expected["factor"]:
            fail(f"Index factor mismatch for {key}")
            errors += 1

        workload = row.get("workload") or []
        impls = row.get("implementations") or []
        if sorted(workload) != sorted(expected["workload"]):
            fail(f"Index workload mismatch for {key}")
            errors += 1
        if sorted(impls) != sorted(expected["implementations"]):
            fail(f"Index implementations mismatch for {key}")
            errors += 1

    missing = sorted(set(requirements.keys()) - seen)
    for key in missing:
        fail(f"{INDEX_FILE.relative_to(ROOT)} missing requirement '{key}'")
        errors += 1

    return errors


def check_databricks_pilot_fixture() -> int:
    errors = 0
    if not CONFORMANCE_FIXTURE.exists():
        fail(f"Missing conformance fixture: {CONFORMANCE_FIXTURE.relative_to(ROOT)}")
        return 1

    fixture = load_yaml(CONFORMANCE_FIXTURE)
    requirements = fixture.get("requirements", [])
    if not isinstance(requirements, list) or not requirements:
        fail(f"{CONFORMANCE_FIXTURE.relative_to(ROOT)} requirements must be non-empty")
        return 1

    for row in requirements:
        key = row.get("key")
        patterns = row.get("check_patterns", [])
        if not isinstance(key, str):
            fail(f"{CONFORMANCE_FIXTURE.relative_to(ROOT)} has requirement without key")
            errors += 1
            continue
        check_path = REQ_ROOT / key / "implementations" / "databricks" / "check.sql"
        diag_path = REQ_ROOT / key / "implementations" / "databricks" / "diagnostic.sql"
        if not check_path.exists():
            fail(f"Missing Databricks pilot check.sql: {check_path.relative_to(ROOT)}")
            errors += 1
            continue
        if not diag_path.exists():
            fail(f"Missing Databricks pilot diagnostic.sql: {diag_path.relative_to(ROOT)}")
            errors += 1
        check_text = check_path.read_text(encoding="utf-8")
        for pat in patterns:
            if re.search(str(pat), check_text, flags=re.IGNORECASE) is None:
                fail(
                    f"{check_path.relative_to(ROOT)} missing expected pattern "
                    f"from conformance fixture: {pat}"
                )
                errors += 1
    return errors


def main() -> int:
    errors = 0
    known_platforms = get_platforms()
    if not known_platforms:
        fail("No platform capability manifests found")
        return 1

    requirements: dict[str, dict] = {}
    for req_yaml in sorted(REQ_ROOT.glob("*/requirement.yaml")):
        req_dir = req_yaml.parent
        e1, data = check_requirement_schema(req_dir)
        e2, impls = check_sql_contract(req_dir, known_platforms)
        errors += e1 + e2
        requirements[req_dir.name] = {
            "name": data.get("name"),
            "factor": data.get("factor"),
            "workload": data.get("workload") or [],
            "implementations": impls,
        }

    errors += check_index_consistency(requirements)
    errors += check_databricks_pilot_fixture()

    if errors:
        print(f"\nRequirement contract validation failed with {errors} issue(s).")
        return 1
    print("Requirement contract validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
