# Check: bias_testing_coverage

Fraction of tables tagged as having undergone bias testing.

## Context

Detects whether tables have been tagged with any of the recognized bias-testing tags: `bias_tested`, `bias_test_date`, `fairness_tested`, `bias_status`. The tag records that testing has been completed — actual bias testing is done externally (e.g., via fairness toolkits, statistical analysis).

This is a governance signal, not a technical measurement. A table tagged `bias_tested = true` is trusted to have been evaluated; the check does not verify the quality or methodology of the testing.

`account_usage.tag_references` has approximately 2-hour latency for newly applied tags.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
tested_tables AS (
    SELECT COUNT(DISTINCT tr.object_name) AS cnt
    FROM snowflake.account_usage.tag_references tr
    JOIN {{ database }}.information_schema.tables t
        ON UPPER(tr.object_name) = UPPER(t.table_name)
        AND t.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
    WHERE UPPER(tr.object_database) = UPPER('{{ database }}')
        AND UPPER(tr.object_schema) = UPPER('{{ schema }}')
        AND tr.domain = 'TABLE'
        AND LOWER(tr.tag_name) IN ('bias_tested', 'bias_test_date', 'fairness_tested', 'bias_status')
)
SELECT
    tested_tables.cnt AS tables_bias_tested,
    table_count.cnt AS total_tables,
    tested_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, tested_tables
```
