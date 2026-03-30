"""Base assertion classes for the skill eval harness.

Two-tier design adapted from deepagents:
  - SuccessAssertion: correctness checks that hard-fail the test
  - EfficiencyAssertion: trajectory-shape checks that are logged but never fail
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from eval.trajectory import SkillTrajectory


class SuccessAssertion(ABC):
    """Correctness assertion — violation fails the test."""

    @abstractmethod
    def check(self, trajectory: SkillTrajectory) -> bool: ...

    @abstractmethod
    def describe_failure(self, trajectory: SkillTrajectory) -> str: ...


class EfficiencyAssertion(ABC):
    """Efficiency assertion — logged as feedback, never fails the test."""

    @abstractmethod
    def check(self, trajectory: SkillTrajectory) -> bool: ...

    @abstractmethod
    def describe_failure(self, trajectory: SkillTrajectory) -> str: ...
