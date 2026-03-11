# Execution Contract (Phase 0)

This contract defines how the assessment engine should invoke requirement operations in a platform-aware way.

## Objective

Decouple requirement intent from execution implementation so new platforms can contribute without changing core semantics.

## Inputs

- `requirement_key` (string)
- `platform` (string; examples: `snowflake`, `databricks`, `aws`, `azure`)
- `operation` (`check` | `diagnostic` | `fix`)
- `variant` (optional string)
- `context` (object with placeholders, scope, runtime metadata)

## Operation Resolution

Resolver lookup order:

1. `requirements/{key}/implementations/{platform}/{operation}.{variant}.sql` (if variant given)
2. `requirements/{key}/implementations/{platform}/{operation}.sql`
3. If not found: unsupported for this platform/operation

For non-SQL execution types in future phases, this contract remains valid and only backend adapters change.

### Resolver Pseudocode

```text
resolve(requirement_key, platform, operation, variant):
  check capability manifest for required feature flags
  if capability missing:
    return N/A(reason = "MISSING_CAPABILITY: ...")

  if variant provided and operation.variant.sql exists:
    return that file

  if operation.sql exists:
    return that file

  return N/A(reason = "MISSING_IMPLEMENTATION: ...")
```

## Output Shape

All operations return normalized envelopes:

### Check

```json
{
  "requirement": "semantic_documentation",
  "platform": "snowflake",
  "operation": "check",
  "value": 0.93,
  "status": "PASS",
  "threshold": 0.90,
  "reason": null,
  "evidence": {}
}
```

### Diagnostic

```json
{
  "requirement": "semantic_documentation",
  "platform": "snowflake",
  "operation": "diagnostic",
  "status": "PASS",
  "rows": [],
  "reason": null,
  "evidence": {}
}
```

### Fix Plan/Execution

```json
{
  "requirement": "semantic_documentation",
  "platform": "snowflake",
  "operation": "fix",
  "status": "PASS",
  "actions": [],
  "reason": null,
  "evidence": {}
}
```

## Status Semantics

- `PASS`: requirement met or operation succeeded.
- `FAIL`: requirement not met or operation failed.
- `N/A`: unsupported on platform or blocked by capability constraints.

`N/A` must include a non-empty `reason`.

### Error Taxonomy

Use stable error classes in `reason`:

- `MISSING_CAPABILITY` - platform cannot support required behavior
- `MISSING_IMPLEMENTATION` - operation file does not exist for platform
- `INVALID_OUTPUT_SHAPE` - operation result cannot be normalized to contract
- `EXECUTION_ERROR` - runtime execution failure

### `N/A` Reason Format

Use this structure to improve user/operator guidance:

`<ERROR_CLASS>: <short cause>. Suggested action: <next step>`

Example:

`MISSING_CAPABILITY: Databricks workspace has no lineage table visibility. Suggested action: enable Unity Catalog lineage tables or skip lineage_completeness for this run.`

## Capability Gating

Before resolving operation files, verify required capability flags from the platform manifest. If missing:

- Skip execution
- Return `N/A` with explicit reason

## Compatibility Requirements

- Existing Snowflake check SQL must keep returning a `value` column in `[0,1]`.
- Requirement thresholds remain assessment-defined and platform-independent.
- Stage-level pass/fail logic remains unchanged.
