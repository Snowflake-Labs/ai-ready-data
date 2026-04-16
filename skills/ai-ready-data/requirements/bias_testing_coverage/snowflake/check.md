# Check: bias_testing_coverage

Fraction of base tables in the schema tagged as having undergone bias testing.

## Context

Detects whether tables have been tagged with any of the recognized bias-testing tags. The tag records that testing has been completed — actual bias testing happens outside Snowflake (fairness toolkits, statistical analysis). This is a governance signal, not a technical measurement: the check does not validate testing quality or methodology.

`account_usage.tag_references` has approximately 2-hour latency for newly applied tags.

Requires `{{ tag_names }}` — a comma-separated quoted list of recognized tag names, typically `'bias_tested','bias_test_date','fairness_tested','bias_status'`. Override per profile to match your governance vocabulary.

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
