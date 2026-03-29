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

**RAG** — Retrieval must complete in milliseconds for interactive experiences. Documents must be pre-chunked to fit context windows, embeddings must exist for semantic search, and vector indexes must be built and maintained. Query-time transformation breaks SLAs. Retrieval recall and search optimization directly determine answer quality.

**Agents** — Agents need fast query responses and predictable data formats. Text-to-SQL and tool-use patterns require optimized access paths, point lookups, and sub-second latency. Agents make multiple round-trips per interaction, so latency compounds — a slow lookup on one step delays the entire reasoning chain.

**Feature Serving** — Real-time inference requires sub-100ms lookups with features materialized in row-oriented stores. Features must be pre-computed and point-addressable by entity key. Query-time transformation breaks SLAs. Feature materialization coverage and serving latency compliance are the critical gates.

**Training** — Training processes terabytes repeatedly across epochs. Features must exist in batch-optimized columnar formats. I/O bottlenecks cause expensive GPU idle time. Any format mismatch or throughput limitation multiplies across the entire training run.

