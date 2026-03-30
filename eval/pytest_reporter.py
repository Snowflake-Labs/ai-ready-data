"""Pytest session reporter for skill eval results.

Adapted from deepagents' pytest_reporter.py. Produces a terminal
summary and optional JSON report with:
  - Per-category correctness scores
  - SQL efficiency metrics
  - Phase coverage
  - AI workload improvement deltas
"""

from __future__ import annotations

import json
import statistics
from datetime import UTC, datetime
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    import pytest

import eval.runner as _runner_module
from eval.conftest import get_category_for_nodeid
from eval.runner import EfficiencyResult

# ---------------------------------------------------------------------------
# Session-level accumulators
# ---------------------------------------------------------------------------

_RESULTS: dict[str, int] = {
    "passed": 0,
    "failed": 0,
    "skipped": 0,
    "total": 0,
}

_DURATIONS_S: list[float] = []
_EFFICIENCY_RESULTS: list[EfficiencyResult] = []
_CATEGORY_RESULTS: dict[str, dict[str, int]] = {}


# ---------------------------------------------------------------------------
# Derived metrics
# ---------------------------------------------------------------------------

def _sql_efficiency_ratio() -> float | None:
    """Ratio of actual to expected SQL calls across all tests."""
    total_expected = 0
    total_actual = 0
    for r in _EFFICIENCY_RESULTS:
        if r.expected_sql_calls is not None:
            total_expected += r.expected_sql_calls
            total_actual += r.actual_sql_calls
    if total_expected == 0:
        return None
    return round(total_actual / total_expected, 2)


def _phase_coverage() -> dict[str, int]:
    """Count how many tests reached each phase."""
    counts: dict[str, int] = {}
    for r in _EFFICIENCY_RESULTS:
        for phase in r.phases_reached:
            counts[phase] = counts.get(phase, 0) + 1
    return counts


# ---------------------------------------------------------------------------
# Hooks
# ---------------------------------------------------------------------------

def pytest_configure(config: pytest.Config) -> None:
    _ = config
    _runner_module._on_efficiency_result = _EFFICIENCY_RESULTS.append


def pytest_runtest_logreport(report: pytest.TestReport) -> None:
    if report.when != "call":
        return

    _RESULTS["total"] += 1
    duration = float(report.duration)
    _DURATIONS_S.append(duration)

    outcome = report.outcome
    if outcome in {"passed", "failed", "skipped"}:
        _RESULTS[outcome] += 1

    category = get_category_for_nodeid(report.nodeid)
    if category and outcome in {"passed", "failed"}:
        bucket = _CATEGORY_RESULTS.setdefault(category, {"passed": 0, "failed": 0, "total": 0})
        bucket[outcome] += 1
        bucket["total"] += 1

    if _EFFICIENCY_RESULTS and _EFFICIENCY_RESULTS[-1].duration_s is None:
        _EFFICIENCY_RESULTS[-1].duration_s = duration
        _EFFICIENCY_RESULTS[-1].passed = outcome == "passed"


def pytest_sessionfinish(session: pytest.Session, exitstatus: int) -> None:
    _ = exitstatus

    correctness = round(
        (_RESULTS["passed"] / _RESULTS["total"]) if _RESULTS["total"] else 0.0, 2
    )
    sql_ratio = _sql_efficiency_ratio()
    phase_cov = _phase_coverage()
    median_duration = round(statistics.median(_DURATIONS_S), 4) if _DURATIONS_S else 0.0

    category_scores: dict[str, float] = {}
    for cat, counts in sorted(_CATEGORY_RESULTS.items()):
        if counts["total"] > 0:
            category_scores[cat] = round(counts["passed"] / counts["total"], 2)

    # Terminal output
    tr = session.config.pluginmanager.getplugin("terminalreporter")
    if tr is not None:
        tr.write_sep("=", "ai-ready-data skill eval summary")
        tr.write_line(f"model: {session.config.getoption('--model') or 'mock'}")
        tr.write_line(
            f"results: {_RESULTS['passed']} passed, {_RESULTS['failed']} failed, "
            f"{_RESULTS['skipped']} skipped (total={_RESULTS['total']})"
        )
        tr.write_line(f"correctness: {correctness:.2f}")

        if category_scores:
            tr.write_sep("-", "per-category correctness")
            for cat, score in sorted(category_scores.items()):
                counts = _CATEGORY_RESULTS[cat]
                tr.write_line(f"  {cat}: {score:.2f} ({counts['passed']}/{counts['total']})")

        if sql_ratio is not None:
            tr.write_line(f"sql_efficiency: {sql_ratio:.2f}")
        tr.write_line(f"median_duration_s: {median_duration:.4f}")

        if phase_cov:
            tr.write_sep("-", "phase coverage (tests reaching each phase)")
            for phase, count in sorted(phase_cov.items()):
                tr.write_line(f"  {phase}: {count}")

    # JSON report
    payload: dict[str, object] = {
        "created_at": datetime.now(UTC).replace(microsecond=0).isoformat(),
        "model": session.config.getoption("--model") or "mock",
        **_RESULTS,
        "correctness": correctness,
        "category_scores": category_scores,
        "sql_efficiency": sql_ratio,
        "median_duration_s": median_duration,
        "phase_coverage": phase_cov,
    }

    report_path_opt = session.config.getoption("--evals-report-file")
    if not report_path_opt:
        return

    report_path = Path(str(report_path_opt))
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
