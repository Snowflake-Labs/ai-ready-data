# Diagnostic: semantic_documentation

Identifies tables and semantic views to show where documentation gaps exist.

## Context

This requirement has two diagnostic queries:

1. **Tables without semantic coverage** — Lists base tables in the schema that are not covered by any semantic view. These tables lack machine-readable metadata for Text-to-SQL, Cortex Analyst, and agent queries. Use this to identify which tables need semantic view coverage.

2. **Existing semantic view inventory** — Shows all semantic views in the schema with their logical tables, base table mappings, and descriptions. Use this to understand what semantic documentation already exists and where gaps remain.

## SQL: diagnostic (tables without semantic coverage)

```sql
SELECT t.table_name
FROM {{ database }}.information_schema.tables t
LEFT JOIN {{ database }}.information_schema.semantic_tables st
    ON t.table_name = st.base_table_name
    AND t.table_schema = st.base_table_schema
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
    AND st.base_table_name IS NULL
ORDER BY t.table_name
```

## SQL: diagnostic.semantic (semantic view inventory)

```sql
SELECT
    sv.name AS semantic_view_name,
    st.name AS logical_table_name,
    st.base_table_name,
    st.comment AS table_description
FROM {{ database }}.information_schema.semantic_views sv
JOIN {{ database }}.information_schema.semantic_tables st
    ON sv.catalog = st.semantic_view_catalog
    AND sv.schema = st.semantic_view_schema
    AND sv.name = st.semantic_view_name
WHERE sv.schema = '{{ schema }}'
ORDER BY sv.name, st.base_table_name
```
