# Check: uniqueness

Fraction of duplicate records across scoped key columns.

## Context

Computes a uniqueness score between 0.0 and 1.0 by partitioning rows on `key_columns` and counting how many rows have a row number greater than 1. A score of 1.0 means every combination of key columns is unique — no duplicates exist.

`key_columns` should be the logical primary key of the table.

For tables with more than 1 million rows, use the **sampled** variant to limit scan cost. The sampled variant uses `TABLESAMPLE` to draw a fixed number of rows before checking for duplicates.

## SQL

```sql
SELECT
    '{{ asset }}' AS table_name,
    1.0 - (SUM(IFF(rn > 1, 1, 0)) * 1.0 / NULLIF(COUNT(*), 0)) AS value
FROM (
    SELECT
        ROW_NUMBER() OVER (PARTITION BY {{ key_columns }} ORDER BY 1) AS rn
    FROM {{ database }}.{{ schema }}.{{ asset }}
)
```

## SQL: sampled

For tables with more than 1 million rows.

```sql
SELECT
    '{{ asset }}' AS table_name,
    1.0 - (SUM(IFF(rn > 1, 1, 0)) * 1.0 / NULLIF(COUNT(*), 0)) AS value
FROM (
    SELECT
        ROW_NUMBER() OVER (PARTITION BY {{ key_columns }} ORDER BY 1) AS rn
    FROM {{ database }}.{{ schema }}.{{ asset }}
        TABLESAMPLE ({{ sample_rows }} ROWS)
)
```