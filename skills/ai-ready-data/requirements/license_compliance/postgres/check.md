# Check: license_compliance

Fraction of externally sourced datasets with documented and valid usage licenses permitting AI training.

## Context

PostgreSQL does not have a native tagging system. This check uses table comments (`obj_description`) to detect license documentation. A table is considered licensed if its comment contains any of the recognized keywords: `license`, `data_license`, `usage_license`, `license_type`, `cc-by`, `mit`, `apache`.

This is a governance signal — the check detects whether a license has been documented, not whether the license actually permits AI training. Verify license terms independently.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
license_documented AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND obj_description(c.oid) IS NOT NULL
        AND (
            LOWER(obj_description(c.oid)) LIKE '%license%'
            OR LOWER(obj_description(c.oid)) LIKE '%data_license%'
            OR LOWER(obj_description(c.oid)) LIKE '%usage_license%'
            OR LOWER(obj_description(c.oid)) LIKE '%license_type%'
            OR LOWER(obj_description(c.oid)) LIKE '%cc-by%'
            OR LOWER(obj_description(c.oid)) LIKE '%mit %'
            OR LOWER(obj_description(c.oid)) LIKE '%apache%'
        )
)
SELECT
    license_documented.cnt AS tables_with_license,
    table_count.cnt AS total_tables,
    license_documented.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, license_documented
```
