# Check: data_completeness

Fraction of non-null values for a given column in the target table.

## Context

Computes `1.0 - (null_count / total_count)` for a single column, returning a value between 0.0 (entirely null) and 1.0 (fully complete). A score of 1.0 means no nulls exist in the column.

For tables with more than 1 million rows, use the sampled variant to avoid a full table scan. The sampled check uses `TABLESAMPLE ({{ sample_rows }} ROWS)` to estimate completeness from a subset — accurate enough for triage but not suitable as a final gate before applying a NOT NULL constraint.

## SQL

### Full scan

Use this for smaller tables or when you need an exact completeness score.

```sql
SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    1.0 - (COUNT_IF({{ column }} IS NULL) * 1.0 / NULLIF(COUNT(*), 0)) AS value
FROM {{ database }}.{{ schema }}.{{ asset }}
```

### Sampled

Use this for tables over ~1M rows to reduce scan cost. The `{{ sample_rows }}` placeholder controls sample size.

```sql
SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    1.0 - (COUNT_IF({{ column }} IS NULL) * 1.0 / NULLIF(COUNT(*), 0)) AS value
FROM {{ database }}.{{ schema }}.{{ asset }}
    TABLESAMPLE ({{ sample_rows }} ROWS)
```
