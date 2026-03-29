# Check: classification

Fraction of tables with governance tags applied.

## Context

Measures table-level tag coverage. A table counts as classified if it has any tag applied at the table level in `tag_references`. This does not evaluate tag quality or completeness — only presence.

`account_usage.tag_references` has approximately 2-hour latency for newly applied tags. `tag_references` has no `deleted` column — do not filter on it.

For thorough classification, delegate to the `sensitive-data-classification` skill which uses Snowflake's `SYSTEM$CLASSIFY` for automated PII and data type detection.

### Variant: Column-level classification

The primary check measures table-level tag coverage. The column-level variant below measures what fraction of columns across the schema have any tag applied. This is a stricter measure — most schemas will score lower on column-level classification than table-level.

## SQL

### Table-level classification (primary)

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
tagged_tables AS (
    SELECT COUNT(DISTINCT tr.object_name) AS cnt
    FROM snowflake.account_usage.tag_references tr
    JOIN {{ database }}.information_schema.tables t
        ON UPPER(tr.object_name) = UPPER(t.table_name)
        AND t.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
    WHERE UPPER(tr.object_database) = UPPER('{{ database }}')
        AND UPPER(tr.object_schema) = UPPER('{{ schema }}')
        AND tr.domain = 'TABLE'
)
SELECT
    tagged_tables.cnt AS tagged_tables,
    table_count.cnt AS total_tables,
    tagged_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, tagged_tables
```

### Column-level classification (variant)

```sql
WITH column_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_name = t.table_name AND c.table_schema = t.table_schema
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
),
tagged_columns AS (
    SELECT COUNT(DISTINCT UPPER(object_name) || '.' || UPPER(column_name)) AS cnt
    FROM snowflake.account_usage.tag_references tr
    JOIN {{ database }}.information_schema.columns c
        ON UPPER(tr.object_name) = UPPER(c.table_name)
        AND UPPER(tr.column_name) = UPPER(c.column_name)
        AND c.table_schema = '{{ schema }}'
    WHERE UPPER(tr.object_database) = UPPER('{{ database }}')
        AND UPPER(tr.object_schema) = UPPER('{{ schema }}')
        AND tr.domain = 'COLUMN'
)
SELECT
    tagged_columns.cnt AS tagged_columns,
    column_count.cnt AS total_columns,
    tagged_columns.cnt::FLOAT / NULLIF(column_count.cnt::FLOAT, 0) AS value
FROM column_count, tagged_columns
```
