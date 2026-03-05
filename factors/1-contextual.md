# Factor 1: Contextual

**Definition:** Meaning is explicit and colocated with the data. No external lookup, tribal knowledge, or human context is required to take action on the data.

## Why It Matters for AI

If the data's meaning lives outside the system or is not accessible at inference-time, the data is not interpretable. Traditional analytics tolerates implicit meaning — analysts learn the schema, read a wiki, ask colleagues. AI systems have none of that context. A model consuming data with ambiguous column names, missing relationship declarations, or undocumented business logic is operating blind.

Contextual data ensures consistent interpretation across contexts and models at inference-time. Meaning must be explicit, machine-readable, and colocated with the data it describes.

Meaning can be broken into four dimensions:

- **Structural Semantics (What the data is):** Typed schemas, constraint declarations, and evolution contracts encode the data's formal identity.
- **Business Semantics (What the data means):** Versioned definitions, calculation logic, and controlled vocabularies encode authoritative meaning.
- **Entity Semantics (How the data connects):** Typed, scoped, and/or probabilistic relationships encode referential integrity of meaning.
- **Contextual Semantics (When/where it applies):** Temporal scope, jurisdictional applicability, provenance, and confidence encode the boundaries of validity.

## By Workload

**Serving (RAG, feature serving)** — The model has no tribal knowledge. In RAG, if meaning is not colocated with the data, the model generates answers without understanding what the data represents. In feature serving, undocumented features cause silent misinterpretation — the model uses a value without knowing its units, valid range, or business meaning. Unlike analysts who can look up a column definition or ask a colleague, serving workloads have only what the data declares about itself.

**Training** — Ambiguous semantics propagate into learned representations. If the model does not know what a column means, what relationships exist, or when data is valid, it cannot learn the right signal. Full semantic coverage is essential — meaning that is implicit or external to the data at training time is meaning the model will never have.

