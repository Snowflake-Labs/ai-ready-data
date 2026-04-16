# Fix: vector_index_coverage

Remediation guidance for vector tables without search optimization enabled.

## Context

Snowflake uses search optimization to accelerate vector similarity queries. Tables containing `VECTOR` columns that lack search optimization will fall back to brute-force scans, which degrades latency at scale.

Enabling search optimization is idempotent — Snowflake will no-op if the access path already exists. The asynchronous build happens in the background; queries may not be accelerated immediately after enablement. Search optimization requires Enterprise edition.

## Fix: Enable search optimization (broad)

Enables search optimization across all eligible columns on the table. Use this when you don't yet know which vector column is the primary search target, or you want to index multiple columns:

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }} ADD SEARCH OPTIMIZATION;
```

## Fix: Enable search optimization on a specific vector column

Preferred when only one vector column is used for similarity search — scopes the storage overhead:

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }} ADD SEARCH OPTIMIZATION ON EQUALITY({{ column }});
```
