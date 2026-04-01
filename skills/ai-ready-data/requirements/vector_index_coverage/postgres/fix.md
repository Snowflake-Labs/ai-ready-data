# Fix: vector_index_coverage

Remediation guidance for vector tables without similarity indexes.

## Context

pgvector supports two index types for approximate nearest neighbor (ANN) search. Without an index, queries fall back to exact brute-force scans which do not scale.

- **HNSW** — Higher build time and memory usage, but better recall and query performance. Recommended for most use cases.
- **IVFFlat** — Faster to build and lower memory, but requires periodic `REINDEX` after large data changes to maintain recall quality.

Choose the distance operator that matches your embedding model's expected similarity metric.

## Remediation: Create HNSW index (recommended)

```sql
CREATE INDEX {{ index_name }}
    ON {{ schema }}.{{ table_name }}
    USING hnsw ({{ vector_column_name }} vector_cosine_ops);
```

Common operator classes:
- `vector_cosine_ops` — cosine distance (most common for text embeddings)
- `vector_l2_ops` — Euclidean (L2) distance
- `vector_ip_ops` — inner product (dot product)

## Remediation: Create IVFFlat index (alternative)

```sql
CREATE INDEX {{ index_name }}
    ON {{ schema }}.{{ table_name }}
    USING ivfflat ({{ vector_column_name }} vector_cosine_ops)
    WITH (lists = 100);
```

Adjust `lists` based on table size — a common heuristic is `sqrt(row_count)`.

## Idempotency

Before creating an index, check whether one already exists:

```sql
SELECT 1 FROM pg_indexes
WHERE schemaname = '{{ schema }}'
    AND indexname = '{{ index_name }}';
```

Skip creation if this returns a row.
