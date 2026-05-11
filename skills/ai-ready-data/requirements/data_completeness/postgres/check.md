# Check: data_completeness

Fraction of non-null values for a given column in the target table.

## Context

Computes `1.0 - (null_count / total_count)` for a single column, returning a value between 0.0 (entirely null) and 1.0 (fully complete). A score of 1.0 means no nulls exist in the column.

For large tables, use the sampled variant with `TABLESAMPLE BERNOULLI({{ sample_pct }})` to avoid a full table scan. The sampled check estimates completeness from a percentage-based sample — accurate enough for triage but not suitable as a final gate before applying a NOT NULL constraint.

PostgreSQL's `TABLESAMPLE` uses percentage-based sampling (not row-count). Set `{{ sample_pct }}` to a value like `1` for 1% of the table.

## SQL

### Full scan

Use this for smaller tables or when you need an exact completeness score.

```sql
SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    1.0 - (COUNT(*) FILTER (WHERE {{ column }} IS NULL) * 1.0 / NULLIF(COUNT(*), 0)) AS value
FROM {{ schema }}.{{ asset }}
```

### Sampled

Use this for large tables to reduce scan cost. The `{{ sample_pct }}` placeholder controls the sample percentage (e.g., 1 = 1% of rows).

```sql
SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    1.0 - (COUNT(*) FILTER (WHERE {{ column }} IS NULL) * 1.0 / NULLIF(COUNT(*), 0)) AS value
FROM {{ schema }}.{{ asset }}
    TABLESAMPLE BERNOULLI({{ sample_pct }})
```
