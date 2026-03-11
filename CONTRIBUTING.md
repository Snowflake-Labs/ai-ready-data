# Contributing

Thanks for contributing to the AI-Ready Data framework.

## Architecture

The framework has five layers:

- **Factors** — the six categories (Clean, Contextual, Consumable, Current, Correlated, Compliant)
- **Requirements** — platform-agnostic testable claims about data quality
- **Workload Profiles** — curated selections of requirements with thresholds (`workloads/*.yaml`)
- **Platform References** — everything the agent needs to operate on a specific platform (`platforms/`)
- **Assessments** — ephemeral runtime compilations of workload + platform + scope

## Contribution Types

- New or improved requirements
- New workload profiles
- Platform implementations (Snowflake, Databricks, AWS, Azure)
- Platform reference improvements

## Adding a Requirement

1. Create `requirements/{name}/requirement.yaml` with canonical metadata.
2. Add platform files under `requirements/{name}/{platform}/`.
3. Add to relevant workload profiles.

## Adding a Platform

1. Create `platforms/{PLATFORM}.md` covering capabilities, dialect, permissions, nuances, guards, and delegations.
2. Add requirement files under `requirements/{name}/{platform}/`.

## Conventions

- Keep requirement metadata platform-agnostic.
- Keep platform-specific logic in platform references and requirement platform directories.
- Preserve the six factor stage names exactly.
- Scoring: 0.0 to 1.0 where 1.0 is perfect. Alias as `value` in check implementations.

## Pull Request Expectations

- Document behavior changes clearly.
- Keep changes scoped (one concern per PR).
- For platform work, include or update the platform reference in `platforms/`.

## Skill Source of Truth

Canonical skill files live in `skills/`. Mirror copies in `.agents/skills/` must stay in sync.
