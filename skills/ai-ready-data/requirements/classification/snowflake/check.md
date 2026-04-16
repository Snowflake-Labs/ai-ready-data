# Check: classification

Fraction of base tables in the schema that have at least one governance tag applied at the table level.

## Context

Measures table-level tag coverage via `snowflake.account_usage.tag_references`. A table counts as classified if it has any tag applied at the table level — this check does not evaluate tag quality or completeness, only presence.

`account_usage.tag_references` has approximately 2-hour latency for newly applied tags. The view has **no `deleted` column** — do not filter on it.

For thorough classification, delegate to the `sensitive-data-classification` skill which uses Snowflake's `SYSTEM$CLASSIFY` for automated PII and data type detection.

### Variant: Column-level classification

The primary check measures table-level tag coverage. The column-level variant measures what fraction of columns across the schema have any tag applied. This is a stricter measure — most schemas will score lower on column-level classification than table-level.

Returns NULL (N/A) when the schema contains no base tables (primary) or no columns (variant).

## SQL

### Table-level classification (primary)

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type = 'BASE TABLE'
),
tagged_tables AS (
    SELECT COUNT(DISTINCT tr.object_name) AS cnt
    FROM snowflake.account_usage.tag_references tr
    JOIN {{ database }}.information_schema.tables t
        ON UPPER(tr.object_name) = UPPER(t.table_name)
        AND UPPER(t.table_schema) = UPPER('{{ schema }}')
        AND t.table_type = 'BASE TABLE'
    WHERE UPPER(tr.object_database) = UPPER('{{ database }}')
        AND UPPER(tr.object_schema)   = UPPER('{{ schema }}')
        AND tr.domain = 'TABLE'
)
SELECT
    tagged_tables.cnt AS tagged_tables,
    table_count.cnt   AS total_tables,
    tagged_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, tagged_tables
```

### Column-level classification (variant)

```sql
WITH column_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name   = t.table_name
    WHERE UPPER(c.table_schema) = UPPER('{{ schema }}')
        AND t.table_type = 'BASE TABLE'
),
tagged_columns AS (
    SELECT COUNT(DISTINCT UPPER(tr.object_name) || '.' || UPPER(tr.column_name)) AS cnt
    FROM snowflake.account_usage.tag_references tr
    JOIN {{ database }}.information_schema.columns c
        ON UPPER(tr.object_name)   = UPPER(c.table_name)
        AND UPPER(tr.column_name)  = UPPER(c.column_name)
        AND UPPER(c.table_schema)  = UPPER('{{ schema }}')
    WHERE UPPER(tr.object_database) = UPPER('{{ database }}')
        AND UPPER(tr.object_schema)   = UPPER('{{ schema }}')
        AND tr.domain = 'COLUMN'
)
SELECT
    tagged_columns.cnt AS tagged_columns,
    column_count.cnt   AS total_columns,
    tagged_columns.cnt::FLOAT / NULLIF(column_count.cnt::FLOAT, 0) AS value
FROM column_count, tagged_columns
```
