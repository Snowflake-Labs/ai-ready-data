---
name: ai-ready-data
description: Assess and optimize Snowflake data for AI workloads. Runs SQL checks against serving or training requirements, identifies gaps, and guides remediation.
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
- "assess for serving", "assess for training"
- "data governance audit", "governance check"
- "semantic documentation", "document my schema"
- "PII detection", "masking audit", "data classification"

## Structure

```
skills/ai-ready-data/
  SKILL.md                ← Full skill instructions
  requirements/           ← One YAML per requirement (61 total)
  sql/
    check/                ← Assessment queries (read-only)
    diagnostic/           ← Detail queries (read-only)
    fix/                  ← Remediation queries (mutating)
  profiles/
    serving.yaml          ← Serving workload thresholds
    training.yaml         ← Training workload thresholds
  reference/
    gotchas.md            ← Snowflake pitfalls
```
