# Diagnostic: retrieval_recall_compliance

Per-table breakdown of vector columns and their index configuration.

## Context

Lists each table with vector columns, showing the column name, vector dimensions (from the type modifier), any associated vector indexes, the index method (HNSW or IVFFlat), and the index definition which encodes the build parameters. Tables without vector indexes are flagged as `NOT_INDEXED`.

Use this to identify which vector tables need indexes created and whether existing index parameters are likely to achieve target recall.

Requires the `pgvector` extension.

## SQL

```sql
WITH vector_columns AS (
    SELECT
        c.relname AS table_name,
        a.attname AS column_name,
        pg_catalog.format_type(a.atttypid, a.atttypmod) AS vector_type,
        pg_size_pretty(pg_relation_size(c.oid)) AS table_size
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND a.atttypid IN (SELECT oid FROM pg_type WHERE typname = 'vector')
        AND NOT a.attisdropped
),
vector_indexes AS (
    SELECT
        pi.tablename,
        pi.indexname,
        pi.indexdef,
        CASE
            WHEN pi.indexdef LIKE '%hnsw%' THEN 'HNSW'
            WHEN pi.indexdef LIKE '%ivfflat%' THEN 'IVFFlat'
            ELSE 'OTHER'
        END AS index_method
    FROM pg_indexes pi
    WHERE pi.schemaname = '{{ schema }}'
        AND (pi.indexdef LIKE '%hnsw%' OR pi.indexdef LIKE '%ivfflat%')
)
SELECT
    vc.table_name,
    vc.column_name,
    vc.vector_type,
    vc.table_size,
    vi.indexname AS index_name,
    vi.index_method,
    vi.indexdef AS index_definition,
    CASE
        WHEN vi.indexname IS NOT NULL THEN 'INDEXED'
        ELSE 'NOT_INDEXED'
    END AS index_status,
    CASE
        WHEN vi.indexname IS NOT NULL THEN 'Review index parameters for recall target'
        ELSE 'Create HNSW or IVFFlat index for vector search'
    END AS recommendation
FROM vector_columns vc
LEFT JOIN vector_indexes vi ON vi.tablename = vc.table_name
ORDER BY index_status, vc.table_name
```
