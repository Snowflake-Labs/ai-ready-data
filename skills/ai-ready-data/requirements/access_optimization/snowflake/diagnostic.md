# Diagnostic: access_optimization

Per-table breakdown of clustering status across the schema.

## Context

Lists every base table with its row count, size in MB, current clustering key (if any), and a status label: `SMALL (OK)` for tables under 10,000 rows, `CLUSTERED` for large tables with a key, and `NEEDS CLUSTERING` for large tables without one.

Tables marked `NEEDS CLUSTERING` are candidates for the fix. Tables marked `SMALL (OK)` are excluded from the check score entirely.

### Clustering depth (per-table deep dive)

For tables that already have a clustering key, you can assess how effective the clustering is using the depth query below. **Only run this on tables that already have a clustering key** — `SYSTEM$CLUSTERING_DEPTH` errors on unclustered tables.

A clustering depth of 1-2 is well-clustered. Depth above 4-5 suggests the table would benefit from reclustering or a different clustering key.

## SQL

### Schema overview

```sql
SELECT
    table_name,
    row_count,
    bytes / (1024*1024) AS size_mb,
    clustering_key,
    CASE
        WHEN row_count <= 10000 THEN 'SMALL (OK)'
        WHEN clustering_key IS NOT NULL THEN 'CLUSTERED'
        ELSE 'NEEDS CLUSTERING'
    END AS status
FROM {{ database }}.information_schema.tables
WHERE table_schema = '{{ schema }}'
    AND table_type = 'BASE TABLE'
ORDER BY row_count DESC
```

### Clustering depth (single table, must already have a clustering key)

```sql
SELECT
    '{{ asset }}' AS table_name,
    SYSTEM$CLUSTERING_DEPTH('{{ database }}.{{ schema }}.{{ asset }}') AS clustering_depth,
    SYSTEM$CLUSTERING_INFORMATION('{{ database }}.{{ schema }}.{{ asset }}') AS clustering_info
```
