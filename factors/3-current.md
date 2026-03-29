# Factor 3: Current

**Definition:** Data reflects the present state, with freshness enforced by infrastructure rather than assumed by convention.

## Why It Matters for AI

Models have no concept of time. Every input is treated as ground truth. When a model receives stale data, it doesn't produce a "stale answer", it produces a confident, wrong one. The staleness is invisible in the output.

Traditional analytics tolerates staleness through convention: "this dashboard refreshes nightly," "that report uses yesterday's data." Humans adjust their interpretation accordingly. AI systems cannot. 

Thus, freshness must be enforced by infrastructure through mechanisms like:
- **Change tracking** captures when data changes
- **Streams** propagate changes incrementally
- **Materialized views** maintain derived data automatically
- **Freshness monitoring** alerts when data falls outside SLA

Without these mechanisms, freshness depends on pipeline schedules holding, jobs not failing, and upstream sources behaving — a chain of assumptions that eventually breaks.

## By Workload

**RAG** — Users expect current information. A RAG-powered support agent citing outdated policies creates real harm. Stale documents mean stale answers delivered with full model confidence. Change detection and freshness enforcement ensure the retrieval corpus reflects the present state, not a stale snapshot.

**Agents** — Agents that answer from stale data give confidently wrong responses — and may take wrong actions based on those responses. Because agents operate autonomously, stale data is more dangerous than in human-mediated workflows. Propagation latency must be tightly controlled so that agent queries reflect current state.

**Feature Serving** — Stale features mean outdated predictions. Feature serving requires values that reflect the present state — a stale feature produces a prediction based on yesterday's reality. Changes must propagate before the next request. Feature refresh compliance and training-serving parity ensure that serving features stay synchronized with reality and with the features the model was trained on.

**Training** — Training on stale data teaches the model outdated patterns. Point-in-time correctness is essential — the features available at inference must match what was available at training time. Training-serving skew, where training features don't match serving features, silently degrades model performance. Schema evolution tracking ensures the training pipeline adapts to upstream changes.

