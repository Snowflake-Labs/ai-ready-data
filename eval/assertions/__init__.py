"""Skill-specific assertion classes for the eval harness."""

from eval.assertions.base import EfficiencyAssertion, SuccessAssertion
from eval.assertions.flow import (
    ApprovalGateBeforeFix,
    NoMutatingSQLDuring,
    PhaseOrderCorrect,
)
from eval.assertions.report import (
    ReportContainsStages,
    ReportScoresNormalized,
)
from eval.assertions.sql import (
    PlaceholdersAllSubstituted,
    SQLCountInRange,
)
from eval.assertions.workload import (
    WorkloadMetricImproved,
    WorkloadMetricNotRegressed,
)

__all__ = [
    "ApprovalGateBeforeFix",
    "EfficiencyAssertion",
    "NoMutatingSQLDuring",
    "PhaseOrderCorrect",
    "PlaceholdersAllSubstituted",
    "ReportContainsStages",
    "ReportScoresNormalized",
    "SQLCountInRange",
    "SuccessAssertion",
    "WorkloadMetricImproved",
    "WorkloadMetricNotRegressed",
]
