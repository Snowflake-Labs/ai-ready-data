"""Pre- and post-hook framework for skill evaluation lifecycle.

Hooks run at defined points during a skill eval session:
  - pre_session: environment setup, mock configuration, baseline capture
  - pre_turn: validate turn expectations, prepare user response injection
  - post_turn: inspect agent output per-turn, classify phase, log SQL
  - post_session: trajectory construction, assertion execution, workload comparison
"""

from __future__ import annotations

import re
import time
from collections.abc import Callable
from dataclasses import dataclass, field
from typing import Any, Protocol

from eval.trajectory import (
    AgentStep,
    Phase,
    SQLExecution,
    SQLKind,
    SkillTrajectory,
)


# ---------------------------------------------------------------------------
# SQL interceptor — captures all SQL the agent executes
# ---------------------------------------------------------------------------

class SQLInterceptor:
    """Wraps a SQL execution function to capture every call."""

    def __init__(self, execute_fn: Callable[[str], Any]) -> None:
        self._execute_fn = execute_fn
        self.log: list[SQLExecution] = []
        self._current_phase: Phase = Phase.PLATFORM
        self._current_requirement: str | None = None

    def set_phase(self, phase: Phase) -> None:
        self._current_phase = phase

    def set_requirement(self, requirement: str | None) -> None:
        self._current_requirement = requirement

    def execute(self, sql: str, kind: SQLKind = SQLKind.OTHER) -> Any:
        start = time.monotonic()
        result = self._execute_fn(sql)
        duration_ms = (time.monotonic() - start) * 1000

        execution = SQLExecution(
            sql=sql,
            kind=kind,
            phase=self._current_phase,
            requirement=self._current_requirement,
            result=result,
            duration_ms=duration_ms,
        )
        self.log.append(execution)
        return result


# ---------------------------------------------------------------------------
# Phase classifier — detects which phase the conversation is in
# ---------------------------------------------------------------------------

_PHASE_SIGNALS: list[tuple[Phase, list[str]]] = [
    # Order matters: more specific signals first to avoid false matches
    (Phase.REPORT, ["assessment report", "stages passing", "of 6 stages", "requirements passing"]),
    (Phase.REMEDIATE, ["remediation complete", "remediation", "approve", "stage:"]),
    (Phase.COVERAGE, ["coverage summary", "selected:", "runnable:", "proceed?"]),
    (Phase.ASSESS, ["executing assessment", "running check"]),
    (Phase.ADJUSTMENTS, ["skip", "override", "adjustment"]),
    (Phase.PROFILE, ["what would you like to assess", "which profile"]),
    (Phase.DISCOVERY, ["how would you like to scope", "what database", "what schema"]),
    (Phase.PLATFORM, ["what platform", "which platform", "supported platforms"]),
]


def classify_phase(text: str, current_phase: Phase) -> Phase:
    """Heuristic phase detection from agent message text.

    Scans for keyword signals in priority order. Falls back to
    the current phase if no signal matches.
    """
    lower = text.lower()
    for phase, signals in _PHASE_SIGNALS:
        if any(signal in lower for signal in signals):
            return phase
    return current_phase


# ---------------------------------------------------------------------------
# Turn-level hooks
# ---------------------------------------------------------------------------

@dataclass
class TurnExpectation:
    """What we expect the agent to do in a given turn."""

    expect_asks_about: str | None = None
    expect_phase: Phase | None = None
    expect_sql_kind: SQLKind | None = None
    expect_no_mutations: bool = False


@dataclass
class TurnResult:
    """Observed outcome of a single turn."""

    step: AgentStep
    phase_detected: Phase
    sql_executed: list[SQLExecution] = field(default_factory=list)
    expectation_met: bool = True
    expectation_notes: list[str] = field(default_factory=list)


def validate_turn(
    step: AgentStep,
    sql_log: list[SQLExecution],
    expectation: TurnExpectation | None,
    current_phase: Phase,
) -> TurnResult:
    """Post-hook: validate a single agent turn against expectations."""
    phase = classify_phase(step.text, current_phase)

    turn_sql = [s for s in sql_log if s not in getattr(validate_turn, "_seen", [])]
    validate_turn._seen = list(sql_log)  # type: ignore[attr-defined]

    result = TurnResult(step=step, phase_detected=phase, sql_executed=turn_sql)

    if expectation is None:
        return result

    notes: list[str] = []

    if expectation.expect_asks_about:
        needle = expectation.expect_asks_about.lower()
        if needle not in step.text.lower():
            notes.append(f"Expected agent to ask about {expectation.expect_asks_about!r}")
            result.expectation_met = False

    if expectation.expect_phase and phase != expectation.expect_phase:
        notes.append(
            f"Expected phase {expectation.expect_phase.value}, "
            f"detected {phase.value}"
        )
        result.expectation_met = False

    if expectation.expect_no_mutations:
        mutating = [s for s in turn_sql if s.is_mutating]
        if mutating:
            notes.append(f"Expected no mutations, found {len(mutating)}")
            result.expectation_met = False

    result.expectation_notes = notes
    return result


# ---------------------------------------------------------------------------
# Session-level hooks
# ---------------------------------------------------------------------------

class SessionHooks(Protocol):
    """Protocol for pluggable session lifecycle hooks."""

    def pre_session(self, trajectory: SkillTrajectory) -> None:
        """Called before the first agent turn. Modify trajectory state."""
        ...

    def post_session(self, trajectory: SkillTrajectory) -> None:
        """Called after the last agent turn. Final enrichment."""
        ...


@dataclass
class DefaultSessionHooks:
    """Default hook implementation that populates trajectory metadata."""

    def pre_session(self, trajectory: SkillTrajectory) -> None:
        pass

    def post_session(self, trajectory: SkillTrajectory) -> None:
        """Enrich trajectory with derived data from the SQL log."""
        for sql_exec in trajectory.sql_executions:
            if sql_exec.kind == SQLKind.CHECK and sql_exec.requirement:
                if isinstance(sql_exec.result, dict) and "value" in sql_exec.result:
                    trajectory.requirement_scores[sql_exec.requirement] = float(
                        sql_exec.result["value"]
                    )

        # Detect report text from agent messages containing report-like content
        for step in reversed(trajectory.agent_steps):
            lower = step.text.lower()
            has_report_signals = (
                ("stages passing" in lower or "requirements passing" in lower)
                or ("pass" in lower and "fail" in lower and "summary" in lower)
                or ("assessment report" in lower)
            )
            if has_report_signals and len(step.text) > 100:
                trajectory.report_text = step.text
                break
