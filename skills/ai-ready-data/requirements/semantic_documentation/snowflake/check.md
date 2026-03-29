# Check: semantic_documentation

Fraction of objects with machine-readable semantic descriptions.

## Context

This requirement has two check queries that measure different levels of semantic documentation:

1. **Comment coverage** — Measures the fraction of columns that have non-empty comments. This is the baseline: comments are lightweight metadata that help humans and tools understand column purpose, but they don't enable structured query generation (Text-to-SQL, Cortex Analyst).

2. **Semantic view coverage** — Measures the fraction of base tables covered by a Snowflake semantic view. Semantic views provide machine-readable metadata (table roles, relationships, facts, dimensions, metrics) that powers Text-to-SQL, Cortex Analyst, and agent tool use. This is the stronger signal.

A schema can score well on comments but still fail on semantic coverage. Prefer semantic views for full coverage.

## Constraints

- Comments alone don't enable Text-to-SQL — prefer semantic views for full coverage
- Use the Semantic View Builder workflow for semantic view creation
- Fall back to fix.add-comments.sql only when user explicitly opts for comments over semantic views

## SQL: check (comment coverage)

```sql
WITH column_stats AS (
    SELECT
        COUNT(*) AS total_columns,
        COUNT_IF(c.comment IS NOT NULL AND c.comment != '') AS commented_columns
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
)
SELECT
    commented_columns,
    total_columns,
    commented_columns::FLOAT / NULLIF(total_columns::FLOAT, 0) AS value
FROM column_stats
```

## SQL: check.semantic (semantic view coverage)

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
covered_tables AS (
    SELECT COUNT(DISTINCT st.base_table_name) AS cnt
    FROM {{ database }}.information_schema.semantic_tables st
    WHERE st.base_table_schema = '{{ schema }}'
)
SELECT
    covered_tables.cnt AS tables_with_semantics,
    table_count.cnt AS total_tables,
    covered_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, covered_tables
```
