# Assessment Workflow (Platform-Aware)

## Inputs

- platform
- assessment name
- database/schema scope
- optional requirement overrides

## Steps

1. Load assessment YAML and apply overrides.
2. For each requirement, load canonical metadata from `requirement.yaml`.
3. Resolve platform implementation path:
   - required: `implementations/{platform}/check.sql`
4. Gate by capability manifest.
5. Execute check and normalize output (`PASS|FAIL|N/A`).
6. Aggregate by stage and produce report.

## Rules

- `N/A` is valid and must include reason.
- Threshold pass/fail applies only to supported checks.
- Stage names remain exactly the six factor names.
