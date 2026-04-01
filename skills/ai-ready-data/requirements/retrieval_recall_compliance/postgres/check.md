# Check: retrieval_recall_compliance

Fraction of vector indexes configured with parameters that support target recall thresholds.

## Context

Neither Snowflake nor PostgreSQL can measure retrieval recall from metadata alone — recall requires ground-truth benchmark queries. Both platforms proxy via index presence and configuration quality.

Snowflake uses `search_optimization` as its proxy. PostgreSQL with `pgvector` supports HNSW and IVFFlat indexes, whose recall characteristics depend on build parameters:

- **HNSW:** `m` (connections per node, default 16) and `ef_construction` (build-time search width, default 64). Higher values improve recall at the cost of build time and memory.
- **IVFFlat:** `lists` (number of clusters). Recall depends on the ratio of `lists` to `probes` at query time.

This check counts tables with vector columns that have at least one vector index, as a fraction of all tables with vector columns. A score of 1.0 means every vector table has an index. Requires the `pgvector` extension.

## SQL

```sql
SELECT CASE
    WHEN NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector')
    THEN NULL
    ELSE (
        WITH vector_tables AS (
            SELECT DISTINCT a.attrelid::regclass::TEXT AS table_name
            FROM pg_attribute a
            JOIN pg_class c ON c.oid = a.attrelid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = '{{ schema }}'
                AND c.relkind = 'r'
                AND a.atttypid IN (SELECT oid FROM pg_type WHERE typname = 'vector')
                AND NOT a.attisdropped
        ),
        indexed_tables AS (
            SELECT DISTINCT vt.table_name
            FROM vector_tables vt
            WHERE EXISTS (
                SELECT 1 FROM pg_indexes pi
                WHERE pi.schemaname = '{{ schema }}'
                    AND pi.tablename = vt.table_name
                    AND (pi.indexdef LIKE '%hnsw%' OR pi.indexdef LIKE '%ivfflat%')
            )
        )
        SELECT
            (SELECT COUNT(*) FROM indexed_tables)::NUMERIC
                / NULLIF((SELECT COUNT(*) FROM vector_tables)::NUMERIC, 0)
    )
END AS value
```
