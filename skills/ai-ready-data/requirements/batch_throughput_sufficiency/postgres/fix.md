# Fix: batch_throughput_sufficiency

Remediation guidance for improving batch load throughput and table health in PostgreSQL.

## Context

PostgreSQL batch loading performance depends on table maintenance (vacuuming, index management), load method (COPY vs INSERT), and configuration tuning. There is no single DDL fix — remediation depends on the root cause identified in the diagnostic.

## Remediation: VACUUM tables with high dead tuple ratios

Dead tuples from updates and deletes accumulate and degrade insert performance. Run VACUUM on affected tables:

```sql
VACUUM (VERBOSE, ANALYZE) {{ schema }}.{{ asset }};
```

For severely bloated tables, use VACUUM FULL (requires exclusive lock):

```sql
VACUUM FULL {{ schema }}.{{ asset }};
```

## Remediation: Use COPY for bulk loading

`COPY` is significantly faster than row-by-row INSERT for bulk loads. Use it for batch ingestion:

```sql
COPY {{ schema }}.{{ asset }} FROM '/path/to/data.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ',');
```

Or from stdin in a pipeline:

```sql
COPY {{ schema }}.{{ asset }} FROM STDIN WITH (FORMAT csv, HEADER true);
```

## Remediation: Optimize for bulk load throughput

For large batch loads, temporarily adjust session-level settings to reduce overhead:

```sql
SET maintenance_work_mem = '1GB';
SET synchronous_commit = OFF;
SET wal_level = minimal;
```

Consider dropping indexes before bulk loads and recreating them afterward — index maintenance during inserts is a common throughput bottleneck.

## Remediation: Configure autovacuum for high-churn tables

Tables that receive frequent bulk loads benefit from more aggressive autovacuum settings:

```sql
ALTER TABLE {{ schema }}.{{ asset }} SET (
    autovacuum_vacuum_scale_factor = 0.01,
    autovacuum_analyze_scale_factor = 0.005
);
```
