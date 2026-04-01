# Check: bias_testing_coverage

Fraction of tables documented as having undergone bias testing.

## Context

PostgreSQL does not have a native tagging system. This check uses table comments (`obj_description`) to detect bias testing documentation. A table is considered tested if its comment contains any of the recognized keywords: `bias_tested`, `bias_test`, `fairness_tested`, `fairness_test`, `bias_status`.

This is a governance signal, not a technical measurement. A table documented as bias-tested is trusted to have been evaluated; the check does not verify the quality or methodology of the testing. Actual bias testing is done externally (e.g., via fairness toolkits, statistical analysis).

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
tested_tables AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND obj_description(c.oid) IS NOT NULL
        AND (
            LOWER(obj_description(c.oid)) LIKE '%bias_tested%'
            OR LOWER(obj_description(c.oid)) LIKE '%bias_test%'
            OR LOWER(obj_description(c.oid)) LIKE '%fairness_tested%'
            OR LOWER(obj_description(c.oid)) LIKE '%fairness_test%'
            OR LOWER(obj_description(c.oid)) LIKE '%bias_status%'
        )
)
SELECT
    tested_tables.cnt AS tables_bias_tested,
    table_count.cnt AS total_tables,
    tested_tables.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, tested_tables
```
