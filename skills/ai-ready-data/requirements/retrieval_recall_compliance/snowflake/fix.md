# Fix: retrieval_recall_compliance

Remediation guidance for vector tables without search optimization enabled.

## Context

True recall compliance requires evaluating retrieval quality against ground-truth queries, which cannot be done via metadata alone. This requirement proxies recall readiness by checking for search optimization on tables with VECTOR columns.

If tables show as `NOT_INDEXED` in the diagnostic:

1. **Enable search optimization.** This adds an index structure that improves vector search recall and latency. Run the remediation SQL below for each affected table.
2. **Evaluate recall separately.** After enabling search optimization, run ground-truth recall benchmarks against your query set to verify that the target recall threshold is met at the required latency.
3. **Consider vector index tuning.** Snowflake's vector search behavior depends on the index type and parameters. Review Snowflake documentation for HNSW or IVF index configuration if recall is below target.

## Fix: Enable search optimization

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ table_name }} ADD SEARCH OPTIMIZATION;
```
