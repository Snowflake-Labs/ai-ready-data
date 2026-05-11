# Fix: retrieval_recall_compliance

Remediation guidance for vector tables without indexes or with poorly tuned index parameters.

## Context

True recall compliance requires evaluating retrieval quality against ground-truth queries, which cannot be done via metadata alone. This remediation addresses the structural prerequisites: installing `pgvector`, creating appropriate indexes, and tuning parameters for target recall levels.

## Remediation: Install pgvector

If the `pgvector` extension is not installed:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

## Remediation: Create an HNSW index

HNSW provides the best recall/latency tradeoff for most workloads. Higher `m` and `ef_construction` improve recall at the cost of build time and memory.

```sql
CREATE INDEX ON {{ schema }}.{{ asset }}
    USING hnsw ({{ vector_column }} vector_cosine_ops)
    WITH (m = 16, ef_construction = 128);
```

For L2 distance, use `vector_l2_ops`. For inner product, use `vector_ip_ops`.

## Remediation: Create an IVFFlat index

IVFFlat is faster to build and uses less memory, but requires tuning `lists` based on dataset size:

```sql
CREATE INDEX ON {{ schema }}.{{ asset }}
    USING ivfflat ({{ vector_column }} vector_cosine_ops)
    WITH (lists = {{ lists }});
```

Set `lists` to approximately `sqrt(n_rows)` for datasets under 1M rows, or `n_rows / 1000` for larger datasets.

## Remediation: Tune query-time parameters

For HNSW, increase `ef_search` to improve recall at query time:

```sql
SET hnsw.ef_search = 200;
```

For IVFFlat, increase `probes` to search more lists:

```sql
SET ivfflat.probes = 10;
```

## Remediation: Evaluate recall

After indexing, run ground-truth recall benchmarks. Compare approximate nearest neighbor results against exact (`ORDER BY <=> LIMIT k`) results to measure actual recall at your target k.
