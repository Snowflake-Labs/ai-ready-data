# Check: chunk_readiness

Fraction of base tables in the schema that have at least one text-bearing column — a structural proxy for chunk-readiness at schema scope.

## Context

At schema scope this check is metadata-only: it identifies tables in the schema that carry a text-typed column whose name matches common text-content patterns (`text`, `content`, `description`, `body`, `message`, `comment`). Tables that have such a column are considered chunk-capable; chunk-size distribution is not measured here because assessing actual character lengths would require iterating over every candidate column's data, which the skill does not support at schema scope in a single statement.

For the stronger, data-level measurement (fraction of rows whose text length is inside the optimal 100–8000 character window), use the column-scoped variant below against a specific `{{ text_column }}`. The orchestrator can iterate and aggregate.

Pattern matching uses `REGEXP_LIKE`. `data_type` compared against Snowflake's normalized type names (`TEXT`, `VARCHAR`, `STRING`).

Returns NULL (N/A) when the schema contains no base tables.

## SQL

### Schema-level (primary, metadata proxy)

```sql
WITH base_tables AS (
    SELECT UPPER(table_name) AS table_name
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
      AND table_type = 'BASE TABLE'
),
text_bearing AS (
    SELECT DISTINCT UPPER(c.table_name) AS table_name
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
      ON c.table_catalog = t.table_catalog
     AND c.table_schema  = t.table_schema
     AND c.table_name    = t.table_name
    WHERE UPPER(c.table_schema) = UPPER('{{ schema }}')
      AND t.table_type = 'BASE TABLE'
      AND UPPER(c.data_type) IN ('TEXT','VARCHAR','STRING')
      AND REGEXP_LIKE(
          LOWER(c.column_name),
          '.*(text|content|description|body|message|comment).*'
      )
)
SELECT
    COUNT_IF(b.table_name IN (SELECT table_name FROM text_bearing))
        AS chunk_capable_tables,
    COUNT(*) AS total_tables,
    COUNT_IF(b.table_name IN (SELECT table_name FROM text_bearing))::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM base_tables b
```

### Column-level (variant: actual chunk-size measurement)

Use this when the orchestrator is iterating per candidate text column. Optimal character range is 100–8,000 (~25–2,000 tokens).

```sql
WITH text_stats AS (
    SELECT
        '{{ text_column }}' AS column_name,
        COUNT(*) AS total_rows,
        COUNT_IF(LENGTH({{ text_column }}) BETWEEN 100 AND 8000) AS optimal_length_rows,
        AVG(LENGTH({{ text_column }}))    AS avg_length,
        MEDIAN(LENGTH({{ text_column }})) AS median_length
    FROM {{ database }}.{{ schema }}.{{ asset }}
    WHERE {{ text_column }} IS NOT NULL
)
SELECT
    column_name,
    total_rows,
    optimal_length_rows,
    ROUND(avg_length, 0)    AS avg_char_length,
    ROUND(median_length, 0) AS median_char_length,
    optimal_length_rows::FLOAT / NULLIF(total_rows::FLOAT, 0) AS value
FROM text_stats
```
