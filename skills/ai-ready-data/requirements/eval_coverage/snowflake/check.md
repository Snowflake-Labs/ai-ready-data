# Check: eval_coverage

Fraction of base tables in the schema that have a companion evaluation table (name ends in `_eval`, starts with `eval_`, or contains `_eval_`).

## Context

Checks only for the **presence** of eval artifacts, not whether the evals pass. Eval naming conventions vary by team — the regex matches the three common shapes and can be tuned in a per-profile override.

A pathological interpretation: the eval tables themselves are counted in the denominator and (by name) also match the numerator. For small schemas this can inflate the score. If you need the stricter "fraction of non-eval tables with an eval companion" you can drop eval tables from the denominator — see `diagnostic.md` for that variant.

Returns NULL (N/A) when the schema contains no base tables.

## SQL

```sql
WITH base_tables AS (
    SELECT LOWER(table_name) AS table_name
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
      AND table_type = 'BASE TABLE'
)
SELECT
    COUNT_IF(REGEXP_LIKE(table_name, '(^eval_|_eval$|_eval_)')) AS eval_tables,
    COUNT(*) AS total_tables,
    COUNT_IF(REGEXP_LIKE(table_name, '(^eval_|_eval$|_eval_)'))::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM base_tables
```
