# Fix: data_version_coverage

Remediation guidance for enabling point-in-time state reconstruction.

## Context

PostgreSQL has no built-in Time Travel. Two complementary approaches:

1. **Add temporal columns** — add `valid_from` / `valid_to` timestamp columns and maintain them via triggers or application logic. This enables SCD Type 2 patterns for point-in-time queries.
2. **History trigger pattern** — create a history table and trigger that captures row state on every change. The `temporal_tables` extension automates this.

Choose based on your use case: temporal columns are sufficient for slowly-changing dimensions; history triggers provide full audit trails for rapidly-changing tables.

## Remediation: Add temporal columns

```sql
ALTER TABLE {{ schema }}.{{ asset }}
ADD COLUMN valid_from TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN valid_to TIMESTAMPTZ NOT NULL DEFAULT 'infinity'::TIMESTAMPTZ;
```

## Remediation: History table and trigger

```sql
CREATE TABLE IF NOT EXISTS {{ schema }}.{{ asset }}_history (
    LIKE {{ schema }}.{{ asset }} INCLUDING ALL,
    history_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    valid_from TIMESTAMPTZ NOT NULL,
    valid_to TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION {{ schema }}.{{ asset }}_versioning_fn()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        INSERT INTO {{ schema }}.{{ asset }}_history
        SELECT OLD.*, nextval(pg_get_serial_sequence('{{ schema }}.{{ asset }}_history', 'history_id')),
               OLD.valid_from, CURRENT_TIMESTAMP;
    END IF;
    IF TG_OP = 'UPDATE' OR TG_OP = 'INSERT' THEN
        NEW.valid_from = CURRENT_TIMESTAMP;
        RETURN NEW;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER {{ asset }}_versioning_trigger
BEFORE INSERT OR UPDATE OR DELETE ON {{ schema }}.{{ asset }}
FOR EACH ROW EXECUTE FUNCTION {{ schema }}.{{ asset }}_versioning_fn();
```

## Remediation: Use temporal_tables extension

If the `temporal_tables` extension is available, it automates the history trigger pattern:

```sql
CREATE EXTENSION IF NOT EXISTS temporal_tables;

ALTER TABLE {{ schema }}.{{ asset }}
ADD COLUMN sys_period TSTZRANGE NOT NULL DEFAULT tstzrange(CURRENT_TIMESTAMP, NULL);

CREATE TABLE {{ schema }}.{{ asset }}_history (LIKE {{ schema }}.{{ asset }});

CREATE TRIGGER {{ asset }}_versioning_trigger
BEFORE INSERT OR UPDATE OR DELETE ON {{ schema }}.{{ asset }}
FOR EACH ROW EXECUTE FUNCTION versioning('sys_period', '{{ schema }}.{{ asset }}_history', true);
```
