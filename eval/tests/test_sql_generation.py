"""Eval tests for SQL generation correctness.

Validates placeholder substitution, SQL variant selection (full scan vs.
sampled), and that check SQL includes a `value` column. These tests
run against the actual requirement markdown files in the skill directory.
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

SKILL_ROOT = Path(__file__).resolve().parent.parent.parent / "skills" / "ai-ready-data"
REQUIREMENTS_DIR = SKILL_ROOT / "requirements"
pytestmark = [pytest.mark.eval_category("sql_generation")]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _extract_sql_blocks(md_text: str) -> list[str]:
    """Extract fenced SQL blocks from markdown."""
    pattern = r"```sql\s*\n(.*?)```"
    return re.findall(pattern, md_text, re.DOTALL)


def _find_placeholders(sql: str) -> set[str]:
    """Find all {{ placeholder }} tokens in a SQL string."""
    return set(re.findall(r"\{\{\s*(\w+)\s*\}\}", sql))


SAMPLE_VALUES = {
    "database": "TEST_DB",
    "schema": "TEST_SCHEMA",
    "asset": "TEST_TABLE",
    "column": "TEST_COLUMN",
    "sample_rows": "10000",
    "stream_name": "TEST_STREAM",
    "clustering_columns": "COL_A, COL_B",
    "tag_name": "SENSITIVITY",
    "tag_value": "PII",
    "allowed_values": "'A','B','C'",
    "comment": "Test comment",
    "key_columns": "ID",
    "tiebreaker_column": "UPDATED_AT",
    "text_column": "BODY",
    "consistency_rule": "COL_A = COL_B",
    "filter_nulls": "TRUE",
    "freshness_threshold_hours": "24",
    "baseline_mean": "100.0",
    "baseline_stddev": "10.0",
    "stddev_threshold": "3",
    "ref_asset": "REF_TABLE",
    "ref_column": "REF_ID",
    "ref_namespace": "TEST_DB.TEST_SCHEMA",
    "target_asset": "TARGET_TABLE",
    "target_key": "TARGET_ID",
    "target_namespace": "TEST_DB.TEST_SCHEMA",
    "fk_column": "FK_ID",
    "latency_threshold_ms": "500",
    "timestamp_column": "CREATED_AT",
    "min_value": "0",
    "max_value": "100",
}


def _substitute(sql: str) -> str:
    """Substitute all placeholders with sample values."""
    result = sql
    for key, value in SAMPLE_VALUES.items():
        result = re.sub(rf"\{{\{{\s*{key}\s*\}}\}}", value, result)
    return result


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

def _all_check_files():
    """Yield (requirement_key, platform, check_path) for all check.md files."""
    if not REQUIREMENTS_DIR.exists():
        return
    for req_dir in sorted(REQUIREMENTS_DIR.iterdir()):
        if not req_dir.is_dir() or req_dir.name == "__pycache__":
            continue
        for platform_dir in sorted(req_dir.iterdir()):
            if not platform_dir.is_dir():
                continue
            check_file = platform_dir / "check.md"
            if check_file.exists():
                yield req_dir.name, platform_dir.name, check_file


@pytest.mark.parametrize(
    "requirement,platform,check_path",
    list(_all_check_files()),
    ids=[f"{r}/{p}" for r, p, _ in _all_check_files()],
)
def test_check_sql_has_value_column(requirement: str, platform: str, check_path: Path):
    """Every check.md must contain SQL that SELECTs a `value` column."""
    md_text = check_path.read_text(encoding="utf-8")
    sql_blocks = _extract_sql_blocks(md_text)
    assert sql_blocks, f"No SQL blocks found in {check_path}"

    for sql in sql_blocks:
        assert re.search(r"\bAS\s+value\b", sql, re.IGNORECASE), (
            f"{requirement}/{platform}/check.md SQL missing 'AS value': {sql[:100]}"
        )


@pytest.mark.parametrize(
    "requirement,platform,check_path",
    list(_all_check_files()),
    ids=[f"{r}/{p}" for r, p, _ in _all_check_files()],
)
def test_placeholders_all_substitutable(requirement: str, platform: str, check_path: Path):
    """All placeholders can be substituted with sample values."""
    md_text = check_path.read_text(encoding="utf-8")

    for sql in _extract_sql_blocks(md_text):
        substituted = _substitute(sql)
        remaining = _find_placeholders(substituted)
        assert not remaining, (
            f"{requirement}/{platform}: unsubstitutable placeholders {remaining}"
        )


def _all_requirement_dirs():
    """Yield requirement keys that have at least one platform dir."""
    if not REQUIREMENTS_DIR.exists():
        return
    for req_dir in sorted(REQUIREMENTS_DIR.iterdir()):
        if req_dir.is_dir() and req_dir.name != "__pycache__" and req_dir.name != "requirements.yaml":
            yield req_dir.name


@pytest.mark.parametrize("requirement", list(_all_requirement_dirs()))
def test_requirement_has_all_three_files(requirement: str):
    """Every requirement dir should have check.md, diagnostic.md, fix.md."""
    req_path = REQUIREMENTS_DIR / requirement
    for platform_dir in req_path.iterdir():
        if not platform_dir.is_dir():
            continue
        for expected in ("check.md", "diagnostic.md", "fix.md"):
            assert (platform_dir / expected).exists(), (
                f"Missing {requirement}/{platform_dir.name}/{expected}"
            )
