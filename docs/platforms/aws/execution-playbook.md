# AWS Execution Playbook

## Preflight

- Confirm target service stack (for example Athena + Glue + Lake Formation).
- Confirm IAM permissions for metadata and governance introspection.
- Review `skills/ai-ready-data/platforms/aws/gotchas.md`.

## Check Contract

- `check.sql` (or equivalent adapter execution) must produce normalized `value` in `[0,1]`.
- If SQL is not supported for a requirement, return `N/A` with reason.

## Diagnostic Contract

- Return object-level evidence indicating why score is below threshold.
- Keep outputs bounded and clear.

## Fix Contract

- Require explicit approval for mutating actions.
- Prefer idempotent operations and explicit pre-checks.
- Use `N/A` for unsupported governance/remediation capabilities.
