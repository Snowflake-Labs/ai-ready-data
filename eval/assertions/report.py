"""Report-format assertions.

Validate that generated assessment reports conform to the
standardized structure defined in SKILL.md.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import TYPE_CHECKING

from eval.assertions.base import SuccessAssertion
from eval.trajectory import STAGE_NAMES

if TYPE_CHECKING:
    from eval.trajectory import SkillTrajectory


@dataclass(frozen=True)
class ReportContainsStages(SuccessAssertion):
    """Assert that the report text contains all expected stage headings."""

    stages: tuple[str, ...] = STAGE_NAMES

    def check(self, trajectory: SkillTrajectory) -> bool:
        if not trajectory.report_text:
            return False
        return all(stage in trajectory.report_text for stage in self.stages)

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        if not trajectory.report_text:
            return "No report text was generated"
        missing = [s for s in self.stages if s not in trajectory.report_text]
        return f"Report missing stage headings: {missing}"


@dataclass(frozen=True)
class ReportScoresNormalized(SuccessAssertion):
    """Assert that all requirement scores in the trajectory are in [0.0, 1.0]."""

    def check(self, trajectory: SkillTrajectory) -> bool:
        return all(
            0.0 <= v <= 1.0
            for v in trajectory.requirement_scores.values()
        )

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        bad = {k: v for k, v in trajectory.requirement_scores.items() if not (0.0 <= v <= 1.0)}
        return f"Scores outside [0.0, 1.0]: {bad}"


@dataclass(frozen=True)
class ReportContainsMetadata(SuccessAssertion):
    """Assert that the report contains required metadata fields."""

    required_fields: tuple[str, ...] = (
        "Platform", "Database", "Schema", "Profile", "Requirements",
    )

    def check(self, trajectory: SkillTrajectory) -> bool:
        if not trajectory.report_text:
            return False
        return all(f in trajectory.report_text for f in self.required_fields)

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        if not trajectory.report_text:
            return "No report text was generated"
        missing = [f for f in self.required_fields if f not in trajectory.report_text]
        return f"Report missing metadata fields: {missing}"


@dataclass(frozen=True)
class ReportContainsSection(SuccessAssertion):
    """Assert that the report contains a specific markdown section heading."""

    section: str

    def check(self, trajectory: SkillTrajectory) -> bool:
        if not trajectory.report_text:
            return False
        return self.section in trajectory.report_text

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        if not trajectory.report_text:
            return "No report text was generated"
        return f"Report missing section: {self.section!r}"


@dataclass(frozen=True)
class CorrectProfileLoaded(SuccessAssertion):
    """Assert that the agent loaded the expected profile."""

    expected_profile: str

    def check(self, trajectory: SkillTrajectory) -> bool:
        return trajectory.profile_loaded == self.expected_profile

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        return (
            f"Expected profile {self.expected_profile!r}, "
            f"got {trajectory.profile_loaded!r}"
        )
