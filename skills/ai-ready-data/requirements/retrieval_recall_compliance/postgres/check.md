# Check: retrieval_recall_compliance

Fraction of vector-indexed tables with index configurations that support target recall thresholds.

## Context

Neither Snowflake nor PostgreSQL can measure actual retrieval recall from metadata alone — that requires ground-truth benchmark queries. This check proxies recall readiness by inspecting vector index configuration quality via the `pgvector` extension.

PostgreSQL with `pgvector` supports two index types:
- **HNSW** — Higher recall at the cost of more memory. Key parameters: `m` (connections per node, default 16) and `ef_construction` (build-time search depth, default 64). Higher values improve recall.
- **IVFFlat** — Faster build, lower memory, but recall depends heavily on `lists` parameter and `probes` at query time. Key parameter: `lists` (number of inverted lists).

The check counts tables with vector columns that have at least one vector index. A score of 1.0 means every table with vector columns has a vector index. Tables with vector columns but no index score as non-compliant.

If `pgvector` is not installed, the check returns NULL.

## SQL

```sql
SELECT CASE
    WHEN NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector')
    THEN NULL
    ELSE (
        WITH vector_tables AS (
            SELECT DISTINCT a.attrelid AS table_oid, c.relname AS table_name
            FROM pg_attribute a
            JOIN pg_class c ON c.oid = a.attrelid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            JOIN pg_type t ON t.oid = a.atttypid
            WHERE n.nspname = '{{ schema }}'
                AND c.relkind = 'r'
                AND t.typname = 'vector'
                AND NOT a.attisdropped
        ),
        indexed_vector_tables AS (
            SELECT DISTINCT vt.table_oid
            FROM vector_tables vt
            WHERE EXISTS (
                SELECT 1 FROM pg_index i
                JOIN pg_class ic ON ic.oid = i.indexrelid
                JOIN pg_am am ON am.oid = ic.relam
                WHERE i.indrelid = vt.table_oid
                    AND am.amname IN ('hnsw', 'ivfflat')
            )
        )
        SELECT
            (SELECT COUNT(*) FROM indexed_vector_tables)::NUMERIC
            / NULLIF((SELECT COUNT(*) FROM vector_tables)::NUMERIC, 0)
    )
END AS value
```
