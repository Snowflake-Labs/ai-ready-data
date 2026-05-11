# Diagnostic: retrieval_recall_compliance

Per-table breakdown of vector column index status and configuration quality.

## Context

Lists each table with vector columns, its vector indexes (if any), index type (HNSW or IVFFlat), and index parameters. Tables without vector indexes are flagged as `NOT_INDEXED`. For indexed tables, the configuration parameters are shown to help assess whether they are tuned for adequate recall.

HNSW indexes with `ef_construction >= 128` and `m >= 16` generally achieve good recall. IVFFlat indexes should have `lists` proportional to the dataset size (commonly `sqrt(n_rows)`).

## SQL

```sql
WITH vector_columns AS (
    SELECT
        c.relname AS table_name,
        a.attname AS column_name,
        c.oid AS table_oid,
        c.reltuples::BIGINT AS approx_rows
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_type t ON t.oid = a.atttypid
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND t.typname = 'vector'
        AND NOT a.attisdropped
),
vector_indexes AS (
    SELECT
        i.indrelid AS table_oid,
        ic.relname AS index_name,
        am.amname AS index_type,
        pg_get_indexdef(i.indexrelid) AS index_definition
    FROM pg_index i
    JOIN pg_class ic ON ic.oid = i.indexrelid
    JOIN pg_am am ON am.oid = ic.relam
    WHERE am.amname IN ('hnsw', 'ivfflat')
)
SELECT
    vc.table_name,
    vc.column_name,
    vc.approx_rows,
    COALESCE(vi.index_name, 'NONE') AS index_name,
    COALESCE(vi.index_type, 'NONE') AS index_type,
    COALESCE(vi.index_definition, 'N/A') AS index_definition,
    CASE
        WHEN vi.index_name IS NOT NULL THEN 'INDEXED'
        ELSE 'NOT_INDEXED'
    END AS index_status,
    CASE
        WHEN vi.index_name IS NULL THEN 'Create a vector index (HNSW recommended)'
        WHEN vi.index_type = 'hnsw' THEN 'Review ef_construction and m parameters'
        WHEN vi.index_type = 'ivfflat' THEN 'Review lists parameter — should be ~sqrt(row_count)'
        ELSE 'Review index configuration'
    END AS recommendation
FROM vector_columns vc
LEFT JOIN vector_indexes vi ON vi.table_oid = vc.table_oid
ORDER BY index_status, vc.table_name
```
