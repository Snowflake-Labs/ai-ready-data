# Factor 4: Correlated

**Definition:** Data is traceable from source to every decision it informs.

## Why It Matters for AI

AI systems are compositional. Data flows through transformations, feature engineering, model inference, and post-processing before producing an output. When something goes wrong — a bad prediction, a hallucinated answer, a biased decision — you need to trace backward: Was it the source data? A transformation bug? A model issue? A post-processing error?

Without end-to-end traceability, a bad output is a black box.

Traditional analytics has similar needs, but the stakes are different. A wrong dashboard number gets noticed, investigated, fixed. A wrong AI decision may be invisible — or may have already triggered downstream actions before anyone notices.

Correlated data enables:
- **Root cause analysis:** Trace a bad output back to its source
- **Impact analysis:** Understand what's affected when source data changes
- **Reproducibility:** Reconstruct any past decision for audit or debugging
- **Cost attribution:** Know which data and transformations contributed to what outcomes

## By Workload

**RAG** — When a chatbot gives a wrong answer, you need to know which chunks were retrieved, what their sources were, and how they were ranked. Traceability lets you debug which source documents produced which answers. Data provenance and record-level traceability are the minimum — without them, debugging retrieval quality is guesswork.

**Agents** — Agentic actions must be auditable — who asked what, what data was used, what was returned. Because agents operate autonomously, the audit trail is the primary mechanism for accountability. Agent attribution tracks which agent accessed which data and what decisions resulted. Pipeline execution audit ensures every step in an agent's reasoning chain is reconstructable.

**Feature Serving** — When a prediction fails, you need to trace back through the feature pipeline to the source data. Pipeline execution audit and record-level traceability enable incident response. Without lineage, diagnosing whether a bad prediction came from stale data, a transformation bug, or a model issue is guesswork.

**Training** — Training data provenance is a regulatory requirement (EU AI Act). You must be able to reconstruct what data trained what model at what time. Reproducibility — running the same training on the same data and getting the same result — depends on versioned, traceable datasets. Training demands the broadest traceability: data versioning, transformation documentation, dependency graphs, and impact analysis.

