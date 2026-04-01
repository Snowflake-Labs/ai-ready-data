# Fix: batch_throughput_sufficiency

Remediation guidance for improving batch load health and throughput in PostgreSQL.

## Context

PostgreSQL bulk loading differs fundamentally from Snowflake's `COPY INTO`. The primary bulk load mechanism is `COPY FROM`, which reads from files or stdin. Load failures in PG abort the entire transaction by default — there is no `ON_ERROR = 'CONTINUE'` equivalent. Throughput issues are typically caused by missing indexes during load, excessive WAL generation, or autovacuum contention.

## Remediation: Run VACUUM on bloated tables

Tables with high dead tuple ratios (identified in the diagnostic) need vacuuming to reclaim space and update visibility maps:

```sql
VACUUM ANALYZE {{ schema }}.{{ asset }};
```

For heavily bloated tables, use `VACUUM FULL` (requires exclusive lock):

```sql
VACUUM FULL {{ schema }}.{{ asset }};
```

## Remediation: Optimize bulk loading with COPY

Use `COPY` instead of individual `INSERT` statements for bulk loads:

```sql
COPY {{ schema }}.{{ asset }} FROM '/path/to/data.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ',');
```

## Remediation: Tune for bulk load throughput

For large batch loads, temporarily adjust session parameters:

```sql
SET maintenance_work_mem = '1GB';
SET max_wal_size = '4GB';
```

Consider dropping indexes before a large load and recreating them after, to avoid per-row index maintenance overhead.

## Remediation: Configure autovacuum

Ensure autovacuum is running frequently enough to keep dead tuple ratios low:

```sql
ALTER TABLE {{ schema }}.{{ asset }}
    SET (autovacuum_vacuum_threshold = 50,
         autovacuum_vacuum_scale_factor = 0.05);
```
