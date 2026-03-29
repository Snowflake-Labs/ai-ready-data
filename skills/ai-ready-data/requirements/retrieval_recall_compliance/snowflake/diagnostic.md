# Diagnostic: retrieval_recall_compliance

Per-table breakdown of vector column index status for retrieval recall compliance.

## Context

Lists each base table with VECTOR columns, showing column name, data type, row count, size, and whether search optimization is enabled. Tables marked `NOT_INDEXED` lack search optimization, which is the proxy used for recall compliance when ground-truth queries are unavailable.

Use this to identify which vector tables need search optimization enabled and to prioritize by row count and size.

## SQL

```sql
SELECT
    c.table_name,
    c.column_name,
    c.data_type,
    t.row_count,
    t.bytes / (1024*1024) AS size_mb,
    CASE
        WHEN t.search_optimization = 'ON' THEN 'INDEXED'
        ELSE 'NOT_INDEXED'
    END AS index_status
FROM {{ database }}.information_schema.columns c
JOIN {{ database }}.information_schema.tables t
    ON c.table_name = t.table_name AND c.table_schema = t.table_schema
WHERE c.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
    AND c.data_type = 'VECTOR'
ORDER BY index_status, t.row_count DESC
```
