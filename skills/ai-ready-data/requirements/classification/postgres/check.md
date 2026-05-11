# Check: classification

Fraction of tables with governance classification applied.

## Context

PostgreSQL has no native tagging system like Snowflake's `tag_references`. Classification is detected through two signals:

1. **Security labels** (`pg_seclabel`) — primary signal. If a label provider is loaded, tables can have classification labels attached via `SECURITY LABEL`.
2. **Structured comments** — fallback signal. Table comments (via `obj_description()`) containing structured classification markers (e.g., `[classification:` or `[pii:` or `[sensitivity:`) are treated as classification metadata.

A table counts as classified if it has a table-level security label OR a comment containing a structured classification marker.

### Variant: Column-level classification

The primary check measures table-level classification. The column-level variant measures what fraction of columns have any security label or structured classification comment. Most schemas will score lower on column-level classification.

## SQL

### Table-level classification (primary)

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
),
classified_tables AS (
    SELECT COUNT(DISTINCT c.oid) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN pg_seclabel sl
        ON sl.objoid = c.oid
       AND sl.classoid = 'pg_class'::regclass
       AND sl.objsubid = 0
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
      AND (
          sl.label IS NOT NULL
          OR (
              obj_description(c.oid) IS NOT NULL
              AND (
                  LOWER(obj_description(c.oid)) LIKE '%[classification:%'
                  OR LOWER(obj_description(c.oid)) LIKE '%[pii:%'
                  OR LOWER(obj_description(c.oid)) LIKE '%[sensitivity:%'
                  OR LOWER(obj_description(c.oid)) LIKE '%[data_class:%'
              )
          )
      )
)
SELECT
    classified_tables.cnt AS classified_tables,
    table_count.cnt AS total_tables,
    classified_tables.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, classified_tables
```

### Column-level classification (variant)

```sql
WITH column_count AS (
    SELECT COUNT(*) AS cnt
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
      AND a.attnum > 0
      AND NOT a.attisdropped
),
classified_columns AS (
    SELECT COUNT(DISTINCT (a.attrelid, a.attnum)) AS cnt
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN pg_seclabel sl
        ON sl.objoid = a.attrelid
       AND sl.classoid = 'pg_class'::regclass
       AND sl.objsubid = a.attnum
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND sl.label IS NOT NULL
)
SELECT
    classified_columns.cnt AS classified_columns,
    column_count.cnt AS total_columns,
    classified_columns.cnt::NUMERIC / NULLIF(column_count.cnt::NUMERIC, 0) AS value
FROM column_count, classified_columns
```
