#!/usr/bin/env python3
"""Sync canonical skill files into .agents mirror.

Canonical source:
- skills/*/SKILL.md

Mirror destination:
- .agents/skills/*/SKILL.md
"""

from __future__ import annotations

import argparse
import filecmp
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CANONICAL_ROOT = ROOT / "skills"
MIRROR_ROOT = ROOT / ".agents" / "skills"


def collect_pairs() -> list[tuple[Path, Path]]:
    pairs: list[tuple[Path, Path]] = []
    for src in sorted(CANONICAL_ROOT.glob("*/SKILL.md")):
        rel = src.relative_to(CANONICAL_ROOT)
        dst = MIRROR_ROOT / rel
        pairs.append((src, dst))
    return pairs


def check_only() -> int:
    failures = 0
    for src, dst in collect_pairs():
        if not dst.exists():
            print(f"ERROR: missing mirror file: {dst.relative_to(ROOT)}")
            failures += 1
            continue
        if not filecmp.cmp(src, dst, shallow=False):
            print(
                f"ERROR: mirror drift: {src.relative_to(ROOT)} "
                f"!= {dst.relative_to(ROOT)}"
            )
            failures += 1
    if failures == 0:
        print("Skill mirror check passed.")
    return failures


def sync() -> None:
    for src, dst in collect_pairs():
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        print(f"Synced {src.relative_to(ROOT)} -> {dst.relative_to(ROOT)}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="Check for drift only")
    args = parser.parse_args()

    if args.check:
        return 1 if check_only() else 0

    sync()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
