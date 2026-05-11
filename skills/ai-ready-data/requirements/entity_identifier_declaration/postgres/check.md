# Check: entity_identifier_declaration

Fraction of entities or datasets with explicitly declared primary or natural key definitions.

## Context

Checks base tables for primary key or unique constraints in `information_schema.table_constraints`. Unlike Snowflake where key constraints are metadata-only hints, PostgreSQL **enforces** primary key and unique constraints at write time. A table with either a PRIMARY KEY or UNIQUE constraint counts as having an identifier declared.

A score of 1.0 means every base table in the schema has at least one primary key or unique constraint declared and enforced.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT
        t.table_schema,
        t.table_name
    FROM information_schema.tables t
    WHERE t.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
),
pk_constraints AS (
    SELECT DISTINCT
        tc.table_schema,
        tc.table_name
    FROM information_schema.table_constraints tc
    WHERE tc.table_schema = '{{ schema }}'
        AND tc.constraint_type = 'PRIMARY KEY'
),
unique_constraints AS (
    SELECT DISTINCT
        tc.table_schema,
        tc.table_name
    FROM information_schema.table_constraints tc
    WHERE tc.table_schema = '{{ schema }}'
        AND tc.constraint_type = 'UNIQUE'
),
tables_with_identifiers AS (
    SELECT DISTINCT t.table_name
    FROM tables_in_scope t
    LEFT JOIN pk_constraints pk
        ON t.table_schema = pk.table_schema
        AND t.table_name = pk.table_name
    LEFT JOIN unique_constraints uq
        ON t.table_schema = uq.table_schema
        AND t.table_name = uq.table_name
    WHERE pk.table_name IS NOT NULL
        OR uq.table_name IS NOT NULL
)
SELECT
    (SELECT COUNT(*) FROM tables_with_identifiers) AS tables_with_pk,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_identifiers)::NUMERIC /
        NULLIF((SELECT COUNT(*) FROM tables_in_scope)::NUMERIC, 0) AS value
```
