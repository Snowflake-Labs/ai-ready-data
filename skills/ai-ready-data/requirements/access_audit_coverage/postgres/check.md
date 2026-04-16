# Check: access_audit_coverage

Fraction of tables with audit logging coverage.

## Context

PostgreSQL does not have an immutable built-in access history like Snowflake's `access_history`. Audit coverage is assessed in two tiers:

1. **Primary: `pgaudit` extension** — if installed, `pgaudit` provides comprehensive statement-level and object-level audit logging for all tables. When present, the score is 1.0 (full coverage).
2. **Fallback: `pg_stat_user_tables`** — without `pgaudit`, falls back to checking which tables have recorded access activity (`seq_scan + idx_scan > 0`). This is a weaker signal — it shows tables that have been accessed since the last stats reset, not that access is being logged.

A score of 1.0 means either `pgaudit` is installed (comprehensive auditing) or every table has recorded access activity.

## SQL

```sql
SELECT CASE
    WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgaudit')
    THEN 1.0
    ELSE (
        SELECT COUNT(*) FILTER (WHERE seq_scan + idx_scan > 0)::NUMERIC
            / NULLIF(COUNT(*)::NUMERIC, 0)
        FROM pg_stat_user_tables
        WHERE schemaname = '{{ schema }}'
    )
END AS value;
```
