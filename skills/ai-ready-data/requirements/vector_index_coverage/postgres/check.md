# Check: vector_index_coverage

Fraction of embedding collections with a vector similarity index built and maintained.

## Context

pgvector supports two index types for approximate nearest neighbor search: HNSW and IVFFlat. HNSW is generally preferred for its better recall-latency tradeoff. Tables with `vector` columns that lack a vector index fall back to exact (brute-force) scans, which degrades latency at scale.

This check finds all tables with at least one `vector` column, then checks whether each has an HNSW or IVFFlat index via the `pg_am` (access method) catalog. The score is the fraction of vector-bearing tables that have at least one vector index.

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
indexed_vector_tables AS (
    SELECT DISTINCT vt.table_name
    FROM vector_tables vt
    JOIN pg_index i ON i.indrelid = vt.table_oid
    JOIN pg_class ic ON ic.oid = i.indexrelid
    JOIN pg_am am ON am.oid = ic.relam
    WHERE am.amname IN ('hnsw', 'ivfflat')
)
SELECT
    (SELECT COUNT(*) FROM indexed_vector_tables) AS tables_with_vector_index,
    (SELECT COUNT(*) FROM vector_tables) AS total_vector_tables,
    CASE
        WHEN (SELECT COUNT(*) FROM vector_tables) = 0 THEN 1.0
        ELSE (SELECT COUNT(*) FROM indexed_vector_tables)::NUMERIC
             / (SELECT COUNT(*) FROM vector_tables)::NUMERIC
    END AS value
```
