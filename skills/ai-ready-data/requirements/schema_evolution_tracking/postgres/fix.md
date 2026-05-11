# Fix: schema_evolution_tracking

Set up DDL tracking infrastructure via event triggers.

## Context

PostgreSQL event triggers fire on DDL commands at the database level. Creating a DDL audit event trigger captures schema changes for all objects in the database, providing schema evolution tracking.

This requires:
1. A logging table to store DDL events
2. A function that captures DDL event details
3. An event trigger that invokes the function on DDL commands

Event triggers require superuser or a role with the `CREATE` privilege on the database. They operate at the database level — there is no per-schema event trigger scoping (the function can filter by schema if needed).

For schema versioning and migration management, also consider tools like Flyway, Liquibase, or Alembic, which provide version-controlled schema evolution tracking with rollback capabilities.

## Remediation: Create DDL audit logging table

```sql
CREATE TABLE IF NOT EXISTS {{ schema }}.ddl_audit_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_time TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    event_type TEXT,
    object_type TEXT,
    schema_name TEXT,
    object_identity TEXT,
    command_tag TEXT,
    current_user_name TEXT DEFAULT CURRENT_USER
);
```

## Remediation: Create DDL audit function

```sql
CREATE OR REPLACE FUNCTION {{ schema }}.log_ddl_event()
RETURNS event_trigger
LANGUAGE plpgsql AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT * FROM pg_event_trigger_ddl_commands()
    LOOP
        INSERT INTO {{ schema }}.ddl_audit_log
            (event_type, object_type, schema_name, object_identity, command_tag)
        VALUES
            (TG_EVENT, r.object_type, r.schema_name, r.object_identity, r.command_tag);
    END LOOP;
END;
$$;
```

## Remediation: Create event trigger for DDL tracking

```sql
CREATE EVENT TRIGGER track_ddl_changes
    ON ddl_command_end
    EXECUTE FUNCTION {{ schema }}.log_ddl_event();
```

## Remediation: Create event trigger for DROP tracking

```sql
CREATE OR REPLACE FUNCTION {{ schema }}.log_drop_event()
RETURNS event_trigger
LANGUAGE plpgsql AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT * FROM pg_event_trigger_dropped_objects()
    LOOP
        INSERT INTO {{ schema }}.ddl_audit_log
            (event_type, object_type, schema_name, object_identity, command_tag)
        VALUES
            (TG_EVENT, r.object_type, r.schema_name, r.object_identity, TG_TAG);
    END LOOP;
END;
$$;

CREATE EVENT TRIGGER track_drop_changes
    ON sql_drop
    EXECUTE FUNCTION {{ schema }}.log_drop_event();
```
