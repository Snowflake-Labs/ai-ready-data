"""Unit tests for requirement profiles and manifest integrity.

These don't need an LLM — they validate the skill's data files:
  - Every profile references existing requirements
  - Every requirement in the manifest has implementations
  - Factor assignments are consistent
  - Score thresholds are reasonable
"""

from __future__ import annotations

from pathlib import Path

import pytest

SKILL_ROOT = Path(__file__).resolve().parent.parent.parent / "skills" / "ai-ready-data"
REQUIREMENTS_DIR = SKILL_ROOT / "requirements"
PROFILES_DIR = SKILL_ROOT / "profiles"
REQUIREMENTS_YAML = REQUIREMENTS_DIR / "requirements.yaml"


pytestmark = [pytest.mark.eval_category("requirement_unit")]


def _load_yaml(path: Path) -> dict:
    import yaml

    if not path.exists():
        pytest.skip(f"{path} not found")
    with open(path) as f:
        return yaml.safe_load(f)


def _load_manifest() -> dict:
    data = _load_yaml(REQUIREMENTS_YAML)
    return data.get("requirements", {})


def _all_profiles():
    if not PROFILES_DIR.exists():
        return
    for p in sorted(PROFILES_DIR.glob("*.yaml")):
        yield p.stem, p


VALID_FACTORS = {"clean", "contextual", "consumable", "current", "correlated", "compliant"}
VALID_SCOPES = {"schema", "table", "column"}


# ---------------------------------------------------------------------------
# Manifest integrity
# ---------------------------------------------------------------------------

def test_manifest_exists():
    assert REQUIREMENTS_YAML.exists(), "requirements.yaml not found"


def test_manifest_requirements_have_required_fields():
    """Every requirement has description, factor, scope, implementations."""
    manifest = _load_manifest()
    for key, req in manifest.items():
        assert "description" in req, f"{key} missing 'description'"
        assert "factor" in req, f"{key} missing 'factor'"
        assert "scope" in req, f"{key} missing 'scope'"
        assert "implementations" in req, f"{key} missing 'implementations'"


def test_manifest_factors_are_valid():
    manifest = _load_manifest()
    for key, req in manifest.items():
        factor = req.get("factor", "")
        assert factor in VALID_FACTORS, (
            f"{key} has invalid factor {factor!r}, expected one of {VALID_FACTORS}"
        )


def test_manifest_scopes_are_valid():
    manifest = _load_manifest()
    for key, req in manifest.items():
        scope = req.get("scope", "")
        assert scope in VALID_SCOPES, (
            f"{key} has invalid scope {scope!r}, expected one of {VALID_SCOPES}"
        )


def test_manifest_implementations_have_files():
    """Every declared implementation has a corresponding directory with check.md."""
    manifest = _load_manifest()
    for key, req in manifest.items():
        for platform in req.get("implementations", []):
            check_path = REQUIREMENTS_DIR / key / platform / "check.md"
            assert check_path.exists(), (
                f"{key} declares {platform} implementation but {check_path} missing"
            )


# ---------------------------------------------------------------------------
# Profile integrity
# ---------------------------------------------------------------------------

@pytest.mark.parametrize(
    "profile_name,profile_path",
    list(_all_profiles()),
    ids=[name for name, _ in _all_profiles()],
)
def test_profile_requirements_exist_in_manifest(profile_name: str, profile_path: Path):
    """Every requirement referenced in a profile exists in the manifest."""
    manifest = _load_manifest()
    profile = _load_yaml(profile_path)

    for stage in profile.get("stages", []):
        for req_key in stage.get("requirements", {}):
            assert req_key in manifest, (
                f"Profile {profile_name} references {req_key!r} "
                f"which is not in requirements.yaml"
            )


@pytest.mark.parametrize(
    "profile_name,profile_path",
    list(_all_profiles()),
    ids=[name for name, _ in _all_profiles()],
)
def test_profile_thresholds_are_reasonable(profile_name: str, profile_path: Path):
    """All thresholds should be between 0.0 and 1.0."""
    profile = _load_yaml(profile_path)

    for stage in profile.get("stages", []):
        for req_key, config in stage.get("requirements", {}).items():
            if isinstance(config, dict) and "min" in config:
                threshold = config["min"]
                assert 0.0 <= threshold <= 1.0, (
                    f"Profile {profile_name}, stage {stage['name']}, "
                    f"requirement {req_key}: threshold {threshold} out of [0,1]"
                )


@pytest.mark.parametrize(
    "profile_name,profile_path",
    list(_all_profiles()),
    ids=[name for name, _ in _all_profiles()],
)
def test_profile_has_valid_stage_names(profile_name: str, profile_path: Path):
    """Profile stages must use the canonical 6 factor names."""
    valid_names = {"Clean", "Contextual", "Consumable", "Current", "Correlated", "Compliant"}
    profile = _load_yaml(profile_path)

    for stage in profile.get("stages", []):
        name = stage.get("name", "")
        assert name in valid_names, (
            f"Profile {profile_name} has invalid stage name {name!r}"
        )


@pytest.mark.parametrize(
    "profile_name,profile_path",
    list(_all_profiles()),
    ids=[name for name, _ in _all_profiles()],
)
def test_profile_stages_have_why(profile_name: str, profile_path: Path):
    """Every stage should have a 'why' explanation."""
    profile = _load_yaml(profile_path)

    for stage in profile.get("stages", []):
        assert "why" in stage, (
            f"Profile {profile_name}, stage {stage.get('name', '?')} missing 'why'"
        )
