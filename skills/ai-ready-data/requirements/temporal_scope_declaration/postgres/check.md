# Check: temporal_scope_declaration

Fraction of temporal columns in the schema that have documentation via column comments declaring their temporal role.

## Context

Scans `information_schema.columns` for all date and timestamp types (`date`, `timestamp without time zone`, `timestamp with time zone`, `time without time zone`, `time with time zone`) as well as columns matching temporal name patterns (`%_at`, `%_date`, `%valid%`, `%effective%`). Checks whether each has a non-empty comment retrieved via `col_description()` from `pg_catalog`.

A score of 1.0 means every temporal column has a comment describing its validity window, effective date, or temporal role. Columns without comments are assumed undocumented. The check does not validate comment content — only presence.

PostgreSQL does not expose column comments in `information_schema.columns`. Comments must be retrieved via `col_description()` and set via `COMMENT ON COLUMN`.

## SQL

```sql
WITH temporal_columns AS (
    SELECT
        c.table_schema,
        c.table_name,
        c.column_name,
        c.data_type,
        c.ordinal_position
    FROM information_schema.columns c
    INNER JOIN information_schema.tables t
        ON c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
        AND (
            c.data_type IN ('date', 'timestamp without time zone', 'timestamp with time zone',
                            'time without time zone', 'time with time zone')
            OR LOWER(c.column_name) LIKE '%\_at' ESCAPE '\'
            OR LOWER(c.column_name) LIKE '%\_date' ESCAPE '\'
            OR LOWER(c.column_name) LIKE '%valid%'
            OR LOWER(c.column_name) LIKE '%effective%'
        )
),
documented_temporal AS (
    SELECT *
    FROM temporal_columns tc
    WHERE col_description(
        (quote_ident(tc.table_schema) || '.' || quote_ident(tc.table_name))::regclass,
        tc.ordinal_position
    ) IS NOT NULL
)
SELECT
    (SELECT COUNT(*) FROM documented_temporal) AS documented_temporal_columns,
    (SELECT COUNT(*) FROM temporal_columns) AS total_temporal_columns,
    (SELECT COUNT(*) FROM documented_temporal)::NUMERIC /
        NULLIF((SELECT COUNT(*) FROM temporal_columns)::NUMERIC, 0) AS value
```
