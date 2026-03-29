# Diagnostic: license_compliance

Fraction of externally sourced datasets with documented and valid usage licenses permitting AI training.

## Context

Lists every base table in the schema with its license tag status. Tables that carry a recognized license tag (`license`, `data_license`, `usage_license`, `license_type`) show as `HAS_LICENSE`; all others show as `NO_LICENSE`. Results are sorted so unlicensed tables appear first.

`account_usage.tag_references` has approximately 2-hour latency for new tags — recently tagged tables may not appear yet.

## SQL

```sql
SELECT
    t.table_name,
    t.row_count,
    t.comment AS table_comment,
    tr.tag_name AS license_tag,
    tr.tag_value AS license_value,
    CASE
        WHEN tr.tag_name IS NOT NULL THEN 'HAS_LICENSE'
        ELSE 'NO_LICENSE'
    END AS status
FROM {{ database }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON UPPER(tr.object_database) = UPPER('{{ database }}')
    AND UPPER(tr.object_schema) = UPPER('{{ schema }}')
    AND UPPER(tr.object_name) = UPPER(t.table_name)
    AND tr.domain = 'TABLE'
    AND LOWER(tr.tag_name) IN ('license', 'data_license', 'usage_license', 'license_type')
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY status DESC, t.table_name
```
