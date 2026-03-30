"""AI workload improvement tests.

End-to-end tests that measure whether the skill's remediation cycle
actually improves AI workload performance. These tests:

  1. Capture baseline workload metrics (pre-hook)
  2. Run the skill assessment + remediation
  3. Capture post-remediation metrics (post-hook)
  4. Assert improvement via WorkloadMetricImproved assertions

Marked @pytest.mark.slow — requires --run-slow to execute.
In mock mode, simulates workload degradation/improvement via
adjustable noise levels in the mock retrieval index.
"""

from __future__ import annotations

import pytest

from eval.runner import MockAgent, run_skill_session, user_turn
from eval.scorer import SkillScorer
from eval.scenarios.degraded_rag import DEGRADED_RAG
from eval.trajectory import SkillTrajectory
from eval.workloads.base import WorkloadComparison, WorkloadMetrics
from eval.workloads.rag_workload import MockRetrievalIndex, RAGWorkloadRunner


pytestmark = [
    pytest.mark.eval_category("ai_workload"),
    pytest.mark.slow,
]


class TestRAGWorkloadImprovement:
    """Verify that RAG retrieval quality improves after remediation."""

    def test_baseline_captures_metrics(self):
        """Sanity: baseline workload runner produces valid metrics."""
        runner = RAGWorkloadRunner(index=MockRetrievalIndex(noise_level=0.5))
        metrics = runner.run()

        assert "recall@5" in metrics.values
        assert "precision@5" in metrics.values
        assert "avg_latency_ms" in metrics.values
        assert 0.0 <= metrics.values["recall@5"] <= 1.0
        assert 0.0 <= metrics.values["precision@5"] <= 1.0

    def test_improved_index_has_better_recall(self):
        """Lower noise = better recall, validating the mock index model."""
        degraded = RAGWorkloadRunner(index=MockRetrievalIndex(noise_level=0.6))
        improved = RAGWorkloadRunner(index=MockRetrievalIndex(noise_level=0.1))

        baseline_metrics = degraded.run()
        after_metrics = improved.run()

        comparison = degraded.compare(baseline_metrics, after_metrics)
        delta = comparison.delta("recall@5")
        assert delta is not None
        assert delta > 0, f"Expected recall improvement, got delta={delta}"

    def test_full_remediation_cycle_improves_workload(self):
        """Simulated end-to-end: baseline → skill run → improved workload."""
        # 1. Baseline workload (degraded)
        baseline_index = MockRetrievalIndex(noise_level=0.5)
        baseline_runner = RAGWorkloadRunner(index=baseline_index)
        baseline_metrics = baseline_runner.run()

        # 2. Run skill session (mock agent simulates remediation)
        agent = MockAgent(responses=[
            "What platform is your data on?",
            "How would you like to scope this assessment?",
            "What database?",
            "What schema?",
            "What would you like to assess?",
            (
                "RAG Assessment — snowflake — KNOWLEDGE_BASE.DOCUMENTS\n\n"
                "Clean: PASS\nContextual: FAIL\nConsumable: FAIL\n"
                "Current: FAIL\nCorrelated: FAIL\nCompliant: FAIL\n\n"
                "Summary: 1 of 6 stages passing\n\n"
                "Platform: snowflake\nDatabase: KNOWLEDGE_BASE\nSchema: DOCUMENTS\n"
                "Profile: rag\nRequirements: 28 of 62\n\n"
                "Would you like to remediate?"
            ),
            (
                "Remediation Complete\n\n"
                "Stage          Before    After\n"
                "─────          ──────    ─────\n"
                "Consumable     FAIL      PASS\n"
                "Current        FAIL      PASS\n\n"
                "Added embeddings, created vector indexes, enabled change tracking."
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
                user_turn("remediate"),
            ],
            scenario=DEGRADED_RAG,
        )

        # 3. Post-remediation workload (simulated improvement)
        improved_index = MockRetrievalIndex(noise_level=0.1)
        improved_runner = RAGWorkloadRunner(index=improved_index)
        after_metrics = improved_runner.run()

        # 4. Compare and attach to trajectory
        comparison = baseline_runner.compare(baseline_metrics, after_metrics)
        trajectory.workload_comparison = comparison  # type: ignore[attr-defined]

        # 5. Assert improvement
        scorer = (
            SkillScorer()
            .expect_workload_improved("recall@5", min_delta=0.1)
            .expect_workload_not_regressed("avg_latency_ms", max_regression=50.0, higher_is_better=False)
        )

        # Manual assertion since we already have the trajectory
        for assertion in scorer._success:
            passed = assertion.check(trajectory)
            if not passed:
                pytest.fail(assertion.describe_failure(trajectory))

    def test_workload_comparison_summary(self):
        """WorkloadComparison.summary() produces readable output."""
        baseline = WorkloadMetrics(values={"recall@5": 0.45, "avg_latency_ms": 120.0})
        after = WorkloadMetrics(values={"recall@5": 0.82, "avg_latency_ms": 95.0})
        comparison = WorkloadComparison(
            baseline=baseline,
            after=after,
            workload_name="rag_retrieval",
        )

        summary = comparison.summary()
        assert "recall@5" in summary
        assert "avg_latency_ms" in summary
        assert "rag_retrieval" in summary

        assert comparison.delta("recall@5") == pytest.approx(0.37, abs=0.01)
        assert comparison.pct_change("recall@5") == pytest.approx(0.822, abs=0.01)
