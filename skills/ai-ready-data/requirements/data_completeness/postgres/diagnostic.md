# Diagnostic: data_completeness

Lists all columns in the schema with their data type and nullability, ordered by table and ordinal position.

## Context

Joins `information_schema.columns` to `information_schema.tables` to scope to base tables only (excludes views, foreign tables, etc.). Use this to identify which columns are nullable and might contain nulls before running the per-column check.

The `is_nullable` column reflects the declared constraint, not actual data — a column marked `YES` may still have zero nulls, and a column marked `NO` is guaranteed null-free by the engine. In PostgreSQL, NOT NULL constraints are enforced, so `NO` is a reliable guarantee.

## SQL

```sql
SELECT
    c.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable
FROM information_schema.columns c
JOIN information_schema.tables t
    ON c.table_name = t.table_name AND c.table_schema = t.table_schema
WHERE c.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY c.table_name, c.ordinal_position
```
