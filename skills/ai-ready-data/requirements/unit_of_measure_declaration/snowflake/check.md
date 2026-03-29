# Check: unit_of_measure_declaration

Fraction of measured numeric columns with unit declarations.

## Context

Identifies numeric columns in the schema and checks whether each has an explicit unit of measure — either encoded in the column name suffix (e.g., `_usd`, `_pct`, `_kg`) or documented in the column comment. Columns likely to be identifiers, keys, counts, or flags are excluded.

A score of 1.0 means every measured numeric column has a discoverable unit. A low score means downstream consumers (models, agents) must guess units, which introduces silent conversion errors.

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
    WHERE c.table_schema = '{{ schema }}'
      AND t.table_type = 'BASE TABLE'
      AND c.data_type IN ('NUMBER', 'DECIMAL', 'NUMERIC', 'INT', 'INTEGER', 'BIGINT', 'SMALLINT', 'FLOAT', 'DOUBLE', 'REAL')
      AND LOWER(c.column_name) NOT LIKE '%_id'
      AND LOWER(c.column_name) NOT LIKE '%_key'
      AND LOWER(c.column_name) NOT LIKE '%count%'
      AND LOWER(c.column_name) NOT LIKE '%flag%'
),
columns_with_units AS (
    SELECT *
    FROM numeric_columns
    WHERE
      (comment IS NOT NULL AND (
          LOWER(comment) LIKE '%usd%'
          OR LOWER(comment) LIKE '%dollar%'
          OR LOWER(comment) LIKE '%percent%'
          OR LOWER(comment) LIKE '%unit%'
          OR LOWER(comment) LIKE '%meter%'
          OR LOWER(comment) LIKE '%kilogram%'
          OR LOWER(comment) LIKE '%second%'
          OR LOWER(comment) LIKE '%hour%'
          OR LOWER(comment) LIKE '%day%'
      ))
      OR LOWER(column_name) LIKE '%_usd'
      OR LOWER(column_name) LIKE '%_pct'
      OR LOWER(column_name) LIKE '%_percent'
      OR LOWER(column_name) LIKE '%_seconds'
      OR LOWER(column_name) LIKE '%_hours'
      OR LOWER(column_name) LIKE '%_days'
      OR LOWER(column_name) LIKE '%_kg'
      OR LOWER(column_name) LIKE '%_meters'
)
SELECT
    (SELECT COUNT(*) FROM columns_with_units) AS columns_with_units,
    (SELECT COUNT(*) FROM numeric_columns) AS total_numeric_columns,
    CASE
      WHEN (SELECT COUNT(*) FROM numeric_columns) = 0 THEN 1.0
      ELSE (SELECT COUNT(*) FROM columns_with_units)::FLOAT / (SELECT COUNT(*) FROM numeric_columns)::FLOAT
    END AS value
```