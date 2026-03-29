# Check: row_access_policy

Fraction of tables with row access policies enforcing row-level security.

## Context

Uses `snowflake.account_usage.policy_references` to count distinct tables with an attached `ROW_ACCESS_POLICY`. The view uses `ref_entity_name` (not `table_name`) to identify the target table.

`policy_references` has approximately 2-hour latency — recently attached policies may not appear yet.

A score of 1.0 means every base table in the schema has at least one row access policy attached.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
rap_tables AS (
    SELECT COUNT(DISTINCT ref_entity_name) AS cnt
    FROM snowflake.account_usage.policy_references
    WHERE UPPER(ref_database_name) = UPPER('{{ database }}')
        AND UPPER(ref_schema_name) = UPPER('{{ schema }}')
        AND policy_kind = 'ROW_ACCESS_POLICY'
)
SELECT
    rap_tables.cnt AS tables_with_rap,
    table_count.cnt AS total_tables,
    rap_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, rap_tables
```