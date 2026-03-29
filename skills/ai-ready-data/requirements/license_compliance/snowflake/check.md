# Check: license_compliance

Fraction of externally sourced datasets with documented and valid usage licenses permitting AI training.

## Context

Looks for tables in the target schema that carry a license-related tag (`license`, `data_license`, `usage_license`, or `license_type`) via `snowflake.account_usage.tag_references`. The score is the fraction of base tables with at least one such tag.

`account_usage.tag_references` has approximately 2-hour latency for new tags — recently tagged tables may not appear yet.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
license_tagged AS (
    SELECT COUNT(DISTINCT tr.object_name) AS cnt
    FROM snowflake.account_usage.tag_references tr
    JOIN {{ database }}.information_schema.tables t
        ON UPPER(tr.object_name) = UPPER(t.table_name)
        AND t.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
    WHERE UPPER(tr.object_database) = UPPER('{{ database }}')
        AND UPPER(tr.object_schema) = UPPER('{{ schema }}')
        AND tr.domain = 'TABLE'
        AND LOWER(tr.tag_name) IN ('license', 'data_license', 'usage_license', 'license_type')
)
SELECT
    license_tagged.cnt AS tables_with_license,
    table_count.cnt AS total_tables,
    license_tagged.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, license_tagged
```
