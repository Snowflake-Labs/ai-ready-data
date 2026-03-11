#!/usr/bin/env python3
"""Normalize requirement SQL layout to platform-specific implementations.

Behavior:
- Ensures Snowflake implementation files exist by seeding from root SQL files
- Removes root SQL files so only platform implementations remain
- Generates requirements/index.yaml for deterministic discovery
"""

from __future__ import annotations

import shutil
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
REQ_ROOT = ROOT / "skills" / "ai-ready-data" / "requirements"
INDEX_FILE = REQ_ROOT / "index.yaml"


def parse_requirement_yaml(path: Path) -> tuple[str | None, str | None, list[str]]:
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    name = data.get("name")
    factor = data.get("factor")
    workloads = data.get("workload") or []
    if not isinstance(workloads, list):
        workloads = []
    return name, factor, [str(w) for w in workloads]


def detect_implementations(req_dir: Path) -> list[str]:
    impl_root = req_dir / "implementations"
    if not impl_root.exists():
        return []
    names = []
    for p in sorted(impl_root.iterdir()):
        if p.is_dir():
            names.append(p.name)
    return names


def prune_root_sql(req_dir: Path) -> int:
    deleted = 0
    for sql in sorted(req_dir.glob("*.sql")):
        sql.unlink()
        deleted += 1
    return deleted


def migrate_requirement(req_dir: Path) -> dict:
    impl_dir = req_dir / "implementations" / "snowflake"
    impl_dir.mkdir(parents=True, exist_ok=True)

    copied = 0
    for sql in sorted(req_dir.glob("*.sql")):
        target = impl_dir / sql.name
        if not target.exists():
            shutil.copy2(sql, target)
            copied += 1

    deleted_sql_files = prune_root_sql(req_dir)

    req_yaml = req_dir / "requirement.yaml"
    name, factor, workloads = parse_requirement_yaml(req_yaml)
    implementations = detect_implementations(req_dir)
    return {
        "key": req_dir.name,
        "name": name or req_dir.name,
        "factor": factor or "",
        "workload": workloads,
        "implementations": implementations,
        "copied_sql_files": copied,
        "deleted_root_sql_files": deleted_sql_files,
    }


def write_index(entries: list[dict]) -> None:
    lines: list[str] = []
    lines.append("version: v1")
    lines.append("requirements:")
    for entry in sorted(entries, key=lambda x: x["key"]):
        workloads = entry["workload"]
        workload_text = ", ".join(workloads)
        lines.append(f"  - key: {entry['key']}")
        lines.append(f"    name: {entry['name']}")
        lines.append(f"    factor: {entry['factor']}")
        lines.append(f"    workload: [{workload_text}]")
        impl_text = ", ".join(entry["implementations"]) if entry["implementations"] else ""
        lines.append(f"    implementations: [{impl_text}]")
    INDEX_FILE.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    if not REQ_ROOT.exists():
        raise SystemExit(f"Requirements root not found: {REQ_ROOT}")

    entries: list[dict] = []
    total_copied = 0
    total_deleted = 0
    for req_yaml in sorted(REQ_ROOT.glob("*/requirement.yaml")):
        req_dir = req_yaml.parent
        result = migrate_requirement(req_dir)
        entries.append(result)
        total_copied += result["copied_sql_files"]
        total_deleted += result["deleted_root_sql_files"]

    write_index(entries)
    print(
        f"Migrated {len(entries)} requirements; copied {total_copied} SQL files; "
        f"deleted {total_deleted} root SQL files; "
        f"wrote {INDEX_FILE.relative_to(ROOT)}"
    )


if __name__ == "__main__":
    main()
