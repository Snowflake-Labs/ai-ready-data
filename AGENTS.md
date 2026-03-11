---
name: ai-ready-data
description: Assess and optimize data for AI workloads across platforms. Runs checks against workload-specific profiles, identifies gaps, and guides remediation.
---

# AI-Ready Data Agent

A skill for assessing and optimizing data for AI workloads.

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

## Structure

```
skills/
  ai-ready-data/
    SKILL.md                    ← Orchestration protocol
    platforms/                  ← Platform references
      {PLATFORM}.md             ← Capabilities, nuances, permissions, dialect
    requirements/               ← One directory per requirement (61 total)
      index.yaml                ← Requirement registry
      {name}/
        requirement.yaml        ← Metadata (no SQL paths)
        {platform}/
          check.sql           ← Platform check query (read-only)
          diagnostic.sql      ← Platform detail query (read-only)
          fix.*.sql           ← Platform remediation queries (mutating)
    workloads/
      rag.yaml                  ← RAG workload profile
      feature-serving.yaml      ← Feature serving workload profile
      training.yaml             ← Training workload profile
      agents.yaml               ← Agents workload profile
```
