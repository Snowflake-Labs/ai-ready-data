# Check: data_completeness

Fraction of non-null values for a given column in the target table. A score of 1.0 means no nulls exist in the column.

## Context

Computes `1.0 - (null_count / total_count)` for a single column. For tables with more than ~1M rows, use the **sampled** variant to avoid a full table scan. The sampled check uses `TABLESAMPLE ({{ sample_rows }} ROWS)` — suitable for triage, not for gating a `SET NOT NULL` operation.

NULL-counting treats NULL as NULL (no implicit type coercion). For VARIANT/JSON null handling, wrap the column in `TYPEOF(col) = 'NULL_VALUE'` instead.

## SQL

### Full scan (primary)

```sql
SELECT
    '{{ asset }}'  AS table_name,
    '{{ column }}' AS column_name,
    1.0 - (COUNT_IF({{ column }} IS NULL)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0)) AS value
FROM {{ database }}.{{ schema }}.{{ asset }}
```

### Sampled (variant)

Use this for tables over ~1M rows to reduce scan cost. `{{ sample_rows }}` controls sample size.

```sql
SELECT
    '{{ asset }}'  AS table_name,
    '{{ column }}' AS column_name,
    1.0 - (COUNT_IF({{ column }} IS NULL)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0)) AS value
FROM {{ database }}.{{ schema }}.{{ asset }}
    TABLESAMPLE ({{ sample_rows }} ROWS)
```
