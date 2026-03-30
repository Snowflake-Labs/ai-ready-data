"""AI workload assertions.

Validate that running the skill's assessment + remediation cycle
actually improves measurable AI workload metrics (recall, latency,
data quality, etc.).
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from eval.assertions.base import SuccessAssertion

if TYPE_CHECKING:
    from eval.trajectory import SkillTrajectory
    from eval.workloads.base import WorkloadComparison


@dataclass(frozen=True)
class WorkloadMetricImproved(SuccessAssertion):
    """Assert that a named workload metric improved by at least `min_delta`.

    The comparison is stored on the trajectory via `trajectory.workload_comparison`.
    For "higher is better" metrics (recall, accuracy), improvement means increase.
    For "lower is better" metrics (latency, null_ratio), improvement means decrease.
    """

    metric: str
    min_delta: float = 0.0
    higher_is_better: bool = True

    def check(self, trajectory: SkillTrajectory) -> bool:
        comparison = getattr(trajectory, "workload_comparison", None)
        if comparison is None:
            return False
        delta = comparison.delta(self.metric)
        if delta is None:
            return False
        if self.higher_is_better:
            return delta >= self.min_delta
        return (-delta) >= self.min_delta

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        comparison = getattr(trajectory, "workload_comparison", None)
        if comparison is None:
            return f"No workload comparison data for metric {self.metric!r}"
        delta = comparison.delta(self.metric)
        direction = "increase" if self.higher_is_better else "decrease"
        return (
            f"Metric {self.metric!r} did not {direction} by >= {self.min_delta}. "
            f"Delta: {delta}"
        )


@dataclass(frozen=True)
class WorkloadMetricNotRegressed(SuccessAssertion):
    """Assert that a metric did not get worse beyond a tolerance.

    Guards against remediation introducing regressions in metrics
    that aren't the primary target (e.g., latency shouldn't blow up
    while fixing recall).
    """

    metric: str
    max_regression: float = 0.1
    higher_is_better: bool = True

    def check(self, trajectory: SkillTrajectory) -> bool:
        comparison = getattr(trajectory, "workload_comparison", None)
        if comparison is None:
            return True  # no data = no regression detected
        delta = comparison.delta(self.metric)
        if delta is None:
            return True
        if self.higher_is_better:
            return delta >= -self.max_regression
        return delta <= self.max_regression

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        comparison = getattr(trajectory, "workload_comparison", None)
        delta = comparison.delta(self.metric) if comparison else None
        return (
            f"Metric {self.metric!r} regressed beyond tolerance. "
            f"Max allowed: {self.max_regression}, actual delta: {delta}"
        )
