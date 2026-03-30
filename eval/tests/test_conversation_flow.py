"""Eval tests for SKILL.md conversation flow compliance.

Verifies that the agent follows the 8-step conversation protocol:
Platform → Discovery → Profile → Adjustments → Coverage → Assess → Report → Remediate.

Uses mock agents with scripted responses to test the harness's phase
detection and flow validation. Replace MockAgent with a live agent
adapter to test actual LLM behavior.
"""

from __future__ import annotations

import pytest

from eval.runner import MockAgent, run_skill_session, user_turn
from eval.scorer import SkillScorer
from eval.scenarios.clean_snowflake import CLEAN_SNOWFLAKE
from eval.scenarios.degraded_rag import DEGRADED_RAG


pytestmark = [pytest.mark.eval_category("conversation_flow")]


def test_guided_flow_reaches_assess_phase():
    """Agent follows guided discovery through to assessment."""
    agent = MockAgent(responses=[
        "What platform is your data on? We support Snowflake.",
        "How would you like to scope this assessment?\n1. I know which database/schema/tables\n2. Help me explore\n3. Scan",
        "What database would you like to assess?",
        "What schema in ANALYTICS?",
        "What would you like to assess?\n1. RAG readiness\n2. Feature serving\n3. Training",
        "RAG Assessment — snowflake — ANALYTICS.PRODUCT_METRICS\n\nSelected: 28 requirements\nRunnable: 26\nProceed?",
        "Executing assessment...\nClean: PASS\nContextual: PASS\nConsumable: PASS\nCurrent: PASS\nCorrelated: PASS\nCompliant: PASS\n\nSummary: 6 of 6 stages passing",
    ])

    trajectory = run_skill_session(
        agent,
        turns=[
            user_turn("Assess my data for RAG readiness"),
            user_turn("snowflake"),
            user_turn("1"),
            user_turn("ANALYTICS"),
            user_turn("PRODUCT_METRICS"),
            user_turn("1"),
            user_turn("yes"),
        ],
        scenario=CLEAN_SNOWFLAKE,
        scorer=(
            SkillScorer()
            .expect_phase_reached("platform")
            .expect_phase_reached("discovery")
            .expect_phase_reached("report")
        ),
    )
    assert len(trajectory.steps) == 14  # 7 user + 7 agent


def test_phase_order_enforced():
    """Agent that skips discovery and jumps to assessment fails."""
    agent = MockAgent(responses=[
        "What platform?",
        "Running assessment now...\nClean: PASS",  # skipped discovery/profile!
    ])

    with pytest.raises(pytest.fail.Exception, match="Required phases missing"):
        run_skill_session(
            agent,
            turns=[
                user_turn("Assess my data"),
                user_turn("snowflake"),
            ],
            scenario=CLEAN_SNOWFLAKE,
            scorer=(
                SkillScorer()
                .expect_phases_required(["platform", "discovery", "profile", "assess"])
            ),
        )


def test_degraded_scenario_reaches_report():
    """Agent completes assessment on a degraded scenario and produces a report."""
    agent = MockAgent(responses=[
        "What platform is your data on?",
        "How would you like to scope this assessment?",
        "What database?",
        "What schema?",
        "What would you like to assess? 1. RAG readiness (28 requirements)",
        "RAG Assessment — snowflake — KNOWLEDGE_BASE.DOCUMENTS\nSelected: 28\nRunnable: 26\nProceed?",
        (
            "RAG Assessment Report\n\n"
            "Clean: PASS\nContextual: FAIL\nConsumable: FAIL\n"
            "Current: FAIL\nCorrelated: FAIL\nCompliant: FAIL\n\n"
            "Summary: 1 of 6 stages passing (8 of 26 requirements passing)\n\n"
            "Platform: snowflake\nDatabase: KNOWLEDGE_BASE\nSchema: DOCUMENTS\n"
            "Profile: rag\nRequirements: 28 of 62"
        ),
    ])

    trajectory = run_skill_session(
        agent,
        turns=[
            user_turn("Assess my documents for RAG"),
            user_turn("snowflake"),
            user_turn("1"),
            user_turn("KNOWLEDGE_BASE"),
            user_turn("DOCUMENTS"),
            user_turn("1"),
            user_turn("yes"),
        ],
        scenario=DEGRADED_RAG,
        scorer=(
            SkillScorer()
            .expect_phase_reached("report")
            .expect_report_stages()
            .expect_report_metadata()
        ),
    )
    assert trajectory.report_text is not None


def test_agent_asks_about_platform_first():
    """The first agent response should ask about platform selection."""
    agent = MockAgent(responses=[
        "What platform is your data on? Currently supported platforms: snowflake",
    ])

    run_skill_session(
        agent,
        turns=[user_turn("Assess my data")],
        scenario=CLEAN_SNOWFLAKE,
        scorer=(
            SkillScorer()
            .expect_agent_asks_about("platform")
        ),
    )


def test_explore_discovery_mode():
    """Agent handles explore-first discovery correctly."""
    agent = MockAgent(responses=[
        "What platform?",
        "How would you like to scope this assessment?",
        (
            "Available databases:\n"
            "  ANALYTICS    3 schemas    104 tables\n"
            "Which database would you like to explore?"
        ),
        (
            "ANALYTICS schemas:\n"
            "  PRODUCT_METRICS    3 tables\n"
            "  USER_BEHAVIOR      3 tables\n"
            "  RAW_EVENTS         3 tables"
        ),
    ])

    trajectory = run_skill_session(
        agent,
        turns=[
            user_turn("Help me explore my data"),
            user_turn("snowflake"),
            user_turn("2"),  # explore mode
            user_turn("ANALYTICS"),
        ],
        scenario=CLEAN_SNOWFLAKE,
        scorer=(
            SkillScorer()
            .expect_phase_reached("discovery")
        ),
    )
    assert len(trajectory.agent_steps) == 4
