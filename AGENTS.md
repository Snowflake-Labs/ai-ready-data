---
name: ai-ready-data
description: Assess and optimize data for AI workloads across platforms. Scan estates for prioritization, assess assets against profiles, and guide remediation.
---

# AI-Ready Data Agent

A skill for assessing and optimizing data for AI workloads.

## Entry Point

Read `skills/ai-ready-data/SKILL.md` for full instructions, execution model, and workflow details.

## Triggers

This skill activates when the user mentions:

- "assess my data", "is my data AI-ready", "check my data"
- "scan my data estate", "data estate overview", "prioritize my data"
- "data quality check", "data quality assessment"
- "optimize for AI", "AI optimization", "make data AI-ready"
- "assess for RAG", "assess for serving", "assess for training", "assess for agents"

## Structure

```
skills/
  ai-ready-data/
    SKILL.md                    ← Orchestration protocol
    platforms/                  ← Platform references
      {PLATFORM}.md             ← Capabilities, nuances, permissions, dialect
    requirements/               ← Requirement manifest + implementation directories
      requirements.yaml         ← Single manifest (all requirement metadata)
      {name}/
        {platform}/
          check.md            ← Context + check SQL (read-only, returns 0–1 score)
          diagnostic.md       ← Context + diagnostic SQL (read-only detail)
          fix.md              ← Context + remediation SQL/guidance (mutating)
    profiles/
      scan.yaml                 ← Estate-level scan profile (lightweight)
      rag.yaml                  ← RAG readiness profile
      feature-serving.yaml      ← Feature serving readiness profile
      training.yaml             ← Training readiness profile
      agents.yaml               ← Agents readiness profile
```
