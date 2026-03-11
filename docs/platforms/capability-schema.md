# Platform Capability Schema (Phase 0)

Each platform must declare capabilities in:

`skills/ai-ready-data/platforms/{platform}/capabilities.yaml`

## Required Top-Level Fields

- `platform`: unique lowercase identifier
- `version`: schema version string (start with `v1`)
- `capabilities`: map of capability flags and optional metadata

## Recommended Capability Keys

These keys should be booleans unless otherwise noted.

- `supports_semantic_views`
- `supports_native_column_masking`
- `supports_row_access_policies`
- `supports_vector_index_introspection`
- `supports_lineage_api`
- `supports_governance_tag_introspection`
- `supports_account_usage_equivalent`
- `supports_change_tracking_introspection`
- `supports_sql_check_execution`
- `supports_sql_fix_execution`

## Example

```yaml
platform: snowflake
version: v1
capabilities:
  supports_semantic_views: true
  supports_native_column_masking: true
  supports_row_access_policies: true
  supports_vector_index_introspection: true
  supports_lineage_api: true
  supports_governance_tag_introspection: true
  supports_account_usage_equivalent: true
  supports_change_tracking_introspection: true
  supports_sql_check_execution: true
  supports_sql_fix_execution: true
```

## Naming Rules

- Capability keys must use `snake_case`.
- Use `supports_` prefix for boolean availability flags.
- Do not encode business policy in capability names.

## Behavior Rules

- Missing required capability for an operation => return `N/A`.
- `N/A` responses must include explicit `reason`.
- Capability manifests should be conservative; unknown features default to `false`.
