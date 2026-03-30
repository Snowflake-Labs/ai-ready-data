"""AI-Ready Data skill evaluation harness.

Trajectory-based testing framework for validating agent behavior
against the ai-ready-data SKILL.md conversation protocol.
"""

from eval.trajectory import (
    AgentStep,
    Remediation,
    SkillTrajectory,
    SQLExecution,
    StageResult,
)
from eval.scorer import SkillScorer
from eval.runner import run_skill_session

__all__ = [
    "AgentStep",
    "Remediation",
    "run_skill_session",
    "SkillScorer",
    "SkillTrajectory",
    "SQLExecution",
    "StageResult",
]
