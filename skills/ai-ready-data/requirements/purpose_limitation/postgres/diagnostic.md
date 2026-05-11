# Diagnostic: purpose_limitation

Per-table breakdown of purpose-limitation declarations.

## Context

Lists every base table in the schema alongside any purpose-related RLS policies or security labels. Tables with status `NO_PURPOSE` have no declared processing purpose and need remediation.

Purpose is detected via:
- `pg_policy.polname` containing purpose keywords
- `pg_seclabel.label` containing purpose keywords on the table object

Tables may have multiple purpose declarations (e.g., both a policy and a label).

## SQL

```sql
WITH tables AS (
    SELECT t.table_name
    FROM information_schema.tables t
    WHERE t.table_schema = '{{ schema }}'
      AND t.table_type = 'BASE TABLE'
),
purpose_policy AS (
    SELECT
        c.relname  AS table_name,
        'POLICY:' || p.polname AS purpose_source
    FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND (
          LOWER(p.polname) LIKE '%purpose%'
          OR LOWER(p.polname) LIKE '%allowed_purpose%'
          OR LOWER(p.polname) LIKE '%processing_purpose%'
          OR LOWER(p.polname) LIKE '%data_purpose%'
      )
),
purpose_label AS (
    SELECT
        c.relname  AS table_name,
        'LABEL:' || sl.label AS purpose_source
    FROM pg_seclabel sl
    JOIN pg_class c ON c.oid = sl.objoid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND sl.objsubid = 0
      AND (
          LOWER(sl.label) LIKE '%purpose%'
          OR LOWER(sl.label) LIKE '%allowed_purpose%'
          OR LOWER(sl.label) LIKE '%processing_purpose%'
          OR LOWER(sl.label) LIKE '%data_purpose%'
      )
),
all_purposes AS (
    SELECT table_name, purpose_source FROM purpose_policy
    UNION ALL
    SELECT table_name, purpose_source FROM purpose_label
)
SELECT
    tb.table_name,
    ap.purpose_source,
    CASE
        WHEN ap.purpose_source IS NOT NULL THEN 'HAS_PURPOSE'
        ELSE 'NO_PURPOSE'
    END AS status
FROM tables tb
LEFT JOIN all_purposes ap ON tb.table_name = ap.table_name
ORDER BY status DESC, tb.table_name;
```
