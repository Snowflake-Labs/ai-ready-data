"""Pytest configuration for the ai-ready-data skill eval suite.

Provides:
  - --model option for selecting the LLM
  - --eval-category filtering by test category
  - --run-slow gate for AI workload tests
  - Scenario fixtures for mock Snowflake environments
  - Agent adapter fixture (mock by default, live with --live-agent)
"""

from __future__ import annotations

from typing import Any

import pytest

from eval.mocks.mock_snowflake import SnowflakeScenario
from eval.runner import AgentAdapter, MockAgent
from eval.scenarios.clean_snowflake import CLEAN_SNOWFLAKE
from eval.scenarios.degraded_rag import DEGRADED_RAG
from eval.scenarios.governance_gap import GOVERNANCE_GAP

import eval.runner as _runner_module

pytest_plugins = ["eval.pytest_reporter"]


# ---------------------------------------------------------------------------
# CLI options
# ---------------------------------------------------------------------------

def pytest_addoption(parser: pytest.Parser) -> None:
    parser.addoption(
        "--model",
        action="store",
        default=None,
        help="Model identifier for agent evals (e.g. 'anthropic:claude-sonnet-4-6')",
    )
    parser.addoption(
        "--eval-category",
        action="append",
        default=[],
        help="Run only evals tagged with this category (repeatable)",
    )
    parser.addoption(
        "--run-slow",
        action="store_true",
        default=False,
        help="Run slow AI workload tests that require live Snowflake",
    )
    parser.addoption(
        "--live-agent",
        action="store_true",
        default=False,
        help="Use live Cortex Code CLI agent instead of mock",
    )
    parser.addoption(
        "--evals-report-file",
        action="store",
        default=None,
        help="Write a JSON eval report to this path",
    )


# ---------------------------------------------------------------------------
# Custom markers
# ---------------------------------------------------------------------------

def pytest_configure(config: pytest.Config) -> None:
    config.addinivalue_line(
        "markers",
        "eval_category(name): tag an eval test with a category for grouping/reporting",
    )
    config.addinivalue_line(
        "markers",
        "slow: marks tests that require live infrastructure (deselected unless --run-slow)",
    )


# ---------------------------------------------------------------------------
# Category filtering
# ---------------------------------------------------------------------------

_NODEID_TO_CATEGORY: dict[str, str] = {}


def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:
    # Skip slow tests unless --run-slow
    if not config.getoption("--run-slow"):
        skip_slow = pytest.mark.skip(reason="need --run-slow option to run")
        for item in items:
            if "slow" in item.keywords:
                item.add_marker(skip_slow)

    # Category filtering
    categories = config.getoption("--eval-category")
    for item in items:
        marker = item.get_closest_marker("eval_category")
        if marker and marker.args:
            _NODEID_TO_CATEGORY[item.nodeid] = str(marker.args[0])

    if not categories:
        return

    selected: list[pytest.Item] = []
    deselected: list[pytest.Item] = []
    for item in items:
        marker = item.get_closest_marker("eval_category")
        if marker and marker.args and marker.args[0] in categories:
            selected.append(item)
        else:
            deselected.append(item)
    items[:] = selected
    config.hook.pytest_deselected(items=deselected)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture(scope="session")
def model_name(request: pytest.FixtureRequest) -> str:
    """The model identifier from --model or a default."""
    return request.config.getoption("--model") or "mock"


@pytest.fixture
def agent(request: pytest.FixtureRequest) -> AgentAdapter:
    """Agent adapter — mock by default, live with --live-agent."""
    if request.config.getoption("--live-agent"):
        pytest.skip("Live agent adapter not yet implemented")
    return MockAgent(responses=[])


@pytest.fixture
def clean_scenario() -> SnowflakeScenario:
    return CLEAN_SNOWFLAKE


@pytest.fixture
def degraded_rag_scenario() -> SnowflakeScenario:
    return DEGRADED_RAG


@pytest.fixture
def governance_gap_scenario() -> SnowflakeScenario:
    return GOVERNANCE_GAP


def get_category_for_nodeid(nodeid: str) -> str | None:
    return _NODEID_TO_CATEGORY.get(nodeid)
