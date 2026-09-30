# Check: data_completeness

Fraction of non-null values for a given column in the target table. A score of 1.0 means no nulls exist in the column.

## Context

Computes `1.0 - (null_count / total_count)` for a single column. For tables with more than ~1M rows, use the **sampled** variant to avoid a full table scan. Postgres has no row-count `TABLESAMPLE`, so the sampled check uses `TABLESAMPLE SYSTEM ({{ sample_percent }})` — block-level sampling, fast but approximate. Use `BERNOULLI` instead of `SYSTEM` if a more uniform (row-level) sample is needed, at the cost of a full scan.

NULL-counting treats NULL as NULL (no implicit type coercion). For `jsonb` columns where a JSON null (`'null'::jsonb`) should also count as missing, add `OR {{ column }} = 'null'::jsonb` to the filter.

## SQL

### Full scan (primary)

```sql
SELECT
    '{{ asset }}'  AS table_name,
    '{{ column }}' AS column_name,
    1.0 - (COUNT(*) FILTER (WHERE {{ column }} IS NULL)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0)) AS value
FROM {{ schema }}.{{ asset }}
```

### Sampled (variant)

Use this for tables over ~1M rows to reduce scan cost. `{{ sample_percent }}` controls the sample size as a percentage of the table (e.g. `5` for 5%).

```sql
SELECT
    '{{ asset }}'  AS table_name,
    '{{ column }}' AS column_name,
    1.0 - (COUNT(*) FILTER (WHERE {{ column }} IS NULL)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0)) AS value
FROM {{ schema }}.{{ asset }}
    TABLESAMPLE SYSTEM ({{ sample_percent }})
```
