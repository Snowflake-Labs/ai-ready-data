# Check: retention_policy

Fraction of datasets with defined and enforced data retention and deletion schedules.

## Context

Counts base tables in the schema that carry at least one retention-related tag (`retention_days`, `retention_policy`, `data_retention`, `ttl`) in `snowflake.account_usage.tag_references`. A score of 1.0 means every base table has an explicit retention schedule.

`account_usage.tag_references` has approximately 2-hour latency — recently tagged tables may not appear yet. Note: `tag_references` has no `deleted` column — do not filter on it.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
tagged_retention AS (
    SELECT COUNT(DISTINCT tr.object_name) AS cnt
    FROM snowflake.account_usage.tag_references tr
    JOIN {{ database }}.information_schema.tables t
        ON UPPER(tr.object_name) = UPPER(t.table_name)
        AND t.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
    WHERE UPPER(tr.object_database) = UPPER('{{ database }}')
        AND UPPER(tr.object_schema) = UPPER('{{ schema }}')
        AND tr.domain = 'TABLE'
        AND LOWER(tr.tag_name) IN ('retention_days', 'retention_policy', 'data_retention', 'ttl')
)
SELECT
    tagged_retention.cnt AS tables_with_retention,
    table_count.cnt AS total_tables,
    tagged_retention.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, tagged_retention
```
