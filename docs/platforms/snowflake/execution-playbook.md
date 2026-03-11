# Snowflake Execution Playbook

## Preflight

- Confirm connection scope: database, schema, and selected assets.
- Read `skills/ai-ready-data/platforms/snowflake/gotchas.md`.
- Verify required privileges before running checks.

## Check Contract

- `check.sql` must return a numeric `value` in `[0,1]`.
- Use explicit alias `AS value`.
- Keep SQL read-only for assess/discover phases.

## Diagnostic Contract

- Diagnostics should provide operator-friendly detail (missing tags, missing comments, stale objects).
- Return bounded row counts where possible.

## Fix Contract

- Fixes require explicit user approval.
- Prefer idempotent patterns or pre-check guards.
- When unsupported in current role/account, return `N/A` with a reason.
