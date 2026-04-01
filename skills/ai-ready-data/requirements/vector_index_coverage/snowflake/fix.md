# Fix: vector_index_coverage

Remediation guidance for vector tables without search optimization enabled.

## Context

Snowflake uses search optimization to accelerate vector similarity queries. Tables containing `VECTOR` columns that lack search optimization will fall back to brute-force scans, which degrades latency at scale.

To enable vector indexing, run the following on each table identified by the diagnostic:

## Fix: Enable search optimization

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ table_name }} SET SEARCH_OPTIMIZATION = ON;
```
