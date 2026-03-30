"""SkillScorer — two-tier assertion builder for skill evaluations.

Adapted from deepagents' TrajectoryScorer. Separates correctness
assertions (hard-fail) from efficiency assertions (logged, never fail).
Adds convenience methods for common skill-specific patterns.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from eval.assertions.base import EfficiencyAssertion, SuccessAssertion
from eval.assertions.flow import (
    AgentAskedAbout,
    ApprovalGateBeforeFix,
    NoMutatingSQLDuring,
    PhaseOrderCorrect,
    PhaseReached,
    PhasesRequired,
)
from eval.assertions.report import (
    CorrectProfileLoaded,
    ReportContainsMetadata,
    ReportContainsStages,
    ReportScoresNormalized,
)
from eval.assertions.sql import (
    CheckSQLReturnsValueColumn,
    PlaceholdersAllSubstituted,
    SQLCountInRange,
    SQLUsedCorrectVariant,
)
from eval.assertions.workload import (
    WorkloadMetricImproved,
    WorkloadMetricNotRegressed,
)
from eval.trajectory import PHASE_ORDER, Phase

if TYPE_CHECKING:
    from eval.trajectory import SkillTrajectory


@dataclass(frozen=True)
class SkillScorer:
    """Two-tier assertion container for skill trajectories.

    Use ``.success()`` to add correctness assertions (hard-fail).
    Use ``.expect()`` to add efficiency assertions (soft-log).
    Use the convenience methods for common patterns.
    """

    _success: tuple[SuccessAssertion, ...] = ()
    _expectations: tuple[EfficiencyAssertion, ...] = ()

    # ── Generic builders ──

    def success(self, *assertions: SuccessAssertion) -> SkillScorer:
        """Append correctness assertions that hard-fail the test."""
        return SkillScorer(
            _success=(*self._success, *assertions),
            _expectations=self._expectations,
        )

    def expect(self, *assertions: EfficiencyAssertion) -> SkillScorer:
        """Append efficiency assertions that are logged but never fail."""
        return SkillScorer(
            _success=self._success,
            _expectations=(*self._expectations, *assertions),
        )

    # ── Conversation flow conveniences ──

    def expect_phase_order(self, phases: list[str] | None = None) -> SkillScorer:
        """Assert phases occurred in the canonical SKILL.md order."""
        phase_enums = [Phase(p) for p in phases] if phases else list(PHASE_ORDER)
        return self.success(PhaseOrderCorrect(expected=phase_enums))

    def expect_phase_reached(self, phase: str) -> SkillScorer:
        return self.success(PhaseReached(phase=Phase(phase)))

    def expect_phases_required(self, phases: list[str]) -> SkillScorer:
        """Assert that ALL listed phases must be reached."""
        return self.success(PhasesRequired(required=[Phase(p) for p in phases]))

    def expect_agent_asks_about(self, topic: str) -> SkillScorer:
        return self.success(AgentAskedAbout(topic=topic))

    def expect_no_mutations_during(self, phase: str) -> SkillScorer:
        return self.success(NoMutatingSQLDuring(phase=Phase(phase)))

    def expect_approval_before_mutations(self) -> SkillScorer:
        return self.success(ApprovalGateBeforeFix())

    def expect_read_only_assess(self) -> SkillScorer:
        """Shorthand: no mutations during discovery, profile, coverage, or assess."""
        scorer = self
        for phase_name in ("discovery", "profile", "coverage", "assess"):
            scorer = scorer.expect_no_mutations_during(phase_name)
        return scorer

    # ── SQL conveniences ──

    def expect_sql_calls(
        self,
        *,
        min: int = 0,
        max: int | None = None,
    ) -> SkillScorer:
        return self.expect(SQLCountInRange(min_count=min, max_count=max))

    def expect_placeholders_substituted(self) -> SkillScorer:
        return self.success(PlaceholdersAllSubstituted())

    def expect_check_sql_has_value_column(self) -> SkillScorer:
        return self.success(CheckSQLReturnsValueColumn())

    def expect_correct_sql_variants(self, row_threshold: int = 1_000_000) -> SkillScorer:
        return self.success(SQLUsedCorrectVariant(row_threshold=row_threshold))

    # ── Report conveniences ──

    def expect_report_stages(self, stages: tuple[str, ...] | None = None) -> SkillScorer:
        if stages:
            return self.success(ReportContainsStages(stages=stages))
        return self.success(ReportContainsStages())

    def expect_scores_normalized(self) -> SkillScorer:
        return self.success(ReportScoresNormalized())

    def expect_report_metadata(self) -> SkillScorer:
        return self.success(ReportContainsMetadata())

    def expect_correct_profile(self, name: str) -> SkillScorer:
        return self.success(CorrectProfileLoaded(expected_profile=name))

    # ── AI workload conveniences ──

    def expect_workload_improved(
        self,
        metric: str,
        min_delta: float = 0.0,
        higher_is_better: bool = True,
    ) -> SkillScorer:
        return self.success(
            WorkloadMetricImproved(
                metric=metric,
                min_delta=min_delta,
                higher_is_better=higher_is_better,
            )
        )

    def expect_workload_not_regressed(
        self,
        metric: str,
        max_regression: float = 0.1,
        higher_is_better: bool = True,
    ) -> SkillScorer:
        return self.success(
            WorkloadMetricNotRegressed(
                metric=metric,
                max_regression=max_regression,
                higher_is_better=higher_is_better,
            )
        )

    # ── Compound presets ──

    def standard_assess_checks(self) -> SkillScorer:
        """Bundle of assertions common to all assessment tests."""
        return (
            self
            .expect_phase_order()
            .expect_read_only_assess()
            .expect_placeholders_substituted()
            .expect_scores_normalized()
            .expect_report_stages()
        )
