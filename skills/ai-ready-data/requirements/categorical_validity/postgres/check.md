# Check: categorical_validity

Fraction of categorical column values that belong to a declared controlled vocabulary or code set.

## Context

This is a column-scoped check — run it per categorical column with the allowed values for that column. `{{ allowed_values }}` should be a comma-separated quoted list like `'A','B','C'`. NULL values are excluded from the denominator (only non-null values are tested).

Categories may change over time. If the allowed values are maintained in a reference table, query that table first to build the allowed values list rather than hardcoding it.

A score of 1.0 means every non-null value is in the allowed set. Values outside the allowed set represent data quality issues — typos, legacy codes, upstream schema drift, or encoding problems.

PostgreSQL also supports native ENUM types for categorical columns — see the fix for migration guidance.

## SQL

```sql
SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN {{ column }} IN ({{ allowed_values }}) THEN 1 ELSE 0 END) AS valid_rows,
    SUM(CASE WHEN {{ column }} IN ({{ allowed_values }}) THEN 1 ELSE 0 END)::NUMERIC
        / NULLIF(COUNT(*)::NUMERIC, 0) AS value
FROM {{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
```
