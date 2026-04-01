# Fix: change_detection

Add tables to a logical replication publication for CDC coverage.

## Context

Two approaches to enabling change detection in PostgreSQL:

1. **Logical replication publications** — the native CDC mechanism. Create a publication and add tables to it. Downstream subscribers (logical replication slots, Debezium, etc.) consume row-level changes. Requires `wal_level = logical` in the server configuration.
2. **Audit triggers** — create triggers that write change records to a history table. More portable but adds write overhead. Use when logical replication is not available or when you need custom change formats.

Before creating a publication, verify that `wal_level` is set to `logical`:

```sql
SHOW wal_level;
```

If it returns `replica` or `minimal`, a server restart is required after changing the setting.

## Remediation: Create a publication and add tables

```sql
CREATE PUBLICATION {{ publication_name }} FOR TABLE {{ schema }}.{{ asset }}
```

## Remediation: Add a table to an existing publication

```sql
ALTER PUBLICATION {{ publication_name }} ADD TABLE {{ schema }}.{{ asset }}
```

## Remediation: Create a publication for all tables in the schema

```sql
CREATE PUBLICATION {{ publication_name }} FOR TABLES IN SCHEMA {{ schema }}
```

## Remediation: Audit trigger pattern

Create a history table and trigger for change tracking when logical replication is not available.

```sql
CREATE TABLE IF NOT EXISTS {{ schema }}.{{ asset }}_audit (
    audit_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    operation CHAR(1) NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    old_row JSONB,
    new_row JSONB
);

CREATE OR REPLACE FUNCTION {{ schema }}.{{ asset }}_audit_fn()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO {{ schema }}.{{ asset }}_audit (operation, old_row)
        VALUES ('D', to_jsonb(OLD));
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO {{ schema }}.{{ asset }}_audit (operation, old_row, new_row)
        VALUES ('U', to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO {{ schema }}.{{ asset }}_audit (operation, new_row)
        VALUES ('I', to_jsonb(NEW));
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER {{ asset }}_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON {{ schema }}.{{ asset }}
FOR EACH ROW EXECUTE FUNCTION {{ schema }}.{{ asset }}_audit_fn();
```
