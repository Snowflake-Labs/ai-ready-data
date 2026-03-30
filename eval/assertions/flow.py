"""Conversation-flow assertions.

Validate that the agent follows the SKILL.md conversation protocol:
correct phase ordering, approval gates before mutations, read-only
during assessment, etc.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import TYPE_CHECKING

from eval.assertions.base import SuccessAssertion
from eval.trajectory import PHASE_ORDER, Phase

if TYPE_CHECKING:
    from eval.trajectory import SkillTrajectory


@dataclass(frozen=True)
class PhaseOrderCorrect(SuccessAssertion):
    """Assert that conversation phases occurred in the correct order.

    Does not require every phase to appear — only that observed phases
    respect the canonical ordering from SKILL.md.
    """

    expected: list[Phase] = field(default_factory=lambda: list(PHASE_ORDER))

    def check(self, trajectory: SkillTrajectory) -> bool:
        observed = trajectory.phase_order
        # Filter expected to only those that actually appeared
        expected_present = [p for p in self.expected if p in observed]
        return observed == expected_present

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        observed = trajectory.phase_order
        return (
            f"Phase order violation. "
            f"Expected: {[p.value for p in self.expected]}. "
            f"Observed: {[p.value for p in observed]}"
        )


@dataclass(frozen=True)
class NoMutatingSQLDuring(SuccessAssertion):
    """Assert that no mutating SQL was executed during a given phase."""

    phase: Phase

    def check(self, trajectory: SkillTrajectory) -> bool:
        sql_in_phase = trajectory.sql_in_phase(self.phase)
        return not any(s.is_mutating for s in sql_in_phase)

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        mutating = [s for s in trajectory.sql_in_phase(self.phase) if s.is_mutating]
        sqls = [s.sql[:80] for s in mutating]
        return (
            f"Found {len(mutating)} mutating SQL statement(s) during "
            f"{self.phase.value} phase: {sqls}"
        )


@dataclass(frozen=True)
class ApprovalGateBeforeFix(SuccessAssertion):
    """Assert that every fix SQL was preceded by an approval interaction.

    Checks that each SQLExecution with kind=FIX has a corresponding
    Remediation entry with approved=True.
    """

    def check(self, trajectory: SkillTrajectory) -> bool:
        fix_sqls = [s for s in trajectory.sql_executions if s.kind.value == "fix"]
        if not fix_sqls:
            return True
        approved_sqls = {r.sql for r in trajectory.remediations if r.approved and r.sql}
        return all(s.sql in approved_sqls for s in fix_sqls)

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        fix_sqls = [s for s in trajectory.sql_executions if s.kind.value == "fix"]
        approved_sqls = {r.sql for r in trajectory.remediations if r.approved and r.sql}
        unapproved = [s.sql[:80] for s in fix_sqls if s.sql not in approved_sqls]
        return f"Fix SQL executed without approval: {unapproved}"


@dataclass(frozen=True)
class PhaseReached(SuccessAssertion):
    """Assert that the agent reached a specific phase."""

    phase: Phase

    def check(self, trajectory: SkillTrajectory) -> bool:
        return self.phase in trajectory.phase_order

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        return (
            f"Expected to reach phase {self.phase.value!r}. "
            f"Phases observed: {[p.value for p in trajectory.phase_order]}"
        )


@dataclass(frozen=True)
class PhasesRequired(SuccessAssertion):
    """Assert that ALL listed phases were reached (order-independent)."""

    required: list[Phase] = field(default_factory=list)

    def check(self, trajectory: SkillTrajectory) -> bool:
        observed = set(trajectory.phase_order)
        return all(p in observed for p in self.required)

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        observed = set(trajectory.phase_order)
        missing = [p.value for p in self.required if p not in observed]
        return (
            f"Required phases missing: {missing}. "
            f"Observed: {[p.value for p in trajectory.phase_order]}"
        )


@dataclass(frozen=True)
class AgentAskedAbout(SuccessAssertion):
    """Assert that the agent asked the user about a topic (substring match).

    Scans assistant messages for a keyword indicating the agent solicited
    user input about the given topic (e.g., "platform", "database", "profile").
    """

    topic: str
    case_insensitive: bool = True

    def check(self, trajectory: SkillTrajectory) -> bool:
        needle = self.topic.lower() if self.case_insensitive else self.topic
        for step in trajectory.agent_steps:
            haystack = step.text.lower() if self.case_insensitive else step.text
            if needle in haystack:
                return True
        return False

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        return f"Agent never asked about {self.topic!r} in any assistant message"
