#!/usr/bin/env python3
"""Move platform-specific requirement constraints into implementation docs."""

from __future__ import annotations

import re
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
REQ_ROOT = ROOT / "skills" / "ai-ready-data" / "requirements"
SNOWFLAKE_CONSTRAINTS_FILE = "constraints.md"

PLATFORM_PATTERNS = [
    r"\bsnowflake\b",
    r"\baccount_usage\b",
    r"\bresult_scan\b",
    r"\bshow\s+\w+",
    r"\bcurrent_role\s*\(",
    r"\bis_role_in_session\s*\(",
    r"\bcortex\b",
]


def is_platform_constraint(text: str) -> bool:
    return any(re.search(pat, text, flags=re.IGNORECASE) for pat in PLATFORM_PATTERNS)


def load_yaml(path: Path) -> dict:
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    return data or {}


def write_yaml(path: Path, data: dict) -> None:
    path.write_text(yaml.safe_dump(data, sort_keys=False), encoding="utf-8")


def append_constraints(path: Path, requirement_key: str, constraints: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    existing = path.read_text(encoding="utf-8") if path.exists() else "# Snowflake Constraints\n\n"
    key_header = f"## {requirement_key}"
    if key_header in existing:
        return
    lines = [existing.rstrip(), "", f"## {requirement_key}", ""]
    for c in constraints:
        lines.append(f"- {c}")
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    migrated = 0
    moved_constraints = 0
    for req_yaml in sorted(REQ_ROOT.glob("*/requirement.yaml")):
        req_dir = req_yaml.parent
        data = load_yaml(req_yaml)
        constraints = data.get("constraints") or []
        if not isinstance(constraints, list) or not constraints:
            continue

        generic: list[str] = []
        platform_specific: list[str] = []
        for c in constraints:
            text = str(c)
            if is_platform_constraint(text):
                platform_specific.append(text)
            else:
                generic.append(text)

        if not platform_specific:
            continue

        data["constraints"] = generic
        write_yaml(req_yaml, data)

        sf_constraints_path = (
            req_dir / "implementations" / "snowflake" / SNOWFLAKE_CONSTRAINTS_FILE
        )
        append_constraints(sf_constraints_path, req_dir.name, platform_specific)
        migrated += 1
        moved_constraints += len(platform_specific)

    print(
        f"Migrated platform constraints for {migrated} requirements; "
        f"moved {moved_constraints} constraints."
    )


if __name__ == "__main__":
    main()
