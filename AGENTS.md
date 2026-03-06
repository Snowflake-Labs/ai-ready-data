---
name: ai-ready-data
description: Assess and optimize Snowflake data for AI workloads. Runs SQL checks against workload-specific assessments, identifies gaps, and guides remediation.
---

# AI-Ready Data Agent

A skill for assessing and optimizing Snowflake data for AI workloads.

## Entry Point

Read `skills/ai-ready-data/SKILL.md` for full instructions, execution model, and workflow details.

## Triggers

This skill activates when the user mentions:

- "assess my data", "is my data AI-ready", "check my data"
- "data quality check", "data quality assessment"
- "optimize for AI", "AI optimization", "make data AI-ready"
- "assess for RAG", "assess for serving", "assess for training", "assess for agents"
- "data governance audit", "governance check"
- "semantic documentation", "document my schema"
- "PII detection", "masking audit", "data classification"

For building custom assessments:

- "build me an assessment", "create a custom assessment", "customize an assessment"
- "none of the built-in assessments fit", "I need a custom profile"

When the user wants to **build or customize** an assessment, read `skills/build-assessment/SKILL.md`.

## Structure

```
skills/
  ai-ready-data/
    SKILL.md                    ← Assessment & remediation instructions
    requirements/               ← One directory per requirement (61 total)
      {name}/
        requirement.yaml        ← Metadata (no SQL paths)
        check.sql               ← Assessment query (read-only)
        diagnostic.sql          ← Detail query (read-only)
        fix.*.sql               ← Remediation queries (mutating)
    assessments/
      rag.yaml                  ← RAG workload assessment
      feature-serving.yaml      ← Feature serving workload assessment
      training.yaml             ← Training workload assessment
      agents.yaml               ← Agents workload assessment
    reference/
      gotchas.md                ← Snowflake pitfalls
  build-assessment/
    SKILL.md                    ← Guided assessment builder
```
