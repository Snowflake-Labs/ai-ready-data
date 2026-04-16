# Check: row_access_policy

Fraction of base tables in the schema with a row access policy attached.

## Context

Joins `snowflake.account_usage.policy_references` (filtered to `ROW_ACCESS_POLICY`) against `information_schema.tables` to count **base tables** — not views or materialized views — with a policy attached. Without the base-table filter, policies on views could push the score above 1.0.

`policy_references` has approximately 2-hour latency — recently attached policies may not appear yet. It exposes the target table via `ref_entity_name` (not `table_name`).

Returns NULL (N/A) when the schema contains no base tables.

## SQL

```sql
WITH base_tables AS (
    SELECT UPPER(table_name) AS table_name
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type = 'BASE TABLE'
),
rap_tables AS (
    SELECT DISTINCT UPPER(ref_entity_name) AS table_name
    FROM snowflake.account_usage.policy_references
    WHERE UPPER(ref_database_name) = UPPER('{{ database }}')
        AND UPPER(ref_schema_name) = UPPER('{{ schema }}')
        AND policy_kind = 'ROW_ACCESS_POLICY'
)
SELECT
    COUNT_IF(b.table_name IN (SELECT table_name FROM rap_tables)) AS tables_with_rap,
    COUNT(*) AS total_tables,
    COUNT_IF(b.table_name IN (SELECT table_name FROM rap_tables))::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM base_tables b
```
