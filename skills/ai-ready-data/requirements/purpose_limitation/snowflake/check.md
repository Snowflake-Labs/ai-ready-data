# Check: purpose_limitation

Fraction of data access paths with declared permitted AI processing purposes and enforced purpose-based authorization.

## Context

Counts base tables in the schema that carry at least one purpose-related tag (`purpose`, `allowed_purpose`, `processing_purpose`, or `data_purpose`) via `snowflake.account_usage.tag_references`. A score of 1.0 means every base table has an explicit processing-purpose declaration.

`account_usage.tag_references` has approximately 2-hour latency — recently applied tags may not appear yet.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
purpose_tagged AS (
    SELECT COUNT(DISTINCT tr.object_name) AS cnt
    FROM snowflake.account_usage.tag_references tr
    JOIN {{ database }}.information_schema.tables t
        ON UPPER(tr.object_name) = UPPER(t.table_name)
        AND t.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
    WHERE UPPER(tr.object_database) = UPPER('{{ database }}')
        AND UPPER(tr.object_schema) = UPPER('{{ schema }}')
        AND tr.domain = 'TABLE'
        AND LOWER(tr.tag_name) IN ('purpose', 'allowed_purpose', 'processing_purpose', 'data_purpose')
)
SELECT
    purpose_tagged.cnt AS tables_with_purpose,
    table_count.cnt AS total_tables,
    purpose_tagged.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, purpose_tagged
```