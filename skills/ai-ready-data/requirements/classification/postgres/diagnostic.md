# Diagnostic: classification

Per-table breakdown of classification coverage and identification of unclassified tables.

## Context

Two diagnostic views:

1. **Classification inventory** — shows every table with its security labels and structured comment markers (or `(no classification)` if none). Use this to understand what classification has been done and identify gaps.
2. **Unclassified tables** — lists only tables with no security labels and no structured classification comments. Use this as a remediation worklist.

Security labels require a label provider to be loaded. If no provider is configured, only comment-based classification will appear.

## SQL

### Classification inventory (all tables with their labels)

```sql
SELECT
    c.relname AS table_name,
    COALESCE(sl.label, '(no security label)') AS security_label,
    CASE
        WHEN obj_description(c.oid) IS NOT NULL
         AND (
             LOWER(obj_description(c.oid)) LIKE '%[classification:%'
             OR LOWER(obj_description(c.oid)) LIKE '%[pii:%'
             OR LOWER(obj_description(c.oid)) LIKE '%[sensitivity:%'
             OR LOWER(obj_description(c.oid)) LIKE '%[data_class:%'
         ) THEN 'Classification markers in comment'
        ELSE '(no comment classification)'
    END AS comment_classification,
    COALESCE(obj_description(c.oid), '') AS current_comment
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_seclabel sl
    ON sl.objoid = c.oid
   AND sl.classoid = 'pg_class'::regclass
   AND sl.objsubid = 0
WHERE n.nspname = '{{ schema }}'
  AND c.relkind = 'r'
ORDER BY c.relname
```

### Unclassified tables only

```sql
SELECT c.relname AS table_name
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_seclabel sl
    ON sl.objoid = c.oid
   AND sl.classoid = 'pg_class'::regclass
   AND sl.objsubid = 0
WHERE n.nspname = '{{ schema }}'
  AND c.relkind = 'r'
  AND sl.label IS NULL
  AND (
      obj_description(c.oid) IS NULL
      OR (
          LOWER(obj_description(c.oid)) NOT LIKE '%[classification:%'
          AND LOWER(obj_description(c.oid)) NOT LIKE '%[pii:%'
          AND LOWER(obj_description(c.oid)) NOT LIKE '%[sensitivity:%'
          AND LOWER(obj_description(c.oid)) NOT LIKE '%[data_class:%'
      )
  )
ORDER BY c.relname
```
