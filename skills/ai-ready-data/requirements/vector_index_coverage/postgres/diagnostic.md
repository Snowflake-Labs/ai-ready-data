# Diagnostic: vector_index_coverage

Per-table breakdown of vector tables and their index status.

## Context

Lists every table in the schema that has a `vector` column, along with any HNSW or IVFFlat indexes found on that table. Tables without a vector index will show `NOT_INDEXED` and receive a recommendation to create one.

HNSW indexes are generally preferred over IVFFlat for better recall at comparable latency. IVFFlat indexes require periodic retraining (via `REINDEX`) after significant data changes to maintain quality.

## SQL

```sql
WITH vector_tables AS (
    SELECT DISTINCT
        n.nspname AS schema_name,
        c.relname AS table_name,
        c.oid AS table_oid
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_type t ON t.oid = a.atttypid
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND a.attnum > 0
        AND NOT a.attisdropped
        AND t.typname = 'vector'
),
vector_indexes AS (
    SELECT
        vt.schema_name,
        vt.table_name,
        ic.relname AS index_name,
        am.amname AS index_type,
        pg_get_indexdef(i.indexrelid) AS index_definition
    FROM vector_tables vt
    JOIN pg_index i ON i.indrelid = vt.table_oid
    JOIN pg_class ic ON ic.oid = i.indexrelid
    JOIN pg_am am ON am.oid = ic.relam
    WHERE am.amname IN ('hnsw', 'ivfflat')
)
SELECT
    vt.schema_name,
    vt.table_name,
    COALESCE(vi.index_name, 'NONE') AS index_name,
    COALESCE(vi.index_type, 'NONE') AS index_type,
    COALESCE(vi.index_definition, '') AS index_definition,
    CASE
        WHEN vi.index_name IS NOT NULL THEN 'INDEXED'
        ELSE 'NOT_INDEXED'
    END AS index_status,
    CASE
        WHEN vi.index_name IS NOT NULL THEN 'Vector index present'
        ELSE 'Create an HNSW index: CREATE INDEX ON table USING hnsw (column vector_cosine_ops)'
    END AS recommendation
FROM vector_tables vt
LEFT JOIN vector_indexes vi
    ON vt.schema_name = vi.schema_name
    AND vt.table_name = vi.table_name
ORDER BY index_status DESC, vt.table_name
```
