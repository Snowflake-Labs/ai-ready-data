# Diagnostic: license_compliance

Per-table breakdown of license documentation status.

## Context

Lists every base table in the schema with its table comment and a status label: `HAS_LICENSE` if the comment contains recognized license keywords, `NO_LICENSE` otherwise. Use this to identify which tables need license documentation for AI training compliance.

Recognized keywords in comments: `license`, `data_license`, `usage_license`, `license_type`, `cc-by`, `mit`, `apache`.

## SQL

```sql
SELECT
    c.relname AS table_name,
    COALESCE(s.n_live_tup, 0) AS estimated_row_count,
    obj_description(c.oid) AS table_comment,
    CASE
        WHEN obj_description(c.oid) IS NOT NULL
            AND (
                LOWER(obj_description(c.oid)) LIKE '%license%'
                OR LOWER(obj_description(c.oid)) LIKE '%data_license%'
                OR LOWER(obj_description(c.oid)) LIKE '%usage_license%'
                OR LOWER(obj_description(c.oid)) LIKE '%license_type%'
                OR LOWER(obj_description(c.oid)) LIKE '%cc-by%'
                OR LOWER(obj_description(c.oid)) LIKE '%mit %'
                OR LOWER(obj_description(c.oid)) LIKE '%apache%'
            )
        THEN 'HAS_LICENSE'
        ELSE 'NO_LICENSE'
    END AS status
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_stat_user_tables s ON s.relid = c.oid
WHERE n.nspname = '{{ schema }}'
    AND c.relkind = 'r'
ORDER BY status DESC, c.relname
```
