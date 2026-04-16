# Check: demographic_representation

Fraction of training datasets with measured and documented demographic distribution relative to target population.

## Context

PostgreSQL does not have a native tagging system. This check uses table and column comments to detect demographic documentation. A table is considered documented if its table comment or any of its column comments contain recognized keywords: `demographic`, `protected_class`, `sensitive_attribute`, `fairness_attribute`.

Scope is schema-level. A score of 1.0 means every base table in the schema has at least one demographic-related comment on the table or one of its columns. Demographic attributes are sensitive — handle with appropriate access controls.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
documented_tables AS (
    SELECT COUNT(DISTINCT c.relname) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND (
            (obj_description(c.oid) IS NOT NULL
             AND (
                LOWER(obj_description(c.oid)) LIKE '%demographic%'
                OR LOWER(obj_description(c.oid)) LIKE '%protected_class%'
                OR LOWER(obj_description(c.oid)) LIKE '%sensitive_attribute%'
                OR LOWER(obj_description(c.oid)) LIKE '%fairness_attribute%'
             ))
            OR EXISTS (
                SELECT 1
                FROM pg_attribute a
                WHERE a.attrelid = c.oid
                    AND a.attnum > 0
                    AND NOT a.attisdropped
                    AND col_description(a.attrelid, a.attnum) IS NOT NULL
                    AND (
                        LOWER(col_description(a.attrelid, a.attnum)) LIKE '%demographic%'
                        OR LOWER(col_description(a.attrelid, a.attnum)) LIKE '%protected_class%'
                        OR LOWER(col_description(a.attrelid, a.attnum)) LIKE '%sensitive_attribute%'
                        OR LOWER(col_description(a.attrelid, a.attnum)) LIKE '%fairness_attribute%'
                    )
            )
        )
)
SELECT
    documented_tables.cnt AS tables_with_demographics,
    table_count.cnt AS total_tables,
    documented_tables.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, documented_tables
```
