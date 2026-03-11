# Azure Execution Playbook

## Preflight

- Confirm target data stack (for example Fabric, Synapse, Purview).
- Confirm access for metadata and governance APIs.
- Review `skills/ai-ready-data/platforms/azure/gotchas.md`.

## Check Contract

- `check.sql` (or adapter equivalent) must produce normalized `value` in `[0,1]`.
- Use `AS value` for SQL implementations.

## Diagnostic Contract

- Provide scoped evidence for missing metadata, policies, or lineage.
- Keep result sets bounded.

## Fix Contract

- Explicit user approval is required for mutating operations.
- Prefer idempotent operations and guarded changes.
- Return `N/A` with actionable reason when capabilities are missing.
