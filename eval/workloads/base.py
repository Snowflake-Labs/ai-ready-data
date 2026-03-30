"""Base classes for AI workload measurement.

A workload runner captures before/after metrics for a specific AI task
(RAG retrieval, feature serving, training data extraction). The comparison
object computes deltas and feeds into WorkloadMetricImproved assertions.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any


@dataclass(frozen=True)
class WorkloadMetrics:
    """Named metric values from a single workload run."""

    values: dict[str, float]
    metadata: dict[str, Any] = field(default_factory=dict)

    def get(self, metric: str) -> float | None:
        return self.values.get(metric)


@dataclass(frozen=True)
class WorkloadComparison:
    """Before/after comparison of workload metrics."""

    baseline: WorkloadMetrics
    after: WorkloadMetrics
    workload_name: str = ""

    def delta(self, metric: str) -> float | None:
        """Compute after - baseline for a named metric."""
        before = self.baseline.get(metric)
        after = self.after.get(metric)
        if before is None or after is None:
            return None
        return after - before

    def pct_change(self, metric: str) -> float | None:
        """Compute percentage change: (after - before) / before."""
        before = self.baseline.get(metric)
        delta = self.delta(metric)
        if before is None or delta is None or before == 0:
            return None
        return delta / before

    def summary(self) -> str:
        """Human-readable summary of all metric changes."""
        lines = [f"Workload: {self.workload_name}"]
        all_metrics = set(self.baseline.values) | set(self.after.values)
        for metric in sorted(all_metrics):
            before = self.baseline.get(metric)
            after = self.after.get(metric)
            delta = self.delta(metric)
            pct = self.pct_change(metric)
            pct_str = f" ({pct:+.1%})" if pct is not None else ""
            lines.append(
                f"  {metric}: {before} → {after} (delta: {delta}{pct_str})"
            )
        return "\n".join(lines)


class WorkloadRunner(ABC):
    """Abstract base for AI workload runners.

    Subclass for each workload type (RAG, feature serving, training).
    Each runner knows how to execute its workload against a data source
    and return structured metrics.
    """

    @property
    @abstractmethod
    def name(self) -> str:
        """Workload identifier (e.g. 'rag_retrieval', 'feature_serving')."""
        ...

    @abstractmethod
    def run(self, **kwargs: Any) -> WorkloadMetrics:
        """Execute the workload and return metrics."""
        ...

    def compare(self, baseline: WorkloadMetrics, after: WorkloadMetrics) -> WorkloadComparison:
        return WorkloadComparison(
            baseline=baseline,
            after=after,
            workload_name=self.name,
        )
