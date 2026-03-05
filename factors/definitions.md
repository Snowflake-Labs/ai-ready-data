# Definitions

Canonical definitions for the AI-Ready Data project. A short summary appears in the framework README; this document is the source of truth.

---

## AI-ready data

**AI-ready data** is data that meets the requirements of the five factors (Contextual, Consumable, Current, Correlated, Compliant) for the **workload (use case)** you target. The factors define what the data layer must provide so that what crosses the boundary into the AI system is fit for consumption.

Whether data is "AI-ready" is therefore relative to your use case. We define four workloads: RAG, Agents, Feature Serving, and Training.

---

## Data layer and AI system boundary

An **AI system** performs inference: it accepts inputs, applies a learned function, and produces outputs. The boundary of the AI system is the model and its inference layer. Everything outside that boundary—ingestion, transformation, storage, serving—is the **data layer**. The data layer's job is to ensure that what crosses the boundary is fit for consumption. Assessment evaluates the data layer against the factors; it does not evaluate the model or inference logic.

---

## Data product

A **data product** is a named, bounded set of data assets maintained by a defined owner to serve a specific business function. It is the primary unit of assessment. Agents can evaluate data products against the five factors.

A data product has a **name** (user-declared, e.g. "customer_360"), an optional **owner** (team or person), a set of **assets** (tables, schemas, or patterns), and an optional **target workload**. When no data products are defined, the agent treats all discovered assets as a single unnamed product.

---

## Data asset

A **data asset** is a concrete object within a data product: e.g. a table and column in a relational system, a collection and field in a document store, or an index in a search engine. 

---

## Workloads (use cases)

Requirements differ by **use case**: what you are building determines how strict the requirements are. We define four workload categories:

- **RAG** — Retrieval-augmented generation: chunking, embedding, retrieval, and governance for LLM-powered search and Q&A.
- **Agents** — Agentic AI: Text-to-SQL, tool use, and autonomous data access by LLM agents.
- **Feature Serving** — Online feature stores and real-time inference: low-latency lookups, materialized features, and freshness guarantees.
- **Training** — AI/ML training: fine-tuning, ML training, and dataset curation.

Requirements and thresholds are defined per factor and per workload. Each workload has its own assessment profile with workload-specific requirements and thresholds.

---

## Factor

A **factor** is one of six high-level categories of AI-readiness: Clean (0), Contextual (1), Consumable (2), Current (3), Correlated (4), Compliant (5). Each factor has a definition, workload-specific requirements and thresholds, and platform-specific check operations. Checks are tagged by factor and workload.
