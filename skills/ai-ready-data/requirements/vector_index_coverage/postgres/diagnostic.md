# Diagnostic: vector_index_coverage

Per-table breakdown of vector tables and their index status.

## Context

Lists all tables with `vector` columns and checks whether each has an HNSW or IVFFlat index. HNSW is generally preferred over IVFFlat for better recall accuracy and query performance without needing periodic re-training.

Requires the `pgvector` extension.

## SQL

```sql
WITH vector_tables AS (
    SELECT DISTINCT c.oid AS table_oid, c.relname AS table_name
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
        vt.table_name,
        ic.relname AS index_name,
        am.amname AS index_method
    FROM vector_tables vt
    JOIN pg_index i ON i.indrelid = vt.table_oid
    JOIN pg_class ic ON ic.oid = i.indexrelid
    JOIN pg_am am ON am.oid = ic.relam
    WHERE am.amname IN ('hnsw', 'ivfflat')
)
SELECT
    '{{ schema }}' AS schema_name,
    vt.table_name,
    COALESCE(vi.index_name, 'NONE') AS index_name,
    COALESCE(vi.index_method, 'NONE') AS index_method,
    CASE
        WHEN vi.index_name IS NOT NULL THEN 'INDEXED'
        ELSE 'NOT_INDEXED'
    END AS index_status,
    CASE
        WHEN vi.index_method = 'hnsw' THEN 'HNSW index present — good recall and performance'
        WHEN vi.index_method = 'ivfflat' THEN 'IVFFlat index present — consider HNSW for better recall'
        ELSE 'No vector index — run CREATE INDEX ... USING hnsw'
    END AS recommendation
FROM vector_tables vt
LEFT JOIN vector_indexes vi ON vt.table_name = vi.table_name
ORDER BY index_status DESC, vt.table_name
```
