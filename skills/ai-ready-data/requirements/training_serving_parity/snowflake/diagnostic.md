# Diagnostic: training_serving_parity

Per-table breakdown of feature table parity status between training and serving paths.

## Context

Lists every feature table (names matching `%feature%` or `%feat_%`) with its type, row count, size, and parity status. Tables typed as `DYNAMIC TABLE` are labeled `DYNAMIC (serving-ready)` because their refresh pipeline can serve both training and real-time inference. Static `BASE TABLE` entries are labeled `STATIC (training-only)` — these lack an automated refresh path and may introduce skew between training and serving.

## SQL

```sql
SELECT
    t.table_name,
    t.table_type,
    t.row_count,
    t.bytes / (1024*1024) AS size_mb,
    CASE
        WHEN t.table_type = 'DYNAMIC TABLE' THEN 'DYNAMIC (serving-ready)'
        WHEN t.table_type = 'BASE TABLE' THEN 'STATIC (training-only)'
        ELSE t.table_type
    END AS parity_status
FROM {{ database }}.information_schema.tables t
WHERE t.table_schema = '{{ schema }}'
    AND (
        LOWER(t.table_name) LIKE '%feature%'
        OR LOWER(t.table_name) LIKE '%feat_%'
    )
ORDER BY t.table_type, t.table_name
```