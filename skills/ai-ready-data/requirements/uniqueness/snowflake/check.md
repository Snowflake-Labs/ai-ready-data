# Check: uniqueness

Fraction of rows that are unique on the declared key columns. A score of 1.0 means every combination of key columns is unique — no duplicates exist.

## Context

Partitions rows on `{{ key_columns }}` (a comma-separated list of the table's logical primary key) and counts how many rows have `ROW_NUMBER() > 1` in their partition — those are the duplicates. The `ORDER BY (SELECT NULL)` in the window makes the row-number assignment explicitly order-agnostic (all rows in the same partition are equivalent for duplicate-counting).

For tables over ~1M rows, use the **sampled** variant to limit scan cost. Note that sampling for duplicate rate is only a triage measurement — rare duplicates may not appear in the sample.

## SQL

### Full scan (primary)

```sql
SELECT
    '{{ asset }}' AS table_name,
    1.0 - (COUNT_IF(rn > 1)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0)) AS value
FROM (
    SELECT ROW_NUMBER() OVER (PARTITION BY {{ key_columns }} ORDER BY (SELECT NULL)) AS rn
    FROM {{ database }}.{{ schema }}.{{ asset }}
)
```

### Sampled (variant)

For tables with more than ~1M rows.

```sql
SELECT
    '{{ asset }}' AS table_name,
    1.0 - (COUNT_IF(rn > 1)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0)) AS value
FROM (
    SELECT ROW_NUMBER() OVER (PARTITION BY {{ key_columns }} ORDER BY (SELECT NULL)) AS rn
    FROM {{ database }}.{{ schema }}.{{ asset }}
        TABLESAMPLE ({{ sample_rows }} ROWS)
)
```
