# Diagnostic: eval_coverage

Fraction of data assets with associated evaluation sets that verify AI tool correctness.

## Context

Lists each base table and checks whether a matching eval table exists (by `_eval` suffix or `eval_` prefix). Tables are labeled `HAS_EVAL` or `NO_EVAL`. Use this to identify which assets lack evaluation coverage.

## SQL

```sql
SELECT
    t.table_name,
    CASE
      WHEN EXISTS (
        SELECT 1 FROM information_schema.tables e
        WHERE e.table_schema = '{{ schema }}'
          AND e.table_type = 'BASE TABLE'
          AND (
            LOWER(e.table_name) = LOWER(t.table_name || '_eval')
            OR LOWER(e.table_name) = LOWER('eval_' || t.table_name)
          )
      ) THEN 'HAS_EVAL'
      ELSE 'NO_EVAL'
    END AS eval_status
FROM information_schema.tables t
WHERE t.table_schema = '{{ schema }}'
  AND t.table_type = 'BASE TABLE'
ORDER BY eval_status DESC, t.table_name
```
