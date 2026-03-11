# Contributing

Thanks for contributing to the AI-Ready Data framework.

This project is evolving from a Snowflake-first skillset to a multi-platform framework. The immediate architecture direction is:

- Canonical requirement intent in `requirement.yaml`
- Platform-specific execution implementations
- Explicit platform capabilities and normalized results

## Repository Conventions

- Keep requirement intent platform-agnostic.
- Keep platform-specific logic isolated from canonical metadata.
- Preserve the six factor stage names exactly: `Clean`, `Contextual`, `Consumable`, `Current`, `Correlated`, `Compliant`.
- Keep scoring normalized between `0.0` and `1.0` when a check is supported.

## Contribution Types

- New or improved requirements
- New assessments
- Platform implementations (Snowflake, Databricks, AWS, Azure)
- Contributor docs and validation guardrails

## Phase 0 Contracts

Before adding platform implementations, align with:

- `docs/contracts/execution-contract.md`
- `docs/platforms/capability-schema.md`
- `docs/PLATFORM_CONTRIBUTOR_SPEC.md`

## Pull Request Expectations

- Document behavior changes clearly.
- Keep changes scoped (one concern per PR).
- For platform work, include or update:
  - platform capability manifest
  - supported requirement matrix/docs
  - guardrail validation coverage where applicable

## Local Validation

Run:

```bash
python3 scripts/validate_phase0.py
python3 scripts/validate_structure.py
python3 scripts/validate_requirements_contracts.py
python3 scripts/generate_support_matrix.py --check
```

This checks:

- Required docs exist
- Capability manifests exist and include minimum fields
- Capability keys follow naming conventions
- Requirement metadata schema and index consistency
- SQL check contract (`AS value`) and pilot conformance fixtures
- Support matrix artifact freshness

## Notes on Skill Source of Truth

Skill instructions currently exist in both `skills/` and `.agents/skills/`.
Do not edit one copy in isolation.

Recommended local hook setup:

```bash
git config core.hooksPath .githooks
```

Then use `.githooks/pre-commit` to prevent mirror drift and stale artifacts.
