# Remediation Workflow

## Inputs

- Failing requirements from assessment results
- Selected platform
- User approval per stage

## Steps

1. Load fix files from the requirement's `{platform}/` directory.
2. Check the platform reference for delegation targets and idempotency guards.
3. Present plan and constraints from `requirement.yaml`.
4. Execute only after explicit user approval.
5. Re-run platform check to verify improvement.

## Rules

- Never run mutating operations during assess phases.
- Use idempotency guards for non-idempotent operations.
- If fix is unsupported, report `N/A`.
