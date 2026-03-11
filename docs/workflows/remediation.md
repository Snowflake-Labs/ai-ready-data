# Remediation Workflow (Platform-Aware)

## Inputs

- failing requirements from assessment output
- selected platform
- user approval per stage

## Steps

1. Resolve fix files from `implementations/{platform}/fix.*.sql`.
2. Present plan and constraints from `requirement.yaml`.
3. Execute only after explicit user approval.
4. Re-run resolved platform check to verify improvement.

## Rules

- Never run mutating SQL during assess/discover.
- Use idempotency guards for non-idempotent operations.
- If fix is unsupported, return `N/A` with reason.
