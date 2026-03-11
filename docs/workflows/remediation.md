# Remediation Workflow

## Inputs

- Failing requirements from assessment results
- Selected platform
- User approval per stage

## Steps

1. Load fix files from `{platform}/fix.*`.
2. Check `platforms/{platform}/delegations.yaml` for delegation targets.
3. Check `platforms/{platform}/guards.yaml` for idempotency guards.
4. Present plan and constraints from `requirement.yaml`.
5. Execute only after explicit user approval.
6. Re-run platform check to verify improvement.

## Rules

- Never run mutating SQL during assess phases.
- Use idempotency guards for non-idempotent operations.
- If fix is unsupported, report `N/A`.
