# Fix: retrieval_recall_compliance

Remediation guidance for vector tables without indexes or with suboptimal index parameters.

## Context

True recall compliance requires evaluating retrieval quality against ground-truth queries, which cannot be done via metadata alone. This fix focuses on creating and tuning vector indexes to improve recall readiness.

PostgreSQL with `pgvector` supports two index types:

- **HNSW** — Graph-based index. Higher `m` and `ef_construction` improve recall. Recommended for most use cases. Build is slower but query recall is more predictable.
- **IVFFlat** — Cluster-based index. Recall depends on `lists` (build) and `probes` (query). Faster build time but recall is more sensitive to parameter tuning.

## Remediation: Create an HNSW index

HNSW is recommended for most vector search workloads. Increase `m` and `ef_construction` for higher recall:

```sql
CREATE INDEX {{ asset }}_vector_hnsw_idx
    ON {{ schema }}.{{ asset }}
    USING hnsw ({{ vector_column }} vector_cosine_ops)
    WITH (m = 24, ef_construction = 128);
```

Adjust parameters:
- `m` — Max connections per node (default 16, increase to 24-48 for higher recall)
- `ef_construction` — Build-time search width (default 64, increase to 128-256 for higher recall)

## Remediation: Create an IVFFlat index

IVFFlat is faster to build but requires tuning `lists` relative to dataset size. A common heuristic is `lists = sqrt(row_count)`:

```sql
CREATE INDEX {{ asset }}_vector_ivfflat_idx
    ON {{ schema }}.{{ asset }}
    USING ivfflat ({{ vector_column }} vector_cosine_ops)
    WITH (lists = {{ lists }});
```

At query time, set `probes` higher for better recall:

```sql
SET ivfflat.probes = 20;
```

## Remediation: Tune HNSW query-time parameters

Increase `ef_search` at query time for higher recall (at the cost of latency):

```sql
SET hnsw.ef_search = 100;
```

## Remediation: Run recall benchmarks

After creating or tuning indexes, run ground-truth recall benchmarks to verify the target recall threshold is met. Compare approximate nearest neighbor results against exact nearest neighbor results on a representative query set.
