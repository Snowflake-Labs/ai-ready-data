# Check: uniqueness

Fraction of duplicate records across scoped key columns.

## Context

Computes a uniqueness score between 0.0 and 1.0 by partitioning rows on `key_columns` and counting how many rows have a row number greater than 1. A score of 1.0 means every combination of key columns is unique — no duplicates exist.

`key_columns` should be the logical primary key of the table.

For large tables, use the **sampled** variant with `TABLESAMPLE BERNOULLI({{ sample_pct }})` to limit scan cost. Note that sampling may undercount duplicates since duplicate rows may land in different sample partitions.

## SQL

```sql
SELECT
    '{{ asset }}' AS table_name,
    1.0 - (SUM(CASE WHEN rn > 1 THEN 1 ELSE 0 END) * 1.0 / NULLIF(COUNT(*), 0)) AS value
FROM (
    SELECT
        ROW_NUMBER() OVER (PARTITION BY {{ key_columns }} ORDER BY 1) AS rn
    FROM {{ schema }}.{{ asset }}
) sub
```

## SQL: sampled

For large tables. Set `{{ sample_pct }}` to a percentage (e.g., `1` for 1%).

```sql
SELECT
    '{{ asset }}' AS table_name,
    1.0 - (SUM(CASE WHEN rn > 1 THEN 1 ELSE 0 END) * 1.0 / NULLIF(COUNT(*), 0)) AS value
FROM (
    SELECT
        ROW_NUMBER() OVER (PARTITION BY {{ key_columns }} ORDER BY 1) AS rn
    FROM {{ schema }}.{{ asset }}
        TABLESAMPLE BERNOULLI({{ sample_pct }})
) sub
```
