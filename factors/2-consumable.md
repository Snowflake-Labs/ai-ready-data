# Factor 2: Consumable

**Definition:** Data is served in the right format and at the right latencies for AI workloads.

## Why It Matters for AI

AI workloads have fundamentally different access patterns than BI. Traditional analytics tolerates query times measured in seconds or minutes — a dashboard refresh, a report generation. AI workloads cannot.

- **Vector retrieval** must return in milliseconds for interactive experiences
- **Feature serving** requires sub-100ms latency for real-time inference
- **Inference chains** make multiple round-trips, multiplying any latency

Beyond latency, AI systems require data in specific formats:
- **Embeddings** for semantic search and similarity
- **Pre-chunked documents** sized for context windows
- **Feature vectors** materialized for both training and serving
- **Native formats** (Parquet, JSON, vectors) without conversion overhead

A format mismatch or latency miss isn't a degraded experience — it's a failed prediction, a timeout, a broken agent.

## By Workload

**Serving (RAG, feature serving)** — RAG retrieval must complete in milliseconds for interactive experiences — documents must be pre-chunked, embeddings must exist, and vector indexes must be built. Feature serving requires sub-100ms lookups for real-time inference, with features materialized in row-oriented stores. Query-time transformation breaks SLAs in both cases.

**Training** — Training processes terabytes repeatedly across epochs. Features must exist in batch-optimized columnar formats. I/O bottlenecks cause expensive GPU idle time. Any format mismatch or throughput limitation multiplies across the entire training run.

