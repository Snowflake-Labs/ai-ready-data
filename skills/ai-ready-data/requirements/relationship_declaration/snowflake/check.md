# Check: relationship_declaration

Fraction of semantic views in the schema that declare at least one RELATIONSHIP between their member tables.

## Context

Semantic views in Snowflake express join paths via the `RELATIONSHIPS` clause of `CREATE SEMANTIC VIEW`. Without a declared relationship, downstream tools (Cortex Analyst, Text-to-SQL) can't reliably join across the view's member tables.

This check queries `INFORMATION_SCHEMA.SEMANTIC_VIEWS` to enumerate the schema's semantic views, then uses `GET_DDL` to inspect each view's definition for a `RELATIONSHIPS` clause. `GET_DDL` requires read privileges on the semantic view.

`INFORMATION_SCHEMA.SEMANTIC_VIEWS` is not present on accounts that have never been opted into the Snowflake semantic views preview — in that case the query will fail with an object-not-found error and the check should be reported as N/A by the orchestrator.

Returns NULL (N/A) when the schema contains no semantic views.

## SQL

```sql
WITH sv AS (
    SELECT
        semantic_view_name,
        GET_DDL(
            'SEMANTIC VIEW',
            semantic_view_catalog || '.' || semantic_view_schema || '.' || semantic_view_name
        ) AS ddl
    FROM {{ database }}.information_schema.semantic_views
    WHERE UPPER(semantic_view_schema) = UPPER('{{ schema }}')
      AND deleted IS NULL
)
SELECT
    COUNT_IF(UPPER(ddl) LIKE '%RELATIONSHIPS%') AS views_with_relationships,
    COUNT(*) AS total_semantic_views,
    COUNT_IF(UPPER(ddl) LIKE '%RELATIONSHIPS%')::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM sv
```
