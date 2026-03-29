# Diagnostic: row_access_policy

Per-table breakdown of row access policy assignments.

## Context

Lists all policy references in the schema from `snowflake.account_usage.policy_references`, showing the policy name, target table (`ref_entity_name`), and column. Use this to identify which tables lack row access policies and which policies are in effect.

`policy_references` has approximately 2-hour latency for newly attached policies.

## SQL

```sql
SELECT
    policy_kind,
    policy_name,
    ref_entity_name AS table_name,
    ref_column_name AS column_name
FROM snowflake.account_usage.policy_references
WHERE UPPER(ref_database_name) = UPPER('{{ database }}')
    AND UPPER(ref_schema_name) = UPPER('{{ schema }}')
ORDER BY policy_kind, ref_entity_name, ref_column_name
```