# Diagnostic: business_glossary_linkage

Per-column breakdown of glossary linkage status.

## Context

Shows every column on base tables in the schema with its documentation status: `LABELED` (has a security label), `DOCUMENTED` (comment >20 characters), `PARTIAL` (comment exists but ≤20 characters), or `UNDOCUMENTED` (no label, no comment).

Includes the security label (if present), current comment text, and a recommendation for undocumented columns.

Security labels require a label provider to be loaded. If no provider is configured, only comment-based statuses will appear.

## SQL

```sql
WITH columns_in_scope AS (
    SELECT
        c.oid AS table_oid,
        c.relname AS table_name,
        a.attname AS column_name,
        a.attnum,
        format_type(a.atttypid, a.atttypmod) AS data_type
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
      AND a.attnum > 0
      AND NOT a.attisdropped
),
labeled_columns AS (
    SELECT
        sl.objoid AS table_oid,
        sl.objsubid AS attnum,
        sl.label
    FROM pg_seclabel sl
    WHERE sl.classoid = 'pg_class'::regclass
      AND sl.objsubid > 0
)
SELECT
    cs.table_name,
    cs.column_name,
    cs.data_type,
    CASE
        WHEN lc.label IS NOT NULL THEN 'LABELED'
        WHEN col_description(cs.table_oid, cs.attnum) IS NOT NULL
         AND LENGTH(col_description(cs.table_oid, cs.attnum)) > 20 THEN 'DOCUMENTED'
        WHEN col_description(cs.table_oid, cs.attnum) IS NOT NULL THEN 'PARTIAL'
        ELSE 'UNDOCUMENTED'
    END AS documentation_status,
    lc.label AS security_label,
    COALESCE(col_description(cs.table_oid, cs.attnum), '') AS current_comment,
    CASE
        WHEN lc.label IS NOT NULL THEN 'Glossary link via security label'
        WHEN col_description(cs.table_oid, cs.attnum) IS NOT NULL
         AND LENGTH(col_description(cs.table_oid, cs.attnum)) > 20 THEN 'Glossary link via comment'
        ELSE 'Add COMMENT ON COLUMN or SECURITY LABEL to link to business glossary'
    END AS recommendation
FROM columns_in_scope cs
LEFT JOIN labeled_columns lc
    ON cs.table_oid = lc.table_oid
   AND cs.attnum = lc.attnum
ORDER BY
    documentation_status DESC,
    cs.table_name,
    cs.attnum
```
