# Check: relationship_declaration

Fraction of cross-entity references with explicit foreign key declarations.

## Context

PostgreSQL does not have Snowflake's semantic views. Instead, relationships are declared via foreign key constraints, which PostgreSQL **enforces** at write time (referential integrity is guaranteed).

This check identifies columns that appear to be cross-entity references based on naming patterns (`%_id` columns that are not the table's own primary key) and measures what fraction of those candidates have an actual foreign key constraint declared.

A score of 1.0 means every FK-candidate column has an explicit, enforced foreign key constraint. A low score indicates implicit relationships that are not machine-discoverable or enforcement-protected.

## SQL

```sql
WITH pk_columns AS (
    SELECT
        kcu.table_schema,
        kcu.table_name,
        kcu.column_name
    FROM information_schema.key_column_usage kcu
    INNER JOIN information_schema.table_constraints tc
        ON kcu.constraint_name = tc.constraint_name
        AND kcu.table_schema = tc.table_schema
    WHERE kcu.table_schema = '{{ schema }}'
        AND tc.constraint_type = 'PRIMARY KEY'
),
fk_candidate_columns AS (
    SELECT
        c.table_schema,
        c.table_name,
        c.column_name
    FROM information_schema.columns c
    INNER JOIN information_schema.tables t
        ON c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
        AND LOWER(c.column_name) LIKE '%\_id' ESCAPE '\'
        AND NOT EXISTS (
            SELECT 1 FROM pk_columns pk
            WHERE pk.table_schema = c.table_schema
              AND pk.table_name = c.table_name
              AND pk.column_name = c.column_name
        )
),
fk_declared_columns AS (
    SELECT DISTINCT
        kcu.table_schema,
        kcu.table_name,
        kcu.column_name
    FROM information_schema.key_column_usage kcu
    INNER JOIN information_schema.table_constraints tc
        ON kcu.constraint_name = tc.constraint_name
        AND kcu.table_schema = tc.table_schema
    WHERE kcu.table_schema = '{{ schema }}'
        AND tc.constraint_type = 'FOREIGN KEY'
)
SELECT
    COUNT(*) FILTER (WHERE fk.column_name IS NOT NULL) AS fk_declared,
    COUNT(*) AS total_fk_candidates,
    CASE
        WHEN COUNT(*) = 0 THEN 1.0
        ELSE COUNT(*) FILTER (WHERE fk.column_name IS NOT NULL)::NUMERIC / COUNT(*)::NUMERIC
    END AS value
FROM fk_candidate_columns c
LEFT JOIN fk_declared_columns fk
    ON c.table_schema = fk.table_schema
    AND c.table_name = fk.table_name
    AND c.column_name = fk.column_name
```
