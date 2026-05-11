# Fix: vector_index_coverage

Remediation guidance for vector tables without a similarity index.

## Context

Without an HNSW or IVFFlat index, pgvector falls back to brute-force sequential scans for similarity queries, which degrades latency at scale. HNSW is generally preferred for its better recall accuracy and consistent performance without periodic re-training.

Requires the `pgvector` extension.

## Remediation: Create an HNSW index

For each table identified by the diagnostic as `NOT_INDEXED`, create an HNSW index on the vector column. Choose the operator class that matches your distance metric:

- `vector_cosine_ops` — cosine distance (most common for text embeddings)
- `vector_l2_ops` — Euclidean (L2) distance
- `vector_ip_ops` — inner product (max inner product search)

```sql
CREATE INDEX ON {{ schema }}.{{ table_name }}
    USING hnsw ({{ vector_column_name }} vector_cosine_ops);
```

### Optional: Tune HNSW parameters

For large datasets, adjust `m` (connections per layer) and `ef_construction` (build-time search width) to balance build time vs. recall:

```sql
CREATE INDEX ON {{ schema }}.{{ table_name }}
    USING hnsw ({{ vector_column_name }} vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);
```

### Alternative: IVFFlat index

If build time is a constraint, IVFFlat indexes are faster to create but require periodic re-training with `REINDEX` as data changes:

```sql
CREATE INDEX ON {{ schema }}.{{ table_name }}
    USING ivfflat ({{ vector_column_name }} vector_cosine_ops)
    WITH (lists = 100);
```
