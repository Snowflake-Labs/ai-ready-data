# Factor 0: Clean

**Definition:** Clean data is consistently accurate, complete, valid, and free of errors that would compromise downstream consumption.

## Why It Matters for AI

The importance of data quality is nothing new, but the consequences of poor data quality are dramatically increased when used by AI systems.

Clean data is not perfect data. Perfection is neither achievable nor necessary. What matters is that data is clean *enough* for the workload it feeds. Different workloads have materially different tolerance thresholds for data quality. The demands escalate as the system's autonomy increases and as the cost of errors shifts from recoverable to permanent.

Clean data is Factor 0 because nothing else in the framework matters without it. Context, consumability, freshness, lineage, and compliance all assume that the underlying data is trustworthy. If it isn't, you are building on a foundation that will fail — not quietly or immediately, but quietly and pervasively.

Models optimize on whatever signal is present — including noise. Dirty data doesn't just degrade output quality; it gets encoded into weights and embeddings as learned patterns, making errors systematic and hard to detect downstream.

## By Workload

**RAG** — Any chunk can surface verbatim as an answer — a dirty record becomes a wrong answer delivered with full model confidence. Unlike BI dashboards where humans notice anomalies, RAG consumes data uncritically and at machine speed. Duplicate or malformed source documents create retrieval noise and degrade recall.

**Agents** — Agents query data autonomously and act on results. A dirty record doesn't just produce a wrong answer — it can trigger a wrong action. Because agents operate with minimal human oversight, data quality errors compound through multi-step reasoning chains. A malformed value in one query result can cascade through subsequent tool calls, producing confidently wrong conclusions.

**Feature Serving** — A malformed or missing feature value produces a bad prediction on every request that hits it. Feature serving operates at machine speed with no human in the loop to catch anomalies. Cross-column inconsistencies and referential integrity failures cause silent prediction errors that are difficult to detect without monitoring.

**Training** — Errors in training data are not retrieved — they are *learned*. The model encodes patterns from the training distribution into its weights. A bias, a labeling error, or a systematic data quality issue produces a model that is structurally wrong across every inference it serves. Training has the strictest clean data requirements because errors become permanent and remediation means retraining.
