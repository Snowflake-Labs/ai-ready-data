# Databricks Execution Playbook

## Preflight

- Confirm Unity Catalog-enabled workspace and metadata visibility.
- Confirm catalog/schema scope is available to the executing principal.
- Review `skills/ai-ready-data/platforms/databricks/gotchas.md`.

## Check Contract

- `check.sql` must return numeric `value` in `[0,1]` with `AS value`.
- Prefer Information Schema and Unity Catalog metadata sources.

## Diagnostic Contract

- Diagnostics should identify missing metadata and impacted tables/columns.
- Keep outputs focused and bounded for operator readability.

## Fix Contract

- Fixes require explicit approval.
- Use safe, idempotent operations when possible.
- If capability is unavailable, return `N/A` with actionable reason.
