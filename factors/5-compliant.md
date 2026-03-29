# Factor 5: Compliant

**Definition:** Data is governed with explicit ownership, enforced access boundaries, and AI-specific safeguards.

## Why It Matters for AI

AI introduces novel governance surface area that traditional data governance doesn't cover:

- **PII leaks through embeddings:** Personal data encoded in vector representations can't be masked at query time — it's baked into the model. Once trained, the PII is permanent.
- **Bias encoded in training distributions:** A biased dataset produces a biased model. The bias becomes structural, affecting every inference the model serves.
- **Model outputs as regulated decisions:** Credit scoring, hiring, content moderation — AI outputs increasingly fall under regulatory scrutiny (EU AI Act, CCPA, GDPR).
- **Consent and purpose limitations:** Data collected for analytics may not be permissible for training. Purpose creep from "reporting" to "AI training" may violate original consent.

Traditional RBAC and audit logs are necessary but insufficient. You need:
- **Technical protection:** Masking, anonymization applied *before* AI consumption — not at query time
- **Classification:** Sensitive data identified and tagged so policies can be enforced automatically
- **Purpose boundaries:** Explicit permissions for which AI systems can access what data for what purposes

## By Workload

**RAG** — The model may surface sensitive information in generated responses — PII must be masked before indexing, and access controls must prevent retrieval of restricted content. Classification and column masking are the minimum gates. Governance must be applied *before* AI consumption, not at query time, because once content is in the retrieval corpus it can surface in any response.

**Agents** — Autonomous agents amplify governance gaps — sensitive data exposure scales with agent autonomy. An agent with broad query access can surface, combine, and act on sensitive data across tables in ways that humans never would. Row-level access policies, classification, and purpose limitation are essential. Consent and audit coverage must be stricter than in human-mediated workflows because the agent operates without per-query human review.

**Feature Serving** — Sensitive attributes used as features can leak through model outputs. Column masking must be applied before feature materialization. Row access policies prevent unauthorized feature access. Governance applied at query time is insufficient — it must be enforced at the feature store level before data reaches the model.

**Training** — Training data becomes permanent. PII in training data is PII in the model — it cannot be masked after the fact. Bias in training data is bias in every inference the model serves. EU AI Act requires documented, representative datasets with provenance. Training has the strictest compliance requirements: license compliance, anonymization effectiveness, demographic representation, bias testing, and purpose limitations must all be enforced before data enters a training pipeline.

