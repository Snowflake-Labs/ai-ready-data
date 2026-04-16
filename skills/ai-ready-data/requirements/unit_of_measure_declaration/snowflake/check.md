# Check: unit_of_measure_declaration

Fraction of numeric columns (excluding identifiers, keys, counts, flags) whose unit of measure is declared either in the column name suffix or in the column comment.

## Context

Identifiers (`_id`, `_key`), counts, and flags are excluded from the population — they don't need a unit. For the remaining numeric columns, the check looks for a unit declaration as either:

- a name suffix such as `_usd`, `_pct`, `_percent`, `_seconds`, `_hours`, `_days`, `_kg`, `_meters`
- a comment containing a recognizable unit word (`usd`, `dollar`, `percent`, `unit`, `meter`, `kilogram`, `second`, `hour`, `day`)

All pattern matching uses `REGEXP_LIKE` so literal underscores in names aren't swallowed by `_` as a LIKE wildcard.

A low score means downstream consumers must guess units, which introduces silent conversion errors. Returns NULL (N/A) when the schema contains no measured numeric columns.

## SQL

```sql
WITH numeric_columns AS (
    SELECT
        c.table_name,
        c.column_name,
        c.comment
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
      ON c.table_catalog = t.table_catalog
     AND c.table_schema = t.table_schema
     AND c.table_name = t.table_name
    WHERE UPPER(c.table_schema) = UPPER('{{ schema }}')
      AND t.table_type = 'BASE TABLE'
      AND c.data_type IN ('NUMBER','DECIMAL','NUMERIC','INT','INTEGER','BIGINT','SMALLINT','FLOAT','DOUBLE','REAL')
      AND NOT REGEXP_LIKE(LOWER(c.column_name), '.*(_id$|_key$|count|flag).*')
),
columns_with_units AS (
    SELECT *
    FROM numeric_columns
    WHERE
        REGEXP_LIKE(
            LOWER(column_name),
            '.*(_usd$|_pct$|_percent$|_seconds$|_hours$|_days$|_kg$|_meters$)'
        )
        OR (comment IS NOT NULL AND REGEXP_LIKE(
                LOWER(comment),
                '.*(usd|dollar|percent|unit|meter|kilogram|second|hour|day).*'
            ))
)
SELECT
    (SELECT COUNT(*) FROM columns_with_units) AS columns_with_units,
    (SELECT COUNT(*) FROM numeric_columns) AS total_numeric_columns,
    (SELECT COUNT(*) FROM columns_with_units)::FLOAT
        / NULLIF((SELECT COUNT(*) FROM numeric_columns)::FLOAT, 0) AS value
```
