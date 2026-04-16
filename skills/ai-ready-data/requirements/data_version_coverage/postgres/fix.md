# Fix: data_version_coverage

Remediation guidance for enabling point-in-time state reconstruction.

## Context

PostgreSQL has no built-in Time Travel. Two complementary approaches:

1. **Add temporal columns** — add `valid_from` / `valid_to` columns and a trigger that populates them on INSERT/UPDATE, enabling SCD Type 2 queries. This is the most portable approach.
2. **Use the `temporal_tables` extension** — the `temporal_tables` PostgreSQL extension provides system-period temporal tables with automatic history management. Requires the extension to be installed.

Choose based on your environment: temporal columns work everywhere; the extension provides cleaner semantics but adds a dependency.

## Remediation: Add temporal columns with history trigger

```sql
ALTER TABLE {{ schema }}.{{ asset }}
ADD COLUMN valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
ADD COLUMN valid_to TIMESTAMPTZ NOT NULL DEFAULT 'infinity'
```

```sql
CREATE TABLE {{ schema }}.{{ asset }}_history (LIKE {{ schema }}.{{ asset }} INCLUDING ALL)
```

```sql
CREATE OR REPLACE FUNCTION {{ schema }}.{{ asset }}_versioning()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        OLD.valid_to := NOW();
        INSERT INTO {{ schema }}.{{ asset }}_history VALUES (OLD.*);
    END IF;
    IF TG_OP = 'UPDATE' THEN
        NEW.valid_from := NOW();
        NEW.valid_to := 'infinity';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql
```

```sql
CREATE TRIGGER {{ asset }}_versioning_trigger
BEFORE UPDATE OR DELETE ON {{ schema }}.{{ asset }}
FOR EACH ROW EXECUTE FUNCTION {{ schema }}.{{ asset }}_versioning()
```

## Remediation: Use temporal_tables extension

```sql
CREATE EXTENSION IF NOT EXISTS temporal_tables
```

```sql
ALTER TABLE {{ schema }}.{{ asset }}
ADD COLUMN sys_period TSTZRANGE NOT NULL DEFAULT TSTZRANGE(NOW(), NULL)
```

```sql
CREATE TABLE {{ schema }}.{{ asset }}_history (LIKE {{ schema }}.{{ asset }} INCLUDING ALL)
```

```sql
CREATE TRIGGER {{ asset }}_versioning_trigger
BEFORE INSERT OR UPDATE OR DELETE ON {{ schema }}.{{ asset }}
FOR EACH ROW EXECUTE FUNCTION versioning('sys_period', '{{ schema }}.{{ asset }}_history', true)
```
