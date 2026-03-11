#!/usr/bin/env python3
"""Phase 0 guardrail validation.

Lightweight validation with stdlib only:
- required docs exist
- platform capability manifests exist
- capability manifests include minimum required keys
- capability names follow supports_* snake_case convention
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

REQUIRED_DOCS = [
    ROOT / "CONTRIBUTING.md",
    ROOT / "docs" / "contracts" / "execution-contract.md",
    ROOT / "docs" / "platforms" / "capability-schema.md",
    ROOT / "docs" / "PLATFORM_CONTRIBUTOR_SPEC.md",
]

PLATFORMS = ["snowflake", "databricks", "aws", "azure"]

CAP_KEY_RE = re.compile(r"^\s{2}supports_[a-z0-9_]+:\s+(true|false)\s*$")


def fail(msg: str) -> None:
    print(f"ERROR: {msg}")


def validate_docs() -> int:
    errors = 0
    for path in REQUIRED_DOCS:
        if not path.exists():
            fail(f"Missing required doc: {path.relative_to(ROOT)}")
            errors += 1
    return errors


def validate_capability_file(path: Path, platform: str) -> int:
    errors = 0
    if not path.exists():
        fail(f"Missing capability manifest: {path.relative_to(ROOT)}")
        return 1

    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()

    if f"platform: {platform}" not in text:
        fail(f"{path.relative_to(ROOT)} missing exact line: platform: {platform}")
        errors += 1

    if "version: v1" not in text:
        fail(f"{path.relative_to(ROOT)} missing exact line: version: v1")
        errors += 1

    if "capabilities:" not in text:
        fail(f"{path.relative_to(ROOT)} missing top-level capabilities map")
        errors += 1
        return errors

    cap_lines = [ln for ln in lines if ln.startswith("  ")]
    if not cap_lines:
        fail(f"{path.relative_to(ROOT)} has empty capabilities map")
        errors += 1
        return errors

    for ln in cap_lines:
        if not CAP_KEY_RE.match(ln):
            fail(
                f"{path.relative_to(ROOT)} invalid capability line "
                f"(must be `supports_*: true|false`): {ln}"
            )
            errors += 1

    return errors


def validate_capabilities() -> int:
    errors = 0
    for platform in PLATFORMS:
        path = (
            ROOT
            / "skills"
            / "ai-ready-data"
            / "platforms"
            / platform
            / "capabilities.yaml"
        )
        errors += validate_capability_file(path, platform)
    return errors


def main() -> int:
    errors = 0
    errors += validate_docs()
    errors += validate_capabilities()

    if errors:
        print(f"\nPhase 0 validation failed with {errors} issue(s).")
        return 1

    print("Phase 0 validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
