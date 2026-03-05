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

**Serving (RAG, feature serving)** — In RAG, the model may surface sensitive information in responses — PII must be masked before indexing, and access controls must prevent retrieval of restricted content. In feature serving, sensitive attributes used as features can leak through model outputs. Both require governance applied *before* AI consumption, not at query time.

**Training** — Training data becomes permanent. PII in training data is PII in the model — it cannot be masked after the fact. Bias in training data is bias in every inference the model serves. EU AI Act requires documented, representative datasets with provenance. Purpose limitations must be enforced: data collected for analytics may not be permissible for training.

