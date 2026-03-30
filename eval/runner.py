"""Session runner — orchestrates multi-turn skill evaluation.

The central entry point for running a skill eval session. Manages the
conversation loop, hooks, SQL interception, phase tracking, trajectory
construction, and assertion execution.
"""

from __future__ import annotations

import time
import uuid
from collections.abc import Callable
from dataclasses import dataclass, field
from typing import Any

import pytest

from eval.hooks import (
    DefaultSessionHooks,
    SQLInterceptor,
    SessionHooks,
    TurnExpectation,
    classify_phase,
    validate_turn,
)
from eval.mocks.mock_snowflake import SnowflakeScenario
from eval.scorer import SkillScorer
from eval.trajectory import (
    AgentStep,
    Phase,
    SQLExecution,
    SQLKind,
    SkillTrajectory,
)


# ---------------------------------------------------------------------------
# Turn specification — what the user sends and what we expect back
# ---------------------------------------------------------------------------

@dataclass
class UserTurn:
    """A scripted user message to send to the agent."""

    text: str
    expect: TurnExpectation | None = None


def user_turn(text: str, **kwargs: Any) -> UserTurn:
    """Convenience factory for UserTurn."""
    expect = TurnExpectation(**kwargs) if kwargs else None
    return UserTurn(text=text, expect=expect)


def expect_agent_asks(about: str) -> TurnExpectation:
    """Convenience: expect the agent to ask about a topic."""
    return TurnExpectation(expect_asks_about=about)


# ---------------------------------------------------------------------------
# Agent adapter protocol
# ---------------------------------------------------------------------------

class AgentAdapter:
    """Wraps a concrete agent (Cortex Code CLI or mock) for the eval harness.

    Subclass this to connect to the actual Cortex Code CLI agent
    or use MockAgent for deterministic testing.
    """

    def send(self, message: str, *, files: dict[str, str] | None = None) -> dict[str, Any]:
        """Send a user message and return the agent's response.

        Returns a dict with at minimum:
          - "content": str (agent's text response)
          - "tool_calls": list[dict] (optional)
          - "sql_executed": list[dict] (optional, intercepted SQL)
          - "files": dict[str, str] (optional, file state after turn)
        """
        raise NotImplementedError

    def reset(self) -> None:
        """Reset agent state between test sessions."""
        raise NotImplementedError


class MockAgent(AgentAdapter):
    """Deterministic agent for testing the harness itself.

    Returns pre-scripted responses in order.
    """

    def __init__(self, responses: list[str]) -> None:
        self._responses = list(responses)
        self._index = 0

    def send(self, message: str, *, files: dict[str, str] | None = None) -> dict[str, Any]:
        if self._index >= len(self._responses):
            return {"content": "[no more scripted responses]", "tool_calls": []}
        response = self._responses[self._index]
        self._index += 1
        return {"content": response, "tool_calls": []}

    def reset(self) -> None:
        self._index = 0


# ---------------------------------------------------------------------------
# Efficiency result (mirrors deepagents)
# ---------------------------------------------------------------------------

@dataclass
class EfficiencyResult:
    """Per-test efficiency data for session-level reporting."""

    expected_sql_calls: int | None = None
    actual_sql_calls: int = 0
    expected_steps: int | None = None
    actual_steps: int = 0
    duration_s: float | None = None
    passed: bool | None = None
    phases_reached: list[str] = field(default_factory=list)


_on_efficiency_result: Callable[[EfficiencyResult], None] | None = None


# ---------------------------------------------------------------------------
# The main runner
# ---------------------------------------------------------------------------

def run_skill_session(
    agent: AgentAdapter,
    *,
    turns: list[UserTurn],
    scenario: SnowflakeScenario | None = None,
    scorer: SkillScorer | None = None,
    initial_files: dict[str, str] | None = None,
    session_hooks: SessionHooks | None = None,
    session_id: str | None = None,
) -> SkillTrajectory:
    """Run a multi-turn skill evaluation session.

    Orchestrates:
      1. Pre-session hooks (environment setup)
      2. Conversation loop (user turns → agent responses)
      3. Per-turn hooks (phase detection, SQL capture, validation)
      4. Post-session hooks (trajectory enrichment)
      5. Assertion execution (scorer)

    Returns the fully populated SkillTrajectory.
    """
    hooks = session_hooks or DefaultSessionHooks()
    session_id = session_id or str(uuid.uuid4())

    # Build trajectory
    trajectory = SkillTrajectory(files=dict(initial_files or {}))

    if scenario:
        trajectory.platform = "snowflake"
        tool = scenario.build_tool()
        sql_interceptor = SQLInterceptor(tool.execute)
    else:
        sql_interceptor = None

    # Pre-session hook
    hooks.pre_session(trajectory)

    start_time = time.monotonic()
    current_phase = Phase.PLATFORM
    trajectory.phases_entered.append(current_phase)
    step_index = 0

    for turn in turns:
        # Record user turn
        step_index += 1
        user_step = AgentStep(
            index=step_index,
            role="user",
            text=turn.text,
            phase=current_phase,
        )
        trajectory.steps.append(user_step)

        # Send to agent
        if sql_interceptor:
            sql_interceptor.set_phase(current_phase)
        response = agent.send(turn.text, files=trajectory.files)

        # Record agent response
        step_index += 1
        agent_text = response.get("content", "")
        agent_step = AgentStep(
            index=step_index,
            role="assistant",
            text=agent_text,
            tool_calls=response.get("tool_calls", []),
            phase=current_phase,
        )

        # Phase detection
        new_phase = classify_phase(agent_text, current_phase)
        if new_phase != current_phase:
            trajectory.phases_entered.append(new_phase)
            current_phase = new_phase
            agent_step = AgentStep(
                index=agent_step.index,
                role=agent_step.role,
                text=agent_step.text,
                tool_calls=agent_step.tool_calls,
                phase=new_phase,
            )

        trajectory.steps.append(agent_step)

        # Capture any SQL executed during this turn
        if sql_interceptor:
            new_sqls = sql_interceptor.log[len(trajectory.sql_executions):]
            trajectory.sql_executions.extend(new_sqls)

        # Update files if agent modified them
        if "files" in response:
            trajectory.files.update(response["files"])

        # Per-turn validation
        if turn.expect:
            turn_result = validate_turn(
                agent_step,
                trajectory.sql_executions,
                turn.expect,
                current_phase,
            )

    trajectory.duration_s = time.monotonic() - start_time

    # Post-session hook
    hooks.post_session(trajectory)

    # Run assertions
    if scorer is not None:
        _assert_expectations(trajectory, scorer)

    # Efficiency callback for reporter
    if _on_efficiency_result is not None:
        eff = EfficiencyResult(
            actual_sql_calls=trajectory.total_sql_calls,
            actual_steps=len(trajectory.agent_steps),
            duration_s=trajectory.duration_s,
            phases_reached=[p.value for p in trajectory.phase_order],
        )
        _on_efficiency_result(eff)

    return trajectory


# ---------------------------------------------------------------------------
# Assertion execution
# ---------------------------------------------------------------------------

def _assert_expectations(
    trajectory: SkillTrajectory,
    scorer: SkillScorer,
) -> None:
    """Run all assertions in the scorer against the trajectory.

    Success assertions hard-fail via pytest.fail.
    Efficiency assertions are logged but never cause failure.
    """
    # Efficiency (soft)
    for assertion in scorer._expectations:
        passed = assertion.check(trajectory)
        if not passed:
            # Log but don't fail
            _log_soft_failure(assertion.describe_failure(trajectory))

    # Correctness (hard)
    failures: list[str] = []
    for assertion in scorer._success:
        if not assertion.check(trajectory):
            failures.append(assertion.describe_failure(trajectory))

    if failures:
        detail = "\n\n".join(failures)
        pytest.fail(
            f"{len(failures)} correctness assertion(s) failed:\n\n{detail}"
            f"\n\nTrajectory:\n{trajectory.pretty()}",
            pytrace=False,
        )


def _log_soft_failure(message: str) -> None:
    """Log an efficiency assertion failure without failing the test."""
    import warnings
    warnings.warn(f"[efficiency] {message}", stacklevel=2)
