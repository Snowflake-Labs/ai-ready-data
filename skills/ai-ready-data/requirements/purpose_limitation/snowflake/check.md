# Check: purpose_limitation

Fraction of base tables with at least one tag declaring permitted AI processing purposes.

## Context

Counts base tables in the schema that carry a purpose-related tag via `snowflake.account_usage.tag_references`. A score of 1.0 means every base table has an explicit purpose declaration; enforcement of purpose-based authorization is a separate concern (typically handled via row access policies keyed on tags).

`account_usage.tag_references` has approximately 2-hour latency.

Requires `{{ tag_names }}` — comma-separated quoted list, typically `'purpose','allowed_purpose','processing_purpose','data_purpose'`.

Returns NULL (N/A) when the schema contains no base tables.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type = 'BASE TABLE'
),
tagged_tables AS (
    SELECT COUNT(DISTINCT tr.object_name) AS cnt
    FROM snowflake.account_usage.tag_references tr
    JOIN {{ database }}.information_schema.tables t
        ON UPPER(tr.object_name) = UPPER(t.table_name)
        AND UPPER(t.table_schema) = UPPER('{{ schema }}')
        AND t.table_type = 'BASE TABLE'
    WHERE UPPER(tr.object_database) = UPPER('{{ database }}')
        AND UPPER(tr.object_schema)   = UPPER('{{ schema }}')
        AND tr.domain = 'TABLE'
        AND LOWER(tr.tag_name) IN ({{ tag_names }})
)
SELECT
    tagged_tables.cnt AS tables_tagged,
    table_count.cnt   AS total_tables,
    tagged_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, tagged_tables
```
