#!/usr/bin/env python3
"""Generate requirement/platform support matrix artifacts."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
REQ_ROOT = ROOT / "skills" / "ai-ready-data" / "requirements"
PLAT_ROOT = ROOT / "skills" / "ai-ready-data" / "platforms"
OUT_MD = ROOT / "docs" / "support-matrix.md"
OUT_JSON = ROOT / "docs" / "support-matrix.json"


def load_yaml(path: Path) -> dict:
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    return data or {}


def collect_platforms() -> list[str]:
    platforms: list[str] = []
    for cap in sorted(PLAT_ROOT.glob("*/capabilities.yaml")):
        data = load_yaml(cap)
        platform = data.get("platform")
        if isinstance(platform, str):
            platforms.append(platform)
    return sorted(set(platforms))


def collect_rows() -> list[dict]:
    rows: list[dict] = []
    for req_yaml in sorted(REQ_ROOT.glob("*/requirement.yaml")):
        req_dir = req_yaml.parent
        data = load_yaml(req_yaml)
        impls = []
        for p in sorted((req_dir / "implementations").glob("*")):
            if p.is_dir():
                impls.append(p.name)
        rows.append(
            {
                "key": req_dir.name,
                "factor": data.get("factor"),
                "workload": data.get("workload") or [],
                "implementations": sorted(impls),
            }
        )
    return rows


def build_markdown(platforms: list[str], rows: list[dict]) -> str:
    counts = {p: 0 for p in platforms}
    for row in rows:
        for p in row["implementations"]:
            if p in counts:
                counts[p] += 1

    lines: list[str] = []
    lines.append("# Support Matrix")
    lines.append("")
    lines.append(f"- Total requirements: {len(rows)}")
    lines.append("")
    lines.append("## Coverage by Platform")
    lines.append("")
    lines.append("| Platform | Implemented Requirements |")
    lines.append("|---|---:|")
    for p in platforms:
        lines.append(f"| {p} | {counts[p]} |")

    lines.append("")
    lines.append("## Requirement Coverage")
    lines.append("")
    lines.append("| Requirement | Factor | Workload | Implementations |")
    lines.append("|---|---|---|---|")
    for row in rows:
        workload = ", ".join(row["workload"])
        impls = ", ".join(row["implementations"])
        lines.append(f"| {row['key']} | {row['factor']} | {workload} | {impls} |")
    lines.append("")
    return "\n".join(lines)


def write_outputs(platforms: list[str], rows: list[dict]) -> tuple[str, str]:
    payload = {
        "version": "v1",
        "platforms": platforms,
        "requirements": rows,
    }
    md = build_markdown(platforms, rows)
    js = json.dumps(payload, indent=2) + "\n"
    return md, js


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="Check only; do not write files")
    args = parser.parse_args()

    platforms = collect_platforms()
    rows = collect_rows()
    md, js = write_outputs(platforms, rows)

    if args.check:
        current_md = OUT_MD.read_text(encoding="utf-8") if OUT_MD.exists() else ""
        current_js = OUT_JSON.read_text(encoding="utf-8") if OUT_JSON.exists() else ""
        if md != current_md or js != current_js:
            print("ERROR: support matrix artifacts are stale. Run:")
            print("  python3 scripts/generate_support_matrix.py")
            return 1
        print("Support matrix check passed.")
        return 0

    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.write_text(md, encoding="utf-8")
    OUT_JSON.write_text(js, encoding="utf-8")
    print(
        f"Wrote {OUT_MD.relative_to(ROOT)} and {OUT_JSON.relative_to(ROOT)} "
        f"for {len(rows)} requirements."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
