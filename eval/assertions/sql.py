"""SQL-related assertions.

Validate placeholder substitution, SQL count ranges, and query correctness
for the ai-ready-data skill's generated SQL.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from eval.assertions.base import EfficiencyAssertion, SuccessAssertion

if TYPE_CHECKING:
    from eval.trajectory import SkillTrajectory


@dataclass(frozen=True)
class PlaceholdersAllSubstituted(SuccessAssertion):
    """Assert that no executed SQL contains unsubstituted {{ placeholder }} tokens."""

    def check(self, trajectory: SkillTrajectory) -> bool:
        return not any(s.has_unsubstituted_placeholders for s in trajectory.sql_executions)

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        bad = [
            (s.requirement or "unknown", s.sql[:120])
            for s in trajectory.sql_executions
            if s.has_unsubstituted_placeholders
        ]
        return f"Unsubstituted placeholders in SQL: {bad}"


@dataclass(frozen=True)
class SQLCountInRange(EfficiencyAssertion):
    """Assert that total SQL executions fall within an expected range."""

    min_count: int = 0
    max_count: int | None = None

    def check(self, trajectory: SkillTrajectory) -> bool:
        n = trajectory.total_sql_calls
        if n < self.min_count:
            return False
        if self.max_count is not None and n > self.max_count:
            return False
        return True

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        n = trajectory.total_sql_calls
        return (
            f"SQL call count {n} outside expected range "
            f"[{self.min_count}, {self.max_count or '∞'}]"
        )


@dataclass(frozen=True)
class CheckSQLReturnsValueColumn(SuccessAssertion):
    """Assert that every check SQL contains a `value` column in its SELECT."""

    def check(self, trajectory: SkillTrajectory) -> bool:
        checks = [s for s in trajectory.sql_executions if s.kind.value == "check"]
        for sql_exec in checks:
            normalized = sql_exec.sql.upper()
            if "AS VALUE" not in normalized and "VALUE" not in normalized.split("SELECT")[1].split("FROM")[0] if "SELECT" in normalized and "FROM" in normalized else True:
                return False
        return True

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        checks = [s for s in trajectory.sql_executions if s.kind.value == "check"]
        bad = [s.requirement or "unknown" for s in checks if "VALUE" not in s.sql.upper()]
        return f"Check SQL missing `value` column: {bad}"


@dataclass(frozen=True)
class SQLUsedCorrectVariant(SuccessAssertion):
    """Assert that sampled SQL was used for large tables and full scan for small.

    Requires that SQLExecution.result includes row_count metadata.
    """

    row_threshold: int = 1_000_000

    def check(self, trajectory: SkillTrajectory) -> bool:
        checks = [s for s in trajectory.sql_executions if s.kind.value == "check"]
        for sql_exec in checks:
            if not isinstance(sql_exec.result, dict):
                continue
            row_count = sql_exec.result.get("row_count")
            if row_count is None:
                continue
            uses_sample = "TABLESAMPLE" in sql_exec.sql.upper()
            if row_count > self.row_threshold and not uses_sample:
                return False
            if row_count <= self.row_threshold and uses_sample:
                return False
        return True

    def describe_failure(self, trajectory: SkillTrajectory) -> str:
        return (
            f"SQL variant mismatch: expected sampled for tables > {self.row_threshold} rows "
            f"and full scan otherwise"
        )
