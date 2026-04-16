# Fix: access_audit_coverage

Enable audit logging for tables without coverage.

## Context

PostgreSQL does not have automatic immutable audit logging like Snowflake. The primary remediation is installing and configuring the `pgaudit` extension, which provides comprehensive statement-level and object-level logging.

If `pgaudit` is not available (e.g., managed environments that do not support it), alternative approaches include `pg_stat_statements` for query tracking or custom audit triggers.

Installing `pgaudit` requires superuser privileges and a server restart for the `shared_preload_libraries` setting.

## Remediation: Install pgaudit

```sql
CREATE EXTENSION IF NOT EXISTS pgaudit;
```

## Remediation: Configure pgaudit logging

Set the logging level in `postgresql.conf` or via `ALTER SYSTEM`:

```sql
ALTER SYSTEM SET pgaudit.log = 'read, write, ddl';
ALTER SYSTEM SET pgaudit.log_catalog = off;
ALTER SYSTEM SET pgaudit.log_relation = on;
```

Reload the configuration:

```sql
SELECT pg_reload_conf();
```

## Remediation: Object-level audit for specific tables

For granular per-table auditing, use object-level audit logging:

```sql
ALTER SYSTEM SET pgaudit.role = 'auditor';
```

Then grant the audit role access to tables that need logging:

```sql
GRANT SELECT, INSERT, UPDATE, DELETE ON {{ schema }}.{{ asset }} TO auditor;
```

## Remediation: Fallback audit trigger (without pgaudit)

If `pgaudit` is unavailable, create a basic audit trigger:

```sql
CREATE TABLE IF NOT EXISTS {{ schema }}.audit_log (
    id            BIGINT GENERATED ALWAYS AS IDENTITY,
    table_name    TEXT NOT NULL,
    operation     TEXT NOT NULL,
    executed_by   TEXT NOT NULL DEFAULT current_user,
    executed_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION {{ schema }}.audit_trigger_fn()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO {{ schema }}.audit_log (table_name, operation)
    VALUES (TG_TABLE_NAME, TG_OP);
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON {{ schema }}.{{ asset }}
    FOR EACH ROW EXECUTE FUNCTION {{ schema }}.audit_trigger_fn();
```
