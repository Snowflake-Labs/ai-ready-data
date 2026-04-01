# Check: constraint_declaration

Fraction of columns in the schema with explicitly declared constraints (NOT NULL or key constraints).

## Context

Scopes to all columns in base tables within the target schema. A column counts as "constrained" if it has `is_nullable = 'NO'`. This captures both explicit NOT NULL declarations and primary key columns (PK implies NOT NULL in Snowflake).

`character_maximum_length` and `numeric_precision` are intentionally excluded because Snowflake always populates these with defaults (e.g., VARCHAR defaults to 16,777,216). Only explicit, user-declared constraints count.

Primary key and unique constraints in Snowflake are **not enforced** — they are metadata hints only. They still count toward this check because they express developer intent about the data model, which is valuable for AI workloads even without enforcement. PK columns are implicitly NOT NULL, so they are captured by the `is_nullable` check. UNIQUE columns that allow NULLs are not captured — this is an acceptable gap since nullable unique columns are uncommon.

NOT NULL constraints **are** enforced by Snowflake. Adding a NOT NULL constraint will fail if the column currently contains NULLs — fill or delete them first.

Snowflake does not have `information_schema.key_column_usage`. Column-level key membership requires `SHOW PRIMARY KEYS` / `SHOW UNIQUE KEYS` (see diagnostic), but the `is_nullable` approach is sufficient for scoring.

Returns a float 0–1 representing the fraction of constrained columns.

## SQL

```sql
SELECT
    COUNT_IF(c.is_nullable = 'NO') AS columns_with_constraints,
    COUNT(*) AS total_columns,
    COUNT_IF(c.is_nullable = 'NO')::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM {{ database }}.information_schema.columns c
INNER JOIN {{ database }}.information_schema.tables t
    ON c.table_catalog = t.table_catalog
    AND c.table_schema = t.table_schema
    AND c.table_name = t.table_name
WHERE c.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
```
