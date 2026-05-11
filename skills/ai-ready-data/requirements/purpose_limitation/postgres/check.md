# Check: purpose_limitation

Fraction of tables with declared AI processing purposes.

## Context

PostgreSQL has no native tagging system like Snowflake's object tags. This check uses two mechanisms to detect purpose declarations:

1. **RLS policies with purpose-related names** — checks `pg_policy.polname` for policies containing purpose keywords (`purpose`, `allowed_purpose`, `processing_purpose`, `data_purpose`). Purpose-named policies indicate that access is scoped by intended use.
2. **Security labels** — checks `pg_seclabel` for table-level labels containing purpose keywords. Security labels require a label provider but are the closest analog to Snowflake tags.

A score of 1.0 means every base table in the schema has at least one purpose declaration via either mechanism.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM information_schema.tables
    WHERE table_schema = '{{ schema }}'
      AND table_type = 'BASE TABLE'
),
purpose_policy AS (
    SELECT DISTINCT c.relname AS table_name
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
    SELECT DISTINCT c.relname AS table_name
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
purpose_tables AS (
    SELECT COUNT(DISTINCT table_name) AS cnt
    FROM (
        SELECT table_name FROM purpose_policy
        UNION
        SELECT table_name FROM purpose_label
    ) combined
)
SELECT
    purpose_tables.cnt  AS tables_with_purpose,
    table_count.cnt     AS total_tables,
    purpose_tables.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, purpose_tables;
```
