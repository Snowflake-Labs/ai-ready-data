# Check: demographic_representation

Fraction of training datasets with measured and documented demographic distribution relative to target population.

## Context

Looks for tables or columns tagged with any of the recognized demographic tag names: `demographic`, `protected_class`, `sensitive_attribute`, or `fairness_attribute`. Uses `snowflake.account_usage.tag_references` which has approximately 2-hour latency for new tags — recently tagged objects may not appear yet.

Scope is schema-level. A score of 1.0 means every base table in the schema has at least one demographic-related tag on the table or one of its columns. Demographic attributes are sensitive — handle with appropriate access controls.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
documented_tables AS (
    SELECT COUNT(DISTINCT tr.object_name) AS cnt
    FROM snowflake.account_usage.tag_references tr
    JOIN {{ database }}.information_schema.tables t
        ON UPPER(tr.object_name) = UPPER(t.table_name)
        AND t.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
    WHERE UPPER(tr.object_database) = UPPER('{{ database }}')
        AND UPPER(tr.object_schema) = UPPER('{{ schema }}')
        AND tr.domain IN ('TABLE', 'COLUMN')
        AND LOWER(tr.tag_name) IN ('demographic', 'protected_class', 'sensitive_attribute', 'fairness_attribute')
)
SELECT
    documented_tables.cnt AS tables_with_demographics,
    table_count.cnt AS total_tables,
    documented_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, documented_tables
```