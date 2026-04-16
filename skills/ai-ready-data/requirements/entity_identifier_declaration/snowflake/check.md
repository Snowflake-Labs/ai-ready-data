# Check: entity_identifier_declaration

Fraction of base tables in the schema that have at least one PRIMARY KEY or UNIQUE constraint declared.

## Context

Uses `information_schema.table_constraints` with `constraint_type IN ('PRIMARY KEY','UNIQUE')` to identify tables with an entity-identifier declaration. Primary key and unique constraints in Snowflake are **not enforced** — they are metadata hints — but they still count here because they express the author's intent about the entity's identity.

A score of 1.0 means every base table in the schema carries at least one identifier declaration.

Returns NULL (N/A) when the schema contains no base tables.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT UPPER(table_name) AS table_name
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
      AND table_type = 'BASE TABLE'
),
tables_with_identifiers AS (
    SELECT DISTINCT UPPER(table_name) AS table_name
    FROM {{ database }}.information_schema.table_constraints
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
      AND constraint_type IN ('PRIMARY KEY','UNIQUE')
)
SELECT
    COUNT_IF(t.table_name IN (SELECT table_name FROM tables_with_identifiers))
        AS tables_with_identifiers,
    COUNT(*) AS total_tables,
    COUNT_IF(t.table_name IN (SELECT table_name FROM tables_with_identifiers))::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM tables_in_scope t
```
