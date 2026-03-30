"""RAG retrieval workload runner.

Measures retrieval quality before and after the ai-ready-data skill
remediation cycle. Metrics: recall@k, precision@k, avg latency,
and a composite retrieval score.

Designed for Snowflake Cortex Search or any vector search endpoint.
In mock mode, simulates retrieval against a pre-defined corpus.
"""

from __future__ import annotations

import time
from dataclasses import dataclass, field
from typing import Any

from eval.workloads.base import WorkloadMetrics, WorkloadRunner


@dataclass(frozen=True)
class RAGQuery:
    """A test query with known-good retrieval targets."""

    query: str
    expected_doc_ids: list[str]
    category: str = "general"


# Default eval queries for testing
RAG_EVAL_QUERIES: list[RAGQuery] = [
    RAGQuery(
        query="How do I reset my password?",
        expected_doc_ids=["doc_001", "doc_002"],
        category="account",
    ),
    RAGQuery(
        query="What are the pricing tiers?",
        expected_doc_ids=["doc_010", "doc_011", "doc_012"],
        category="billing",
    ),
    RAGQuery(
        query="How to configure SSO with SAML?",
        expected_doc_ids=["doc_020"],
        category="security",
    ),
    RAGQuery(
        query="What data formats are supported for import?",
        expected_doc_ids=["doc_030", "doc_031"],
        category="data",
    ),
    RAGQuery(
        query="How do I set up automated backups?",
        expected_doc_ids=["doc_040", "doc_041"],
        category="operations",
    ),
]


@dataclass
class MockRetrievalIndex:
    """Simulates a vector search index with controllable quality.

    Adjusting `noise_level` simulates degraded vs. improved retrieval:
      - 0.0: perfect retrieval (all expected docs in top-k)
      - 0.5: half the expected docs are retrieved
      - 1.0: completely random results
    """

    noise_level: float = 0.3
    latency_base_ms: float = 50.0
    latency_noise_ms: float = 20.0
    all_doc_ids: list[str] = field(default_factory=lambda: [f"doc_{i:03d}" for i in range(100)])

    def search(self, query: str, expected: list[str], k: int = 5) -> tuple[list[str], float]:
        """Return (retrieved_doc_ids, latency_ms)."""
        import random

        start = time.monotonic()

        # Deterministic seed from query for reproducibility
        rng = random.Random(hash(query))

        # Mix expected docs with noise
        results: list[str] = []
        for doc_id in expected:
            if rng.random() > self.noise_level:
                results.append(doc_id)

        # Fill remaining slots with random docs
        noise_pool = [d for d in self.all_doc_ids if d not in results]
        while len(results) < k and noise_pool:
            results.append(rng.choice(noise_pool))
            noise_pool.remove(results[-1])

        # Simulate latency
        simulated_ms = self.latency_base_ms + rng.uniform(0, self.latency_noise_ms)
        actual_ms = (time.monotonic() - start) * 1000 + simulated_ms

        return results[:k], actual_ms


class RAGWorkloadRunner(WorkloadRunner):
    """Measures RAG retrieval quality against a set of eval queries."""

    def __init__(
        self,
        queries: list[RAGQuery] | None = None,
        k: int = 5,
        index: MockRetrievalIndex | None = None,
    ) -> None:
        self._queries = queries or RAG_EVAL_QUERIES
        self._k = k
        self._index = index or MockRetrievalIndex()

    @property
    def name(self) -> str:
        return "rag_retrieval"

    def run(self, **kwargs: Any) -> WorkloadMetrics:
        """Execute all queries and compute aggregate metrics."""
        recalls: list[float] = []
        precisions: list[float] = []
        latencies: list[float] = []

        for q in self._queries:
            retrieved, latency_ms = self._index.search(q.query, q.expected_doc_ids, self._k)
            latencies.append(latency_ms)

            # Recall@k: fraction of expected docs found in retrieved
            hits = sum(1 for d in q.expected_doc_ids if d in retrieved)
            recall = hits / len(q.expected_doc_ids) if q.expected_doc_ids else 0.0
            recalls.append(recall)

            # Precision@k: fraction of retrieved that are relevant
            precision = hits / len(retrieved) if retrieved else 0.0
            precisions.append(precision)

        avg_recall = sum(recalls) / len(recalls) if recalls else 0.0
        avg_precision = sum(precisions) / len(precisions) if precisions else 0.0
        avg_latency = sum(latencies) / len(latencies) if latencies else 0.0
        p99_latency = sorted(latencies)[int(len(latencies) * 0.99)] if latencies else 0.0

        return WorkloadMetrics(
            values={
                f"recall@{self._k}": round(avg_recall, 4),
                f"precision@{self._k}": round(avg_precision, 4),
                "avg_latency_ms": round(avg_latency, 2),
                "p99_latency_ms": round(p99_latency, 2),
                "query_count": float(len(self._queries)),
            },
            metadata={
                "k": self._k,
                "noise_level": self._index.noise_level,
            },
        )
