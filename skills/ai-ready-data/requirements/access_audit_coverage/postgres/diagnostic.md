# Diagnostic: access_audit_coverage

Per-table breakdown of audit coverage and access activity.

## Context

Shows each base table with its access statistics and audit status. Two diagnostic views:

1. **Audit infrastructure** — checks whether `pgaudit` is installed and its configuration.
2. **Per-table access activity** — shows scan counts and activity timestamps from `pg_stat_user_tables`. Tables with `NO_ACTIVITY` have no recorded scans since the last stats reset and may lack audit trail entries.

Without `pgaudit`, `pg_stat_user_tables` provides coarse access signals but not a true audit log — it shows aggregate counts, not individual access events.

## SQL

### Audit infrastructure

```sql
SELECT
    extname       AS extension,
    extversion    AS version,
    'INSTALLED'   AS status
FROM pg_extension
WHERE extname IN ('pgaudit', 'pg_stat_statements')

UNION ALL

SELECT
    name          AS extension,
    setting       AS version,
    'CONFIGURED'  AS status
FROM pg_settings
WHERE name LIKE 'pgaudit.%'
  AND setting <> '';
```

### Per-table access activity

```sql
SELECT
    relname                           AS table_name,
    seq_scan                          AS sequential_scans,
    idx_scan                          AS index_scans,
    COALESCE(seq_scan, 0) + COALESCE(idx_scan, 0) AS total_scans,
    n_tup_ins                         AS rows_inserted,
    n_tup_upd                         AS rows_updated,
    n_tup_del                         AS rows_deleted,
    last_analyze                      AS last_analyze,
    last_autoanalyze                  AS last_autoanalyze,
    CASE
        WHEN COALESCE(seq_scan, 0) + COALESCE(idx_scan, 0) > 0
        THEN 'HAS_ACTIVITY'
        ELSE 'NO_ACTIVITY'
    END                               AS status
FROM pg_stat_user_tables
WHERE schemaname = '{{ schema }}'
ORDER BY status DESC, relname;
```
