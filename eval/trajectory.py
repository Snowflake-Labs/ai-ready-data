"""Core data structures for skill evaluation trajectories.

Adapted from deepagents' AgentTrajectory pattern but extended with
phase tracking, SQL execution logs, and requirement scoring that
the ai-ready-data conversation protocol requires.
"""

from __future__ import annotations

import re
from collections.abc import Mapping
from dataclasses import dataclass, field
from enum import Enum
from typing import Any


# ---------------------------------------------------------------------------
# Conversation phases (mirrors SKILL.md 8-step flow)
# ---------------------------------------------------------------------------

STAGE_NAMES = ("Clean", "Contextual", "Consumable", "Current", "Correlated", "Compliant")

class Phase(str, Enum):
    PLATFORM = "platform"
    DISCOVERY = "discovery"
    PROFILE = "profile"
    ADJUSTMENTS = "adjustments"
    COVERAGE = "coverage"
    ASSESS = "assess"
    REPORT = "report"
    REMEDIATE = "remediate"

PHASE_ORDER = list(Phase)


# ---------------------------------------------------------------------------
# SQL execution tracking
# ---------------------------------------------------------------------------

class SQLKind(str, Enum):
    CHECK = "check"
    DIAGNOSTIC = "diagnostic"
    FIX = "fix"
    DISCOVERY = "discovery"
    OTHER = "other"


@dataclass(frozen=True)
class SQLExecution:
    """A single SQL statement executed during the session."""

    sql: str
    kind: SQLKind
    phase: Phase
    requirement: str | None = None
    platform: str | None = None
    result: Any = None
    duration_ms: float | None = None

    @property
    def is_mutating(self) -> bool:
        """Heuristic: does this SQL modify state?"""
        normalized = self.sql.strip().upper()
        mutating_prefixes = (
            "INSERT", "UPDATE", "DELETE", "DROP", "ALTER", "CREATE",
            "MERGE", "TRUNCATE", "GRANT", "REVOKE", "COPY",
        )
        return any(normalized.startswith(p) for p in mutating_prefixes)

    @property
    def has_unsubstituted_placeholders(self) -> bool:
        return bool(re.search(r"\{\{\s*\w+\s*\}\}", self.sql))


# ---------------------------------------------------------------------------
# Agent step (mirrors deepagents AgentStep)
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class AgentStep:
    """One turn of agent output, optionally with tool calls and observations."""

    index: int
    role: str  # "assistant" or "user"
    text: str
    tool_calls: list[dict[str, Any]] = field(default_factory=list)
    tool_results: list[dict[str, Any]] = field(default_factory=list)
    phase: Phase | None = None

    def __post_init__(self) -> None:
        if self.index <= 0:
            msg = "index must be positive"
            raise ValueError(msg)


# ---------------------------------------------------------------------------
# Requirement & stage results
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class RequirementResult:
    """Outcome of a single requirement check."""

    key: str
    value: float
    threshold: float
    passed: bool
    sql_used: str | None = None
    scope: str | None = None  # "schema", "table", "column"


@dataclass(frozen=True)
class StageResult:
    """Outcome of one assessment stage (Clean, Contextual, etc.)."""

    name: str
    passed: bool
    why: str
    requirements: list[RequirementResult] = field(default_factory=list)

    @property
    def pass_count(self) -> int:
        return sum(1 for r in self.requirements if r.passed)

    @property
    def fail_count(self) -> int:
        return sum(1 for r in self.requirements if not r.passed)


@dataclass(frozen=True)
class Remediation:
    """A remediation action applied during the session."""

    requirement: str
    stage: str
    sql: str | None
    description: str
    approved: bool
    before_value: float | None = None
    after_value: float | None = None


# ---------------------------------------------------------------------------
# SkillTrajectory — the top-level evaluation artifact
# ---------------------------------------------------------------------------

@dataclass
class SkillTrajectory:
    """Full trajectory of a skill evaluation session.

    Extends deepagents' AgentTrajectory with phase tracking,
    SQL execution logs, and structured scoring results.
    """

    steps: list[AgentStep] = field(default_factory=list)
    files: dict[str, str] = field(default_factory=dict)

    # Skill-specific tracking
    phases_entered: list[Phase] = field(default_factory=list)
    sql_executions: list[SQLExecution] = field(default_factory=list)
    requirement_scores: dict[str, float] = field(default_factory=dict)
    stage_results: dict[str, StageResult] = field(default_factory=dict)
    report_text: str | None = None
    remediations: list[Remediation] = field(default_factory=list)
    profile_loaded: str | None = None
    platform: str | None = None
    duration_s: float | None = None

    # ── Derived properties ──

    @property
    def answer(self) -> str:
        """Text content of the last assistant step."""
        for step in reversed(self.steps):
            if step.role == "assistant":
                return step.text
        return ""

    @property
    def total_sql_calls(self) -> int:
        return len(self.sql_executions)

    @property
    def mutating_sql_calls(self) -> list[SQLExecution]:
        return [s for s in self.sql_executions if s.is_mutating]

    @property
    def total_tool_calls(self) -> int:
        return sum(len(s.tool_calls) for s in self.steps)

    @property
    def agent_steps(self) -> list[AgentStep]:
        return [s for s in self.steps if s.role == "assistant"]

    @property
    def user_steps(self) -> list[AgentStep]:
        return [s for s in self.steps if s.role == "user"]

    @property
    def phase_order(self) -> list[Phase]:
        """Unique phases in the order they were first entered."""
        seen: set[Phase] = set()
        order: list[Phase] = []
        for phase in self.phases_entered:
            if phase not in seen:
                seen.add(phase)
                order.append(phase)
        return order

    def sql_in_phase(self, phase: Phase) -> list[SQLExecution]:
        return [s for s in self.sql_executions if s.phase == phase]

    def pretty(self) -> str:
        """Human-readable summary of the trajectory."""
        lines: list[str] = []
        lines.append(f"platform: {self.platform or 'unknown'}")
        lines.append(f"profile: {self.profile_loaded or 'unknown'}")
        lines.append(f"phases: {' → '.join(p.value for p in self.phase_order)}")
        lines.append(f"sql calls: {self.total_sql_calls} ({len(self.mutating_sql_calls)} mutating)")
        lines.append("")

        for step in self.steps:
            phase_tag = f" [{step.phase.value}]" if step.phase else ""
            lines.append(f"step {step.index} ({step.role}){phase_tag}:")
            if step.tool_calls:
                for tc in step.tool_calls:
                    lines.append(f"  tool: {tc.get('name')} {tc.get('args', {})}")
            text = step.text.strip()
            if text:
                preview = text[:200].replace("\n", "\\n")
                lines.append(f"  text: {preview}")

        if self.stage_results:
            lines.append("")
            lines.append("── stage results ──")
            for name in STAGE_NAMES:
                if name in self.stage_results:
                    sr = self.stage_results[name]
                    status = "PASS" if sr.passed else "FAIL"
                    lines.append(f"  {name}: {status} ({sr.pass_count}/{len(sr.requirements)})")

        return "\n".join(lines)


# ---------------------------------------------------------------------------
# Builder helpers
# ---------------------------------------------------------------------------

def build_trajectory_from_messages(
    messages: list[dict[str, Any]],
    *,
    files: dict[str, str] | None = None,
) -> SkillTrajectory:
    """Construct a SkillTrajectory from a flat list of message dicts.

    Each message dict should have at minimum: role, content.
    Tool calls and results are extracted from the message structure.
    """
    steps: list[AgentStep] = []
    index = 0
    for msg in messages:
        role = msg.get("role", "")
        if role not in ("assistant", "user"):
            continue
        index += 1
        steps.append(AgentStep(
            index=index,
            role=role,
            text=msg.get("content", "") or "",
            tool_calls=msg.get("tool_calls", []),
            tool_results=msg.get("tool_results", []),
        ))

    return SkillTrajectory(
        steps=steps,
        files=files or {},
    )
