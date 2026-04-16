# Check: semantic_documentation

Fraction of objects with machine-readable semantic descriptions.

## Context

This requirement offers two check SQL blocks that measure complementary levels of documentation:

1. **Comment coverage** (primary) — Fraction of columns (across all base tables) that have a non-empty `COMMENT`. Comments are lightweight metadata that help humans and tools understand column purpose, but they don't enable structured query generation (Text-to-SQL, Cortex Analyst).

2. **Semantic view coverage** (variant) — Fraction of base tables that participate in at least one Snowflake semantic view. Semantic views provide machine-readable metadata (roles, relationships, facts, dimensions, metrics) that powers Text-to-SQL, Cortex Analyst, and agent tool use. This is the stronger signal — prefer it when the account has semantic views enabled.

A schema can score well on comments but still fail on semantic coverage. The variant uses `INFORMATION_SCHEMA.SEMANTIC_VIEWS` plus `GET_DDL` to discover which base tables are referenced inside each semantic view's `TABLES` clause. If `INFORMATION_SCHEMA.SEMANTIC_VIEWS` is not present on the account, the orchestrator should report the variant as N/A.

## Constraints

- Comments alone don't enable Text-to-SQL — prefer semantic views for full coverage.
- Use the Semantic View Builder workflow for semantic view creation.
- Fall back to `fix.add-comments.sql` only when the user explicitly opts for comments over semantic views.

## SQL

### Comment coverage (primary)

```sql
WITH column_stats AS (
    SELECT
        COUNT(*) AS total_columns,
        COUNT_IF(c.comment IS NOT NULL AND c.comment <> '') AS commented_columns
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE UPPER(c.table_schema) = UPPER('{{ schema }}')
        AND t.table_type = 'BASE TABLE'
)
SELECT
    commented_columns,
    total_columns,
    commented_columns::FLOAT / NULLIF(total_columns::FLOAT, 0) AS value
FROM column_stats
```

### Semantic view coverage (variant)

```sql
WITH base_tables AS (
    SELECT UPPER(table_name) AS table_name
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type = 'BASE TABLE'
),
sv_ddls AS (
    SELECT
        semantic_view_name,
        UPPER(GET_DDL(
            'SEMANTIC VIEW',
            semantic_view_catalog || '.' || semantic_view_schema || '.' || semantic_view_name
        )) AS ddl
    FROM {{ database }}.information_schema.semantic_views
    WHERE UPPER(semantic_view_schema) = UPPER('{{ schema }}')
      AND deleted IS NULL
),
covered AS (
    SELECT DISTINCT b.table_name
    FROM base_tables b
    JOIN sv_ddls sv
      ON sv.ddl LIKE '%' || b.table_name || '%'
)
SELECT
    (SELECT COUNT(*) FROM covered) AS tables_with_semantics,
    (SELECT COUNT(*) FROM base_tables) AS total_tables,
    (SELECT COUNT(*) FROM covered)::FLOAT
        / NULLIF((SELECT COUNT(*) FROM base_tables)::FLOAT, 0) AS value
```
