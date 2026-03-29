# Repo Contributions

## Architecture

The framework has five layers:

- **Factors** — the six categories (Clean, Contextual, Consumable, Current, Correlated, Compliant)
- **Requirements** — platform-agnostic testable claims about the data and platform, defined in a single manifest (`requirements/requirements.yaml`)
- **Profiles** — curated selections of requirements with thresholds (`profiles/*.yaml`), including the lightweight scan profile for estate-level analysis
- **Platform References** — everything the agent needs to operate on a specific platform (`platforms/`)
- **Assessments** — ephemeral runtime compilations of profile + platform + scope

## Contribution Types

- New or improved requirements
- New profiles
- Platform implementations (eg AWS, Azure, dbt)
- Platform reference improvements

## Adding a Requirement

1. Add an entry to `requirements/requirements.yaml` with: description, factor, scope, placeholders, implementations.
2. Create `requirements/{name}/{platform}/` with three markdown files:
   - `check.md` — context + SQL returning a `value` score 0–1
   - `diagnostic.md` — context + SQL for detail drill-down
   - `fix.md` — remediation SQL and/or organizational guidance
3. Add to relevant profiles.

### Markdown file format

Each implementation file follows this structure:

```
# {Type}: {requirement_key}

{One-line description}

## Context

{Prose: what it measures, constraints, gotchas, platform-specific notes,
 variant selection guidance, preconditions.}

## SQL

```sql
{SQL with {{ placeholder }} syntax}
```
```

A single file can contain multiple SQL implementations under separate `###` subheadings. For example, `check.md` can contain both a full-scan and a sampled variant; `fix.md` can contain multiple remediation options. The agent reads the context to decide which to use.

Fix files may contain organizational process guidance (not just SQL) for remediations that require human judgment, governance decisions, or data model changes.

## Adding a Platform

1. Create `platforms/{PLATFORM}.md` covering capabilities, dialect, permissions, nuances, guards, and delegations.
2. Add requirement files under `requirements/{name}/{platform}/`.

## Conventions

- Keep requirement metadata in the manifest platform-agnostic.
- Keep platform-specific logic in platform references and requirement platform directories.
- Preserve the six factor stage names exactly.
- Scoring: 0.0 to 1.0 where 1.0 is perfect. Alias as `value` in check SQL blocks.
- Co-locate constraints and gotchas in the markdown file's Context section, directly above the SQL they apply to.
- Every requirement directory must have all three files: `check.md`, `diagnostic.md`, `fix.md`.

## Pull Request Expectations

- Document behavior changes clearly.
- Keep changes scoped (one concern per PR).
- For platform work, include or update the platform reference in `platforms/`.

## Skill Source of Truth

Canonical skill files live in `skills/`.
